from firebase_admin import auth
from firebase_functions import https_fn

def get_uid_from_request(req: https_fn.Request) -> str:
    auth_header = req.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise ValueError("Missing or invalid Authorization header")
    token = auth_header.split("Bearer ")[1]
    decoded_token = auth.verify_id_token(token)
    return decoded_token["uid"]