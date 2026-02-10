from dataclasses import dataclass
from firebase_functions import https_fn


@dataclass(frozen=True)
class ErrorInfo:
    message: str
    status: int


def error_response(error: ErrorInfo) -> https_fn.Response:
    return https_fn.Response(error.message, status=error.status)


def error_response_with_detail(error: ErrorInfo, detail: str) -> https_fn.Response:
    return https_fn.Response(f"{error.message}: {detail}", status=error.status)


class NotFound:
    USER = ErrorInfo("User not found", 404)
    USER_TOKEN_INVALID = ErrorInfo("User not found (Token Invalid)", 404)
    TARGET_USER_INVALID_CODE = ErrorInfo("Target user not found (Invalid Code)", 404)
    COUPLE = ErrorInfo("Couple not found", 404)
    COUPLE_DOCUMENT = ErrorInfo("Couple document not found", 404)
    QUESTION = ErrorInfo("Question not found", 404)
    DAMAGO = ErrorInfo("Damago not found", 404)
    NO_MORE_QUESTIONS = ErrorInfo("No more questions available", 404)
    NO_MORE_BALANCE_GAMES = ErrorInfo("No more balance games available", 404)


class BadRequest:
    MISSING_FIELDS = ErrorInfo("Missing fields", 400)
    INVALID_FIELDS = ErrorInfo("Invalid fields", 400)
    MISSING_PARAMETERS = ErrorInfo("Missing parameters", 400)
    MISSING_TARGET_CODE = ErrorInfo("Missing 'targetCode'", 400)
    MISSING_DAMAGO_ID = ErrorInfo("Missing damagoID", 400)
    MISSING_AMOUNT = ErrorInfo("Missing amount", 400)
    AMOUNT_NOT_INTEGER = ErrorInfo("Amount must be an integer", 400)
    INVALID_TYPE = ErrorInfo("Invalid type. Use 'daily_question' or 'balance_game'", 400)
    INVALID_JSON = ErrorInfo("Invalid JSON", 400)
    INVALID_JSON_BODY = ErrorInfo("Invalid JSON body", 400)
    AT_LEAST_ONE_PARAM_REQUIRED = ErrorInfo("At least one parameter is required", 400)
    INVALID_DATE_FORMAT = ErrorInfo("Invalid date format. Use ISO 8601.", 400)
    MISSING_FCM_TOKEN = ErrorInfo("Missing fcmToken", 400)
    MISSING_TARGET_UID_OR_CONTENT_STATE = ErrorInfo("Missing targetUID or contentState", 400)
    START_TOKEN_NOT_FOUND_OR_DISABLED = ErrorInfo(
        "Start Token not found or Live Activity disabled", 400
    )
    NOT_ENOUGH_COINS = ErrorInfo("Not enough coins", 400)
    USER_HAS_NO_COUPLE = ErrorInfo("User has no couple", 400)


class Forbidden:
    ADMIN_REQUIRED = ErrorInfo("Unauthorized: Admin access required", 403)


class Internal:
    UNABLE_TO_GENERATE_NEW_CODE = ErrorInfo("Unable to generate new code", 500)
    FAILED_TO_SEND_PUSH_NOTIFICATION = ErrorInfo("Failed to send push notification", 500)
    TRANSACTION_FAILED = ErrorInfo("Transaction failed", 500)
