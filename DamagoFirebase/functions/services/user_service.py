from firebase_functions import https_fn
from utils.firestore import get_db
from utils.constants import get_required_exp
from utils.middleware import get_uid_from_request
import json
from datetime import datetime

def update_user_info(req: https_fn.Request) -> https_fn.Response:
    """
    사용자 정보(닉네임) 및 커플 기념일(anniversaryDate)을 수정합니다.
    
    Args:
        req (https_fn.Request):
            Header: Authorization Bearer Token
            Body: { 
                "nickname": "NewName" (Optional),
                "anniversaryDate": "2023-01-01T00:00:00Z" (Optional, ISO8601)
            }
            
    Returns:
        200 OK: Success
        400 Bad Request: If both params are missing or invalid date format.
        401 Unauthorized: Invalid token.
        404 Not Found: User or Couple not found.
    """
    try:
        uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)
        
    try:
        body = req.get_json()
    except Exception:
        return https_fn.Response("Invalid JSON body", status=400)
        
    nickname = body.get("nickname")
    anniversary_date_str = body.get("anniversaryDate")
    use_fcm = body.get("useFCM")
    use_activity = body.get("useActivity")
    
    # 파라미터가 모두 없으면 400 Bad Request 리턴
    if all(param is None for param in [nickname, anniversary_date_str, use_fcm, use_activity]):
        return https_fn.Response("At least one parameter is required", status=400)
        
    db = get_db()
    user_ref = db.collection("users").document(uid)
    
    updates = {}
    
    # 1. 닉네임 업데이트
    if nickname is not None:
        updates["nickname"] = nickname
        
    # 2. 알림 설정 업데이트
    if use_fcm is not None:
        updates["useFCM"] = use_fcm
        
    if use_activity is not None:
        updates["useActivity"] = use_activity
        
    if updates:
        user_ref.update(updates)

    # 3. 기념일 업데이트 (커플인 경우에만)
    if anniversary_date_str is not None:
        try:
            # ISO 8601 문자열 파싱 (Python 3.11+의 datetime.fromisoformat은 Z 지원하지만 
            # 구버전 호환성이나 타임존 처리를 위해 replace('Z', '+00:00') 등을 고려)
            if anniversary_date_str.endswith('Z'):
                 anniversary_date_str = anniversary_date_str.replace('Z', '+00:00')
            anniversary_date = datetime.fromisoformat(anniversary_date_str)
        except ValueError:
             return https_fn.Response("Invalid date format. Use ISO 8601.", status=400)

        # coupleID 확인을 위해 유저 문서 조회
        user_snap = user_ref.get()
        if not user_snap.exists:
             return https_fn.Response("User not found", status=404)
             
        couple_id = user_snap.to_dict().get("coupleID")
        if couple_id:
            couple_ref = db.collection("couples").document(couple_id)
            couple_ref.update({"anniversaryDate": anniversary_date})
        # 커플이 아닌 경우 기념일 업데이트 요청은 무시하거나 에러 처리할 수 있으나, 
        # 여기서는 조용히 넘어감(혹은 404 리턴도 가능). 요구사항은 '둘 다 빼먹었을 때만 바로 리턴'이었음.

    return https_fn.Response("Updated successfully", status=200)

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
                "petType": pet_data.get("petType", "Bunny"),
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

def update_fcm_token(req: https_fn.Request) -> https_fn.Response:
    """
    사용자의 FCM 토큰을 업데이트합니다.
    
    Args:
        req (https_fn.Request): 
            - Header: Authorization Bearer Token
            - Body: { "fcmToken": "..." }
            
    Returns:
        JSON Response: { "message": "FCM token updated successfully" }
    """
    try:
        uid = get_uid_from_request(req)
        data = req.get_json()
        fcm_token = data.get("fcmToken")
        
        if not fcm_token:
            return https_fn.Response("Missing fcmToken", status=400)
            
    except ValueError as e:
        return https_fn.Response(str(e), status=401)
    except Exception as e:
        return https_fn.Response(f"Invalid request: {str(e)}", status=400)

    db = get_db()
    user_ref = db.collection("users").document(uid)
    
    # 해당 사용자가 존재하는지 확인
    doc = user_ref.get()
    if not doc.exists:
        return https_fn.Response("User not found", status=404)
        
    user_ref.update({"fcmToken": fcm_token})
    
    return https_fn.Response(
        json.dumps({"message": "FCM token updated successfully"}),
        mimetype="application/json"
    )