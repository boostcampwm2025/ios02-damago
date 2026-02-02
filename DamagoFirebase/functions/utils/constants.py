import os

# 앱의 번들 ID (APNS Topic 설정용)
BUNDLE_ID = os.environ.get("BUNDLE_ID", "kr.codesquad.boostcamp10.Damago")

# 환경 변수 및 에뮬레이터 확인
IS_EMULATOR = bool(os.environ.get("FUNCTIONS_EMULATOR"))
PROJECT_ID = os.environ.get("GCLOUD_PROJECT", "damago-dev")

# Cloud Tasks 설정
LOCATION = "asia-northeast3"
QUEUE_NAME = "make-hungry-queue"
HUNGER_DELAY_SECONDS = 4 * 60 * 60 # 4시간

# --- Game Balance Constants ---

FEED_EXP = 10  # 1회 밥주기 경험치

# 레벨별 필요 경험치 테이블 (Index 0 = Lv 1의 필요 경험치)
# Lv 1 ~ 30 (약 1달 코스)
XP_TABLE = [
    20, 40, 40, 60, 60,              # Lv 1 ~ 5
    100, 100, 120, 120, 140,         # Lv 6 ~ 10
    160, 160, 180, 180, 200,         # Lv 11 ~ 15
    200, 220, 220, 240, 240,         # Lv 16 ~ 20
    260, 260, 280, 280, 300,         # Lv 21 ~ 25
    300, 320, 320, 340, 360          # Lv 26 ~ 30
]

def get_required_exp(level: int) -> int:
    """
    해당 레벨에서 다음 레벨로 가기 위해 필요한 경험치를 반환합니다.
    - Lv 1 ~ 30: XP_TABLE 참조
    - Lv 31 ~ : 선형 증가 공식 적용 (360 + (Lv - 30) * 20)
    """
    if level <= 0:
        return XP_TABLE[0]
    
    if level <= len(XP_TABLE):
        return XP_TABLE[level - 1]
    
    # Lv 31 이상 로직
    # Lv 30의 경험치(360)을 기준으로 레벨당 20씩 증가
    base_exp = XP_TABLE[-1] # 360
    extra_level = level - len(XP_TABLE)
    return base_exp + (extra_level * 20)

def get_level_up_reward(level: int) -> int:
    """
    레벨업 달성 시 지급할 코인 보상을 반환합니다.
    - 지급 주기: 매 5레벨 (5, 10, 15 ...)
    - 지급 양: 50 + (Level * 10)
    - 해당하지 않으면 0 반환
    """
    if level % 5 != 0:
        return 0

    return 50 + (level * 10)


# DamagoAttributes.DamagoType.isAvailable == true 인 타입 (동기화 유지)
AVAILABLE_DAMAGO_TYPES = [
    "CatSiamese",
    "CatTiger",
    "CatBatman",
    "CatChristmas",
    "CatEgypt",
    "CatOddEye",
    "CatThreeColored",
    "CatWizard",
]

# DamagoType rawValue → 기본 이름 (DamagoAttributes.DamagoType.defaultName과 동기화)
DAMAGO_TYPE_DEFAULT_NAMES = {
    "CatSiamese": "샴",
    "CatTiger": "호랑이",
    "CatBatman": "배트맨",
    "CatChristmas": "크리스마스",
    "CatEgypt": "이집트",
    "CatOddEye": "오드아이",
    "CatThreeColored": "삼색",
    "CatWizard": "위자드",
    "Dog": "강아지",
    "Fish": "물고기",
    "Lizard": "도마뱀",
    "Owl": "부엉이",
    "Parrot": "앵무새",
    "Rabbit": "토끼",
}


def get_default_damago_name(damago_type: str | None) -> str:
    """damago_type에 맞는 기본 이름을 반환합니다. 없으면 '다마고'."""
    if not damago_type:
        return "다마고"
    return DAMAGO_TYPE_DEFAULT_NAMES.get(damago_type, "다마고")