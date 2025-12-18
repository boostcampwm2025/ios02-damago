# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_functions.options import set_global_options
from firebase_admin import initialize_app, firestore, messaging
from nanoid import generate
import google.cloud.firestore

# For cost control, you can set the maximum number of containers that can be
# running at the same time. This helps mitigate the impact of unexpected
# traffic spikes by instead downgrading performance. This limit is a per-function
# limit. You can override the limit for each function using the max_instances
# parameter in the decorator, e.g. @https_fn.on_request(max_instances=5).
set_global_options(max_instances=10)
initialize_app()

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
            doc_ref.update({"fcmToken": fcm_token})
            print(f"Updated FCM token for user {udid}")  # 로그 기록 (선택)

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
    doc_ref.set({
        "udid": udid,
        "code": unique_code,
        "fcmToken": fcm_token,
        "couple_id": None
    })

    # --- [Step 4] 코드 리턴 ---
    return https_fn.Response(f"{unique_code}")

@https_fn.on_request()
def connect_couple(req: https_fn.Request) -> https_fn.Response:
    # --- [Parameters] ---
    data = req.get_json(silent=True) or req.args
    my_code = data.get("my_code")
    target_code = data.get("target_code")

    if not my_code or not target_code:
        return https_fn.Response("Missing 'my_code' or 'target_code'", status=400)

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

    my_data = my_doc.to_dict()
    target_data = target_doc.to_dict()

    # --- [Step 2] Couple ID 생성 (정렬하여 유일성 보장) ---
    # 예: code_A와 code_B가 있으면 항상 알파벳 순서로 "codeA_codeB" 형태가 됨
    codes = sorted([my_code, target_code])
    couple_doc_id = f"{codes[0]}_{codes[1]}"
    couple_ref = db.collection("couples").document(couple_doc_id)

    # --- [Transaction] 데이터 일관성 보장 ---
    # 커플 문서 생성과 각 유저의 couple_id 업데이트가 동시에 성공하거나 실패해야 함

    @google.cloud.firestore.transactional
    def run_transaction(transaction, couple_ref, my_ref, target_ref, my_fcm, target_fcm):
        snapshot = couple_ref.get(transaction=transaction)

        # --- [Step 2-1] 이미 커플 문서가 존재하면 반환 ---
        if snapshot.exists:
            return "ok"

        # --- [Step 3] Couples 컬렉션에 문서 만들기 ---
        # 누가 client_a인지 헷갈리지 않게, 요청자(my)와 대상(target)을 명확히 저장하거나
        # ID 생성 순서대로 저장할 수 있습니다. 여기서는 요청대로 저장합니다.
        transaction.set(couple_ref, {
            "user_a": {
                "id": my_ref.id,
                "fcm": my_fcm
            },
            "user_b": {
                "id": target_ref.id,
                "fcm": target_fcm
            }
        })

        # --- [Step 4] 나와 상대 User Document 업데이트 ---
        transaction.update(my_ref, {"couple_id": couple_ref.id})
        transaction.update(target_ref, {"couple_id": couple_ref.id})

        return "ok"

    # 트랜잭션 실행
    try:
        result_message = run_transaction(
            db.transaction(),
            couple_ref,
            my_doc.reference,
            target_doc.reference,
            my_data.get("fcmToken"),
            target_data.get("fcmToken")
        )
    except Exception as e:
        return https_fn.Response(f"Transaction failed: {str(e)}", status=500)

    # --- [Step 5] 반환 ---
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
    my_user_ref = db.collection("users").document(my_udid)
    my_user_doc = my_user_ref.get()

    if not my_user_doc.exists:
        return https_fn.Response("User not found", status=404)

    my_user_data = my_user_doc.to_dict()
    couple_id = my_user_data.get("couple_id")

    if not couple_id:
        return https_fn.Response("User is not in a couple", status=400)

    # --- [Step 2] 상대방 정보 조회 ---
    couple_ref = db.collection("couples").document(couple_id)
    couple_doc = couple_ref.get()

    if not couple_doc.exists:
        return https_fn.Response("Couple not found", status=404)

    couple_data = couple_doc.to_dict()
    user_a = couple_data.get("user_a")
    user_b = couple_data.get("user_b")

    target_fcm_token = None
    if user_a and user_a.get("id") != my_udid:
        target_fcm_token = user_a.get("fcm")
    elif user_b and user_b.get("id") != my_udid:
        target_fcm_token = user_b.get("fcm")

    if not target_fcm_token:
        return https_fn.Response("Opponent's FCM token not found", status=404)

    # --- [Step 3] 푸시 알림 보내기 ---
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title="콕!",
                body="상대방이 당신을 콕 찔렀어요!",
            ),
            token=target_fcm_token
        )
        response = messaging.send(message)
        print("Successfully sent message:", response)
        return https_fn.Response("Push notification sent successfully")

    except Exception as e:
        print("Error sending message:", e)
        return https_fn.Response(f"Error sending push notification: {str(e)}", status=500)
