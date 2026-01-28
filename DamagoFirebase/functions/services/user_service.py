from firebase_functions import https_fn
from firebase_admin import firestore
from utils.firestore import get_db
from utils.constants import get_default_pet_name, get_required_exp
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
    use_live_activity = body.get("useLiveActivity")
    pet_name = body.get("petName")
    pet_type = body.get("petType")
    
    # 파라미터가 모두 없으면 400 Bad Request 리턴
    if all(param is None for param in [nickname, anniversary_date_str, use_fcm, use_live_activity, pet_name, pet_type]):
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
        
    if use_live_activity is not None:
        updates["useLiveActivity"] = use_live_activity
        
    if updates:
        user_ref.update(updates)

    # 기념일 또는 펫 정보 업데이트가 필요한 경우 유저 정보를 조회해야 함
    if any(param is not None for param in [anniversary_date_str, pet_name, pet_type]):
        user_snap = user_ref.get()
        if not user_snap.exists:
             return https_fn.Response("User not found", status=404)
        user_data = user_snap.to_dict()

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

            couple_id = user_data.get("coupleID")
            if couple_id:
                couple_ref = db.collection("couples").document(couple_id)
                couple_ref.update({"anniversaryDate": anniversary_date})

        # 4. 펫 정보 업데이트 (이름, 타입)
        if pet_name is not None or pet_type is not None:
            couple_id = user_data.get("coupleID")
            if not couple_id:
                 return https_fn.Response("Couple not found", status=404)

            # pet_type에 따라 고유한 damagoID 생성 (예: coupleID_Bunny)
            current_damago_id = user_data.get("damagoID")
            if pet_type is not None:
                target_damago_id = f"{couple_id}_{pet_type}"
                # 유저, 파트너 및 커플의 활성 펫 ID 업데이트
                user_ref.update({"damagoID": target_damago_id})
                db.collection("couples").document(couple_id).update({"damagoID": target_damago_id})
                
                partner_uid = user_data.get("partnerUID")
                if partner_uid:
                    db.collection("users").document(partner_uid).update({"damagoID": target_damago_id})
            else:
                target_damago_id = current_damago_id

            if target_damago_id:
                damago_ref = db.collection("damagos").document(target_damago_id)
                pet_snap = damago_ref.get()
                
                pet_updates = {"lastUpdatedAt": firestore.SERVER_TIMESTAMP}
                if pet_name is not None:
                    pet_updates["petName"] = pet_name
                if pet_type is not None:
                    pet_updates["petType"] = pet_type
                
                if not pet_snap.exists:
                    # 해당 타입의 펫이 처음인 경우 초기화
                    from utils.constants import XP_TABLE
                    pet_updates.update({
                        "id": target_damago_id,
                        "level": 1,
                        "currentExp": 0,
                        "maxExp": XP_TABLE[0],
                        "isHungry": False,
                        "statusMessage": "반가워요! 새로 태어났어요.",
                        "coupleID": couple_id,
                        "createdAt": firestore.SERVER_TIMESTAMP,
                        "lastFedAt": None,
                        "endedAt": None
                    })
                    # 요청에 petName이 없으면 해당 타입의 기본 이름 사용
                    if "petName" not in pet_updates:
                        pet_updates["petName"] = get_default_pet_name(pet_type)
                    damago_ref.set(pet_updates)
                else:
                    damago_ref.update(pet_updates)

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

def check_couple_connection(req: https_fn.Request) -> https_fn.Response:
    """
    커플 연결 상태를 확인합니다.
    
    Args:
        req (https_fn.Request): Header Authorization Bearer Token
        
    Returns:
        JSON Response: { "isConnected": bool }
    """
    try:
        uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)
        
    db = get_db()
    user_ref = db.collection("users").document(uid)
    user_doc = user_ref.get()
    
    is_connected = False
    
    if user_doc.exists:
        user_data = user_doc.to_dict()
        if user_data.get("coupleID"):
            is_connected = True
            
    return https_fn.Response(
        json.dumps({"isConnected": is_connected}),
        mimetype="application/json"
    )