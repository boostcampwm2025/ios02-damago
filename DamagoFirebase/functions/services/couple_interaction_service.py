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
