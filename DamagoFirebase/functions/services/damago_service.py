import os
import json
from datetime import datetime, timezone, timedelta
import random
from firebase_functions import https_fn
from firebase_admin import firestore
import google.cloud.firestore
from google.cloud.firestore import FieldFilter
from google.cloud import tasks_v2
from google.protobuf import timestamp_pb2

from utils.firestore import get_db
from utils.middleware import get_uid_from_request
from utils.constants import (
    get_required_exp, 
    get_level_up_reward, 
    FEED_EXP, 
    IS_EMULATOR, 
    PROJECT_ID, 
    LOCATION, 
    QUEUE_NAME, 
    HUNGER_DELAY_SECONDS,
    AVAILABLE_DAMAGO_TYPES
)
from services.push_service import update_live_activity_internal

def pick_random_damago() -> str:
    """
    뽑기 로직을 수행하여 다마고 타입을 반환합니다.
    현재는 모든 타입에 대해 균등한 확률(Uniform Distribution)을 가집니다.
    """
    return random.choice(AVAILABLE_DAMAGO_TYPES)

def feed(req: https_fn.Request) -> https_fn.Response:
    """
    다마고에게 먹이를 줍니다.
    경험치를 증가시키고, 레벨업 여부를 판단하여 DB를 업데이트합니다.
    이후 Cloud Tasks를 통해 4시간(또는 테스트 모드 시 10초) 뒤 배고픔 상태로 전환되도록 예약합니다.
    """
    # --- [Parameters] ---
    try:
        # 미들웨어로 UID 추출
        uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)

    data = req.get_json(silent=True) or req.args
    damago_id = data.get("damagoID")

    if not damago_id:
        return https_fn.Response("Missing damagoID", status=400)

    db = get_db()
    damago_ref = db.collection("damagos").document(damago_id)

    @google.cloud.firestore.transactional
    def run_feed_transaction(transaction, doc_ref):
        snapshot = doc_ref.get(transaction=transaction)
        
        if not snapshot.exists:
            return None

        data = snapshot.to_dict()
        current_level = data.get("level", 1)
        current_exp = data.get("currentExp", 0)
        couple_id = data.get("coupleID")
        
        # --- [Ownership Validation] ---
        # 다마고의 주인이 맞는지 검증
        if not couple_id:
             raise ValueError("This damago has no couple owner")

        couple_ref = db.collection("couples").document(couple_id)
        couple_snapshot = couple_ref.get(transaction=transaction)
        
        if not couple_snapshot.exists:
             raise ValueError("Couple info not found")
        
        couple_data = couple_snapshot.to_dict()
        # 변경된 필드명 사용 (user1UDID -> user1UID)
        user1 = couple_data.get("user1UID")
        user2 = couple_data.get("user2UID")

        if uid != user1 and uid != user2:
             raise PermissionError("You are not the owner of this damago")

        # --- [Food Consumption Logic] ---
        current_food_count = couple_data.get("foodCount", 0)
        if current_food_count <= 0:
            raise ValueError("Not enough food")
        
        new_food_count = current_food_count - 1

        # --- [Experience Logic] ---
        new_exp = current_exp + FEED_EXP
        new_level = current_level
        
        # 레벨업 계산 (초과 경험치 이월)
        # 무한 레벨이므로 while 루프로 연속 레벨업 처리 가능
        required_exp = get_required_exp(new_level)
        while new_exp >= required_exp:
            new_exp -= required_exp
            new_level += 1
            required_exp = get_required_exp(new_level)
        
        # --- [Reward Logic] ---
        reward_coin = 0
        if new_level > current_level:
            # 상승한 레벨만큼 보상 계산 (e.g. 5->7로 2업 했으면 6, 7레벨 보상 체크)
            for lv in range(current_level + 1, new_level + 1):
                reward_coin += get_level_up_reward(lv)

        # --- [DB Update] ---
        update_data = {
            "level": new_level,
            "currentExp": new_exp,
            "maxExp": get_required_exp(new_level),
            "isHungry": False,
            "lastFedAt": firestore.SERVER_TIMESTAMP,
            "lastUpdatedAt": firestore.SERVER_TIMESTAMP,
            "statusMessage": "냠냠! 밥이 너무 맛있어요! 🍚"
        }
        transaction.update(doc_ref, update_data)

        # 커플 문서 업데이트 (먹이 차감 및 코인 보상)
        couple_updates = {"foodCount": new_food_count}
        if reward_coin > 0:
            couple_updates["totalCoin"] = firestore.Increment(reward_coin)
            
        transaction.update(couple_ref, couple_updates)

        return {
            "level": new_level,
            "currentExp": new_exp,
            "maxExp": get_required_exp(new_level),
            "isLevelUp": new_level > current_level,
            "isHungry": False,
            "rewardCoin": reward_coin,
            "foodCount": new_food_count,
            "user1UID": user1,
            "user2UID": user2,
            "damagoType": data.get("damagoType", "Bunny"),
            "statusMessage": update_data["statusMessage"],
            "damagoName": data.get("damagoName", "이름 없는 다마고")
        }

    try:
        result = run_feed_transaction(db.transaction(), damago_ref)
        if result is None:
             return https_fn.Response("Damago not found", status=404)
        
        # --- [Live Activity Update] ---
        # 밥 주기 성공 시 파트너에게만 Live Activity 업데이트 전송 (본인은 로컬에서 직접 업데이트)
        try:
            partner_uid = result.get("user2UID") if uid == result.get("user1UID") else result.get("user1UID")
            now_str = datetime.now(timezone.utc).isoformat(timespec='seconds')
            
            content_state = {
                "damagoType": result.get("damagoType"),
                "isHungry": False,
                "statusMessage": result.get("statusMessage"),
                "level": result.get("level"),
                "currentExp": result.get("currentExp"),
                "maxExp": result.get("maxExp"),
                "lastFedAt": now_str
            }
            
            attributes = {
                "damagoName": result.get("damagoName")
            }

            if partner_uid:
                update_live_activity_internal(partner_uid, content_state, attributes)
                    
        except Exception as la_error:
            print(f"Failed to update Live Activity for partner: {la_error}")

        # --- [Cloud Task Scheduling] ---
        try:
            client = tasks_v2.CloudTasksClient()
            parent = client.queue_path(PROJECT_ID, LOCATION, QUEUE_NAME)
            
            # 태스크 페이로드 설정
            task_payload = {"damagoID": damago_id}
            json_payload = json.dumps(task_payload).encode()

            # 실행 시간 설정
            # 환경 변수 IS_TEST_MODE가 true이면 10초, 아니면 기본값(4시간) 사용
            is_test_mode = os.environ.get("IS_TEST_MODE", "false").lower() == "true"
            delay_seconds = 10 if is_test_mode else HUNGER_DELAY_SECONDS
            
            d = datetime.now(timezone.utc) + timedelta(seconds=delay_seconds)
            timestamp = timestamp_pb2.Timestamp()
            timestamp.FromDatetime(d)

            # 에뮬레이터 환경이면 로컬 주소 사용
            is_emulator = os.environ.get("FUNCTIONS_EMULATOR") == "true"

            if is_emulator:
                target_url = f"http://127.0.0.1:5001/{PROJECT_ID}/{LOCATION}/make_hungry"
            else:
                target_url = f"https://{LOCATION}-{PROJECT_ID}.cloudfunctions.net/make_hungry"
                
            service_acount_email = f"{PROJECT_ID}@appspot.gserviceaccount.com"

            task = {
                "http_request": {
                    "http_method": tasks_v2.HttpMethod.POST,
                    "url": target_url,
                    "headers": {"Content-Type": "application/json"},
                    "body": json_payload,
                },
                "schedule_time": timestamp,
            }
            
            if not IS_EMULATOR:
                task["http_request"]["oidc_token"] = {
                    "service_account_email": service_acount_email
                }

            client.create_task(request={"parent": parent, "task": task})
            print(f"Cloud Task scheduled for damago {damago_id} at {d}")

        except Exception as task_error:
            print(f"Failed to schedule Cloud Task: {task_error}")
            # 태스크 실패가 전체 요청 실패로 이어지지는 않도록 함 (DB는 이미 업데이트됨)

        return https_fn.Response(
            json.dumps(result), 
            mimetype="application/json"
        )
    except ValueError as ve:
         return https_fn.Response(str(ve), status=400)
    except PermissionError as pe:
         return https_fn.Response(str(pe), status=403)
    except Exception as e:
        return https_fn.Response(f"Transaction failed: {str(e)}", status=500)

@https_fn.on_request()
def make_hungry(req: https_fn.Request) -> https_fn.Response:
    """
    Cloud Tasks에 의해 호출되어 다마고를 배고픔 상태로 변경합니다.
    마지막으로 밥을 먹은 지 충분한 시간이 지났는지 검증합니다.
    """
    data = req.get_json(silent=True) or req.args
    damago_id = data.get("damagoID")

    if not damago_id:
        return https_fn.Response("Missing damagoID", status=400)

    db = get_db()
    damago_ref = db.collection("damagos").document(damago_id)
    
    doc = damago_ref.get()
    if not doc.exists:
        return https_fn.Response("Damago not found", status=404)
        
    damago_data = doc.to_dict()
    
    # 이미 배고프면 패스
    if damago_data.get("isHungry", False):
        return https_fn.Response("Already hungry", status=200)

    # --- [Validation: 중복 실행 방지] ---
    last_fed_at = damago_data.get("lastFedAt")
    if last_fed_at:
        # DB의 lastFedAt은 datetime 객체 (timezone 정보 포함 가능)
        # 비교를 위해 UTC 기준으로 통일
        now = datetime.now(timezone.utc)
        
        # 환경 변수 체크 (테스트 모드일 땐 10초, 아니면 4시간)
        is_test_mode = os.environ.get("IS_TEST_MODE", "false").lower() == "true"
        delay_seconds = 10 if is_test_mode else HUNGER_DELAY_SECONDS
        
        # 경과 시간 계산
        elapsed = (now - last_fed_at).total_seconds()
        
        # 아직 시간이 덜 지났으면(즉, 그 사이에 밥을 또 줬으면) 무시
        # 약간의 오차(예: 5초)를 두어 실행 지연으로 인한 실패 방지
        if elapsed < (delay_seconds - 5):
            print(f"Skipping make_hungry: Fed recently ({elapsed}s ago)")
            return https_fn.Response("Skipped: Fed recently", status=200)

    # 상태 업데이트
    new_status = "배고파요... 밥 주세요! 꼬르륵"
    damago_ref.update({
        "isHungry": True,
        "statusMessage": new_status,
        "lastUpdatedAt": firestore.SERVER_TIMESTAMP
    })
    
    # --- [Notify Users] ---
    # 해당 다마고를 보고 있는 커플 유저들을 찾아 알림 전송
    couple_id = damago_data.get("coupleID")
    if couple_id:
        couple_doc = db.collection("couples").document(couple_id).get()
        if couple_doc.exists:
            couple_data = couple_doc.to_dict()
            # 변경된 필드명 사용 (user1UDID -> user1UID)
            users = [couple_data.get("user1UID"), couple_data.get("user2UID")]
            
            last_fed_at = damago_data.get("lastFedAt")
            last_fed_at_str = last_fed_at.isoformat(timespec='seconds') if last_fed_at else None
            
            # Live Activity Payload
            content_state = {
                "damagoType": damago_data.get("damagoType", "Bunny"),
                "isHungry": True,
                "statusMessage": new_status,
                "level": damago_data.get("level"),
                "currentExp": damago_data.get("currentExp"),
                "maxExp": damago_data.get("maxExp"),
                "lastFedAt": last_fed_at_str
            }
            
            attributes = {
                "damagoName": damago_data.get("damagoName", "이름 없는 다마고")
            }
            
            for uid in users:
                if uid:
                    update_live_activity_internal(uid, content_state, attributes)

    return https_fn.Response("Made hungry and notified", status=200)

@https_fn.on_request()
def create_damago(req: https_fn.Request) -> https_fn.Response:
    """
    새로운 다마고를 생성합니다 (뽑기).
    서버에서 랜덤으로 다마고를 결정하며, 커플의 코인을 100 차감합니다.
    """
    try:
        uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)
        
    db = get_db()
    
    # 1. 유저 및 커플 ID 조회 (Transaction 밖에서 조회하여 쿼리 기반 마련)
    user_doc = db.collection("users").document(uid).get()
    if not user_doc.exists:
        return https_fn.Response("User not found", status=404)
        
    couple_id = user_doc.to_dict().get("coupleID")
    if not couple_id:
        return https_fn.Response("User has no couple", status=400)
        
    # 2. 랜덤 선택 (전체 목록에서 무작위 선택)
    target_type = pick_random_damago()
    
    couple_ref = db.collection("couples").document(couple_id)
    
    @google.cloud.firestore.transactional
    def run_create_transaction(transaction):
        couple_snapshot = couple_ref.get(transaction=transaction)
        if not couple_snapshot.exists:
            raise ValueError("Couple not found")
            
        couple_data = couple_snapshot.to_dict()
        current_coin = couple_data.get("totalCoin", 0)
        
        # 중복 확인 (ID 기반)
        new_damago_id = f"{couple_id}_{target_type}"
        new_damago_ref = db.collection("damagos").document(new_damago_id)
        existing_damago = new_damago_ref.get(transaction=transaction)

        # 코인 확인
        draw_cost = 100
        if current_coin < draw_cost:
            raise ValueError("Not enough coins")
            
        is_new = not existing_damago.exists
        
        # 코인 차감 (공통)
        new_coin = current_coin - draw_cost
        couple_updates = {"totalCoin": new_coin}
        
        if is_new:
            # 신규 캐릭터: 다마고 생성
            new_damago_data = {
                "id": new_damago_id,
                "coupleID": couple_id,
                "damagoName": "이름 없는 다마고",
                "damagoType": target_type,
                "isHungry": False,
                "statusMessage": "안녕! 만나서 반가워!",
                "level": 1,
                "currentExp": 0,
                "maxExp": get_required_exp(1),
                "lastFedAt": firestore.SERVER_TIMESTAMP,
                "lastUpdatedAt": firestore.SERVER_TIMESTAMP,
                "createdAt": firestore.SERVER_TIMESTAMP,
                "totalPlayTime": 0,
                "lastActiveAt": firestore.SERVER_TIMESTAMP
            }
            transaction.set(new_damago_ref, new_damago_data)
        else:
            # 중복 캐릭터: 먹이 5개 지급
            couple_updates["foodCount"] = firestore.Increment(5)
        
        # 커플 문서 업데이트
        transaction.update(couple_ref, couple_updates)
        
        return {
            "id": new_damago_id,
            "totalCoin": new_coin,
            "damagoType": target_type,
            "isNew": is_new
        }

    try:
        result = run_create_transaction(db.transaction())
        return https_fn.Response(json.dumps(result), mimetype="application/json")
    except ValueError as ve:
        return https_fn.Response(str(ve), status=400)
    except Exception as e:
        return https_fn.Response(f"Transaction failed: {str(e)}", status=500)