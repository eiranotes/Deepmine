# DeepMine Gameplay-Complete MVP

업데이트: 2026-07-31

## 제품 정의

DeepMine은 암반을 탭해 부수고, 장비를 사서 자동 채굴을 키우며, 세로 갱도를 내려가는 로컬
iOS 방치형 게임이다. 15·25·50분 집중 차단은 광석을 더 받는 선택적 증폭기이며 심도나
프레스티지 자격의 전제 조건이 아니다. 현재 구현 범위는 클리커 P3까지다. StoreKit, 서버,
소셜, 순위표, 퀘스트와 시즌은 포함하지 않는다.

## 전체 게임 흐름

1. 홈의 세로 갱도에서 작업 중인 막장을 탭한다. 약점·크리티컬·연속 탭이 손 채굴 효율을 올린다.
2. 암반이 깨지면 광석과 파편이 나오고 실제 막장이 한 층 내려간다.
3. 드릴은 탭 데미지, 광차는 초당 자동 데미지, 램프는 크리티컬과 아래 시야를 키운다.
4. 앱을 닫아도 최대 8시간×효율 0.75의 자동 채굴을 정산하고 복귀 시 한 번만 수령한다.
5. 이번 하강에서 부순 층 목표를 채우면 프레스티지한다. 위치와 장비는 초기화하지만 최고
   심도·지역·테마·굴착 기억은 남는다.
6. 원하면 홈 하단의 집중 출정에서 15·25·50분 차단과 채굴 계획을 고른다. 권한을 거부해도
   클리커 루프는 끝까지 진행된다.
7. 집중 출정 완료·포기 뒤 귀환 보고서는 약속 이행, 증폭 광석·광맥, 추천 장비를 보여준다.

현재 온보딩은 아직 피벗 이전의 집중 설명과 연습을 먼저 보여준다. 구현된 주 루프와 첫 경험의
순서가 어긋난 상태이며 P4 재작성 과제다.

## 구현 계층

| 계층 | 책임 | 주요 경로 |
|---|---|---|
| Core | 수식, 상태 전이, 보상, 장비, 광맥, 스트릭, 지역, 프레스티지 | `DeepMineCore/Sources/DeepMineCore/` |
| 저장 | 명시적 SwiftData v1 그래프, 세션/보고서 원자적 커밋, 손상 격리 | `DeepMineApp/Persistence/` |
| 오케스트레이션 | 시스템 준비, 세션 재개, idempotent 명령, 수동/자동 귀환 | `DeepMineApp/Session/` |
| 제품 UI | 온보딩부터 프레스티지까지 플레이어 흐름 | `DeepMineApp/Views/` |
| 디자인 | 네 안료, 금속판, 현지화, fixture, 숫자 표시 | `DeepMineApp/DesignSystem/`, `DESIGN.md` |
| 시스템 표면 | Live Activity, 잠금화면, 홈 위젯 | `DeepMineProbe/Shared/`, `DeepMineProbe/Widget/` |
| 검증 | Core, 앱, 저장/복구, UI 흐름, 표면 캡처 | `DeepMineCore/Tests/`, `DeepMineAppTests/`, `DeepMineAppUITests/` |

`GameRepository`만 제품 SwiftData를 쓴다. Widget/Control/Live Activity intent는 snapshot DTO를 읽고 파일 명령을 append한다. 앱이 활성화되면 프로세스 잠금 아래 명령을 drain하고 SwiftData에 command ID와 변이를 함께 저장한다. UI fixture는 격리 저장소와 결정적 coordinator를 사용하며 제품 App Group 명령 큐를 소비하지 않는다.

## 경제와 공정성

- 집중 크레딧은 `focusedMinutes / 25`다.
- 성장 배율은 `1.04 ^ min(lifetimeFocusCredits, 20)`으로 상한을 둔다.
- 15·25·50분 보정은 ×1.0·×1.1·×1.3이다.
- 심도는 실제 막장 세그먼트×4m이며 집중 크레딧은 심도를 직접 주지 않는다.
- 암반 내구는 ×1.058, 광석은 ×1.07로 성장하고 구매 후 층 시간 증가는 약 3.064%다.
- 장비 상한은 `min(200, 5 + 최고 심도/15m)`이며 프레스티지 후에도 다시 잠기지 않는다.
- 심층 포기/붕괴는 해당 세션 보상만 잃는다. 이미 획득한 일일 목표와 스트릭은 되돌리지 않는다.
- 광맥은 기본 12%이며 네 번의 미발견 이후 보정이 시작되고 여덟 번째 적격 완료에서 보장된다.
- 프레스티지는 광석·현재 위치·장비를 초기화하고 최고 심도·테마·수정·스트릭·영구 강화를 보존한다.

30일 시뮬레이션, 수식과 페르소나별 결과는 `docs/BALANCE_REPORT.md`에 고정돼 있다. 모든 숫자 상수는 `DeepMineCore/Sources/DeepMineCore/Balance.swift`에서 관리한다.

## 리텐션 설계

현재 리텐션은 반복 압박이 아니라 다음 행동을 예측 가능하게 만드는 데 집중한다.

- 홈의 `다음 약속`: 다음에 열릴 층·장비·지역을 한 가지로 제한해 보여준다. 세션 단위 잔여
  문구는 아직 층 단위로 바꿔야 한다.
- 오늘 목표와 휴광일: 스스로 정한 25–360분 목표와 주 1회 자동 보호일을 제공한다.
- 누적 진행: 최고 심도, 장비 세 종, 지역·테마, 장식과 프레스티지 영구 강화가 암반 파괴를
  장기 자산으로 바꾼다.
- 광맥 드라이 스펠 보호: 미획득이 끝없이 이어지지 않도록 확률 보정과 8회 보장을 둔다.
- 귀환 3박자: 완료 확인 → 보상 공개 → 다음 약속 순으로 감정적 마침표를 만든다.
- 무료 회고: 주간 일지와 기본 기록을 유료화하지 않아 실제 집중 습관을 확인할 수 있다.
- 수동적 복귀 표면: 집중 중에는 잠금화면·Dynamic Island, 방치 중에는 홈 위젯이 앱을
  열지 않아도 현재 약속이나 오프라인 상태를 설명한다.
- 비강압 종료: `마치기`와 `다음 출정 준비`를 동등하게 두며 자동 재시작, 강제 연속 플레이, 소급 스트릭 파괴를 사용하지 않는다.

향후 검토 우선순위는 신규 퀘스트 수가 아니라 1일·7일 복귀, 권한 거부군의 완료율, 세션 길이별 포기율, 귀환 후 자발적 장비 열람률이다. 분석 SDK는 아직 추가하지 않았으며 로컬 이벤트 계약도 출시 개인정보 검토 전에는 확정하지 않는다.

## 시각 시스템

`DESIGN.md`가 기준이다. 석탄 `#10100F`, 혈암 `#373630`, 석회 `#E7E0CF`, 램프 황동 `#C58C39` 네 안료만 쓰고, 황동 채움은 화면의 주 동작 하나에만 허용한다. 패널과 버튼은 5–9pt 모서리, 리벳, 단단한 하단 깊이를 사용한다. 상태는 색만으로 전달하지 않고 아이콘, 문구, 외곽선과 채움으로 중복 표현한다.

생성 픽셀 광부와 완료·광맥·붕괴 스프라이트는 24×24 논리 그리드, 1x/2x/3x, 이진 alpha, 동일 네 안료를 사용한다. 앱의 광산 제어 장면과 시스템 표면이 같은 캐릭터를 공유한다.

홈의 갱도는 지역별 320×128 와이드 벽면 4종, 320×90 지표 캐노피, 구조물·광맥 오버레이
2종을 사용한다. 정사각 암반 타일을 반복하지 않는다. 약점은 36pt로 보여도 48×48pt 조작
영역을 유지하고, 층 전환은 네이티브 spring을 사용한다. Reduce Motion은 이동 대신 제자리
교차 페이드를 제공한다.

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
- Activity/잠금화면/widget과 동일한 production view의 크기 제한 렌더링
- 코드 서명 비활성 generic iOS 빌드

물리 기기에서만 통과시킬 것:

- 승인된 FamilyControls와 App Group entitlement
- 실제 ManagedSettings 차단·해제와 DeviceActivityMonitor 종료 콜백
- AlarmKit과 커스텀 Live Activity 동시 운용
- 실제 Dynamic Island와 SpringBoard 잠금화면 Live Activity 등록·크롭·수명주기
- extension 프로세스에서 앱 프로세스로 이어지는 실제 App Group 명령 왕복
- 실제 VoiceOver, Reduce Motion, Increase Contrast, 햅틱과 사운드

물리 기기 결과가 없으므로 위 항목을 구현 완료나 출시 준비 완료로 해석하면 안 된다.

## 명시적 미구현

- StoreKit, 구독, 결제, 유료 상세 분석
- 서버 동기화, 계정, 클라우드 백업
- 소셜, 친구, 순위표, 경쟁형 스트릭
- 퀘스트, 시즌, 배틀패스, 푸시 기반 복귀 캠페인
- 출시 분석 SDK와 원격 설정
