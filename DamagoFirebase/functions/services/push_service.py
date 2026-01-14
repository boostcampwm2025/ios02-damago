from firebase_functions import https_fn
from firebase_admin import firestore, messaging
from utils.firestore import get_db
from utils.middleware import get_uid_from_request
import time
from utils.constants import BUNDLE_ID

def poke(req: https_fn.Request) -> https_fn.Response:
    """
    상대방(partner)에게 '콕 찌르기' 푸시 알림을 전송합니다.
    
    Args:
        req: Header Authorization Bearer Token
    """
    try:
        # 미들웨어로 UID 추출
        my_uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)

    db = get_db()

    # --- [Step 1] 파트너 조회 ---
    my_user_ref = db.collection("users").document(my_uid)
    my_user_doc = my_user_ref.get()

    if not my_user_doc.exists:
        return https_fn.Response("User not found", status=404)

    my_user_data = my_user_doc.to_dict()
    partner_uid = my_user_data.get("partnerUID") # partnerUDID -> partnerUID

    if not partner_uid:
        return https_fn.Response("User is not in a couple", status=400)

    target_user_doc = db.collection("users").document(partner_uid).get()

    if not target_user_doc.exists:
        return https_fn.Response("Opponent not found", status=404)

    target_user_data = target_user_doc.to_dict()
    target_fcm_token = target_user_data.get("fcmToken")

    if not target_fcm_token:
        return https_fn.Response("Opponent's FCM token not found", status=404)

    # --- [Step 2] FCM 전송 ---
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

def save_live_activity_token(req: https_fn.Request) -> https_fn.Response:
    """
    클라이언트로부터 받은 Live Activity용 토큰(Start/Update)을 저장합니다.
    """
    try:
        # 미들웨어로 UID 추출
        uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)

    data = req.get_json(silent=True) or req.args
    la_update_token = data.get("laUpdateToken")
    la_start_token = data.get("laStartToken")

    db = get_db()
    # UDID 대신 UID 사용
    user_ref = db.collection("users").document(uid)

    update_data = {"updatedAt": firestore.SERVER_TIMESTAMP}
    if la_update_token: update_data["laUpdateToken"] = la_update_token
    if la_start_token: update_data["laStartToken"] = la_start_token

    user_ref.update(update_data)

    return https_fn.Response("Live Activity Token Saved")

def update_live_activity(req: https_fn.Request) -> https_fn.Response:
    """
    실행 중인 Live Activity의 상태를 APNs를 통해 업데이트합니다.
    """
    data = req.get_json(silent=True) or req.args
    target_uid = data.get("targetUID") # targetUDID -> targetUID
    content_state = data.get("contentState") 

    if not target_uid or not content_state:
        return https_fn.Response("Missing targetUID or contentState", status=400)

    success = update_live_activity_internal(target_uid, content_state)
    
    if success:
        return https_fn.Response(f"Live Activity Updated")
    else:
        return https_fn.Response("Live Activity update skipped or failed", status=200)

def update_live_activity_internal(target_uid: str, content_state: dict) -> bool:
    """
    내부 호출용 Live Activity 업데이트 함수 (targetUDID -> targetUID)
    """
    db = get_db()
    
    # UDID 대신 UID로 문서 조회
    user_doc = db.collection("users").document(target_uid).get()
    
    if not user_doc.exists:
        print(f"User {target_uid} not found")
        return False

    user_data = user_doc.to_dict()
    fcm_token = user_data.get("fcmToken")
    la_token = user_data.get("laUpdateToken")
    use_la = user_data.get("useLiveActivity", True)

    if not fcm_token or not la_token or not use_la:
        print(f"Live Activity not active for {target_uid}")
        return False

    try:
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
            token=fcm_token, 
            apns=messaging.APNSConfig(
                live_activity_token=la_token, 
                headers={
                    "apns-push-type": "liveactivity",
                    "apns-topic": f"{BUNDLE_ID}.push-type.liveactivity",
                    "apns-priority": "10"
                },
                payload=messaging.APNSPayload(aps=aps)
            )
        )
        response = messaging.send(message)
        print(f"Live Activity update sent to {target_uid}: {response}")
        return True

    except Exception as e:
        print(f"Error updating Live Activity: {e}")
        return False

def start_live_activity(req: https_fn.Request) -> https_fn.Response:
    """
    Live Activity를 원격으로 시작합니다 (Push-to-Start).
    iOS 17.2 이상에서 지원됩니다.
    """
    data = req.get_json(silent=True) or req.args
    target_uid = data.get("targetUID") # targetUDID -> targetUID
    attributes = data.get("attributes")
    content_state = data.get("contentState")

    if not target_uid or not attributes or not content_state:
        return https_fn.Response("Missing parameters", status=400)

    db = get_db()
    
    # UDID 대신 UID로 조회
    user_doc = db.collection("users").document(target_uid).get()
    if not user_doc.exists:
        return https_fn.Response("User not found", status=404)

    user_data = user_doc.to_dict()
    fcm_token = user_data.get("fcmToken")
    la_start_token = user_data.get("laStartToken")
    use_la = user_data.get("useLiveActivity", True)

    if not fcm_token or not la_start_token or not use_la:
        return https_fn.Response("Start Token not found or Live Activity disabled", status=400)

    try:
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
        print(f"Live Activity start request sent to {target_uid}: {response}")
        return https_fn.Response("Live Activity Started Remotely")

    except Exception as e:
        print(f"Error starting Live Activity: {e}")
        return https_fn.Response(f"Error: {str(e)}", status=500)