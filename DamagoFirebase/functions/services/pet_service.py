from firebase_functions import https_fn
from firebase_admin import firestore
import google.cloud.firestore
import json
from utils.firestore import get_db
from utils.constants import XP_TABLE, MAX_LEVEL, FEED_EXP

def feed(req: https_fn.Request) -> https_fn.Response:
    """
    펫에게 먹이를 줍니다.
    경험치를 증가시키고, 레벨업 여부를 판단하여 DB를 업데이트합니다.
    
    Args:
        req (https_fn.Request): { "damagoID": "..." }
        
    Returns:
        JSON Response: 업데이트된 레벨, 경험치 정보
    """
    # --- [Parameters] ---
    data = req.get_json(silent=True) or req.args
    damago_id = data.get("damagoID")

    if not damago_id:
        return https_fn.Response("Missing damagoID", status=400)

    db = get_db()
    damago_ref = db.collection("damagos").document(damago_id)

    @google.cloud.firestore.transactional
    def run_feed_transaction(transaction, doc_ref):
        snapshot = doc_ref.get(transaction=transaction)
        
        if not snapshot.exists:
            return None

        data = snapshot.to_dict()
        current_level = data.get("level", 1)
        current_exp = data.get("currentExp", 0)
        
        # 만렙 & 경험치 풀이면 더 이상 성장 안 함
        if current_level >= MAX_LEVEL and current_exp >= XP_TABLE[MAX_LEVEL - 1]:
            return {"message": "Max level reached", "level": current_level, "exp": current_exp}

        # --- [Experience Logic] ---
        new_exp = current_exp + FEED_EXP
        new_level = current_level
        
        # 레벨업 계산 (초과 경험치 이월)
        if new_level < MAX_LEVEL:
            max_exp_for_current = XP_TABLE[new_level - 1]
            while new_exp >= max_exp_for_current:
                new_exp -= max_exp_for_current
                new_level += 1
                if new_level >= MAX_LEVEL:
                    new_level = MAX_LEVEL
                    if new_exp > XP_TABLE[MAX_LEVEL - 1]:
                        new_exp = XP_TABLE[MAX_LEVEL - 1]
                    break
                max_exp_for_current = XP_TABLE[new_level - 1]
        
        # 만렙 경험치 상한 고정
        if new_level == MAX_LEVEL:
            limit = XP_TABLE[MAX_LEVEL - 1]
            if new_exp > limit:
                new_exp = limit

        # --- [DB Update] ---
        transaction.update(doc_ref, {
            "level": new_level,
            "currentExp": new_exp,
            "maxExp": XP_TABLE[new_level - 1] if new_level <= MAX_LEVEL else XP_TABLE[-1],
            "isHungry": False, # 밥 먹었으니 배부름
            "lastFedAt": firestore.SERVER_TIMESTAMP,
            "lastUpdatedAt": firestore.SERVER_TIMESTAMP,
            "statusMessage": "냠냠! 밥이 너무 맛있어요! 🍚"
        })

        return {
            "level": new_level,
            "currentExp": new_exp,
            "maxExp": XP_TABLE[new_level - 1] if new_level <= MAX_LEVEL else XP_TABLE[-1],
            "isLevelUp": new_level > current_level
        }

    try:
        result = run_feed_transaction(db.transaction(), damago_ref)
        if result is None:
             return https_fn.Response("Damago not found", status=404)
        
        # TODO: JSON 형식으로 리턴하도록 수정 필요 (현재는 str(dict))
        return https_fn.Response(str(result))
    except Exception as e:
        return https_fn.Response(f"Transaction failed: {str(e)}", status=500)