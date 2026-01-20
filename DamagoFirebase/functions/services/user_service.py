from firebase_functions import https_fn
from utils.firestore import get_db
from utils.constants import get_required_exp
from utils.middleware import get_uid_from_request
import json

def get_user_info(req: https_fn.Request) -> https_fn.Response:
    """
    사용자 정보(UID 기반)를 조회합니다.
    현재 활성화된 펫(damagoID)이 있다면 해당 펫의 상세 상태 정보도 함께 반환합니다(Aggregation).
    
    Args:
        req (https_fn.Request): Header Authorization Bearer Token
        
    Returns:
        JSON Response: { "uid": ..., "damagoID": ..., "petStatus": { ... }, "totalCoin": ... }
    """
    try:
        # 미들웨어로 UID 추출
        uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)

    db = get_db()
    # UDID 대신 UID로 문서 조회
    user_doc = db.collection("users").document(uid).get()

    if not user_doc.exists:
        return https_fn.Response("User not found", status=404)

    user_data = user_doc.to_dict()
    damago_id = user_data.get("damagoID")
    
    # 펫 정보 초기화
    pet_status = None
    total_coin = 0
    
    # --- [Pet & Coin Aggregation] ---
    # damagoID가 있으면 펫 정보도 함께 조회 (Aggregation)
    if damago_id:
        pet_doc = db.collection("damagos").document(damago_id).get()
        if pet_doc.exists:
            pet_data = pet_doc.to_dict()
            
            last_fed_at = pet_data.get("lastFedAt")
            last_fed_at_str = last_fed_at.isoformat(timespec='seconds') if last_fed_at else None
            
            last_active_at = pet_data.get("lastActiveAt")
            last_active_at_str = last_active_at.isoformat(timespec='seconds') if last_active_at else None
            
            # 커플 정보에서 코인 조회
            couple_id = pet_data.get("coupleID")
            if couple_id:
                couple_doc = db.collection("couples").document(couple_id).get()
                if couple_doc.exists:
                    total_coin = couple_doc.to_dict().get("totalCoin", 0)

            pet_status = {
                "petName": pet_data.get("petName", "이름 없는 펫"),
                "petType": pet_data.get("petType", "Teddy"),
                "level": pet_data.get("level", 1),
                "currentExp": pet_data.get("currentExp", 0),
                "maxExp": pet_data.get("maxExp", 20),
                "isHungry": pet_data.get("isHungry", False),
                "statusMessage": pet_data.get("statusMessage", "행복해요!"),
                "lastFedAt": last_fed_at_str,
                "totalPlayTime": pet_data.get("totalPlayTime", 0),
                "lastActiveAt": last_active_at_str
            }

    response_data = {
        "uid": uid,  # udid -> uid
        "damagoID": damago_id,
        "coupleID": user_data.get("coupleID"),
        "partnerUID": user_data.get("partnerUID"), # partnerUDID -> partnerUID
        "nickname": user_data.get("nickname"),
        "petStatus": pet_status,  # 합쳐진 펫 정보
        "totalCoin": total_coin
    }

    return https_fn.Response(
        json.dumps(response_data), 
        mimetype="application/json"
    )