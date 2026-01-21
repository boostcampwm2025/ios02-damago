from firebase_functions import https_fn
from firebase_admin import firestore
from utils.firestore import get_db
from utils.middleware import get_uid_from_request
import json
from datetime import datetime

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
    last_answered_at = stats.get("lastAnsweredAt") # datetime 객체 or None
    
    # 기본적으로 다음 질문(total_answered + 1)을 타겟으로 함
    target_order = total_answered + 1
    
    # 만약 답변이 완료된 기록이 있다면 시간 체크
    if last_answered_at:        
        # 12시간 대기 로직
        # 마지막 답변 완료 시각으로부터 12시간이 지나지 않았으면, 
        # 새로운 질문 대신 '방금 완료한 질문(total_answered)'을 다시 보여줌
        
        # 주의: total_answered가 0이면 이전 질문이 없으므로 무조건 1번 질문
        if total_answered > 0:
            elapsed_time = datetime.now(last_answered_at.tzinfo) - last_answered_at
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
    
    # couples 문서에 currentQuestionId 업데이트 (없거나 다를 경우)
    if couple_data.get("currentQuestionId") != question_id:
        db.collection("couples").document(couple_id).update({"currentQuestionId": question_id})
    
    # 4. 답변 내역 조회 (있다면)
    answer_ref = db.collection("couples").document(couple_id).collection("dailyQuestionAnswers").document(question_id)
    answer_doc = answer_ref.get()
    
    user1_answer = None
    user2_answer = None
    
    if answer_doc.exists:
        answer_data = answer_doc.to_dict()
        user1_answer = answer_data.get("user1Answer")
        user2_answer = answer_data.get("user2Answer")
    
    response_data = {
        "questionID": question_id,
        "questionContent": question_content,
        "user1Answer": user1_answer,
        "user2Answer": user2_answer,
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
        
        now = datetime.now()
        
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
        
        return {
            "questionID": question_id,
            "questionContent": question_content,
            "user1Answer": user1_answer,
            "user2Answer": user2_answer,
            "isUser1": is_user1
        }

    try:
        result = submit_answer_in_transaction(db.transaction())
        return https_fn.Response(json.dumps(result), mimetype="application/json")
    except ValueError as e:
        return https_fn.Response(str(e), status=400)
    except Exception as e:
        return https_fn.Response(f"Internal Error: {str(e)}", status=500)
