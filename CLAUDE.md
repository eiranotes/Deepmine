# DeepMine 작업 규칙

## 프로젝트
집중 차단 기반 채굴 게임. iOS 26+. 서버 없음. 단독 개발.
상세 사양은 `docs/SPEC_v0.2.md`. **사양과 충돌하는 구현을 임의로 하지 말 것.**
사양이 모호하면 구현하지 말고 질문할 것.

## 아키텍처 경계 (절대 위반 금지)
- `DeepMineCore`: 순수 Swift. Foundation만 허용.
  SwiftUI / UIKit / ActivityKit / FamilyControls / SwiftData import 금지.
- `DeepMineApp`: UI와 시스템 프레임워크. 게임 규칙 계산 로직을 여기 두지 말 것.
- 경계를 넘겨야 하면 프로토콜을 Core에 정의하고 App에서 구현할 것.

## 검증 규칙
- 완료를 보고하기 전에 반드시 실행할 것:
  - `swift test` (DeepMineCore)
  - `xcodebuild -scheme DeepMineApp -destination 'generic/platform=iOS' build`
- **실행하지 않은 것을 "동작한다"고 쓰지 말 것.**
- 실기기 검증이 필요한 항목은 "미검증(실기기 필요)"로 명시할 것.

## 보고 형식
작업 종료 시 `BUILD_REPORT.md`를 갱신한다. 항목마다 다음 중 하나로 표시:
- `검증됨` — 테스트 또는 빌드로 확인함. 근거 명령어를 함께 적을 것.
- `미검증` — 코드는 작성했으나 실행 확인 못 함. 사유를 적을 것.
- `미구현` — 안 함.
근거 없이 `검증됨`으로 적지 말 것. 이게 가장 중요한 규칙이다.

## 코드 규칙
- Swift 6 동시성. `@MainActor` 경계 명시.
- 게임 수치는 하드코딩 금지. `Balance.swift` 한 곳에 상수로 모을 것.
- 부동소수점 재화는 `Double`, 표시용 축약은 별도 포맷터.
- 주석은 "왜"만. "무엇"은 코드로 말할 것.
- 파일 300줄 초과 시 분리.

## 금지
- 임의의 기능 추가
- 사양에 없는 화면 추가
- 서버/네트워크 코드
- 광고 SDK
- 테스트 실패를 주석 처리하거나 `XCTSkip`으로 넘기기
