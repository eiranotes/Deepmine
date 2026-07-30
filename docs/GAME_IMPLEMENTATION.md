# DeepMine Gameplay-Complete MVP

업데이트: 2026-07-30

## 제품 정의

DeepMine은 사용자가 15·25·50분 동안 휴대폰 방해를 줄이고 집중한 시간을 광산의 심도와 자원으로 바꾸는 로컬 iOS 게임이다. 현재 구현 범위는 `docs/SPEC_v0.2.md` §16의 P1–P4다. 플레이에 필요한 경제, 세션, 저장, 화면, 위젯 표면은 구현했지만 StoreKit, 서버, 소셜, 순위표, 퀘스트와 시즌은 포함하지 않는다.

## 전체 게임 흐름

1. 첫 실행에서 두 장의 짧은 설명으로 `집중 약속 → 귀환 보상`을 이해한다.
2. 차단 없이 90초 연습 채굴을 끝내고 최초 드릴 강화를 받는다.
3. 갱도 문, 귀환 신호, 귀환 쪽지 권한을 순서대로 선택한다. 거부해도 개방 채굴로 계속 플레이할 수 있다.
4. 광산 홈에서 안전·심층·탐사 갱도와 15·25·50분을 고른다.
5. 출정 약속에서 예상 광석, 검증 등급, 포기 결과와 준비 상태를 확인한다.
6. 채굴 중에는 남은 시간, 진행, 지역만 본다. 광석과 광맥은 귀환 전까지 공개하지 않는다.
7. 완료 또는 명시적 포기 후 귀환 보고서가 약속 이행, 획득 광석·광맥, 다음 심도·추천 장비를 세 박자로 보여준다.
8. 플레이어는 동등한 위계의 `마치기` 또는 `다음 출정 준비`를 선택한다.
9. 장비, 주간 일지, 기록, 광산 꾸미기와 심층 진입으로 장기 진행을 관리한다.

## 구현 계층

| 계층 | 책임 | 주요 경로 |
|---|---|---|
| Core | 수식, 상태 전이, 보상, 장비, 광맥, 스트릭, 지역, 프레스티지 | `DeepMineCore/Sources/DeepMineCore/` |
| 저장 | 명시적 SwiftData v1 그래프, 세션/보고서 원자적 커밋, 손상 격리 | `DeepMineApp/Persistence/` |
| 오케스트레이션 | 시스템 준비, 세션 재개, idempotent 명령, 수동/자동 귀환 | `DeepMineApp/Session/` |
| 제품 UI | 온보딩부터 프레스티지까지 플레이어 흐름 | `DeepMineApp/Views/` |
| 디자인 | 네 안료, 금속판, 현지화, fixture, 숫자 표시 | `DeepMineApp/DesignSystem/`, `DESIGN.md` |
| 시스템 표면 | Live Activity, 잠금화면, StandBy, 홈 위젯, Control Widget | `DeepMineProbe/Shared/`, `DeepMineProbe/Widget/` |
| 검증 | Core, 앱, 저장/복구, UI 흐름, 표면 캡처 | `DeepMineCore/Tests/`, `DeepMineAppTests/`, `DeepMineAppUITests/` |

`GameRepository`만 제품 SwiftData를 쓴다. Widget/Control/Live Activity intent는 snapshot DTO를 읽고 파일 명령을 append한다. 앱이 활성화되면 프로세스 잠금 아래 명령을 drain하고 SwiftData에 command ID와 변이를 함께 저장한다. UI fixture는 격리 저장소와 결정적 coordinator를 사용하며 제품 App Group 명령 큐를 소비하지 않는다.

## 경제와 공정성

- 집중 크레딧은 `focusedMinutes / 25`다.
- 성장 배율은 `1.04 ^ min(lifetimeFocusCredits, 20)`으로 상한을 둔다.
- 15·25·50분 보정은 ×1.0·×1.1·×1.3이다.
- 심층 포기/붕괴는 해당 세션 보상만 잃는다. 이미 획득한 일일 목표와 스트릭은 되돌리지 않는다.
- 광맥은 기본 12%이며 네 번의 미발견 이후 보정이 시작되고 여덟 번째 적격 완료에서 보장된다.
- 프레스티지는 광석·현재 회차 심도·장비를 초기화하고 기록·테마·수정·스트릭·영구 강화를 보존한다.

30일 시뮬레이션, 수식과 페르소나별 결과는 `docs/BALANCE_REPORT.md`에 고정돼 있다. 모든 숫자 상수는 `DeepMineCore/Sources/DeepMineCore/Balance.swift`에서 관리한다.

## 리텐션 설계

현재 리텐션은 반복 압박이 아니라 다음 행동을 예측 가능하게 만드는 데 집중한다.

- 홈의 `다음 약속`: 다음 1–3회 안에 열릴 갱도, 장비, 지역을 한 가지로 제한해 보여준다.
- 오늘 목표와 휴광일: 스스로 정한 25–360분 목표와 주 1회 자동 보호일을 제공한다.
- 누적 진행: 심도, 장비 세 종, 지역·테마, 장식과 프레스티지 영구 강화가 집중 시간을 장기 자산으로 바꾼다.
- 광맥 드라이 스펠 보호: 미획득이 끝없이 이어지지 않도록 확률 보정과 8회 보장을 둔다.
- 귀환 3박자: 완료 확인 → 보상 공개 → 다음 약속 순으로 감정적 마침표를 만든다.
- 무료 회고: 주간 일지와 기본 기록을 유료화하지 않아 실제 집중 습관을 확인할 수 있다.
- 수동적 복귀 표면: 잠금화면, Dynamic Island, StandBy, 홈 위젯, Control Widget이 앱을 열지 않아도 현재 약속이나 오늘 진행을 설명한다.
- 비강압 종료: `마치기`와 `다음 출정 준비`를 동등하게 두며 자동 재시작, 강제 연속 플레이, 소급 스트릭 파괴를 사용하지 않는다.

향후 검토 우선순위는 신규 퀘스트 수가 아니라 1일·7일 복귀, 권한 거부군의 완료율, 세션 길이별 포기율, 귀환 후 자발적 장비 열람률이다. 분석 SDK는 아직 추가하지 않았으며 로컬 이벤트 계약도 출시 개인정보 검토 전에는 확정하지 않는다.

## 시각 시스템

`DESIGN.md`가 기준이다. 석탄 `#10100F`, 혈암 `#373630`, 석회 `#E7E0CF`, 램프 황동 `#C58C39` 네 안료만 쓰고, 황동 채움은 화면의 주 동작 하나에만 허용한다. 패널과 버튼은 5–9pt 모서리, 리벳, 단단한 하단 깊이를 사용한다. 상태는 색만으로 전달하지 않고 아이콘, 문구, 외곽선과 채움으로 중복 표현한다.

생성 픽셀 광부와 완료·광맥·붕괴 스프라이트는 24×24 논리 그리드, 1x/2x/3x, 이진 alpha, 동일 네 안료를 사용한다. 앱의 광산 제어 장면과 시스템 표면이 같은 캐릭터를 공유한다.

## 저장과 복구

- 제품 저장소: App Group의 `DeepMine.store`.
- 현 스키마: 명시적 v1. 미지원 신규 버전은 fail-closed.
- 세션 완료: 플레이어, 귀환 보고서, 세션 정리를 한 트랜잭션으로 커밋한다.
- 보고서 소비: 사용자가 보고서를 닫은 뒤 저장된 보고서를 지우고 대기 snapshot을 게시한다.
- 손상 복구: store/wal/shm을 `CorruptStores/<timestamp>/`로 함께 옮긴 뒤 새 기본 저장소를 만들며, 원본은 자동 삭제하지 않는다.
- 명령 큐: 최대 최근 500개, JSONL 256KB, malformed 격리, SwiftData command ID를 최종 idempotency 기준으로 사용한다.

세부 절차는 `docs/MIGRATION.md`에 있다.

## 현지화와 접근성

- 제품 문자열은 `DeepMineApp/Resources/Localizable.xcstrings`의 한국어·영어를 사용한다.
- 플레이어 화면에는 `ActivityKit`, `ManagedSettings`, `FamilyControls` 같은 프레임워크명을 노출하지 않는다.
- 핵심 컨트롤은 최소 44×44pt, 접근성 label/identifier와 의미 있는 상태를 가진다.
- Dynamic Type과 Reduce Motion 분기를 구현했다. 사용자 요청에 따라 현재 시각 판정은 기본 medium만 실행했다.
- 실제 VoiceOver 초점 순서, 제스처 감각, Increase Contrast, Reduce Motion, 햅틱·사운드 체감은 물리 기기 게이트다.

## 빌드와 테스트

```sh
xcodegen generate --spec project.yml
swift test --package-path DeepMineCore
xcodebuild test -project DeepMine.xcodeproj -scheme DeepMineApp \
  -destination 'platform=iOS Simulator,name=DeepMine QA iPhone 17 Pro,OS=26.5' \
  CODE_SIGNING_ALLOWED=NO
xcodebuild build -project DeepMine.xcodeproj -scheme DeepMineApp \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
```

결정적 캡처는 한국어·다크·표준 대비·기본 medium에서 생성하며 `artifacts/ui/game-mvp-v1/`에 19개 화면과 contact sheet를 보존한다.

## 검증 경계

시뮬레이터에서 검증한 것:

- 전체 로컬 게임 상태와 경제 계산
- SwiftData temporary/in-memory 저장, 재개방, 손상 복구
- 한국어·영어 fixture의 제품 흐름과 의미 접근성
- Activity/잠금/StandBy/widget/control과 동일한 production view의 크기 제한 렌더링
- 코드 서명 비활성 generic iOS 빌드

물리 기기에서만 통과시킬 것:

- 승인된 FamilyControls와 App Group entitlement
- 실제 ManagedSettings 차단·해제와 DeviceActivityMonitor 종료 콜백
- AlarmKit과 커스텀 Live Activity 동시 운용
- 실제 Dynamic Island, SpringBoard 잠금화면, StandBy와 Control Center 등록·크롭·수명주기
- extension 프로세스에서 앱 프로세스로 이어지는 실제 App Group 명령 왕복
- 실제 VoiceOver, Reduce Motion, Increase Contrast, 햅틱과 사운드

물리 기기 결과가 없으므로 위 항목을 구현 완료나 출시 준비 완료로 해석하면 안 된다.

## 명시적 미구현

- StoreKit, 구독, 결제, 유료 상세 분석
- 서버 동기화, 계정, 클라우드 백업
- 소셜, 친구, 순위표, 경쟁형 스트릭
- 퀘스트, 시즌, 배틀패스, 푸시 기반 복귀 캠페인
- 출시 분석 SDK와 원격 설정

