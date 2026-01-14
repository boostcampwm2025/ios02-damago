import os

# 앱의 번들 ID (APNS Topic 설정용)
BUNDLE_ID = os.environ.get("BUNDLE_ID", "kr.codesquad.boostcamp10.Damago")

# 레벨별 필요 경험치 테이블 (Index 0 = Lv 1의 필요 경험치)
# 커플 합산 하루 최대 18회(180XP) 획득 가능 -> 4주(28일) 코스를 위해 모델 1의 값을 2배 상향
# 총합: 5,820 XP (약 32일 소요)
XP_TABLE = [
    20, 40, 40, 60, 60,              # Lv 1 ~ 5 (초고속 구간: 약 1.2일)
    100, 100, 120, 120, 140,         # Lv 6 ~ 10 (가속 구간)
    160, 160, 180, 180, 200,         # Lv 11 ~ 15 (평탄 구간)
    200, 220, 220, 240, 240,         # Lv 16 ~ 20 (평탄 구간)
    260, 260, 280, 280, 300,         # Lv 21 ~ 25 (고난도 구간)
    300, 320, 320, 340, 360          # Lv 26 ~ 30 (최종 숙련 구간)
]

MAX_LEVEL = 30
FEED_EXP = 10  # 1회 밥주기 경험치

# 환경 변수 및 에뮬레이터 확인
IS_EMULATOR = bool(os.environ.get("FUNCTIONS_EMULATOR"))
PROJECT_ID = os.environ.get("GCLOUD_PROJECT", "damago-dev")

# Cloud Tasks 설정
LOCATION = "us-central1"
QUEUE_NAME = "make-hungry-queue"
HUNGER_DELAY_SECONDS = 4 * 60 * 60 # 4시간
