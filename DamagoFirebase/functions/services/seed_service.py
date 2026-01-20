"""
시드 데이터 관리 서비스
관리자가 초기 데이터를 추가하는 Cloud Functions
"""

from firebase_functions import https_fn
from firebase_admin import firestore
import google.cloud.firestore
import csv
import os
from pathlib import Path
from utils.firestore import get_db

def is_admin(req: https_fn.Request) -> bool:
    """
    관리자 권한 확인
    
    개발 환경(에뮬레이터): 인증 없이 허용
    프로덕션: Authorization 헤더의 ID 토큰으로 Custom Claims 확인
    """
    import os
    
    # 에뮬레이터 환경에서는 인증 없이 허용
    if os.getenv('FUNCTIONS_EMULATOR') == 'true' or os.getenv('FIRESTORE_EMULATOR_HOST'):
        return True
    
    # 프로덕션: ID 토큰 검증
    auth_header = req.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return False
    
    try:
        from firebase_admin import auth
        id_token = auth_header.split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        
        # Custom Claims에서 admin 권한 확인
        return decoded_token.get('admin', False)
        
    except Exception as e:
        print(f"Admin verification error: {e}")
        return False


def load_daily_questions_from_csv() -> list:
    """CSV 파일에서 일일 응답 질문 로드"""
    csv_path = Path(__file__).parent.parent / 'data' / 'DailyQuestionResource.csv'
    questions = []
    
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                questions.append({
                    'order': int(row['번호']),
                    'questionText': row['질문 내용'].strip()
                })
        return questions
    except FileNotFoundError:
        raise Exception(f"CSV file not found: {csv_path}")
    except Exception as e:
        raise Exception(f"Error loading CSV: {str(e)}")


def load_balance_games_from_csv() -> list:
    """CSV 파일에서 밸런스 게임 로드"""
    csv_path = Path(__file__).parent.parent / 'data' / 'BalanceGameResource.csv'
    games = []
    
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                games.append({
                    'order': int(row['번호']),
                    'questionText': row['질문'].strip(),
                    'option1': row['선택지 1'].strip(),
                    'option2': row['선택지 2'].strip()
                })
        return games
    except FileNotFoundError:
        raise Exception(f"CSV file not found: {csv_path}")
    except Exception as e:
        raise Exception(f"Error loading CSV: {str(e)}")


def seed_daily_questions(req: https_fn.Request) -> https_fn.Response:
    """
    일일 응답 질문 시드 데이터 추가 (CSV 파일에서 로드)
    
    사용법:
        # 개발 환경 (에뮬레이터) - 인증 불필요
        curl -X POST http://localhost:5001/damago-dev-26/us-central1/seed_daily_questions
        
        # 프로덕션 - Authorization 헤더 필요
        curl -X POST https://your-function-url/seed_daily_questions \
          -H "Authorization: Bearer YOUR_ID_TOKEN"
    """
    
    # 관리자 권한 확인 (에뮬레이터에서는 자동 통과)
    if not is_admin(req):
        return https_fn.Response("Unauthorized: Admin access required", status=403)
    
    try:
        import time
        request_id = str(time.time())
        print(f"[SEED-DAILY] Request {request_id} started")
        
        # Firestore 클라이언트 초기화
        db = get_db()
        
        # CSV에서 데이터 로드
        questions_data = load_daily_questions_from_csv()
        print(f"[SEED-DAILY] Request {request_id} - CSV loaded: {len(questions_data)} questions")
        
        # force 파라미터 확인
        force = req.args.get('force', 'false').lower() == 'true'
        
        # 기존 데이터 확인
        existing_docs = list(db.collection('dailyQuestions').limit(1).get())
        has_existing_data = len(existing_docs) > 0
        
        print(f"[SEED-DAILY] Request {request_id} - Current state: has_data={has_existing_data}, force={force}")
        
        if has_existing_data and not force:
            print(f"[SEED-DAILY] Request {request_id} - BLOCKED: Data already exists")
            return https_fn.Response(
                "Daily questions already exist. Use ?force=true to override.",
                status=409
            )
        
        print(f"[SEED-DAILY] Request {request_id} - Proceeding to add data")
        
        # force=true이면 기존 데이터 삭제
        deleted_count = 0
        if force and has_existing_data:
            # 기존 데이터 삭제 (배치 단위로)
            while True:
                docs = list(db.collection('dailyQuestions').limit(500).get())
                if len(docs) == 0:
                    break
                    
                batch = db.batch()
                for doc in docs:
                    batch.delete(doc.reference)
                    deleted_count += 1
                batch.commit()
        
        # 배치로 추가 (Firestore는 배치당 최대 500개)
        added_count = 0
        batch = db.batch()
        batch_count = 0
        
        for question in questions_data:
            doc_ref = db.collection('dailyQuestions').document()
            batch.set(doc_ref, {
                'order': question['order'],
                'questionText': question['questionText'],
                'createdAt': firestore.SERVER_TIMESTAMP
            })
            batch_count += 1
            added_count += 1
            
            # 500개마다 커밋
            if batch_count >= 500:
                batch.commit()
                batch = db.batch()
                batch_count = 0
        
        # 남은 데이터 커밋
        if batch_count > 0:
            batch.commit()
        
        print(f"[SEED-DAILY] Request {request_id} - COMPLETED: deleted={deleted_count}, added={added_count}")
        
        # 성공 메시지
        message = f"✅ Successfully added {added_count} daily questions from CSV"
        if deleted_count > 0:
            message = f"✅ Deleted {deleted_count} existing questions, added {added_count} new questions from CSV"
        
        return https_fn.Response(message, status=200)
        
    except Exception as e:
        return https_fn.Response(f"Error: {str(e)}", status=500)


def seed_balance_games(req: https_fn.Request) -> https_fn.Response:
    """
    밸런스 게임 시드 데이터 추가 (CSV 파일에서 로드)
    
    사용법:
        # 개발 환경 (에뮬레이터) - 인증 불필요
        curl -X POST http://localhost:5001/damago-dev-26/us-central1/seed_balance_games
        
        # 프로덕션 - Authorization 헤더 필요
        curl -X POST https://your-function-url/seed_balance_games \
          -H "Authorization: Bearer YOUR_ID_TOKEN"
    """
    
    # 관리자 권한 확인 (에뮬레이터에서는 자동 통과)
    if not is_admin(req):
        return https_fn.Response("Unauthorized: Admin access required", status=403)
    
    try:
        import time
        request_id = str(time.time())
        print(f"[SEED-BALANCE] Request {request_id} started")
        
        # Firestore 클라이언트 초기화
        db = get_db()
        
        # CSV에서 데이터 로드
        games_data = load_balance_games_from_csv()
        print(f"[SEED-BALANCE] Request {request_id} - CSV loaded: {len(games_data)} games")
        
        # force 파라미터 확인
        force = req.args.get('force', 'false').lower() == 'true'
        
        # 기존 데이터 확인
        existing_docs = list(db.collection('balanceGames').limit(1).get())
        has_existing_data = len(existing_docs) > 0
        
        print(f"[SEED-BALANCE] Request {request_id} - Current state: has_data={has_existing_data}, force={force}")
        
        if has_existing_data and not force:
            print(f"[SEED-BALANCE] Request {request_id} - BLOCKED: Data already exists")
            return https_fn.Response(
                "Balance games already exist. Use ?force=true to override.",
                status=409
            )
        
        print(f"[SEED-BALANCE] Request {request_id} - Proceeding to add data")
        
        # force=true이면 기존 데이터 삭제
        deleted_count = 0
        if force and has_existing_data:
            while True:
                docs = list(db.collection('balanceGames').limit(500).get())
                if len(docs) == 0:
                    break
                    
                batch = db.batch()
                for doc in docs:
                    batch.delete(doc.reference)
                    deleted_count += 1
                batch.commit()
        
        # 배치로 추가
        batch = db.batch()
        added_count = 0
        batch_count = 0
        
        for game in games_data:
            doc_ref = db.collection('balanceGames').document()
            batch.set(doc_ref, {
                'order': game['order'],
                'questionText': game['questionText'],
                'option1': game['option1'],
                'option2': game['option2'],
                'createdAt': firestore.SERVER_TIMESTAMP
            })
            batch_count += 1
            added_count += 1
            
            # 500개마다 커밋
            if batch_count >= 500:
                batch.commit()
                batch = db.batch()
                batch_count = 0
        
        # 남은 데이터 커밋
        if batch_count > 0:
            batch.commit()
        
        print(f"[SEED-BALANCE] Request {request_id} - COMPLETED: deleted={deleted_count}, added={added_count}")
        
        # 성공 메시지
        message = f"✅ Successfully added {added_count} balance games from CSV"
        if deleted_count > 0:
            message = f"✅ Deleted {deleted_count} existing games, added {added_count} new games from CSV"
        
        return https_fn.Response(message, status=200)
        
    except Exception as e:
        return https_fn.Response(f"Error: {str(e)}", status=500)


def clear_seed_data(req: https_fn.Request) -> https_fn.Response:
    """
    시드 데이터 삭제
    
    사용법:
        # 모든 시드 데이터 삭제 (dailyQuestions + balanceGames)
        curl -X DELETE http://localhost:5001/damago-dev-26/us-central1/clear_seed_data
        
        # 특정 컬렉션만 삭제
        curl -X DELETE "http://localhost:5001/damago-dev-26/us-central1/clear_seed_data?collection=dailyQuestions"
        curl -X DELETE "http://localhost:5001/damago-dev-26/us-central1/clear_seed_data?collection=balanceGames"
    """
    
    # 관리자 권한 확인 (에뮬레이터에서는 자동 통과)
    if not is_admin(req):
        return https_fn.Response("Unauthorized: Admin access required", status=403)
    
    try:
        # Firestore 클라이언트 초기화
        db = get_db()
        
        # collection 파라미터 확인 (없으면 둘 다 삭제)
        collection = req.args.get('collection', 'all')
        
        # 삭제할 컬렉션 목록
        if collection == 'all':
            collections_to_delete = ['dailyQuestions', 'balanceGames']
        elif collection in ['dailyQuestions', 'balanceGames']:
            collections_to_delete = [collection]
        else:
            return https_fn.Response(
                "Invalid collection. Use: dailyQuestions, balanceGames, or omit for all",
                status=400
            )
        
        total_deleted = 0
        results = []
        
        for coll_name in collections_to_delete:
            deleted_count = 0
            
            # 배치 단위로 삭제
            while True:
                docs = list(db.collection(coll_name).limit(500).get())
                if len(docs) == 0:
                    break
                
                batch = db.batch()
                for doc in docs:
                    batch.delete(doc.reference)
                    deleted_count += 1
                batch.commit()
            
            total_deleted += deleted_count
            results.append(f"{coll_name}: {deleted_count}")
        
        message = f"✅ Deleted {total_deleted} documents ({', '.join(results)})"
        return https_fn.Response(message, status=200)
        
    except Exception as e:
        return https_fn.Response(f"Error: {str(e)}", status=500)
