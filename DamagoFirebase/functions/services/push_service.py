from firebase_functions import https_fn
from firebase_admin import firestore, messaging
from google.cloud import tasks_v2
from google.protobuf import timestamp_pb2
from utils.firestore import get_db
from utils.middleware import get_uid_from_request
import time
import json
import datetime
import os
from utils.constants import BUNDLE_ID, PROJECT_ID, LOCATION, PUSH_RETRY_QUEUE_NAME, IS_EMULATOR


def enqueue_push_retry(payload: dict):
    """실패한 푸시 알림을 Cloud Tasks 큐에 지수 백오프와 함께 예약합니다."""
    try:
        client = tasks_v2.CloudTasksClient()
        parent = client.queue_path(PROJECT_ID, LOCATION, PUSH_RETRY_QUEUE_NAME)
        
        # 재시도 횟수 제한 (최대 3회)
        retry_count = payload.get("retry_count", 0)
        if retry_count >= 3:
            print(f"Max retries reached for task type: {payload.get('type')}")
            return
            
        # 지수 백오프 적용 (10s, 60s, 300s)
        if retry_count == 0:
            delay_seconds = 10
        elif retry_count == 1:
            delay_seconds = 60
        else:
            delay_seconds = 300

        payload["retry_count"] = retry_count + 1
        json_payload = json.dumps(payload).encode()
        
        # 실행 시간 예약
        d = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(seconds=delay_seconds)
        timestamp = timestamp_pb2.Timestamp()
        timestamp.FromDatetime(d)

        if os.environ.get("FUNCTIONS_EMULATOR") == "true":
            target_url = f"http://127.0.0.1:5001/{PROJECT_ID}/{LOCATION}/retry_push_notification"
        else:
            target_url = f"https://{LOCATION}-{PROJECT_ID}.cloudfunctions.net/retry_push_notification"
        
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
                "service_account_email": f"{PROJECT_ID}@appspot.gserviceaccount.com"
            }

        client.create_task(request={"parent": parent, "task": task})
        print(f"Push retry enqueued: {payload.get('type')} (Attempt {payload['retry_count']})")
    except Exception as e:
        print(f"Failed to enqueue push retry: {e}")


def send_push_notification(target_uid: str, title: str, body: str, data: dict = None, is_retry: bool = False, retry_count: int = 0) -> bool:
    """
    특정 사용자에게 푸시 알림을 전송합니다. 실패 시 Cloud Tasks로 재시도합니다.
    """
    db = get_db()
    target_user_doc = db.collection("users").document(target_uid).get()

    if not target_user_doc.exists:
        print(f"User {target_uid} not found")
        return False

    target_user_data = target_user_doc.to_dict()
    target_fcm_token = target_user_data.get("fcmToken")

    if not target_fcm_token:
        print(f"User {target_uid} has no FCM token")
        return False

    # 알림 설정 확인
    if not target_user_data.get("useFCM", True):
        print(f"User {target_uid} has disabled push notifications")
        return False

    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=target_fcm_token
        )
        response = messaging.send(message)
        print(f"Successfully sent message to {target_uid}: {response}")
        return True
    except Exception as e:
        print(f"Error sending message to {target_uid}: {e}")
        
        # 일시적 네트워크 오류 등 재시도 가능한 상황인 경우 Cloud Task 예약
        if any(err in str(e).lower() for err in ["unavailable", "internal-error", "timeout"]):
            enqueue_push_retry({
                "type": "push",
                "targetUID": target_uid,
                "title": title,
                "body": body,
                "data": data,
                "retry_count": retry_count
            })
            
        return False


def poke(req: https_fn.Request) -> https_fn.Response:
    """
    상대방(partner)에게 '콕 찌르기' 푸시 알림을 전송합니다.

    Args:
        req: Header Authorization Bearer Token
        body: { "message": "사용자가 입력한 메시지 (Optional)" }
    """
    try:
        # 미들웨어로 UID 추출
        my_uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)

    req_body = req.get_json(silent=True)
    if isinstance(req_body, dict):
        req_data = req_body
    else:
        req_data = req.args

    custom_message = req_data.get("message")
    if custom_message is not None:
        custom_message = str(custom_message)

    db = get_db()

    # --- [Step 1] 파트너 조회 ---
    my_user_ref = db.collection("users").document(my_uid)
    my_user_doc = my_user_ref.get()

    if not my_user_doc.exists:
        return https_fn.Response("User not found", status=404)

    my_user_data = my_user_doc.to_dict()
    partner_uid = my_user_data.get("partnerUID")  # partnerUID 사용

    if not partner_uid:
        return https_fn.Response("User is not in a couple", status=400)

    # --- [Step 2] FCM 전송 ---
    nickname = my_user_data.get('nickname') or '상대방'
    final_body = custom_message if custom_message else f"{nickname}님이 당신을 콕 찔렀어요!"
    
    success = send_push_notification(
        target_uid=partner_uid,
        title="콕!",
        body=final_body,
        data={
            "type": "poke",
            "fromUID": my_uid,
            "message": custom_message or "",
        }
    )

    if success:
        return https_fn.Response("Push notification sent successfully")
    else:
        return https_fn.Response("Failed to send push notification", status=500)

def save_live_activity_token(req: https_fn.Request) -> https_fn.Response:
    """
    클라이언트로부터 받은 Live Activity용 토큰(Start/Update)을 저장합니다.
    """
    try:
        uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)

    data = req.get_json(silent=True) or req.args
    la_update_token = data.get("laUpdateToken")
    la_start_token = data.get("laStartToken")

    db = get_db()
    user_ref = db.collection("users").document(uid)

    update_data = {"updatedAt": firestore.SERVER_TIMESTAMP}
    if la_update_token: update_data["laUpdateToken"] = la_update_token
    if la_start_token: update_data["laStartToken"] = la_start_token

    user_ref.set(update_data, merge=True)

    return https_fn.Response("Live Activity Token Saved")


def update_live_activity(req: https_fn.Request) -> https_fn.Response:
    """
    실행 중인 Live Activity의 상태를 APNs를 통해 업데이트합니다.
    """
    data = req.get_json(silent=True) or req.args
    target_uid = data.get("targetUID")
    content_state = data.get("contentState")

    if not target_uid or not content_state:
        return https_fn.Response("Missing targetUID or contentState", status=400)

    success = update_live_activity_internal(target_uid, content_state)

    if success:
        return https_fn.Response(f"Live Activity Updated")
    else:
        return https_fn.Response("Live Activity update skipped or failed", status=200)


def update_live_activity_internal(target_uid: str, content_state: dict, attributes: dict = None, is_retry: bool = False, retry_count: int = 0) -> bool:
    """
    내부 호출용 Live Activity 업데이트 함수.
    업데이트 실패 시, attributes와 Start Token이 있다면 새로운 Activity를 시작합니다.
    """
    db = get_db()

    user_doc = db.collection("users").document(target_uid).get()

    if not user_doc.exists:
        print(f"User {target_uid} not found")
        return False

    user_data = user_doc.to_dict()
    fcm_token = user_data.get("fcmToken")
    la_update_token = user_data.get("laUpdateToken")
    la_start_token = user_data.get("laStartToken")
    use_live_activity = user_data.get("useLiveActivity", True)

    if not fcm_token or not use_live_activity:
        print(f"Live Activity not active (or no FCM token) for {target_uid}")
        return False

    # 1. Update 시도
    if la_update_token:
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
                    live_activity_token=la_update_token,
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
            print(f"Live Activity update failed for {target_uid}: {e}")
            
            # 재시도가 아닌 최초 실패 시에만 Cloud Task 예약
            if not is_retry and any(err in str(e).lower() for err in ["unavailable", "internal-error", "timeout"]):
                enqueue_push_retry({
                    "type": "la_update",
                    "targetUID": target_uid,
                    "contentState": content_state,
                    "attributes": attributes,
                    "retry_count": retry_count
                })
            
            print(f"Trying fallback to Start...")
            # Fallback 진행을 위해 예외를 무시하고 아래로 진행
    
    # 2. Fallback: Start 시도 (Update 실패 혹은 토큰 없음)
    if la_start_token and attributes:
        try:
            print(f"Attempting to START Live Activity for {target_uid} as fallback.")
            aps = messaging.Aps(
                alert=messaging.ApsAlert(
                    title="다마고 알림",
                    body=content_state.get("statusMessage", "새로운 상태가 도착했어요!")
                ),
                custom_data={
                    "event": "start",
                    "timestamp": int(time.time()),
                    "content-state": content_state,
                    "attributes": attributes,
                    "attributes-type": "DamagoAttributes"
                }
            )

            message = messaging.Message(
                token=fcm_token,
                apns=messaging.APNSConfig(
                    live_activity_token=la_start_token,
                    headers={
                        "apns-push-type": "liveactivity",
                        "apns-topic": f"{BUNDLE_ID}.push-type.liveactivity",
                        "apns-priority": "10"
                    },
                    payload=messaging.APNSPayload(aps=aps)
                )
            )
            response = messaging.send(message)
            print(f"Live Activity started (fallback) for {target_uid}: {response}")
            return True
        except Exception as e:
            print(f"Live Activity start (fallback) failed for {target_uid}: {e}")
            return False
    else:
        print(f"Cannot fallback to Start: Missing start token or attributes for {target_uid}")
        return False


def start_live_activity(req: https_fn.Request) -> https_fn.Response:
    """
    Live Activity를 원격으로 시작합니다 (Push-to-Start).
    iOS 17.2 이상에서 지원됩니다.
    """
    data = req.get_json(silent=True) or req.args
    target_uid = data.get("targetUID")
    attributes = data.get("attributes")
    content_state = data.get("contentState")

    if not target_uid or not attributes or not content_state:
        return https_fn.Response("Missing parameters", status=400)

    db = get_db()

    user_doc = db.collection("users").document(target_uid).get()
    if not user_doc.exists:
        return https_fn.Response("User not found", status=404)

    user_data = user_doc.to_dict()
    fcm_token = user_data.get("fcmToken")
    la_start_token = user_data.get("laStartToken")
    use_live_activity = user_data.get("useLiveActivity", True)

    if not fcm_token or not la_start_token or not use_live_activity:
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
            token=fcm_token,
            apns=messaging.APNSConfig(
                live_activity_token=la_start_token,
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


def retry_push_notification(req: https_fn.Request) -> https_fn.Response:
    """
    Cloud Tasks로부터 호출되어 실패했던 푸시 알림을 다시 시도합니다.
    """
    data = req.get_json(silent=True) or req.args
    task_type = data.get("type")
    target_uid = data.get("targetUID")
    retry_count = data.get("retry_count", 0)

    print(f"Retrying task: {task_type} for {target_uid} (Retry count: {retry_count})")

    if task_type == "push":
        send_push_notification(
            target_uid=target_uid,
            title=data.get("title"),
            body=data.get("body"),
            data=data.get("data"),
            is_retry=True,
            retry_count=retry_count
        )
    elif task_type == "la_update":
        update_live_activity_internal(
            target_uid=target_uid,
            content_state=data.get("contentState"),
            attributes=data.get("attributes"),
            is_retry=True,
            retry_count=retry_count
        )

    return https_fn.Response("OK")
