## 📌 관련 이슈
- resolves #

## 🥑 작업 요약
- 설정 탭 진입 시 발생하는 앱 종료(크래시) 현상을 수정했습니다.
- 프로젝트 전역의 Combine 유틸리티를 리팩토링하여 `@MainActor` 기반 ViewModel의 스레드 안전성을 근본적으로 강화했습니다.
- 주요 ViewModel의 전수 조사를 통해 백그라운드 스레드에서의 상태 변경 위험을 제거했습니다.

## 🛠️ 작업 내용
### SettingsViewController 안정성 확보

- `setupTips()`에서 스냅샷 섹션 존재 여부 체크 로직을 추가하여 데이터 미로드 시의 `NSInternalInconsistencyException` 방지.
- 배경색 팝업 노출 시 강제 언래핑(`!`) 제거 및 방어적 코드 적용.

### Combine+.swift` 유틸리티 근본 리팩토링 및 테스트 호환성 확보

- `mapForUI`, `compactMapForUI`, `pulse` 등의 커스텀 연산자 내부에서 `receiveOnMainIfNecessary()`를 호출하여 체인 최상단에서 스레드 관리.
- **테스트 호환성**: 현재 스레드가 이미 메인일 경우 즉시 실행되도록 개선하여, 비동기 처리를 기다리지 않는 기존 단위 테스트들과의 호환성을 유지하면서도 앱 런타임의 안전성을 확보했습니다.
- 이를 통해 변환 클로저(`transform`) 내부에서도 안전하게 `@MainActor` 격리 속성(ViewModel의 `state` 등)에 접근할 수 있도록 개선했습니다.

### 전역 ViewModel 스레드 안전성 점검 및 수정

- `HomeViewModel`, `InteractionViewModel`, `SettingsViewModel` 등 주요 화면의 ViewModel 전수 조사.
- `GlobalStore` 등 백그라운드 발생 가능성이 있는 업스트림 구독 시 메인 스레드 전환을 보장하도록 수정.
- 중복된 `.receive(on: .main)` 코드를 제거하고 개선된 `*ForUI` 유틸리티로 코드 최적화.

## 📸 스크린샷 (UI 변경 시)
| 기능 | AS-IS | TO-BE |
| :--: | :--: | :--: |
| 설정 탭 진입 | 진입 시 간헐적 크래시 발생 | 안정적으로 화면 진입 및 팁 노출 |

## 🧪 테스트 방법
- [x] 앱 실행 후 즉시 설정 탭 진입 시 크래시 여부 확인
- [x] 네트워크 속도를 지연시킨 상태에서 설정 탭 진입 시 안정성 확인
- [x] 다이내믹 아일랜드 설정 토글 및 배경색 변경 팝업 정상 작동 확인
- [x] 모든 ViewModel 단위 테스트가 통과하는지 확인 (특히 비동기 기대를 포함하지 않은 테스트)

## 💬 리뷰 요구사항 (Optional)
- `Combine+.swift`에 도입된 `receiveOnMainIfNecessary()` 방식이 테스트와 런타임 안전성을 모두 만족하는지 검토 부탁드립니다.
- 모든 UI 업데이트용 매핑 로직을 메인 스레드로 정상화하여 Actor Isolation 위반 위험을 근본적으로 제거했습니다.

## ✅ 체크리스트
- [x] 빌드 및 실행 테스트를 완료했나요?
- [x] 불필요한 주석 및 Print 문을 제거했나요?
- [x] 코딩 컨벤션을 준수했나요?
