from firebase_functions import https_fn
from firebase_admin import firestore
from nanoid import generate
import google.cloud.firestore
from utils.firestore import get_db
from utils.middleware import get_uid_from_request

def generate_code(req: https_fn.Request) -> https_fn.Response:
    """
    새로운 사용자 계정을 생성하고, 커플 연결을 위한 고유 코드(8자리)를 발급합니다.
    이미 가입된 유저라면 기존 코드를 반환합니다.
    
    Args:
        req: { "fcmToken": "..." } (Header: Authorization 필수)
    """
    try:
        # 미들웨어를 통해 UID 추출
        uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)

    data = req.get_json(silent=True) or req.args
    fcm_token = data.get("fcmToken")

    if not fcm_token:
        return https_fn.Response("Missing fcmToken", status=400)

    db = get_db()
    users_ref = db.collection("users")
    # 문서 ID를 UDID 대신 UID로 사용
    doc_ref = users_ref.document(uid)

    # --- [Step 1] 기존 유저 확인 ---
    doc_snapshot = doc_ref.get()

    if doc_snapshot.exists:
        user_data = doc_snapshot.to_dict()
        existing_code = user_data.get("code")
        current_db_token = user_data.get("fcmToken")

        # 토큰 갱신
        if current_db_token != fcm_token:
            doc_ref.update({
                "fcmToken": fcm_token,
                "updatedAt": firestore.SERVER_TIMESTAMP
            })
            print(f"Updated FCM token for user {uid}")

        return https_fn.Response(f"{existing_code}")

    # --- [Step 2] 고유 코드 생성 (NanoID) ---
    safe_alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'
    max_retries = 10
    unique_code = None

    for _ in range(max_retries):
        temp_code = generate(alphabet=safe_alphabet, size=8)
        query = users_ref.where("code", "==", temp_code).limit(1).stream()
        if not next(query, None):
            unique_code = temp_code
            break

    if unique_code is None:
        return https_fn.Response("Unable to generate new code", status=500)

    # --- [Step 3] 유저 생성 ---
    doc_ref.set({
        "uid": uid,  # udid -> uid 변경
        "code": unique_code,
        "partnerUID": None, # partnerUDID -> partnerUID 변경
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

    return https_fn.Response(f"{unique_code}")

def connect_couple(req: https_fn.Request) -> https_fn.Response:
    """
    두 유저(Token User, targetCode)를 커플로 연결하고, 첫 번째 펫(Damago)을 생성합니다.
    트랜잭션을 사용하여 데이터 일관성을 보장합니다.
    
    Args:
        req: { "targetCode": "..." } (Header: Authorization 필수)
    """
    try:
        my_uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)

    data = req.get_json(silent=True) or req.args
    target_code = data.get("targetCode")

    if not target_code:
        return https_fn.Response("Missing 'targetCode'", status=400)

    db = get_db()
    users_ref = db.collection("users")

    # --- [Step 1] 유저 조회 ---
    # 내 정보는 UID로 조회
    my_doc_ref = users_ref.document(my_uid)
    my_doc = my_doc_ref.get()

    if not my_doc.exists:
        return https_fn.Response("User not found (Token Invalid)", status=404)
    
    my_code = my_doc.to_dict().get("code")

    if my_code == target_code:
        return https_fn.Response("Cannot connect to yourself", status=400)

    # 상대방 정보는 코드로 조회
    target_snapshot = users_ref.where("code", "==", target_code).limit(1).get()

    if not target_snapshot:
        return https_fn.Response("Target user not found (Invalid Code)", status=404)

    target_doc = target_snapshot[0]

    # --- [Step 2] ID 생성 ---
    codes = sorted([my_code, target_code])
    couple_doc_id = f"{codes[0]}_{codes[1]}"
    couple_ref = db.collection("couples").document(couple_doc_id)
    damago_ref = db.collection("damagos").document()

    from utils.constants import XP_TABLE # 초기 경험치 참조

    # --- [Step 3] 트랜잭션 실행 ---
    @google.cloud.firestore.transactional
    def run_transaction(transaction, couple_ref, damago_ref, my_ref, target_ref, my_uid, target_uid):
        snapshot = couple_ref.get(transaction=transaction)

        if snapshot.exists:
            return "ok" # 이미 연결됨

        # 펫 생성
        transaction.set(damago_ref, {
            "id": damago_ref.id,
            "coupleID": couple_ref.id,
            "petName": "이름 없는 펫",
            "petType": "Bunny",
            "level": 1,
            "currentExp": 0,
            "maxExp": XP_TABLE[0],
            "isHungry": False,
            "statusMessage": "반가워요! 우리 잘 지내봐요.",
            "lastFedAt": None,
            "lastUpdatedAt": firestore.SERVER_TIMESTAMP,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "endedAt": None
        })

        # 커플 생성 (UDID -> UID)
        transaction.set(couple_ref, {
            "id": couple_ref.id,
            "user1UID": my_uid,
            "user2UID": target_uid,
            "damagoID": damago_ref.id,
            "anniversaryDate": None,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "totalCoin": 0,
            "foodCount": 0
        })

        # 유저 정보 업데이트 (상호 참조, UDID -> UID)
        transaction.update(my_ref, {
            "coupleID": couple_ref.id,
            "damagoID": damago_ref.id,
            "partnerUID": target_uid,
            "updatedAt": firestore.SERVER_TIMESTAMP
        })
        transaction.update(target_ref, {
            "coupleID": couple_ref.id,
            "damagoID": damago_ref.id,
            "partnerUID": my_uid,
            "updatedAt": firestore.SERVER_TIMESTAMP
        })

        return "ok"

    try:
        result_message = run_transaction(
            db.transaction(),
            couple_ref,
            damago_ref,
            my_doc.reference,
            target_doc.reference,
            my_uid,
            target_doc.id # target_doc의 ID는 UID임
        )
    except Exception as e:
        return https_fn.Response(f"Transaction failed: {str(e)}", status=500)

    return https_fn.Response(result_message)