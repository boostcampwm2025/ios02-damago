# 다마고 - 다양한 마음을 고이 담아

> **iOS 17+ Live Activity를 활용한 잠금화면 속 펫 양육 및 커플 연결 서비스**

![iOS](https://img.shields.io/badge/iOS-17.0%2B-black?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-6.2.1-orange?logo=swift&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-26.1-blue?logo=xcode&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Serverless-yellow?logo=firebase&logoColor=white)

<img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-01-31 at 21 33 42" src="https://github.com/user-attachments/assets/c1a047dc-d1f9-4656-96d6-18a669eace2a" />
<img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-01-31 at 22 16 38" src="https://github.com/user-attachments/assets/bc8e8ed0-e4fd-4113-993f-78814cd69fff" />
<img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-01-31 at 21 34 45" src="https://github.com/user-attachments/assets/78dc12e4-ba02-4566-ab7d-51d1b9483b8d" />

## 📖 About
**"앱을 켜지 않아도, 우리는 연결되어 있어."**

기존 커플 앱들이 기념일이나 일기 작성 같은 **의무감**을 주는 것에 문제의식을 느꼈습니다.
**Damago**는 **Live Activity**와 **Dynamic Island** 기술을 활용해, 앱을 실행하지 않아도 잠금화면에서 항상 서로의 존재를 확인하고 가볍게 소통할 수 있는 **Always-on Connection** 서비스를 지향합니다.

---

## 🚀 Key Features
*   **Always-on Connection:** Live Activity를 통해 잠금화면과 다이나믹 아일랜드에서 펫의 상태를 실시간으로 확인하고 파트너와 연결됩니다.
    * ![Simulator Screen Recording - iPhone 17 Pro - 2026-01-31 at 21 36 04](https://github.com/user-attachments/assets/bbff32f8-3239-4aa6-bb83-fce8741bf6d4)
 
*   **Hybrid UI (UIKit + SwiftUI):** 안정적인 UIKit 네비게이션 위에 SwiftUI의 화려한 애니메이션과 위젯 기술을 접목했습니다.
    * ![Simulator Screen Recording - iPhone 17 Pro - 2026-01-31 at 22 16 50](https://github.com/user-attachments/assets/338cb165-d9e9-49fe-bd19-4cac9a943339)

*   **Gamification:** 먹이 주기, 콕 찌르기, 밸런스 게임 등 부담 없는 놀이 요소를 통해 관계를 돈독히 합니다.
    * <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-01-31 at 21 33 56" src="https://github.com/user-attachments/assets/6ff19dd4-9e15-43dd-9793-8222021c2e5c" /> <img width="200" alt="Simulator Screenshot - iPhone 17 Pro - 2026-01-31 at 21 37 47" src="https://github.com/user-attachments/assets/ed351df9-9910-48aa-b027-5b3a0d60abe8" />

*   **Local-First Sync:** 네트워크가 불안정해도 끊김 없는 경험을 제공하며, SwiftData를 통해 데이터를 효율적으로 관리합니다.

---

## 🛠 Tech Stack

| Category | Technologies |
| --- | --- |
| **Language** | Swift 6.2.1 (iOS 17.0+) |
| **Framework** | **UIKit** (Base), **SwiftUI** (Complex UI, Widget), ActivityKit, TipKit |
| **Architecture** | **Clean Architecture**, MVVM |
| **Concurrency** | **async/await**, **AsyncStream**, Combine (UI Event Stream) |
| **Data Persistence** | **SwiftData**, UserDefaults (App Group) |
| **Network & Backend** | Firebase (Firestore, Cloud Functions - Python), URLSession |
| **CI/CD** | GitHub Actions, Fastlane |

---

## 💡 기술적 의사 결정

### 1. Hybrid UI Strategy: UIKit & SwiftUI
*   **Decision:** 기본 구조는 **UIKit**을 채택하고, 복잡한 뷰나 최신 기술이 필요한 곳에 **SwiftUI**를 `UIHostingController` 래핑하여 혼용했습니다.
*   **Reason:**
    *   초기 기획 단계에서 SpriteKit 미니게임(공룡 게임 등) 확장을 고려했을 때 UIKit 베이스가 연동에 유리하다고 판단했습니다.
    *   SwiftUI의 `NavigationStack`보다 UIKit의 화면 전환 관리가 더 명확하고, Coordinator 패턴 등으로의 확장 및 유지보수가 용이하다고 판단했습니다.
    *   반면 `ActivityKit`, `TipKit`, 그리고 복잡한 애니메이션(Gacha, Timer) 구현에는 생산성이 높은 SwiftUI를 적재적소에 사용하여 기술적 이점을 모두 취했습니다.

### 2. Concurrency: async/await, Combine, & AsyncStream
*   **Decision:** 비동기 작업의 성격에 따라 **async/await**, **Combine**, **AsyncStream**을 적재적소에 나누어 활용했습니다.
*   **Reason:**
    *   **단발성 작업:** 네트워킹과 같은 단순 비동기 작업에는 `async/await`을 사용하여 코드를 간결하게 작성했습니다.
    *   **UI 이벤트:** 버튼 탭이나 텍스트 입력과 같은 UI 이벤트 스트림은 **Combine**을 사용하여 선언적으로 처리함으로써 MVVM 패턴의 이점을 살렸습니다.
    *   **데이터 스트림 (Local-First):** 로컬 캐시를 먼저 방출하고 네트워크 데이터를 이어서 처리해야 하는 **순차적 다발 데이터 요청**에서는, 기존 Combine(`Future`, `Merge`)의 복잡한 체이닝 대신 **`AsyncStream`**을 도입하여 `if`와 `await`을 활용한 가독성 높은 코드를 구현했습니다.

### 3. Data Persistence: SwiftData
*   **Decision:** 로컬 데이터 저장소로 Core Data 대신 **SwiftData**를 채택했습니다.
*   **Reason:**
    *   팀 프로젝트 특성상 `.xcdatamodeld` 파일의 Git 충돌은 협업 효율을 크게 저하시키는 요소였습니다.
    *   **Code-based**로 스키마 관리가 가능한 SwiftData를 도입하여 파일 충돌 가능성을 획기적으로 줄이고, Swift 네이티브한 문법으로 생산성을 높였습니다.

### 4. Serverless & CI/CD
*   **Serverless Backend:** 별도의 서버 구축 대신 **Firebase Cloud Functions (Python)**를 사용하여 개발 리소스를 기능 구현에 집중했습니다. `SnapshotListener`를 활용해 실시간성을 확보하고, 환경(Dev/Prod)을 분리하여 개발 안정성을 높였습니다.
*   **CI/CD:** **GitHub Actions**를 도입하여 빌드 무결성을 검증하고, 팀원 간 로컬 환경 불일치로 인한 빌드 오류를 사전에 차단했습니다.

---

## 📂 Project Structure

```
ios02-damago
├── Damago/                 # Main App Project
│   ├── Application/        # App Lifecycle & DI Container
│   ├── Presentation/       # MVVM (View, ViewModel, ViewController)
│   ├── Domain/             # UseCases, Entities, Repository Protocols
│   ├── Data/               # Repositories & Persistent Storage (SwiftData)
│   ├── Core/               # Logger, Extensions, Constants
│   └── Resources/          # Assets, Fonts, Info.plist
│
├── DamagoNetwork/          # Network Module (SPM)
│   ├── Network/            # API Endpoints & NetworkProvider (URLSession)
│   └── DTOs/               # Network Response Data Transfer Objects
│
├── DamagoFirebase/         # Backend (Firebase Cloud Functions & Rules)
└── DamagoWidget/           # ActivityKit & Widget Extension
```

* **Clean Architecture** MVVM 구조를 이용하고, 네트워크 레이어의 경우 위젯과 공유된 소스를 SPM 모듈로 분리하였습니다.

---

## 👥 팀원

이름|👑 [하종석](https://www.notion.so/boostcamp-wm/S040_-24fb9dd86abe802fab6bdf9f5ead24ef)|🥸 [박현수](https://www.notion.so/boostcamp-wm/S015_-24fb9dd86abe8000a96ef4f50a888b61)| 🤖 [김재영](https://www.notion.so/boostcamp-wm/S008_-2c3b9dd86abe80a195d5c5c9b999bbbe)|🐶 [박진홍](https://www.notion.so/boostcamp-wm/S012_-24fb9dd86abe8001b757df693b8831e0)
|---|---|---|---|---|
|직책|UI·UX Leader|Project Leader|Jaemini|Bom'sDaddy
|ID|S040|S015|S008|S012
|아바타|<img width="128" height="256" alt="image" src="https://github.com/user-attachments/assets/0365d328-31e6-4ad0-8473-1c7a5257a985" />|<img width="128" height="256" alt="avatar-c8d72daf-4a7e-4fa6-b229-6b75f4bffd5d d34d93bd-8c84-4e33-82ef-6af49ce970c9 f7064b28-6cc9-470a-b6df-679e42a8d7d3 b93675e3-5f87-44d7-8e97-d2e7d2451df0 20251010T233328Z" src="https://github.com/user-attachments/assets/b66467c5-3fa5-432b-b417-eb9e27aaa6ae" />|<img width="128" height="256" alt="image" src="https://github.com/user-attachments/assets/fb2c5d84-cf99-423c-9c87-9262be127ea2" />|<img width="128" height="256" alt="게더 아바타" src="https://github.com/user-attachments/assets/6123cf6d-e22b-47a7-9b1b-031f19c3cf43" />
|MBTI|INTJ|ISTP|INFP|INTJ

## 📚 팀 문서
|[위키](https://github.com/boostcampwm2025/ios02-damago/wiki)|[노션](https://www.notion.so/iOS02-2c3a8af4eff28073864afeb6760f19f1)|[피그마](https://www.figma.com/design/hdowjco5TZoKlEMZGUhNUO/iOS02?node-id=0-1&p=f&t=2vS3UeVDKxSlttgo-0)|
|--|--|--|

## 💾 TestFlight

[**Damago 테스트플라이트 참여하기 🔗**](https://testflight.apple.com/join/UpvK4K6t)
