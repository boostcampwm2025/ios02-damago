# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_functions.options import set_global_options
from firebase_admin import initialize_app, firestore, messaging
from nanoid import generate
import google.cloud.firestore
import time
import os

# For cost control, you can set the maximum number of containers that can be
# running at the same time. This helps mitigate the impact of unexpected
# traffic spikes by instead downgrading performance. This limit is a per-function
# limit. You can override the limit for each function using the max_instances
# parameter in the decorator, e.g. @https_fn.on_request(max_instances=5).
set_global_options(max_instances=10)
initialize_app()

# 앱의 번들 ID (APNS Topic 설정용)
# 환경 변수에서 가져오거나, 없으면 기본값 사용
BUNDLE_ID = os.environ.get("BUNDLE_ID", "kr.codesquad.boostcamp10.Damago")

@https_fn.on_request()
def generate_code(req: https_fn.Request) -> https_fn.Response:
    # --- [Parameters] ---
    data = req.get_json(silent=True) or req.args
    udid = data.get("udid")
    fcm_token = data.get("fcmToken")

    if not udid or not fcm_token:
        return https_fn.Response("Missing udid or fcmToken", status=400)

    db = firestore.client()
    users_ref = db.collection("users")
    doc_ref = users_ref.document(udid)

    # --- [Step 1] 해당 UDID 유저 검사 ---
    doc_snapshot = doc_ref.get()

    if doc_snapshot.exists:
        user_data = doc_snapshot.to_dict()
        existing_code = user_data.get("code")

        # --- [Step 1.1] FCM 토큰 갱신 로직 ---
        # 저장된 토큰이 없거나, 현재 요청받은 토큰과 다르면 업데이트
        current_db_token = user_data.get("fcmToken")

        if current_db_token != fcm_token:
            doc_ref.update({
                "fcmToken": fcm_token,
                "updatedAt": firestore.SERVER_TIMESTAMP
            })
            print(f"Updated FCM token for user {udid}")

        return https_fn.Response(f"{existing_code}")

    # --- [Step 2] 고유 코드 생성 (NanoID 라이브러리 사용) ---
    # 헷갈리는 문자(0, O, 1, I, l)를 제외한 안전한 알파벳
    safe_alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'
    max_retries = 10
    unique_code = None

    for _ in range(max_retries):
        # 라이브러리를 사용하여 8자리 코드 생성
        temp_code = generate(alphabet=safe_alphabet, size=8)

        # 중복 검사
        query = users_ref.where("code", "==", temp_code).limit(1).stream()

        if not next(query, None):
            unique_code = temp_code
            break

    if unique_code is None:
        return https_fn.Response("Unable to generate new code", status=500)

    # --- [Step 3] 신규 유저 생성 ---
    # Schema.dbml 기반으로 모든 필드 초기화 (iOS Codable 호환성 향상)
    doc_ref.set({
        "udid": udid,
        "code": unique_code,
        "partnerUDID": None,
        "damagoID": None,
        "coupleID": None,
        "anniversaryDate": None,
        "nickname": None,
        "fcmToken": fcm_token,
        "laStartToken": None,
        "laUpdateToken": None,
        "useFCM": True,
        "useLiveActivity": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP
    })

    # --- [Step 4] 코드 리턴 ---
    return https_fn.Response(f"{unique_code}")

@https_fn.on_request()
def connect_couple(req: https_fn.Request) -> https_fn.Response:
    # --- [Parameters] ---
    data = req.get_json(silent=True) or req.args
    my_code = data.get("myCode")
    target_code = data.get("targetCode")

    if not my_code or not target_code:
        return https_fn.Response("Missing 'myCode' or 'targetCode'", status=400)

    if my_code == target_code:
        return https_fn.Response("Cannot connect to yourself", status=400)

    db = firestore.client()
    users_ref = db.collection("users")

    # --- [Step 1] 사용자 검색 (내 정보 & 상대 정보) ---
    # code 필드는 Unique하다고 가정
    my_snapshot = users_ref.where("code", "==", my_code).limit(1).get()
    target_snapshot = users_ref.where("code", "==", target_code).limit(1).get()

    # --- [Step 1-1] 유저가 존재하는지 검사 ---
    if not my_snapshot or not target_snapshot:
        return https_fn.Response("User not found (Invalid Code)", status=404)

    # 쿼리 결과에서 실제 문서(DocumentSnapshot) 가져오기
    my_doc = my_snapshot[0]
    target_doc = target_snapshot[0]

    # --- [Step 2] ID 생성 (Couple 및 Damago) ---
    # 예: code_A와 code_B가 있으면 항상 알파벳 순서로 "codeA_codeB" 형태가 됨
    codes = sorted([my_code, target_code])
    couple_doc_id = f"{codes[0]}_{codes[1]}"
    couple_ref = db.collection("couples").document(couple_doc_id)
    
    # 다마고치 ID는 자동 생성
    damago_ref = db.collection("damagos").document()

    # --- [Transaction] 데이터 일관성 보장 ---
    # 커플 문서 생성과 각 유저의 coupleID 업데이트가 동시에 성공하거나 실패해야 함

    @google.cloud.firestore.transactional
    def run_transaction(transaction, couple_ref, damago_ref, my_ref, target_ref, my_udid, target_udid):
        snapshot = couple_ref.get(transaction=transaction)

        # --- [Step 2-1] 이미 커플 문서가 존재하면 반환 ---
        if snapshot.exists:
            return "ok"

        # --- [Step 3] Damago (펫) 생성 ---
        transaction.set(damago_ref, {
            "id": damago_ref.id,
            "coupleID": couple_ref.id,
            "petName": "이름 없는 펫",
            "characterName": "Teddy",
            "isHungry": False,
            "statusMessage": "반가워요! 우리 잘 지내봐요.",
            "lastFedAt": None,
            "lastUpdatedAt": firestore.SERVER_TIMESTAMP
        })

        # --- [Step 4] Couples 컬렉션 생성 (damagoID 포함) ---
        transaction.set(couple_ref, {
            "id": couple_ref.id,
            "user1UDID": my_udid,
            "user2UDID": target_udid,
            "damagoID": damago_ref.id,
            "anniversaryDate": None,
            "createdAt": firestore.SERVER_TIMESTAMP
        })

        # --- [Step 5] 나와 상대 User Document 업데이트 ---
        # 비정규화: partnerUDID와 damagoID를 직접 업데이트하여 이후 조회 성능 최적화
        transaction.update(my_ref, {
            "coupleID": couple_ref.id,
            "damagoID": damago_ref.id,
            "partnerUDID": target_udid,
            "updatedAt": firestore.SERVER_TIMESTAMP
        })
        transaction.update(target_ref, {
            "coupleID": couple_ref.id,
            "damagoID": damago_ref.id,
            "partnerUDID": my_udid,
            "updatedAt": firestore.SERVER_TIMESTAMP
        })

        return "ok"

    # 트랜잭션 실행
    try:
        result_message = run_transaction(
            db.transaction(),
            couple_ref,
            damago_ref,
            my_doc.reference,
            target_doc.reference,
            my_doc.get("udid"),
            target_doc.get("udid")
        )
    except Exception as e:
        return https_fn.Response(f"Transaction failed: {str(e)}", status=500)

    # --- [Step 6] 반환 ---
    return https_fn.Response(result_message)

@https_fn.on_request()
def poke(req: https_fn.Request) -> https_fn.Response:
    # --- [Parameters] ---
    data = req.get_json(silent=True) or req.args
    my_udid = data.get("udid")

    if not my_udid:
        return https_fn.Response("Missing 'udid'", status=400)

    db = firestore.client()

    # --- [Step 1] 내 정보 조회 ---
    # partnerUDID를 사용하여 couples 조회 단계를 생략 (성능 최적화)
    my_user_ref = db.collection("users").document(my_udid)
    my_user_doc = my_user_ref.get()

    if not my_user_doc.exists:
        return https_fn.Response("User not found", status=404)

    my_user_data = my_user_doc.to_dict()
    partner_udid = my_user_data.get("partnerUDID")

    if not partner_udid:
        return https_fn.Response("User is not in a couple", status=400)

    # --- [Step 2] 상대방 정보 조회 ---
    target_user_doc = db.collection("users").document(partner_udid).get()

    if not target_user_doc.exists:
        return https_fn.Response("Opponent not found", status=404)

    target_user_data = target_user_doc.to_dict()
    target_fcm_token = target_user_data.get("fcmToken")

    if not target_fcm_token:
        return https_fn.Response("Opponent's FCM token not found", status=404)

    # --- [Step 3] 푸시 알림 보내기 ---
    try:
        nickname = my_user_data.get('nickname') or '상대방'
        message = messaging.Message(
            notification=messaging.Notification(
                title="콕!",
                body=f"{nickname}님이 당신을 콕 찔렀어요!",
            ),
            token=target_fcm_token
        )
        response = messaging.send(message)
        print("Successfully sent message:", response)
        return https_fn.Response("Push notification sent successfully")

    except Exception as e:
        print("Error sending message:", e)
        return https_fn.Response(f"Error sending push notification: {str(e)}", status=500)

@https_fn.on_request()
def save_live_activity_token(req: https_fn.Request) -> https_fn.Response:
    # --- [Parameters] ---
    data = req.get_json(silent=True) or req.args
    udid = data.get("udid")
    # iOS: Activity.pushToken (Hex String)
    la_update_token = data.get("laUpdateToken")
    # iOS: ActivityAuthorizationInfo().pushToStartToken (Hex String)
    la_start_token = data.get("laStartToken")

    if not udid:
        return https_fn.Response("Missing udid", status=400)

    db = firestore.client()
    user_ref = db.collection("users").document(udid)

    # --- [Step 1] Live Activity 토큰 업데이트 ---
    update_data = {"updatedAt": firestore.SERVER_TIMESTAMP}
    if la_update_token: update_data["laUpdateToken"] = la_update_token
    if la_start_token: update_data["laStartToken"] = la_start_token

    user_ref.update(update_data)

    # --- [Step 2] 결과 반환 ---
    return https_fn.Response("Live Activity Token Saved")

@https_fn.on_request()
def update_live_activity(req: https_fn.Request) -> https_fn.Response:
    # --- [Parameters] ---
    data = req.get_json(silent=True) or req.args
    target_udid = data.get("targetUDID")
    content_state = data.get("contentState") 

    if not target_udid or not content_state:
        return https_fn.Response("Missing targetUDID or contentState", status=400)

    db = firestore.client()
    
    # --- [Step 1] 대상 유저 조회 ---
    user_doc = db.collection("users").document(target_udid).get()
    
    if not user_doc.exists:
        return https_fn.Response("User not found", status=404)

    user_data = user_doc.to_dict()
    fcm_token = user_data.get("fcmToken")
    la_token = user_data.get("laUpdateToken")
    use_la = user_data.get("useLiveActivity", True)

    if not fcm_token or not la_token or not use_la:
        return https_fn.Response("Live Activity not active or disabled", status=200)

    # --- [Step 2] APNs Payload 구성 및 전송 ---
    try:
        # APNs Payload: Aps 객체 생성 및 Custom Data 설정
        aps = messaging.Aps(
            alert=messaging.ApsAlert(
                title="다마고 상태 변경",
                body="다마고치가 반응했어요!"
            ),
            custom_data={
                "event": "update",
                "timestamp": int(time.time()),
                "content-state": content_state
            }
        )
        
        message = messaging.Message(
            token=fcm_token, # FCM 등록 토큰 (Device Target)
            apns=messaging.APNSConfig(
                live_activity_token=la_token, # LA 업데이트 토큰 (APNs Target)
                headers={
                    "apns-push-type": "liveactivity",
                    "apns-topic": f"{BUNDLE_ID}.push-type.liveactivity",
                    "apns-priority": "10"
                },
                payload=messaging.APNSPayload(aps=aps)
            )
        )
        response = messaging.send(message)
        print(f"Live Activity update sent to {target_udid}: {response}")
        return https_fn.Response(f"Live Activity Updated")

    except Exception as e:
        print(f"Error updating Live Activity: {e}")
        return https_fn.Response(f"Error: {str(e)}", status=500)

@https_fn.on_request()
def start_live_activity(req: https_fn.Request) -> https_fn.Response:
    # --- [Parameters] ---
    data = req.get_json(silent=True) or req.args
    target_udid = data.get("targetUDID")
    attributes = data.get("attributes")
    content_state = data.get("contentState")

    if not target_udid or not attributes or not content_state:
        return https_fn.Response("Missing parameters", status=400)

    db = firestore.client()
    
    # --- [Step 1] 대상 유저 조회 ---
    user_doc = db.collection("users").document(target_udid).get()
    if not user_doc.exists:
        return https_fn.Response("User not found", status=404)

    user_data = user_doc.to_dict()
    fcm_token = user_data.get("fcmToken")
    la_start_token = user_data.get("laStartToken")
    use_la = user_data.get("useLiveActivity", True)

    if not fcm_token or not la_start_token or not use_la:
        return https_fn.Response("Start Token not found or Live Activity disabled", status=400)

    # --- [Step 2] APNs Payload 구성 및 전송 (Push-to-Start) ---
    try:
        # APNs Payload: Aps 객체 생성 및 Custom Data 설정
        aps = messaging.Aps(
            alert=messaging.ApsAlert(
                title="다마고가 찾아왔어요!",
                body="새로운 활동이 시작되었습니다."
            ),
            custom_data={
                "event": "start",
                "timestamp": int(time.time()),
                "content-state": content_state,
                "attributes": attributes,
                "attributes-type": "DamagoAttributes"
            }
        )
        
        # [Debug] Payload 확인
        print(f"[Start LA] Payload Custom Data: {aps.custom_data}")
        
        message = messaging.Message(
            token=fcm_token, # FCM 등록 토큰
            apns=messaging.APNSConfig(
                live_activity_token=la_start_token, # LA 시작 토큰 (Push-To-Start Token)
                headers={
                    "apns-push-type": "liveactivity",
                    "apns-topic": f"{BUNDLE_ID}.push-type.liveactivity",
                    "apns-priority": "10"
                },
                payload=messaging.APNSPayload(aps=aps)
            )
        )
        response = messaging.send(message)
        print(f"Live Activity start request sent to {target_udid}: {response}")
        return https_fn.Response("Live Activity Started Remotely")

    except Exception as e:
        print(f"Error starting Live Activity: {e}")
        return https_fn.Response(f"Error: {str(e)}", status=500)