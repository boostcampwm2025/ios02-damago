from firebase_functions import https_fn
from firebase_admin import firestore
import google.cloud.firestore
from utils.firestore import get_db
from utils.constants import get_default_damago_name, get_required_exp
from utils.middleware import get_uid_from_request
import utils.errors as errors
import json
from datetime import datetime

def adjust_coin(req: https_fn.Request) -> https_fn.Response:
    """
    사용자의 코인을 증가하거나 감소시킵니다.
    
    Args:
        req (https_fn.Request): 
            - Header: Authorization Bearer Token
            - Body: { "amount": 100 } (음수면 감소)
            
    Returns:
        JSON Response: { "totalCoin": updated_amount }
    """
    try:
        uid = get_uid_from_request(req)
        data = req.get_json()
        amount = data.get("amount")
        
        if amount is None:
             return errors.error_response(errors.BadRequest.MISSING_AMOUNT)
        
        try:
            amount = int(amount)
        except ValueError:
            return errors.error_response(errors.BadRequest.AMOUNT_NOT_INTEGER)
            
    except ValueError as e:
        return https_fn.Response(str(e), status=401)
    except Exception as e:
        return https_fn.Response(f"Invalid request: {str(e)}", status=400)

    db = get_db()
    
    # User Lookup
    user_ref = db.collection("users").document(uid)
    user_doc = user_ref.get()
    if not user_doc.exists:
        return errors.error_response(errors.NotFound.USER)
        
    couple_id = user_doc.to_dict().get("coupleID")
    if not couple_id:
        return errors.error_response(errors.NotFound.COUPLE)
        
    couple_ref = db.collection("couples").document(couple_id)

    @google.cloud.firestore.transactional
    def run_coin_transaction(transaction, doc_ref):
        snapshot = doc_ref.get(transaction=transaction)
        if not snapshot.exists:
            raise ValueError(errors.NotFound.COUPLE_DOCUMENT.message)
            
        current_coin = snapshot.to_dict().get("totalCoin", 0)
        new_coin = current_coin + amount
        
        if new_coin < 0:
            raise ValueError(errors.BadRequest.NOT_ENOUGH_COINS.message)
            
        transaction.update(doc_ref, {"totalCoin": new_coin})
        return new_coin

    try:
        new_balance = run_coin_transaction(db.transaction(), couple_ref)
        return https_fn.Response(
            json.dumps({"totalCoin": new_balance}),
            mimetype="application/json"
        )
    except ValueError as ve:
         return https_fn.Response(str(ve), status=400)
    except Exception as e:
        return errors.error_response_with_detail(errors.Internal.TRANSACTION_FAILED, str(e))

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
        return errors.error_response(errors.BadRequest.INVALID_JSON_BODY)
        
    nickname = body.get("nickname")
    anniversary_date_str = body.get("anniversaryDate")
    use_fcm = body.get("useFCM")
    use_live_activity = body.get("useLiveActivity")
    damago_name = body.get("damagoName")
    damago_type = body.get("damagoType")
    
    # 파라미터가 모두 없으면 400 Bad Request 리턴
    if all(param is None for param in [nickname, anniversary_date_str, use_fcm, use_live_activity, damago_name, damago_type]):
        return errors.error_response(errors.BadRequest.AT_LEAST_ONE_PARAM_REQUIRED)
        
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
    if any(param is not None for param in [anniversary_date_str, damago_name, damago_type]):
        user_snap = user_ref.get()
        if not user_snap.exists:
             return errors.error_response(errors.NotFound.USER)
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
                 return errors.error_response(errors.BadRequest.INVALID_DATE_FORMAT)

            couple_id = user_data.get("coupleID")
            if couple_id:
                couple_ref = db.collection("couples").document(couple_id)
                couple_ref.update({"anniversaryDate": anniversary_date})

        # 4. 다마고 정보 업데이트 (이름, 타입)
        if damago_name is not None or damago_type is not None:
            couple_id = user_data.get("coupleID")
            if not couple_id:
                 return errors.error_response(errors.NotFound.COUPLE)

            # damago_type에 따라 고유한 damagoID 생성 (예: coupleID_Bunny)
            current_damago_id = user_data.get("damagoID")
            if damago_type is not None:
                target_damago_id = f"{couple_id}_{damago_type}"
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
                damago_snap = damago_ref.get()
                
                damago_updates = {"lastUpdatedAt": firestore.SERVER_TIMESTAMP}
                if damago_name is not None:
                    damago_updates["damagoName"] = damago_name
                if damago_type is not None:
                    damago_updates["damagoType"] = damago_type
                
                if not damago_snap.exists:
                    # 해당 타입의 다마고가 처음인 경우 초기화
                    from utils.constants import XP_TABLE
                    damago_updates.update({
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
                    # 요청에 damagoName이 없으면 해당 타입의 기본 이름 사용
                    if "damagoName" not in damago_updates:
                        damago_updates["damagoName"] = get_default_damago_name(damago_type)
                    damago_ref.set(damago_updates)
                else:
                    damago_ref.update(damago_updates)

    return https_fn.Response("Updated successfully", status=200)

def get_user_info(req: https_fn.Request) -> https_fn.Response:
    """
    사용자 정보(UID 기반)를 조회합니다.
    현재 활성화된 다마고(damagoID)가 있다면 해당 다마고의 상세 상태 정보도 함께 반환합니다(Aggregation).
    
    Args:
        req (https_fn.Request): Header Authorization Bearer Token
        
    Returns:
        JSON Response: { "uid": ..., "damagoID": ..., "damagoStatus": { ... }, "totalCoin": ... }
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
        return errors.error_response(errors.NotFound.USER)

    user_data = user_doc.to_dict()
    damago_id = user_data.get("damagoID")
    
    # 다마고 정보 초기화
    damago_status = None
    total_coin = 0
    
    # --- [Damago & Coin Aggregation] ---
    # damagoID가 있으면 다마고 정보도 함께 조회 (Aggregation)
    if damago_id:
        damago_doc = db.collection("damagos").document(damago_id).get()
        if damago_doc.exists:
            damago_data = damago_doc.to_dict()
            
            last_fed_at = damago_data.get("lastFedAt")
            last_fed_at_str = last_fed_at.isoformat(timespec='seconds') if last_fed_at else None
            
            last_active_at = damago_data.get("lastActiveAt")
            last_active_at_str = last_active_at.isoformat(timespec='seconds') if last_active_at else None
            
            # 커플 정보에서 코인 조회
            couple_id = damago_data.get("coupleID")
            if couple_id:
                couple_doc = db.collection("couples").document(couple_id).get()
                if couple_doc.exists:
                    total_coin = couple_doc.to_dict().get("totalCoin", 0)

            damago_status = {
                "damagoName": damago_data.get("damagoName", "이름 없는 다마고"),
                "damagoType": damago_data.get("damagoType", "Bunny"),
                "level": damago_data.get("level", 1),
                "currentExp": damago_data.get("currentExp", 0),
                "maxExp": damago_data.get("maxExp", 20),
                "isHungry": damago_data.get("isHungry", False),
                "statusMessage": damago_data.get("statusMessage", "행복해요!"),
                "lastFedAt": last_fed_at_str,
                "totalPlayTime": damago_data.get("totalPlayTime", 0),
                "lastActiveAt": last_active_at_str
            }

    response_data = {
        "uid": uid,  # udid -> uid
        "damagoID": damago_id,
        "coupleID": user_data.get("coupleID"),
        "partnerUID": user_data.get("partnerUID"), # partnerUDID -> partnerUID
        "nickname": user_data.get("nickname"),
        "damagoStatus": damago_status,  # 합쳐진 다마고 정보
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
            return errors.error_response(errors.BadRequest.MISSING_FCM_TOKEN)
            
    except ValueError as e:
        return https_fn.Response(str(e), status=401)
    except Exception as e:
        return https_fn.Response(f"Invalid request: {str(e)}", status=400)

    db = get_db()
    user_ref = db.collection("users").document(uid)
    
    # 해당 사용자가 존재하는지 확인
    doc = user_ref.get()
    if not doc.exists:
        # 유저가 없으면 생성 (최초 로그인 시 FCM 토큰 업데이트가 먼저 호출될 수 있음)
        user_ref.set({
            "uid": uid,
            "fcmToken": fcm_token,
            "useFCM": True,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP
        })
    else:
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
