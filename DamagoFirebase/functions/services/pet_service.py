from firebase_functions import https_fn
from firebase_admin import firestore
import google.cloud.firestore
from google.cloud import tasks_v2
from google.protobuf import timestamp_pb2
import json
import datetime
import os
from utils.firestore import get_db
from utils.constants import XP_TABLE, MAX_LEVEL, FEED_EXP, PROJECT_ID, LOCATION, QUEUE_NAME, HUNGER_DELAY_SECONDS
from services.push_service import update_live_activity_internal

def feed(req: https_fn.Request) -> https_fn.Response:
    """
    펫에게 먹이를 줍니다.
    경험치를 증가시키고, 레벨업 여부를 판단하여 DB를 업데이트합니다.
    이후 Cloud Tasks를 통해 4시간(또는 테스트 모드 시 10초) 뒤 배고픔 상태로 전환되도록 예약합니다.
    """
    # --- [Parameters] ---
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
        
        # 만렙 & 경험치 풀이면 더 이상 성장 안 함
        if current_level >= MAX_LEVEL and current_exp >= XP_TABLE[MAX_LEVEL - 1]:
            return {"message": "Max level reached", "level": current_level, "exp": current_exp}

        # --- [Experience Logic] ---
        new_exp = current_exp + FEED_EXP
        new_level = current_level
        
        # 레벨업 계산 (초과 경험치 이월)
        if new_level < MAX_LEVEL:
            max_exp_for_current = XP_TABLE[new_level - 1]
            while new_exp >= max_exp_for_current:
                new_exp -= max_exp_for_current
                new_level += 1
                if new_level >= MAX_LEVEL:
                    new_level = MAX_LEVEL
                    if new_exp > XP_TABLE[MAX_LEVEL - 1]:
                        new_exp = XP_TABLE[MAX_LEVEL - 1]
                    break
                max_exp_for_current = XP_TABLE[new_level - 1]
        
        # 만렙 경험치 상한 고정
        if new_level == MAX_LEVEL:
            limit = XP_TABLE[MAX_LEVEL - 1]
            if new_exp > limit:
                new_exp = limit

        # --- [DB Update] ---
        transaction.update(doc_ref, {
            "level": new_level,
            "currentExp": new_exp,
            "maxExp": XP_TABLE[new_level - 1] if new_level <= MAX_LEVEL else XP_TABLE[-1],
            "isHungry": False,
            "lastFedAt": firestore.SERVER_TIMESTAMP,
            "lastUpdatedAt": firestore.SERVER_TIMESTAMP,
            "statusMessage": "냠냠! 밥이 너무 맛있어요! 🍚"
        })

        return {
            "level": new_level,
            "currentExp": new_exp,
            "maxExp": XP_TABLE[new_level - 1] if new_level <= MAX_LEVEL else XP_TABLE[-1],
            "isLevelUp": new_level > current_level
        }

    try:
        result = run_feed_transaction(db.transaction(), damago_ref)
        if result is None:
             return https_fn.Response("Damago not found", status=404)
        
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
            
            d = datetime.datetime.utcnow() + datetime.timedelta(seconds=delay_seconds)
            timestamp = timestamp_pb2.Timestamp()
            timestamp.FromDatetime(d)

            task = {
                "http_request": {
                    "http_method": tasks_v2.HttpMethod.POST,
                    "url": f"https://{LOCATION}-{PROJECT_ID}.cloudfunctions.net/make_hungry",
                    "headers": {"Content-Type": "application/json"},
                    "body": json_payload,
                },
                "schedule_time": timestamp,
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
    except Exception as e:
        return https_fn.Response(f"Transaction failed: {str(e)}", status=500)

@https_fn.on_request()
def make_hungry(req: https_fn.Request) -> https_fn.Response:
    """
    Cloud Tasks에 의해 호출되어 펫을 배고픔 상태로 변경합니다.
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
        
    pet_data = doc.to_dict()
    
    # 이미 배고프면 패스
    if pet_data.get("isHungry", False):
        return https_fn.Response("Already hungry", status=200)

    # --- [Validation: 중복 실행 방지] ---
    last_fed_at = pet_data.get("lastFedAt")
    if last_fed_at:
        # DB의 lastFedAt은 datetime 객체 (timezone 정보 포함 가능)
        # 비교를 위해 UTC 기준으로 통일
        now = datetime.datetime.now(datetime.timezone.utc)
        
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
    # 해당 펫을 보고 있는 커플 유저들을 찾아 알림 전송
    couple_id = pet_data.get("coupleID")
    if couple_id:
        couple_doc = db.collection("couples").document(couple_id).get()
        if couple_doc.exists:
            couple_data = couple_doc.to_dict()
            users = [couple_data.get("user1UDID"), couple_data.get("user2UDID")]
            
            last_fed_at = pet_data.get("lastFedAt")
            last_fed_at_str = last_fed_at.isoformat() if last_fed_at else None
            
            # Live Activity Payload
            content_state = {
                "petType": pet_data.get("petType", "Teddy"),
                "isHungry": True,
                "statusMessage": new_status,
                "level": pet_data.get("level"),
                "currentExp": pet_data.get("currentExp"),
                "maxExp": pet_data.get("maxExp"),
                "lastFedAt": last_fed_at_str
            }
            
            for udid in users:
                if udid:
                    update_live_activity_internal(udid, content_state)

    return https_fn.Response("Made hungry and notified", status=200)