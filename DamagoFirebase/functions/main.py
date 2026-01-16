# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_functions.options import set_global_options
from firebase_admin import initialize_app
from services import auth_service, pet_service, push_service, user_service

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
