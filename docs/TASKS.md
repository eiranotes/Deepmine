# Tasks

업데이트: 2026-08-01

## Gameplay-complete MVP — implemented

- [x] 문서 3종 보존, XcodeGen 멀티 타깃 프로젝트와 P0 진단 하네스
- [x] `DeepMineCore` 경제/상태/진행/광맥/스트릭/프레스티지 엔진과 30일 밸런스 시뮬레이션
- [x] SwiftData v1 전체 round-trip, 손상 격리, 세션/보고서 commit, 명령 idempotency
- [x] 첫 암반 실제 파괴 → 광석/광맥 보상 → 드릴 강화 → 홈 온보딩 (D-052)
- [x] 광산 홈, 안전/심층/탐사, 15/25/50분, 출정 약속, 활성 채굴, 포기 확인
- [x] 완료/포기/붕괴/광맥 5종 귀환 보고서와 다음 장비 handoff
- [x] 장비, 주간 일지, 무료 기록, 광산 꾸미기, 설정, 심층 진입
- [x] 한국어·영어 플레이어 용어와 4색 광산 디자인 시스템
- [x] 생성 픽셀 광부 및 상태 스프라이트를 앱·Widget Asset Catalog에 편입
- [x] Live Activity, 잠금화면, StandBy-shaped content, small/medium widget, Control Widget
- [x] 전체 실제 흐름 XCUITest와 default-medium 화면 19장 read-back
- [x] `DESIGN.md`, `PRODUCT.md`, 밸런스/QA/마이그레이션/구현 문서

## Economy and retention review — implemented

- [x] 장비 효과 복리 전환, 비용 지수 1.34, 레벨 상한 60을 심도로 해금 (D-023)
- [x] 심도를 lifetime 기준으로 전환하고 심연 보너스를 프레스티지에 보존 (D-024)
- [x] 프레스티지 굴착 기억 재구매 할인과 run 크레딧 비례 조각 (D-025)
- [x] 광석 격차 가드레일 재설정, 심도 역전 금지·사다리 잔존 회귀 추가 (D-026)
- [x] Live Activity intent가 앱 프로세스에서 명령을 즉시 적용 (D-027)
- [x] `CLOCK_MONOTONIC_RAW` 시계 소스로 정직한 세션 강등 방지
- [x] 스트릭 감쇠 1회 제한과 보상 계산 전 확정
- [x] 완료 세션에서만 공명 부스트 소진
- [x] 추천 강화의 광맥 종류별 기대 광석 계산
- [x] 홈 연속 일수·휴광일·계획 리스크·1탭 추천 강화
- [x] 귀환 보고서 심도 증가·오늘 목표·연속 일수·광맥 수량과 등급 배지 카피 수정
- [x] 출정 약속 시트 광맥 확률
- [x] 장비 화면 심도 해금·기억 할인 표시
- [x] 활성 채굴 내려놓기 안내
- [x] 300줄 초과 12개 파일 분리, 세미콜론 압축 해제, 테스트 식별자 정리

## Retention systems — implemented

- [x] 도전과제 엔진(순수 Core)과 30종 카탈로그, 보상 정책 회귀 테스트 (D-028/D-029)
- [x] 도전과제 화면: 계열별 목록, 미달성 진행률, 달성 수 요약
- [x] 세션 완료·장비 구매·프레스티지 경로에서 멱등 평가
- [x] 홈 다음 세 걸음 진행률과 남은 출정 추정 (P4에서 기본 홈 위계와 함께 제거)
- [x] 광부 파생 함수와 갱도 광부 1~12명 표시, 장비 화면 증가 알림
- [x] 성장 곡선(출정 1회 광석, 12주 스파크라인, 기록 시작 대비 배율)
- [x] 광맥 도감과 장비 상위 레벨 목표치

## Play experience — implemented

- [x] 이벤트 9종 감각 피드백과 CoreHaptics 패턴, 미지원 기기 폴백 (D-030)
- [x] 귀환 보상 카운트업과 진행률 레일 채움, Reduce Motion 분기
- [x] 활성 채굴 광부 작업 루프 (D-031)
- [x] 수정 광맥 확정 발견과 첫 강화 광석 지급 (D-032, D-052)
- [x] 결과별 스프라이트(완료·광맥·붕괴)와 홈 갱도 장식 4종 렌더
- [x] `docs/ACHIEVEMENT_ART_PROMPTS.md` 배지 35종 프롬프트
- [x] 도전과제 배지 35종 생성·4색 양자화·48/96/144 PNG Asset Catalog 편입과
      도전과제 목록 48pt 렌더

## System surface and reward payoff — implemented

- [x] iPhone 잠금화면의 medium Activity를 StandBy로 오인하던 레이아웃 분기 수정
- [x] AlarmKit countdown용 Live Activity Widget 구성과 Dynamic Island compact/expanded/minimal 배선
- [x] 활성 countdown은 AlarmKit 하나가 소유하고 커스텀 Activity는 실패/완료 경로로 제한
- [x] 귀환 보고서에 획득량 비례 광석 광차 적재 연출과 Reduce Motion 분기
- [x] 완료 햅틱을 광석 낙하→광차 충돌 리듬으로 변경

## Complete game art — implemented

- [x] 광맥 5종, 장비 9종(1–20/21–40/41–60), 테마 장면 4종
- [x] 투명 장식 4종, 심층/탐사 광부 2종, Dynamic Island 배너 4종
- [x] StandBy 배경 4종, 자원 3종, 영구 강화 3종, 온보딩 2종
- [x] 40 고유 ImageGen 원본과 프롬프트 provenance 매니페스트
- [x] PNG 120개 네 안료·브라스 비율·크기·알파·Contents.json 기계 검증
- [x] 홈/활성/장비/테마/도감/귀환/프레스티지/온보딩/Activity 실제 렌더 연결
- [x] 알 수 없는 plan/region/vein ID fallback과 장비 티어 경계 회귀
- [x] fresh 19-screen 캡처와 compact/scene/safe-zone contact sheet

## Play experience — deferred

- [ ] 커스텀 8-bit SFX 저작. 현재는 이벤트별 시스템 사운드 ID이며 교체 지점은
      `GameFeedbackEvent.systemSoundID`
- [x] 새 게임 아트 기준 19화면을 `artifacts/imagegen/game-assets-v1/ui-captures/`에 재캡처

## Closeout — in progress

- [x] `xcodegen generate --spec project.yml`
- [x] `swift test --package-path DeepMineCore` 73/73
- [x] 핵심 흐름과 화면 캡처 focused suite
- [x] 전체 `DeepMineApp` 시뮬레이터 suite 175/175 fresh gate 결과 기록
- [x] generic iOS code-signing-disabled build 재확인
- [x] Swift 파일 300줄, 4색 계약, 현지화 JSON, 캡처 수량 기계 검사
- [x] 최종 self-review와 상태 문서 closeout

## 아이들 클리커 피벗

### P0 — 길 치우기 (완료)

- [x] 피벗 이전 상태를 브랜치 `pomodoro-v1-focus-blocking`과 태그 `pre-pivot-v1`로 보존
- [x] 코드 감사와 결정 D-033..D-039 기록
- [x] 사양 §1.2 정체성 재작성: 방치 생산이 기본, 집중은 선택적 증폭기
- [x] 피로 소프트캡, 집중 스트릭, 주간 장부, StandBy, Control Center 위젯 제거
- [x] 모듈명 `DeepMineProbe` → `DeepMine`

### P1 — 클리커 코어

- [x] `BigNumber` 가수/지수 산술과 표기 분리
- [x] `RockSegment` 결정적 생성, 4단계 파괴, 광맥층
- [x] `RockEngine` 넘침 이월과 절단 보고
- [x] `StrikeEngine` 탭 데미지·크리티컬·임팩트 미터
- [x] 자동화 데미지와 장비 3종 역할 재조준 (D-039)
- [x] 교체 가능한 아트 레이어, 플레이스홀더 24종, `docs/ROCK_ART_PROMPTS.md`
- [x] 암반 아트 24장 실제 생성과 팔레트 검증
- [x] 밸런스 CLI에 탭 입력과 실제 오프라인 캡 반영 (D-044)

### P2 — 실제로 플레이 가능하게

- [x] 탭→파괴→광석→구매 수직 슬라이스를 새 루트 화면에
- [x] 고정 스텝 시뮬레이션 루프
- [x] 오프라인 계산기와 수령 시트
- [x] 집중 증폭기 재진입 경로 (기존 preflight/active/Live Activity 재사용)

### P3 — 장기 성장과 리텐션

- [x] 성장 천장 3종 제거와 재튜닝: 내구 성장률 1.058, 심도 해금 15m당, 상한 200 (D-044)
- [x] 프레스티지를 부순 암반 기준으로 전환하고 위치를 지표로 되돌린다 (D-045, D-046)
- [x] 세로 갱도 단면 UI와 램프 기반 시야, 홈 재배치 (D-047)
- [x] 도전과제를 암반 파괴 경로에서 평가 (D-047)
- [x] 지역 벽면 4종·지표·구조물·광맥 생성 에셋 7종과 독립 후처리/검증 파이프라인 (D-048)
- [x] 탭 데미지·충격 배율·다음 광맥·파괴 광석/파편을 실제 작업면에 표시
- [x] 홈 시작 UI 테스트를 스크롤 안전 경로로 바꾸고 관련 UI 14/14 재검증
- [ ] 전체 `DeepMineAppUITests` 완주. 이전 이산 갱도 관련 14건 결과는 새 연속 갱도 검증으로 확대하지 않음
- [x] 갱도 텍스처 마감. 정사각 타일 반복을 지역별 320×128 와이드 벽면으로 교체하고
      지표 캐노피·구조물·광맥을 배경/구조/상태 역할로 분리
- [x] 약점 48×48pt 조작 영역, 네이티브 spring, Reduce Motion 제자리 대체
- [x] 장비 상한을 최고 심도에 통일하고 심연 보너스를 실제 막장 이동으로 정규화 (D-049)
- [x] 오프라인 정산 뒤 stale foreground 틱이 배경 구간을 재생하지 않게 정산 시각 통일
- [ ] 공명 결절(golden cookie), 지역 전환 연출
- [ ] 도전과제 카탈로그에 부순 암반 계열 추가 (배지 아트 35종 계약 확장이 선행 조건)
- [x] 온보딩을 클리커 우선으로 재작성 — 실제 첫 암반, 저장 보상, 즉시 강화, 맥락형 권한 (D-052)
- [x] 기본 홈의 다음 약속·다음 세 걸음·연속 일수 위계를 제거하고 집중 기록은 전용 패널로 격리
- [ ] 8비트 SFX 실제 제작 (`GameFeedbackEvent.systemSoundID`가 교체 지점)
- [ ] `RockEngine`이 한 번에 512층을 넘겨 `wasTruncated`가 되면 남은 데미지를 재정산한다.
      현재 호출부는 절단 여부를 전달하지만 남은 데미지를 보존하지 않아 극단적 오프라인 성장에서 손실 가능
- [ ] 장기 클리커 통화를 `Resources.ore: Double`에서 `BigNumber` 또는 별도 저장 표현으로
      마이그레이션한다. 데미지·암반은 큰 수를 지원하지만 실제 지갑은 `Double` 포화에 머문다
- [ ] 180일 heavy/light 누적 광석 역전(0.406배)의 최초 시점을 프레스티지·장비 구매별로
      분해하고, 즉시 프레스티지/지연 프레스티지 시나리오를 비교한다

### P4 — 연속 갱도와 장비가 보이는 성장

- [x] 심도→y 연속 좌표로 전환하고 4m 타일 행·사각 파괴 와이프 제거 (D-050)
- [x] 굴착 헤드가 현재 암반 진행률만큼 실제 하강하고 돌파 시 지층이 같은 거리만큼 이동
- [x] 지역 경계에서만 큰 지층을 나누고 위쪽에 균열·보어 폭·설비 이력을 보존
- [x] 심도 눈금을 폭을 차지하지 않는 좌측 오버레이로 바꿔 갱도 중심 정렬 복원
- [x] 드릴 레벨을 도구 티어·보어 폭·스윙·파편 밀도에 연결
- [x] 광차 레벨을 레일·왕복 대수·속도에, 램프 레벨을 설비·조사 범위에 연결
- [x] 레벨 5에서 장비별 상호 배타 분기 2종, 총 6종을 구매·저장·프레스티지 리셋 (D-051)
- [x] 분기 시각 계약: 넓은 보어/강한 스윙, 추가 광차/큰 화물차, 긴 조사/빛나는 약점
- [x] 현재 에셋 기반 웹 프로토타입, 연속 하강 DOM 계약 3건, 비공개 Sites 배포
- [x] 귀환의 `nextPromise`를 다음 지역 `nextGoal`로 재정의하고 약속 카피 제거
- [x] Swift 연속 갱도 기준 한국어 다크/medium 첫 암반 캡처 확인
- [x] 신규/진행 홈 단일 갱도와 접힌 집중 패널 focused XCUITest 1/1
- [x] 한국어·다크·medium 코어 루프 5화면 캡처 XCUITest 1/1과 갱도 육안 확인
- [x] 막장 전체 폭의 생성 지반을 배경과 분리된 기본 탭 대상으로 만들고 즉시 press-down 반응 연결 (D-053)
- [x] 생성 곡괭이 에셋을 광부 몸과 분리해 수동 타격·자동화 틱마다 명확한 하강/복귀 동작 연결
- [x] 손상률 기반 세로 균열 light/medium/heavy 공개와 파괴 시 좌우 지반 낙하→카메라 하강 연결
- [x] 곡괭이·세로 균열 4종의 ImageGen 원본, provenance, 1x/2x/3x imageset과 11/11 validator
- [x] 실제 지반 탭 뒤 내구가 바뀌는 focused XCUITest 1/1과 시뮬레이터 모션 프레임 판독
- [x] 실제 홈 지반을 끝까지 타격해 0m→4m 교체를 검증하고 좌우 분할·낙하 키프레임 보존
- [x] 웹에서 과거 통로와 현재 암반을 단일 `headDepth` 좌표로 합치고 고정 막장 위를 실제 열린
      통로로 절삭. 암반 텍스처·지표·지지대·심도 눈금이 같은 속도로 연속 이동 (D-054)
- [x] 웹 광차 자동 데미지를 120ms 고정 스텝으로 상시 적용하고, 버튼 외 화면 전체 Pointer
      Events 탭을 가속 입력으로 연결. 스크롤 이동은 취소
- [x] 웹 lint, 4/4 계약 테스트, production build, 데스크톱·390×844 브라우저 검증
- [ ] D-054 웹 기준의 단일 암반 좌표·고정 막장·상시 자동 하강을 SwiftUI 홈 갱도에 포팅
- [ ] 새 웹 기준안을 비공개 Sites에 재배포. 현재 version 2는 이전 헤드 이동 방식
- [ ] 첫 암반을 실제로 끝까지 탭해 보상→강화→홈으로 가는 전체 XCUITest
- [ ] 전체 `DeepMineAppUITests` 완주

## Physical-device release gate — pending

- [ ] 승인된 App Group/FamilyControls entitlement로 서명·설치
- [ ] FamilyControls 선택과 ManagedSettings 차단/정상·포기·비정상 종료 해제
- [ ] AlarmKit countdown Activity와 커스텀 실패/완료 Activity 전환, 실제 Dynamic Island
- [ ] SpringBoard 잠금화면 Live Activity crop/수명주기
- [ ] 실제 Widget/Live Activity intent→app App Group 명령 왕복
- [ ] 앱 종료·재부팅·시간대/자정 경계 복원
- [ ] VoiceOver, Increase Contrast, Reduce Motion, 햅틱과 사운드

## Deferred / not implemented

- [ ] StoreKit, 결제, 구독, 유료 상세 분석
- [ ] 서버/계정/클라우드 동기화
- [ ] 소셜/순위표/퀘스트/시즌
- [ ] 출시 분석 SDK와 원격 설정
