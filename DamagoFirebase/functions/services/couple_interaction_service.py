from firebase_functions import https_fn
from firebase_admin import firestore
from google.cloud.firestore import FieldFilter
from utils.firestore import get_db
from utils.middleware import get_uid_from_request
import json
from datetime import datetime, timezone
from services.push_service import send_push_notification

def fetch_history(req: https_fn.Request) -> https_fn.Response:
    """
    커플의 과거 활동 내역(오늘의 질문, 밸런스 게임)을 조회합니다.
    Query Params:
      - type: "daily_question" | "balance_game" (default: "daily_question")
      - limit: int (default: 20)
    """
    try:
        uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)
        
    db = get_db()
    
    # 1. 사용자 -> 커플 ID 조회
    user_doc = db.collection("users").document(uid).get()
    if not user_doc.exists:
        return https_fn.Response("User not found", status=404)
    
    couple_id = user_doc.get("coupleID")
    if not couple_id:
        return https_fn.Response("Couple not found", status=404)
        
    # 2. 파라미터 파싱
    history_type = req.args.get("type", "daily_question")
    try:
        limit = int(req.args.get("limit", "20"))
    except ValueError:
        limit = 20
        
    couple_ref = db.collection("couples").document(couple_id)
    
    if history_type == "daily_question":
        return _fetch_daily_question_history(db, couple_ref, limit, uid)
    elif history_type == "balance_game":
        return _fetch_balance_game_history(db, couple_ref, limit, uid)
    else:
        return https_fn.Response("Invalid type. Use 'daily_question' or 'balance_game'", status=400)

def _fetch_daily_question_history(db, couple_ref, limit, uid):
    # 답변 내역 조회 (bothAnswered == True)
    answers_query = (
        couple_ref.collection("dailyQuestionAnswers")
        .where(filter=FieldFilter("bothAnswered", "==", True))
        .limit(limit)
    )
    
    answers = list(answers_query.stream())
    
    if not answers:
        return https_fn.Response(json.dumps([]), mimetype="application/json")
        
    # 메모리 정렬 (최신순) - user1AnsweredAt 기준 (없으면 0)
    def get_sort_key(doc):
        data = doc.to_dict()
        t1 = data.get("user1AnsweredAt")
        t2 = data.get("user2AnsweredAt")
        dt1 = t1.timestamp() if t1 else 0
        dt2 = t2.timestamp() if t2 else 0
        return max(dt1, dt2)

    answers.sort(key=get_sort_key, reverse=True)
    answers = answers[:limit] 
    
    # 질문 ID 수집 및 질문 내용 조회
    question_ids = [doc.id for doc in answers]
    question_refs = [db.collection("dailyQuestions").document(qid) for qid in question_ids]
    
    questions = db.get_all(question_refs)
    questions_map = {q.id: q.to_dict() for q in questions if q.exists}
    
    # 커플 정보 조회 (isUser1 판단용)
    couple_data = couple_ref.get().to_dict()
    is_user1 = (couple_data.get("user1UID") == uid)
    
    result_list = []
    for ans_doc in answers:
        ans_data = ans_doc.to_dict()
        qid = ans_doc.id
        q_data = questions_map.get(qid)
        
        if not q_data:
            continue
            
        result_list.append({
            "questionID": qid,
            "questionContent": q_data.get("questionText", "삭제된 질문"),
            "user1Answer": ans_data.get("user1Answer"),
            "user2Answer": ans_data.get("user2Answer"),
            "answeredAt": ans_data.get("user1AnsweredAt", datetime.now()).isoformat(),
            "isUser1": is_user1
        })
        
    return https_fn.Response(json.dumps(result_list, default=str), mimetype="application/json")

def _fetch_balance_game_history(db, couple_ref, limit, uid):
    # 밸런스 게임 답변 내역 조회
    answers_query = (
        couple_ref.collection("balanceGameAnswers")
        .where(filter=FieldFilter("bothAnswered", "==", True))
        .limit(limit)
    )
    
    answers = list(answers_query.stream())
    
    if not answers:
        return https_fn.Response(json.dumps([]), mimetype="application/json")
        
    # 게임 ID 수집
    game_refs = []
    processed_answers = []
    
    for ans_doc in answers:
        data = ans_doc.to_dict()
        # balanceGameID 필드 혹은 doc.id 활용
        # 스키마 상 doc.id는 {coupleID}_{gameID}일 수도 있고, gameID일 수도 있음.
        # 기존 로직과 데이터 구조에 따라 다르지만, 여기서는 data 내에 'balanceGameID'가 있다고 가정하거나
        # 없다면 doc.id가 gameID라고 가정해야 함.
        # 안전하게 data.get('balanceGameID')를 우선 사용
        game_id = data.get("balanceGameID")
        
        # 만약 balanceGameID가 없다면 doc.id가 gameID일 가능성 (시드 데이터 로직 확인 필요하나, 
        # 보통 subcollection document id를 gameID로 쓰는 경우가 많음)
        if not game_id:
            game_id = ans_doc.id
            
        if game_id:
            game_refs.append(db.collection("balanceGames").document(game_id))
            processed_answers.append({**data, "gameID": game_id})
            
    if not game_refs:
        return https_fn.Response(json.dumps([]), mimetype="application/json")

    games = db.get_all(game_refs)
    games_map = {g.id: g.to_dict() for g in games if g.exists}
    
    couple_data = couple_ref.get().to_dict()
    is_user1 = (couple_data.get("user1UID") == uid)
    
    result_list = []
    for ans_data in processed_answers:
        game_id = ans_data.get("gameID")
        game_data = games_map.get(game_id)
        
        if not game_data:
            continue
            
        result_list.append({
            "gameID": game_id,
            "question": game_data.get("questionText"),
            "optionA": game_data.get("option1"), 
            "optionB": game_data.get("option2"),
            "user1Answer": ans_data.get("user1Answer"), # 1: Left, 2: Right (가정)
            "user2Answer": ans_data.get("user2Answer"),
            "isUser1": is_user1
        })
        
    return https_fn.Response(json.dumps(result_list, default=str), mimetype="application/json")


def fetch_daily_question(req: https_fn.Request) -> https_fn.Response:
    """
    사용자의 커플 정보에 기반한 오늘의 질문을 조회합니다.
    """
    try:
        uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)

    db = get_db()
    
    # 1. 사용자 정보 조회 (CoupleID 확인)
    user_doc = db.collection("users").document(uid).get()
    if not user_doc.exists:
        return https_fn.Response("User not found", status=404)
        
    user_data = user_doc.to_dict()
    couple_id = user_data.get("coupleID")
    
    if not couple_id:
        return https_fn.Response("Couple not found", status=404)
        
    # 2. 커플 정보 조회 (User1/User2 확인 및 진행 상황 확인)
    couple_doc = db.collection("couples").document(couple_id).get()
    if not couple_doc.exists:
        return https_fn.Response("Couple document not found", status=404)
        
    couple_data = couple_doc.to_dict()
    is_user1 = (couple_data.get("user1UID") == uid)
    
    # 현재 진행해야 할 질문 순서 계산
    stats = couple_data.get("dailyQuestionStats", {})
    total_answered = stats.get("totalAnswered", 0)
    last_answered_at_from_stats = stats.get("lastAnsweredAt") # datetime 객체 or None
    
    # 기본적으로 다음 질문(total_answered + 1)을 타겟으로 함
    target_order = total_answered + 1
    
    # 만약 답변이 완료된 기록이 있다면 시간 체크
    # 통계 정보가 있거나, 통계는 없어도 답변한 적(total_answered > 0)이 있다면 확인
    if total_answered > 0:
        last_answered = last_answered_at_from_stats
        
        # [Fallback] 통계에 시간이 누락되었다면, 실제 마지막 답변 문서를 조회하여 시간 확인
        if not last_answered:
             last_q_query = db.collection("dailyQuestions").where("order", "==", total_answered).limit(1).stream()
             last_q_doc = next(last_q_query, None)
             
             if last_q_doc:
                 last_ans_doc = db.collection("couples").document(couple_id).collection("dailyQuestionAnswers").document(last_q_doc.id).get()
                 if last_ans_doc.exists:
                     l_data = last_ans_doc.to_dict()
                     last_answered = l_data.get("lastAnsweredAt")
                     if not last_answered:
                         t1 = l_data.get("user1AnsweredAt")
                         t2 = l_data.get("user2AnsweredAt")
                         if t1 and t2: last_answered = max(t1, t2)
                         elif t1: last_answered = t1
                         elif t2: last_answered = t2

        if last_answered:
            # 안전한 시간 비교를 위해 UTC 기준 변환 (에뮬레이터/로컬 시간 차이 해결)
            now = datetime.now(timezone.utc)
            
            if last_answered.tzinfo is None:
                last_answered = last_answered.replace(tzinfo=timezone.utc)
                
            elapsed_time = now - last_answered
            hours_passed = elapsed_time.total_seconds() / 3600
            
            if hours_passed < 12:
                target_order = total_answered
    
    # 3. 질문 조회 (Order 기반)
    # 질문이 존재하는지 확인
    questions_query = db.collection("dailyQuestions").where("order", "==", target_order).limit(1).stream()
    question_doc = next(questions_query, None)
    
    if not question_doc:
        # 더 이상 질문이 없거나 아직 질문이 생성되지 않음
        return https_fn.Response("No more questions available", status=404)
        
    question_data = question_doc.to_dict()
    question_id = question_doc.id
    question_content = question_data.get("questionText", "")
    
    # couples 문서에 currentQuestionID 업데이트 (없거나 다를 경우)
    if couple_data.get("currentQuestionID") != question_id:
        db.collection("couples").document(couple_id).update({"currentQuestionID": question_id})
    
    # 4. 답변 내역 조회 (있다면)
    answer_ref = db.collection("couples").document(couple_id).collection("dailyQuestionAnswers").document(question_id)
    answer_doc = answer_ref.get()
    
    user1_answer = None
    user2_answer = None
    both_answered = False
    current_last_answered_at = None
    
    if answer_doc.exists:
        answer_data = answer_doc.to_dict()
        user1_answer = answer_data.get("user1Answer")
        user2_answer = answer_data.get("user2Answer")
        both_answered = answer_data.get("bothAnswered", False)
        current_last_answered_at = answer_data.get("lastAnsweredAt")
    
    # 문서에 없더라도 12시간 대기 중인 질문이라면 통계에서 가져옴
    if not current_last_answered_at and target_order == total_answered:
        current_last_answered_at = last_answered_at_from_stats
    
    formatted_last_answered_at = None
    if current_last_answered_at:
        # UTC 시간임을 보장하고, Swift 호환성을 위해 +00:00을 Z로 치환
        if current_last_answered_at.tzinfo is None:
            current_last_answered_at = current_last_answered_at.replace(tzinfo=timezone.utc)
        formatted_last_answered_at = current_last_answered_at.isoformat(timespec="seconds").replace("+00:00", "Z")

    response_data = {
        "questionID": question_id,
        "questionContent": question_content,
        "user1Answer": user1_answer,
        "user2Answer": user2_answer,
        "bothAnswered": both_answered,
        "lastAnsweredAt": formatted_last_answered_at,
        "isUser1": is_user1
    }
    
    return https_fn.Response(
        json.dumps(response_data),
        mimetype="application/json"
    )

def submit_daily_question(req: https_fn.Request) -> https_fn.Response:
    """
    일일 질문에 대한 답변을 제출합니다.
    """
    try:
        uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)
        
    # Request Body 파싱
    try:
        body = req.get_json()
        question_id = body.get("questionID")
        answer_text = body.get("answer")
    except Exception:
        return https_fn.Response("Invalid JSON", status=400)
        
    if not question_id or not answer_text:
        return https_fn.Response("Missing fields", status=400)

    db = get_db()
    
    # 트랜잭션 함수 정의
    @firestore.transactional
    def submit_answer_in_transaction(transaction):
        # 1. 사용자 및 커플 정보 조회
        user_ref = db.collection("users").document(uid)
        user_snapshot = next(transaction.get(user_ref))
        
        if not user_snapshot.exists:
            raise ValueError("User not found")
            
        user_data = user_snapshot.to_dict()
        couple_id = user_data.get("coupleID")
        
        if not couple_id:
            raise ValueError("Couple not found")
            
        couple_ref = db.collection("couples").document(couple_id)
        couple_snapshot = next(transaction.get(couple_ref))
        
        if not couple_snapshot.exists:
            raise ValueError("Couple document not found")
            
        couple_data = couple_snapshot.to_dict()
        
        is_user1 = (couple_data.get("user1UID") == uid)
        
        # 2. 질문 정보 조회 (유효성 검사 및 content 확보)
        question_ref = db.collection("dailyQuestions").document(question_id)
        question_snapshot = next(transaction.get(question_ref))
        
        if not question_snapshot.exists:
            raise ValueError("Question not found")
            
        question_content = question_snapshot.get("questionText")
        
        # 3. 답변 저장 위치 참조
        answer_ref = couple_ref.collection("dailyQuestionAnswers").document(question_id)
        answer_snapshot = next(transaction.get(answer_ref))
        
        now = datetime.now(timezone.utc)
        
        # 기존 답변 데이터 가져오기 (안전하게)
        answer_data = answer_snapshot.to_dict() if answer_snapshot.exists else {}
        
        # 업데이트할 데이터 준비
        answer_update = {}
        opponent_answered = False
        
        if is_user1:
            answer_update["user1Answer"] = answer_text
            answer_update["user1AnsweredAt"] = now
            opponent_answered = (answer_data.get("user2Answer") is not None)
        else:
            answer_update["user2Answer"] = answer_text
            answer_update["user2AnsweredAt"] = now
            opponent_answered = (answer_data.get("user1Answer") is not None)
        
        # 이번 답변으로 양쪽 모두 완료되었는지 확인
        is_completing_now = opponent_answered and not answer_data.get("bothAnswered", False)
        
        if is_completing_now:
            answer_update["bothAnswered"] = True
            answer_update["lastAnsweredAt"] = now # 답변 문서 자체에 저장하여 Observer가 읽을 수 있게 함
            
            # 커플 스탯 업데이트 (보상 지급 및 진행도 업데이트)
            current_stats = couple_data.get("dailyQuestionStats", {})
            current_total = current_stats.get("totalAnswered", 0)
            
            transaction.update(couple_ref, {
                "dailyQuestionStats.totalAnswered": current_total + 1,
                "dailyQuestionStats.lastAnsweredAt": now,
                "totalCoin": firestore.Increment(30),
                "foodCount": firestore.Increment(3)
            })
        
        # 답변 문서 저장 (set with merge)
        transaction.set(answer_ref, answer_update, merge=True)
        
        # 리턴을 위한 데이터 구성
        user1_answer = answer_text if is_user1 else answer_data.get("user1Answer")
        user2_answer = answer_text if not is_user1 else answer_data.get("user2Answer")
        is_both_answered = answer_update.get("bothAnswered", answer_data.get("bothAnswered", False))
        
        # 만약 이번에 완료되었다면 now를 사용하고, 아니면 기존 stats의 lastAnsweredAt 사용
        final_last_answered_at = None
        if is_both_answered:
            if is_completing_now:
                # now는 timezone.utc이므로 isoformat은 +00:00을 반환함 -> Z로 치환
                final_last_answered_at = now.isoformat(timespec="seconds").replace("+00:00", "Z")
            else:
                stats = couple_data.get("dailyQuestionStats", {})
                last_at = stats.get("lastAnsweredAt")
                if last_at:
                    if last_at.tzinfo is None:
                        last_at = last_at.replace(tzinfo=timezone.utc)
                    final_last_answered_at = last_at.isoformat(timespec="seconds").replace("+00:00", "Z")

        return {
            "questionID": question_id,
            "questionContent": question_content,
            "user1Answer": user1_answer,
            "user2Answer": user2_answer,
            "bothAnswered": is_both_answered,
            "lastAnsweredAt": final_last_answered_at,
            "isUser1": is_user1,
            "notificationData": {
                "partnerUID": user_data.get("partnerUID"),
                "nickname": user_data.get("nickname", "상대방"),
                "isCompletingNow": is_completing_now
            }
        }

    try:
        result = submit_answer_in_transaction(db.transaction())
        
        # --- [Notification] ---
        # 트랜잭션 성공 후 알림 전송 (재시도로 인한 중복 발송 방지)
        notif_info = result.pop("notificationData", None)
        if notif_info and notif_info.get("partnerUID"):
            try:
                partner_uid = notif_info["partnerUID"]
                nickname = notif_info["nickname"]
                is_completing_now = notif_info["isCompletingNow"]
                
                if is_completing_now:
                    title = "오늘의 질문 답변 완료!"
                    body = f"{nickname}님이 답변을 완료했습니다! 결과를 확인해보세요."
                else:
                    title = "상대방이 오늘의 질문에 답변했어요!"
                    body = f"{nickname}님이 답변을 남겼습니다! 답변하고 결과를 확인해보세요."
                
                send_push_notification(
                    target_uid=partner_uid,
                    title=title,
                    body=body,
                    data={
                        "type": "daily_question",
                        "questionID": result.get("questionID")
                    }
                )
            except Exception as e:
                print(f"Error sending notification: {e}")

        return https_fn.Response(json.dumps(result), mimetype="application/json")
    except ValueError as e:
        return https_fn.Response(str(e), status=400)
    except Exception as e:
        return https_fn.Response(f"Internal Error: {str(e)}", status=500)

def fetch_balance_game(req: https_fn.Request) -> https_fn.Response:
    """
    사용자의 커플 정보에 기반한 오늘의 밸런스 게임을 조회합니다.
    """
    try:
        uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)

    db = get_db()
    
    # 1. 사용자 정보 조회
    user_doc = db.collection("users").document(uid).get()
    if not user_doc.exists:
        return https_fn.Response("User not found", status=404)
        
    user_data = user_doc.to_dict()
    couple_id = user_data.get("coupleID")
    
    if not couple_id:
        return https_fn.Response("Couple not found", status=404)
        
    # 2. 커플 정보 및 진행도 조회
    couple_doc = db.collection("couples").document(couple_id).get()
    if not couple_doc.exists:
        return https_fn.Response("Couple document not found", status=404)
        
    couple_data = couple_doc.to_dict()
    is_user1 = (couple_data.get("user1UID") == uid)
    
    stats = couple_data.get("balanceGameStats", {})
    total_answered = stats.get("totalAnswered", 0)
    last_answered_at = stats.get("lastAnsweredAt")
    
    target_order = total_answered + 1
    
    # 12시간 쿨타임 로직
    if last_answered_at and total_answered > 0:
        elapsed_time = datetime.now(last_answered_at.tzinfo) - last_answered_at
        if (elapsed_time.total_seconds() / 3600) < 12:
            target_order = total_answered
    
    # 3. 질문 조회 (balanceGames 컬렉션)
    games_query = db.collection("balanceGames").where("order", "==", target_order).limit(1).stream()
    game_doc = next(games_query, None)
    
    if not game_doc:
        return https_fn.Response("No more balance games available", status=404)
        
    game_data = game_doc.to_dict()
    game_id = game_doc.id
    
    # 4. 답변 내역 조회
    answer_ref = db.collection("couples").document(couple_id).collection("balanceGameAnswers").document(game_id)
    answer_doc = answer_ref.get()
    
    user1_choice = None
    user2_choice = None
    
    if answer_doc.exists:
        answer_data = answer_doc.to_dict()
        user1_choice = answer_data.get("user1Answer")
        user2_choice = answer_data.get("user2Answer")
    
    my_choice = user1_choice if is_user1 else user2_choice
    opponent_choice = user2_choice if is_user1 else user1_choice
    
    formatted_last_answered_at = None
    if last_answered_at:
        if last_answered_at.tzinfo is None:
            last_answered_at = last_answered_at.replace(tzinfo=timezone.utc)
        formatted_last_answered_at = last_answered_at.isoformat(timespec="seconds").replace("+00:00", "Z")

    response_data = {
        "gameID": game_id,
        "questionContent": game_data.get("questionText", ""),
        "option1": game_data.get("option1", ""),
        "option2": game_data.get("option2", ""),
        "myChoice": my_choice,
        "opponentChoice": opponent_choice,
        "isUser1": is_user1,
        "lastAnsweredAt": formatted_last_answered_at
    }
    
    return https_fn.Response(json.dumps(response_data), mimetype="application/json")

def submit_balance_game(req: https_fn.Request) -> https_fn.Response:
    """
    밸런스 게임 선택지를 제출합니다.
    """
    try:
        uid = get_uid_from_request(req)
    except ValueError as e:
        return https_fn.Response(str(e), status=401)
        
    try:
        body = req.get_json()
        game_id = body.get("gameID")
        choice = body.get("choice") # 1 또는 2
    except Exception:
        return https_fn.Response("Invalid JSON", status=400)
        
    if not game_id or choice not in [1, 2]:
        return https_fn.Response("Invalid fields", status=400)

    db = get_db()

    @firestore.transactional
    def submit_in_transaction(transaction):
        user_ref = db.collection("users").document(uid)
        user_snapshot = next(transaction.get(user_ref))
        if not user_snapshot.exists: raise ValueError("User not found")
        
        user_data = user_snapshot.to_dict()
        couple_id = user_data.get("coupleID")
        if not couple_id: raise ValueError("Couple not found")
            
        couple_ref = db.collection("couples").document(couple_id)
        couple_snapshot = next(transaction.get(couple_ref))
        if not couple_snapshot.exists: raise ValueError("Couple not found")
        
        couple_data = couple_snapshot.to_dict()
        is_user1 = (couple_data.get("user1UID") == uid)
        
        answer_ref = couple_ref.collection("balanceGameAnswers").document(game_id)
        answer_snapshot = next(transaction.get(answer_ref))
        answer_data = answer_snapshot.to_dict() if answer_snapshot.exists else {}
        
        now = datetime.now(timezone.utc)
        answer_update = {}
        
        if is_user1:
            answer_update["user1Answer"] = choice
            answer_update["user1AnsweredAt"] = now
            opponent_choice = answer_data.get("user2Answer")
        else:
            answer_update["user2Answer"] = choice
            answer_update["user2AnsweredAt"] = now
            opponent_choice = answer_data.get("user1Answer")
            
        is_completing_now = (opponent_choice is not None) and not answer_data.get("bothAnswered", False)
        
        if is_completing_now:
            answer_update["bothAnswered"] = True
            answer_update["lastAnsweredAt"] = now
            current_stats = couple_data.get("balanceGameStats", {})
            current_total = current_stats.get("totalAnswered", 0)
            
            transaction.update(couple_ref, {
                "balanceGameStats.totalAnswered": current_total + 1,
                "balanceGameStats.lastAnsweredAt": now,
                "totalCoin": firestore.Increment(20),
                "foodCount": firestore.Increment(2)
            })
            
        transaction.set(answer_ref, answer_update, merge=True)
        
        return {
            "gameID": game_id,
            "myChoice": choice,
            "opponentChoice": opponent_choice,
            "bothAnswered": is_completing_now or answer_data.get("bothAnswered", False),
            "notificationData": {
                "partnerUID": user_data.get("partnerUID"),
                "nickname": user_data.get("nickname", "상대방"),
                "isCompletingNow": is_completing_now
            }
        }

    try:
        result = submit_in_transaction(db.transaction())
        
        # --- [Notification] ---
        notif_info = result.pop("notificationData", None)
        if notif_info and notif_info.get("partnerUID"):
            try:
                partner_uid = notif_info["partnerUID"]
                nickname = notif_info["nickname"]
                is_completing_now = notif_info["isCompletingNow"]
                
                if is_completing_now:
                    title = "밸런스 게임 답변 완료!"
                    body = f"{nickname}님이 선택을 마쳤습니다. 결과를 확인해보세요!"
                else:
                    title = "상대방이 밸런스 게임에 답변했어요!"
                    body = f"{nickname}님이 선택을 마쳤습니다. 선택하고 결과를 확인해보세요!"
                
                send_push_notification(
                    target_uid=partner_uid,
                    title=title,
                    body=body,
                    data={
                        "type": "balance_game",
                        "gameID": result.get("gameID")
                    }
                )
            except Exception as e:
                print(f"Error sending notification: {e}")

        return https_fn.Response(json.dumps(result), mimetype="application/json")
    except ValueError as e:
        return https_fn.Response(str(e), status=400)
    except Exception as e:
        return https_fn.Response(f"Internal Error: {str(e)}", status=500)
