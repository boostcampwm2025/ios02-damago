# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_functions.options import set_global_options
from firebase_admin import initialize_app
from services import auth_service, pet_service, push_service, user_service, seed_service, couple_interaction_service

# For cost control, you can set the maximum number of containers that can be
# running at the same time. This helps mitigate the impact of unexpected
# traffic spikes by instead downgrading performance. This limit is a per-function
# limit. You can override the limit for each function using the max_instances
# parameter in the decorator, e.g. @https_fn.on_request(max_instances=5).
set_global_options(max_instances=10)
initialize_app()

@https_fn.on_request()
def generate_code(req: https_fn.Request) -> https_fn.Response:
    return auth_service.generate_code(req)

@https_fn.on_request()
def connect_couple(req: https_fn.Request) -> https_fn.Response:
    return auth_service.connect_couple(req)

@https_fn.on_request()
def poke(req: https_fn.Request) -> https_fn.Response:
    return push_service.poke(req)

@https_fn.on_request()
def save_live_activity_token(req: https_fn.Request) -> https_fn.Response:
    return push_service.save_live_activity_token(req)

@https_fn.on_request()
def update_live_activity(req: https_fn.Request) -> https_fn.Response:
    return push_service.update_live_activity(req)

@https_fn.on_request()
def start_live_activity(req: https_fn.Request) -> https_fn.Response:
    return push_service.start_live_activity(req)

@https_fn.on_request()
def feed(req: https_fn.Request) -> https_fn.Response:
    return pet_service.feed(req)

@https_fn.on_request()
def make_hungry(req: https_fn.Request) -> https_fn.Response:
    return pet_service.make_hungry(req)

@https_fn.on_request()
def get_user_info(req: https_fn.Request) -> https_fn.Response:
    return user_service.get_user_info(req)

@https_fn.on_request()
def update_fcm_token(req: https_fn.Request) -> https_fn.Response:
    return user_service.update_fcm_token(req)
    
@https_fn.on_request()
def update_user_info(req: https_fn.Request) -> https_fn.Response:
    return user_service.update_user_info(req)

@https_fn.on_request()
def fetch_daily_question(req: https_fn.Request) -> https_fn.Response:
    return couple_interaction_service.fetch_daily_question(req)

@https_fn.on_request()
def submit_daily_question(req: https_fn.Request) -> https_fn.Response:
    return couple_interaction_service.submit_daily_question(req)

# ========================================
# 시드 데이터 관리 (관리자 전용)
# ========================================

@https_fn.on_request()
def seed_daily_questions(req: https_fn.Request) -> https_fn.Response:
    """일일 응답 질문 시드 데이터 추가"""
    return seed_service.seed_daily_questions(req)

@https_fn.on_request()
def seed_balance_games(req: https_fn.Request) -> https_fn.Response:
    """밸런스 게임 시드 데이터 추가"""
    return seed_service.seed_balance_games(req)

@https_fn.on_request()
def clear_seed_data(req: https_fn.Request) -> https_fn.Response:
    """시드 데이터 삭제 (개발 환경 전용)"""
    return seed_service.clear_seed_data(req)
