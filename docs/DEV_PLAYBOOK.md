# DeepMine E2E 개발 프롬프트 플레이북

- 대상 도구: Claude Code (Xcode 프로젝트), 필요 시 Xcode 에이전트 병용
- 전제: Spec v0.2, iOS 26+, 서버 없음
- 문서 버전: v1.0

---

# 0. 이 문서 쓰는 법

프롬프트를 **순서대로** 하나씩 던집니다. 한 번에 여러 단계를 시키지 마세요. 각 프롬프트는 이전 단계의 산출물이 있다고 가정합니다.

각 프롬프트 끝에는 **완료 기준(DoD)** 이 붙어 있습니다. DoD를 만족 못 하면 다음으로 넘어가지 않습니다.

## 0.1 iOS 특유의 한계 — 먼저 알고 시작

- **에이전트는 시뮬레이터/실기기 실행을 못 하거나 매우 불안정합니다.** 빌드까지는 시켜도, 동작 검증은 사람이 합니다.
- **Live Activity, Screen Time, AlarmKit은 시뮬레이터에서 제대로 안 됩니다.** 실기기 필수.
- 따라서 **도메인 로직을 UI에서 완전히 분리해 SwiftPM 패키지로 빼고, 그 부분만 헤드리스 테스트**합니다. 이게 이 플레이북의 핵심 구조입니다.

```text
DeepMineCore (SwiftPM, UIKit/SwiftUI 의존 0)  ← swift test로 CI 가능
        ↑
DeepMineApp (Xcode, UI + 시스템 프레임워크)   ← 사람이 실기기 검증
```

---

# 1. CLAUDE.md — 저장소 규칙 파일

가장 먼저 이 파일을 저장소 루트에 만듭니다. 이후 모든 프롬프트가 이걸 참조합니다.

````markdown
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
````

---

# 2. Phase 0 — 기술 검증 하네스

게임 코드를 한 줄도 쓰기 전에, **위험 항목만 확인하는 껍데기 앱**을 만듭니다.

## 프롬프트 P0

````text
역할: iOS 시니어 엔지니어

목표: DeepMine 본 개발 착수 전, 기술 위험을 확인하는 최소 검증 앱
`DeepMineProbe`를 만든다. 게임 로직은 일절 넣지 않는다.

배경: 이 앱의 핵심 루프가 Live Activity / AlarmKit / Screen Time에
의존하는데, 이 조합이 실제로 되는지 미확인 상태다. 여기서 막히면
기획을 고쳐야 하므로 먼저 확인한다.

구성:
- Xcode 프로젝트 1개 (iOS 26 타깃)
- Widget Extension 1개
- DeviceActivityMonitor Extension 1개
- App Group 1개 (SwiftData 컨테이너 공유)

검증 화면 하나에 아래 버튼들을 나열하고, 각 결과를 화면과
App Group의 로그 파일에 동시에 남긴다.

1. [LA 시작] 60초 Live Activity 시작 (staleDate = 종료시각)
2. [LA 재시작] Expanded의 버튼에서 LiveActivityIntent로
   기존 LA end → 새 LA request. 순서를 지킬 것.
   실패 시 오류를 그대로 로그에 남길 것. 삼키지 말 것.
3. [AlarmKit] 60초 알람 스케줄. LA와 동시 운용 시 Dynamic Island
   충돌 여부를 관찰할 수 있게 함
4. [차단 권한] FamilyControls 권한 요청 + FamilyActivityPicker
5. [차단 적용/해제] ManagedSettingsStore shield 토글,
   적용 지연 시간 측정
6. [시간 무결성] Date()와 mach_continuous_time() 기반 경과시간을
   동시에 기록하고 차이 표시
7. [익스텐션 쓰기] 위젯 AppIntent에서 App Group SwiftData에 쓰고,
   앱 복귀 시 값 일치 확인

Live Activity 뷰 요구사항:
- compact leading에 24pt 더미 아이콘, trailing에 Text(timerInterval:)
- expanded에 ProgressView(timerInterval:) + 버튼 2개
- expanded 높이가 144pt를 넘지 않게 구성
- context.isStale 분기로 완료 뷰 렌더

제약:
- Info.plist 키 누락 없이: NSSupportsLiveActivities,
  NSAlarmKitUsageDescription, App Group entitlement
- FamilyControls entitlement는 아직 미승인일 수 있음.
  미승인 시 해당 항목만 우아하게 실패하고 나머지는 동작할 것

산출:
- 빌드 가능한 프로젝트
- `PROBE_CHECKLIST.md` — 7개 항목을 사람이 실기기에서
  통과/실패로 체크할 수 있는 표. 각 항목에 "무엇을 보면
  통과인지" 판정 기준을 적을 것

완료 기준:
- xcodebuild 빌드 성공
- BUILD_REPORT.md에 각 항목이 검증됨/미검증으로 구분되어 있을 것
- 시뮬레이터에서 확인 불가능한 항목은 반드시 "미검증(실기기 필요)"
````

> **여기서 멈추고 실기기로 직접 돌려보세요.** 7개 항목 결과를 확인한 뒤 다음으로 갑니다. 1번(LA 재시작)이 실패하면 Spec §18의 대응책(제어 센터 컨트롤을 주 진입점으로 승격)을 먼저 사양에 반영하고 진행합니다.

---

# 3. Phase 1 — 도메인 코어 (테스트 우선)

## 프롬프트 P1. 경제 엔진

````text
역할: 게임 시스템 엔지니어

목표: `DeepMineCore` SwiftPM 패키지에 게임 경제를 구현한다.
UI 없음. 시스템 프레임워크 import 금지.

구현 대상 (docs/SPEC_v0.2.md §4 참조):

1. Balance.swift — 모든 수치 상수를 한 곳에
   기본채굴량 100, 성장계수 1.04, 장비가격증가율 1.38,
   세션길이보정, 채굴계획배율, 검증등급배율, 스트릭배율,
   피로도 구간

2. RewardCalculator
   - 입력: 완료세션수, 세션길이, 채굴계획, 검증등급,
     스트릭일수, 당일N번째, 장비레벨, 광맥, 당일누적분
   - 출력: 광석/수정 획득량 + 적용된 배율 내역
   - 배율 내역을 반환하는 게 중요. UI에서 "왜 이만큼인지"를
     보여줘야 하고 밸런싱 때도 필요하다

2. FatigueCalculator — 일일 소프트캡 (240분 ×0.5, 360분 ×0.25)
   구간 경계를 걸치는 세션은 **분 단위로 나누어 가중 계산**할 것.
   예: 230분 시점에 25분 세션 → 10분은 ×1.0, 15분은 ×0.5

3. UpgradeCostCalculator — 가격 = 기본 × 1.38^(레벨-1)

4. UpgradeAdvisor — 효율 = 생산증가량 ÷ 비용, 동률이면 드릴 우선.
   구매 가능한 것 중 최선 1개를 반환. 없으면 nil

5. DepthCalculator — floor(12 × 세션수^1.15)

6. StreakEngine — 일일 목표 달성 판정, 연속일수, 주1회 유예,
   실패 시 절반 감소

7. VeinRoller — 광맥 판정. 시드 주입 가능한 난수를 쓸 것
   (테스트 재현성). 램프 레벨과 탐사 갱도 배율 반영

테스트 요구사항 (이게 본체다):
- 각 계산기별 경계값 테스트
- 피로도 구간 걸침 케이스 최소 3개
- 스트릭: 유예 소모 / 유예 소진 후 실패 / 자정 경과
- 광맥: 고정 시드로 분포 검증 (1000회 롤링 후 기대 확률 ±3%)
- 성장 곡선 회귀 테스트: 세션 1/10/20/40/80회 시점의
  보상값을 스냅샷으로 고정. 밸런스 변경 시 의도치 않은
  변동을 잡기 위함
- 통화 오버플로: 세션 500회 시점에 Double이 무너지지 않는지

완료 기준:
- swift test 전부 통과. 통과 로그를 BUILD_REPORT.md에 첨부
- 테스트 커버리지가 계산기 로직 기준 90% 이상
- Balance.swift의 상수를 바꾸면 스냅샷 테스트가 깨질 것
  (= 밸런스가 정말 한 곳에 모여 있다는 증거)
````

## 프롬프트 P2. 세션 상태 기계 + 시간 무결성

````text
역할: 도메인 엔지니어

목표: DeepMineCore에 세션 상태 기계와 시간 무결성 검증을 구현한다.

1. SessionStateMachine
   상태: preparing → mining → completed / abandoned
   - 허용되지 않는 전이는 에러를 던질 것 (조용히 무시 금지)
   - 각 전이에서 무엇이 기록되는지 명시

2. ClockIntegrityChecker
   - 세션 시작 시 (wallClock: Date, monotonic: UInt64) 쌍을 기록
   - 종료 시 두 경과시간을 비교
   - 차이가 임계(기본 30초) 초과 → .tampered
   - monotonic이 리셋됨(재부팅) → .rebooted, 벽시계 채택,
     강등하지 않음
   - 결과: .valid / .rebooted / .tampered
   - **mach_continuous_time 호출 자체는 프로토콜로 추상화하고
     Core에는 주입받을 것.** 테스트에서 가짜 시계를 넣어야 한다

3. VerificationGrade 판정
   차단 활성 + shield 유지 → .sealed
   차단 미설정/권한 없음 → .open
   shield 강제 해제 → .collapsed

테스트:
- 정상 세션
- 시계를 앞으로 당긴 경우
- 시계를 뒤로 돌린 경우
- 재부팅 시뮬레이션
- 상태 기계의 모든 불법 전이가 에러를 던지는지

완료 기준: swift test 통과, 시스템 프레임워크 import 0
````

---

# 4. Phase 2 — 저장소

## 프롬프트 P3

````text
역할: iOS 데이터 엔지니어

목표: DeepMineApp에 SwiftData 저장소를 구성한다.

요구사항:
1. 컨테이너를 App Group에 배치 (앱 + 위젯 익스텐션 공유)
2. 모델: PlayerState, EquipmentState, SessionRecord,
   DailyRecord, PurchaseState
3. 모든 모델에 schemaVersion 필드. 마이그레이션 경로를
   docs/MIGRATION.md에 문서화
4. **쓰기는 앱 프로세스로 단일화한다.**
   익스텐션은 읽기 전용 + 명령 큐(파일 기반)에 적재만 하고,
   앱이 포그라운드 진입 시 큐를 비운다.
   이유: 앱/익스텐션 동시 쓰기 충돌 방지
5. 손상된 저장소 복구 경로: 로드 실패 시 격리 보관 후 초기화,
   사용자에게 알림

DeepMineCore와의 연결:
- Core에 정의된 저장소 프로토콜을 App에서 구현
- Core는 SwiftData를 모른다

완료 기준:
- 빌드 성공
- 명령 큐 왕복 테스트 (익스텐션 쓰기 → 앱 반영) 코드 작성.
  실기기 검증 필요 항목으로 BUILD_REPORT에 명시
````

---

# 5. Phase 3 — 시스템 통합

## 프롬프트 P4. 차단

````text
목표: FamilyControls / ManagedSettings / DeviceActivity 통합

1. 권한 요청 흐름. 거부/미승인 시 .open 등급으로 우아하게 폴백
2. FamilyActivityPicker로 방해 앱 선택, 선택 결과 영속화
3. 세션 시작 시 shield 적용, 종료/포기 시 해제
4. DeviceActivityMonitor로 세션 경계 보강
5. 앱이 죽은 상태에서 세션이 끝났을 때 shield가 남지 않도록
   안전장치: 스케줄 종료 시각에 익스텐션이 반드시 해제

주의:
- entitlement 미승인 환경에서도 빌드와 실행이 되어야 한다
- shield 관련 실패를 조용히 삼키지 말 것. 등급 강등으로 반영

완료 기준: 빌드 성공. 동작은 실기기 미검증으로 명시
````

## 프롬프트 P5. Live Activity + AlarmKit

````text
목표: 표시 계층의 시간 축을 구현한다.

1. DeepMineActivityAttributes (Spec §10.3 그대로)
   - ContentState 4KB 이내. 이미지는 ID만 전달
   - staleDate = endsAt

2. LiveActivityManager
   - 시작은 앱 포그라운드에서만
   - 재시작은 반드시 end(dismissalPolicy: .immediate) 후 request
   - 실패 시 오류를 사용자에게 표면화

3. AlarmScheduler (AlarmKit)
   - 세션 종료 알람
   - 권한 미허용 시 로컬 알림으로 폴백

4. App Intents
   - StartSessionIntent: LiveActivityIntent
   - AbandonSessionIntent: LiveActivityIntent
   - AcceptUpgradeIntent: AppIntent (명령 큐 경유)
   - OpenGameIntent: openAppWhenRun

금지:
- 세션 중 Live Activity를 갱신하려는 코드를 작성하지 말 것.
  백그라운드에서 불가능하다. 시간 표시는 전부
  Text(timerInterval:) / ProgressView(timerInterval:) /
  context.isStale에 맡긴다

완료 기준: 빌드 성공. Phase 0 검증 결과를 코드 주석에 반영
````

## 프롬프트 P6. 표시 표면

````text
목표: 위젯 익스텐션의 모든 표시 표면 구현

1. Dynamic Island
   - compact leading: 24pt 스프라이트
   - compact trailing: Text(timerInterval:)
   - expanded: 144pt 이내. 완료 시 [추천 강화][25분][50분]
   - minimal: 아이콘 1개
2. 잠금화면 LA: 160pt 이내
3. StandBy 최적화 뷰
   - Night Mode 적색 단색에서 판독 가능하게
   - 명도 대비만으로 형태가 읽히도록
   - 좌측 1/3은 UI 영역이므로 아트를 비움
4. 홈 위젯 (small/medium): 오늘 진행률 + 시작 버튼
5. 제어 센터 컨트롤 (ControlWidget): 25분 세션 시작

에셋은 위젯 익스텐션 번들에 내장한다.

완료 기준:
- 빌드 성공
- 각 표면의 크기 제약을 코드/주석에 명시
- 위젯 프리뷰가 5종 상태(대기/채굴/완료/광맥/붕괴)를 렌더
````

---

# 6. Phase 4 — 앱 UI

## 프롬프트 P7

````text
목표: 메인 앱 화면 구현 (Spec §11)

한 화면 원칙. 상단 자원/심도/오늘진행 → 중앙 채굴계획+세션선택
→ 하단 장비 3종 → 최하단 프레스티지.

숨김 화면: 설정 / 통계 / 테마 / 프레스티지 확인 / 차단 앱 선택

요구사항:
- 모든 수치는 DeepMineCore 계산기에서 받는다. View에서 계산 금지
- 큰 숫자 축약 포맷터 (1.2K, 3.4M, 5.6B)
- 채굴 계획 선택은 1탭, 직전 선택 기억
- 심층 갱도는 3세션 완료 전까지 잠금 + 잠금 사유 표시
- Dynamic Type / VoiceOver / 고대비 대응
- 다크 테마 고정 (#0e0e0f 배경, #7c6aff / #40e0c8 액센트)

완료 기준: 빌드 성공, 접근성 레이블 전부 부여
````

## 프롬프트 P8. 온보딩

````text
목표: 첫 화면에서 클리커 루프 1회를 실제 상태로 완주시키는 온보딩

흐름:
첫 암반을 실제 탭으로 파괴
→ 광석 100과 수정 광맥 1개 확정 지급
→ 드릴 2레벨 강화
→ 홈 진입
→ 집중 출정을 실제 선택할 때만 필요한 권한 요청

핵심 제약:
- 설명 페이지와 대기 타이머로 첫 타격을 막지 않는다
- 타격·파괴·광석·광맥·강화는 모두 실제 저장소에 반영한다
- 권한을 거부하거나 집중 출정을 쓰지 않아도 앱이 끝까지 동작해야 한다
- 옛 온보딩 저장은 첫 암반 또는 레거시 권한 유예 경로로 복구한다

완료 기준: 빌드 성공, 첫 암반→보상→강화→홈 저장 왕복, 레거시 저장 복구
````

---

# 7. Phase 5 — 마감

## 프롬프트 P9. StoreKit

````text
목표: StoreKit 2 인앱 구매 (Spec §13)

상품: 심층 라이선스(원타임, 비소모성) / 테마팩 / 스킨 / 후원팩
- 구매 복원 필수
- 검증은 StoreKit 2 트랜잭션 검증 사용, 서버 없음
- 미구매 상태에서 잠긴 항목이 무엇인지 명확히 표시
- **게임 진행에 영향을 주는 상품을 만들지 말 것.**
  전부 외형/기록/통계에 한정

완료 기준: StoreKit Configuration 파일로 로컬 테스트 통과
````

## 프롬프트 P10. 밸런스 시뮬레이터

````text
역할: 게임 밸런서

목표: DeepMineCore를 사용하는 CLI 시뮬레이터를 만든다.
실제 사람이 30일 플레이하기 전에 곡선을 확인하기 위함이다.

입력: 페르소나 정의 (하루 세션 수, 선호 세션 길이,
채굴 계획 선호, 이탈률, 스트릭 유지율)
출력: 30일간의 일별 광석/심도/장비레벨/프레스티지 도달 시점,
CSV + 요약 표

기본 페르소나 4종:
- 라이트: 하루 1세션 25분, 이탈률 20%
- 스탠다드: 하루 3세션(25/25/50), 이탈률 10%
- 헤비: 하루 6세션, 이탈률 5%
- 불규칙: 이틀에 한 번, 스트릭 자주 끊김

이 시뮬레이터로 확인할 것:
- 첫 강화까지 몇 세션 걸리는가 (목표: 1~2)
- 첫 프레스티지 도달일 (목표: 7~10일, 스탠다드 기준)
- 30일차에 헤비와 라이트의 격차 (10배 이내가 목표)
- 소프트캡이 헤비 페르소나에서 실제로 작동하는가

완료 기준: swift run으로 4종 페르소나 결과 출력.
결과를 docs/BALANCE_REPORT.md에 표로 정리
````

## 프롬프트 P11. QA 스윕

````text
역할: QA 엔지니어

목표: Spec §20 테스트 항목을 전부 훑고 결함 목록을 만든다.

자동화 가능한 것은 테스트로 작성하고, 불가능한 것은
실기기 수동 테스트 체크리스트로 만든다.

특히 확인할 것:
- 앱 강제 종료 후 세션 복원
- 재부팅 중 세션이 진행 중이던 경우
- 자정 경과 시 스트릭/피로도 처리
- 시간대 변경
- shield가 남아있는 상태로 앱이 죽은 경우
- 권한 3종 각각 거부 상태의 전체 경로
- Dynamic Island 미지원 기기 (잠금화면만)
- StandBy 미지원/미사용 사용자

산출:
- docs/QA_CHECKLIST.md (실기기 수동 항목)
- 발견한 결함은 심각도별로 docs/DEFECTS.md에

완료 기준: 체크리스트 항목마다 자동/수동 구분이 명시됨
````

---

# 8. 진행 관리

## 8.1 단계별 게이트

| 단계 | 다음으로 넘어가는 조건 |
|---|---|
| P0 | 실기기에서 7개 항목 결과 확인 완료 |
| P1~P2 | `swift test` 전부 통과 |
| P3 | 명령 큐 왕복이 실기기에서 동작 |
| P4~P6 | 실기기에서 세션 1회 완주 (차단→표시→알람→보상) |
| P7~P8 | 첫 암반→보상→강화→홈 저장 왕복, 레거시 온보딩 복구 |
| P9~P11 | 밸런스 리포트 4종 페르소나 + QA 체크리스트 |

## 8.2 재사용 프롬프트

**막혔을 때**
```text
지금 상태를 BUILD_REPORT.md 형식으로 정리해줘.
검증됨 / 미검증 / 미구현으로 구분하고, 미검증 항목은
왜 검증하지 못했는지 사유를 적어줘. 추측으로 검증됨이라
적지 말 것.
```

**사양 이탈 의심될 때**
```text
docs/SPEC_v0.2.md와 현재 구현을 대조해서 차이를 표로 정리해줘.
사양에 없는데 구현된 것, 사양에 있는데 빠진 것,
사양과 다르게 구현된 것 세 가지로 나눠줘.
```

**리팩터링 필요할 때**
```text
DeepMineCore에 시스템 프레임워크 의존이 새어 들어왔는지 검사하고,
있으면 프로토콜 주입으로 걷어내줘. 걷어낸 뒤 swift test가
여전히 통과하는지 확인하고 로그를 보여줘.
```

## 8.3 하지 말 것

- P0를 건너뛰고 P1로 가기 — 기술 위험이 미확인인 채로 2주치 코드를 쌓게 됩니다
- 한 프롬프트에서 도메인 로직과 UI를 같이 시키기 — 경계가 반드시 무너집니다
- "빌드 성공"을 "동작 확인"으로 받아들이기 — iOS에서 이 둘은 다릅니다
- 밸런스 수치를 여러 파일에 흩기 — P10 시뮬레이터가 무용지물이 됩니다
