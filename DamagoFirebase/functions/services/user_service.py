from firebase_functions import https_fn
from utils.firestore import get_db
from utils.constants import XP_TABLE
import json

def get_user_info(req: https_fn.Request) -> https_fn.Response:
    """
    사용자 정보(UDID 기반)를 조회합니다.
    현재 활성화된 펫(damagoID)이 있다면 해당 펫의 상세 상태 정보도 함께 반환합니다(Aggregation).
    
    Args:
        req (https_fn.Request): { "udid": "..." }
        
    Returns:
        JSON Response: { "udid": ..., "damagoID": ..., "petStatus": { ... } }
    """
    # --- [Parameters] ---
    data = req.get_json(silent=True) or req.args
    udid = data.get("udid")

    if not udid:
        return https_fn.Response("Missing udid", status=400)

    db = get_db()
    user_doc = db.collection("users").document(udid).get()

    if not user_doc.exists:
        return https_fn.Response("User not found", status=404)

    user_data = user_doc.to_dict()
    damago_id = user_data.get("damagoID")
    
    # 펫 정보 초기화
    pet_status = None
    
    # --- [Pet Aggregation] ---
    # damagoID가 있으면 펫 정보도 함께 조회 (Aggregation)
    if damago_id:
        pet_doc = db.collection("damagos").document(damago_id).get()
        if pet_doc.exists:
            pet_data = pet_doc.to_dict()
            
            last_fed_at = pet_data.get("lastFedAt")
            last_fed_at_str = last_fed_at.isoformat() if last_fed_at else None
            
            pet_status = {
                "petName": pet_data.get("petName", "이름 없는 펫"),
                "petType": pet_data.get("petType", "Teddy"),
                "level": pet_data.get("level", 1),
                "currentExp": pet_data.get("currentExp", 0),
                "maxExp": pet_data.get("maxExp", XP_TABLE[0]),
                "isHungry": pet_data.get("isHungry", False),
                "statusMessage": pet_data.get("statusMessage", "행복해요!"),
                "lastFedAt": last_fed_at_str
            }

    response_data = {
        "udid": user_data.get("udid"),
        "damagoID": damago_id,
        "partnerUDID": user_data.get("partnerUDID"),
        "nickname": user_data.get("nickname"),
        "petStatus": pet_status  # 합쳐진 펫 정보
    }

    return https_fn.Response(
        json.dumps(response_data), 
        mimetype="application/json"
    )
