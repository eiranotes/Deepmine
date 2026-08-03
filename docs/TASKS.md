# Tasks

업데이트: 2026-08-03 (현수식 채굴 리그·물리 강화 계약 로컬 closeout)

## 2026-08-02 current audit closeout

아래가 현재 작업 큐다. 이후의 P0~P4 목록은 각 시점의 구현 기록이며, 상한 60/200이나
정련 UI 미구현 같은 문구는 역사적 상태로 읽는다.

완료:

- [x] 세션 복구·시작 준비·활성 집중과 홈 자동/오프라인 채굴의 단일 clock gate
- [x] 150km·500km 8시간 carried-resolution 무손실 회귀
- [x] 광석 134에서도 첫 광차 ◆180 저축 목표 유지
- [x] 자동 광석/초·층/초 HUD와 구매 전후 탭/자동 출력·ETA 변화
- [x] 장비별 정련 발견성 패널과 일반 구매와 구분된 성공 피드백
- [x] 구매 결과·추천 비용의 사용자 표면까지 `BigNumber` 보존
- [x] 일반 저장·원자적 명령·세션 종료에서 기억 장비·정련 단계·달성 업적 영속화
- [x] 5km·20km·100km 시각 지질 경계와 앱/웹 v2 텍스처 소비
- [x] 장기 진행 PNG 7종 strict validator와 CI job
- [x] PR build/main deploy 분리 및 Pages 권한 축소
- [x] PR #3 병합 뒤 `main` validation 성공 및 GitHub Pages Actions 배포·공개 URL 확인
- [x] Pages artifact를 로직 보고서에서 광부·갱도·타격·장비가 동작하는 실제 게임 build로 교체
- [x] 웹 직접 타격→광석→첫 광차 구매→자동 굴착 및 데스크톱·390px 로컬 검증
- [x] 플레이어블 Pages artifact의 `main` 원격 배포와 공개 URL 직접 타격 재검증
- [x] Vinext Sites 플러그인을 clean checkout에도 존재하는 추적 소스로 이동
- [x] 변경 Swift 파일을 모두 300줄 이하로 분리하고 persistence/명령 큐 23/23 재검증
- [x] 별도 ChatGPT Pro 프로젝트에 웹 렌더러·밸런스·타격 로직과 핵심 에셋을 넣고 굴착감 원인 감사
- [x] 고정 작업선을 파생 `headDepth → cameraDepth → headScreenOffset` 좌표로 대체
- [x] 320px 암반 위상 modulo를 제거해 CSS 배경의 순환 경계 역보간 방지
- [x] 기존 스트립·파쇄 립·균열로 데스크톱 약 62px, 모바일 약 61px 실제 하강과 가로 overflow 0 검증
- [x] 카메라가 헤드를 앞서지 않고 4m 끝에서 같은 깊이로 정착하는 순수 수식 회귀 3건 추가
- [x] D-081 플레이어블 Pages 재배포와 공개 URL의 실제 하강·단조 암반 위상 재검증
- [x] D-081 연속 작업면 하강을 파티션 0~99% 고정 굴착으로 대체
- [x] 한 접촉의 N개 파쇄를 `4N m` 단일 낙하 이벤트로 합치고 활성 전환 중 추가 파괴를 batch 하나로 축약
- [x] 1/2/5/20구간 낙하 거리·시간·Reduce Motion 순수 회귀 5건 추가
- [x] ImageGen 참조 생성으로 release/fall A/fall B/landing 4프레임 `MinerDescentStrip` 편입
- [x] 데스크톱·390px에서 진행 중 위치 0px, 완파 후 약 45px 낙하·정착과 모바일 overflow 0 확인
- [x] D-082 플레이어블 Pages 배포와 공개 URL의 실제 완파→낙하 재검증
- [x] Pro 제품·코드 리뷰로 낙하형 아바타와 고정 현수식 설비를 구현성·플레이성 양쪽에서 재선정
- [x] 앱·웹의 절삭 중 작업선을 face depth에 고정하고 경제 head depth만 진행하도록 분리
- [x] 완파 N구간을 클램프 해제→압축 윈치 이동→재체결 한 사이클로 표현하고 Reduce Motion 보존
- [x] ImageGen 현수식 프레임·드릴 3티어·장비 분기 6종·세대 하우징 4종 생성, 14/14 추출·알파·해시·provenance 검증
- [x] `RigToolVisualState`로 모든 장비 레벨의 D/C/L 각인판·정비 셀·하우징 세대 변화를 보장
- [x] 모든 정제 단계의 정확한 R 각인판과 3개까지의 장식 밴드, 분기별 고유 장착 모듈 구현
- [x] 드릴 Lv.1→2의 T1→T2·D1→D2·셀 0→1 변화와 절삭 중 camera 고정을 실제 브라우저에서 확인
- [x] D/C/L 표찰을 앱 9pt·웹 10px, 정비 셀을 5pt·6px로 확대하고 정확한 G세대·R정제 상시 표기
- [x] 세 도구의 레벨·티어·세대·셀·R·분기와 윈치 시작/완료를 VoiceOver·ARIA 상태로 제공
- [x] 윈치 해제 140ms·이동 320~900ms·체결 160ms를 독립 phase로 구현하고 물리 상태 서명 회귀 추가
- [x] 웹 `rigVisual.ts`를 장비 asset·물리 설치 문구의 정본으로 만들고 웹 테스트를 앱보다 먼저 통과
- [x] 매 4레벨 G 경계에서 1~4형 생성 하우징 PNG를 실제 교체하고 후기 G1~G4 순환을 회귀로 고정
- [x] `T1→T2 본체 교체`, `정비 셀 1→2/4 증설`, `G1 · 2형 하우징 교체`를 구매 직후 명시
- [x] 앱 Core·Scene·구매 피드백을 웹 기준과 동일하게 포팅하고 generic Simulator build-for-testing 통과

열림:

- [ ] 실제 앱 홈 추천·최저가·정련·자동화·MAX 정책을 쓰는 30/90/180일 시뮬레이션
- [ ] 집중 보상을 별도 세션 광석이 아닌 실제 `MiningLoop` 진행으로 통합
- [ ] 정련 MAX와 프레스티지 후 기억 정련 일괄 재설치
- [ ] 통계·도전과제의 세션 중심 잔여 비중 재편
- [ ] `NextStepPlanner` 목표 진행도와 호환용 추천 비용 투영의 극후반 `BigNumber` 전환
- [ ] Lv.100,000 산술 안전 천장 이후에도 유한 정수 순회와 저장 계약을 보존하는 true-uncapped 성장
- [ ] JavaScript `number` 범위를 넘는 앱 경제는 웹이 아닌 Core 회귀로 계속 검증
- [ ] 프레스티지의 정련 손실 고지와 홈 진입/재구축 UX 실화면 회귀
- [ ] 전체 `DeepMineAppUITests`와 FamilyControls/AlarmKit/Live Activity 실기기 릴리스 게이트

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
- [x] `RockEngine`이 절단되면 남은 데미지를 재정산한다. `unspentDamage`를 전달하고
      `MiningLoop.advance`가 최대 12패스까지 다시 적용한 뒤 결과를 하나의 update로 합산한다.
      상한 자체는 유지하므로 종료는 보장된다 (D-066)
- [x] `Resources.ore: Double`의 실제 한계를 측정하고 테스트로 고정했다. 포화는 41,881m
      (180일 헤비 도달점의 7배, 같은 속도로 3.7년 연속)이고 상대 정밀도는 전 구간 ~1e-16으로
      일정하다. 지금 `BigNumber`로 옮기는 것은 저장 스키마와 25개 호출부를 바꾸는 위험만
      있고 실익이 없다. 곡선이 가팔라지면 `OreCapacityTests`가 실패해 알려 준다
- [x] 180일 역전을 분해했다. 시뮬레이터에 `--prestige immediate|never`를 추가해 비교한 결과
      **프레스티지를 꺼도 역전이 남는다**(0.406 → 0.483배). 실제 원인은 장기 생산 정체이며,
      레벨 상한 200이 심도 2,925m에서 데미지 성장을 끝내는 반면 내구는 계속 자라기 때문이다.
      분석과 선택지는 `docs/BALANCE_REPORT.md`에 있다
- [ ] **상한 이후의 성장 축을 정한다.** 레벨 상한 상향, 프레스티지 영구 강화가 후반을 맡는
      구조, 심도 구간별 내구 완화 중 하나를 골라야 한다. 수치 변경은 사양 결정이므로 미실행

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
- [x] D-054 초기안의 120ms 자동 데미지와 버튼 외 화면 전체 Pointer Events 탭 가속·스크롤 취소.
      데미지 시점은 D-055에서 820ms 타격의 230ms 접촉 프레임으로 대체
- [x] 웹 lint, 6/6 계약 테스트, production build, 데스크톱·390×844 브라우저 검증
- [x] `ShaftFrontierLip`으로 열린 통로·현재 암반·중앙 절삭 홈을 한 경계에서 3px 겹쳐 연결 (D-055)
- [x] `MinerMiningStrip` 4프레임으로 광부 몸·양손·곡괭이를 한 액터로 묶고 독립 루프 제거
- [x] 자동/수동 데미지를 230ms 접촉 프레임에 적용하고 수동 타격 동안 자동 루프가 덮어쓰지 않게 조정
- [x] 웹 전용 ImageGen 원본·크로마 추출·4색 이진 알파·SHA·provenance 파이프라인과 2/2 validator
- [x] 웹 프로토타입의 자체 밸런스를 제거하고 Core `Balance` 수치를 `coreBalance.ts` 한 곳에서
      쓰도록 정렬. Swift 상수를 직접 파싱해 대조하는 패리티 테스트 3건 추가 (D-061)
- [x] 타격 타임라인(quick/heavy/critical duration·contact, Reduce Motion, 수동 보호, 자동 주기)을
      `Balance`로 옮기고 순수 Core `StrikeTimeline`으로 소비. 프레임 계약 테스트 6건 (D-061)
- [x] D-055 웹 기준의 연결 파쇄 경계·전신 타격을 SwiftUI 홈 갱도에 포팅. `ShaftFrontierLip`과
      `MinerMiningStrip`을 앱 Asset Catalog에 편입하고 광부·양손·곡괭이를 단일 4프레임 액터로
      묶었다. 별도 드릴 스프라이트 배치 제거, 작업면 236pt·간트리 44pt로 재배치 (D-062)
- [x] D-055 웹 기준안을 소유자 전용 Sites version 4로 배포하고 production 상태 `succeeded` 확인
- [x] 공식 Cookie Clicker 웹판의 첫 클릭·자원/CPS·상점·첫 업적을 실제 브라우저에서 비교 감사
- [x] 첫 뷰포트 하단에 `현재 층 예상 광석·완료 ETA·구매 가능한 다음 장비`를 한 줄 행동대로 고정 (D-056)
- [x] 탭 접촉점의 남은 파쇄율·층 보상을 한 초점에 모으고 구매 뒤 광석·레벨·장면·다음 추천을
      함께 갱신해 탭→보상→강화 폐루프를 만든다
- [x] 1280×720에서 행동대 bottom 698.6px/scrollY 0, 390×844에서 bottom 791.6px/가로 넘침 없음과
      실제 포인터 구매 후 scrollY 0을 브라우저에서 확인
- [x] 기존 `ResonanceNode`를 첫 체험 뒤 2~5분 간격의 DeepMine 고유 공명 결절 사건으로 연결하고,
      12초 등장·명시적 탭·18초 수동/자동 ×2·무보상 놓침·백그라운드 일시정지를 구현한다 (D-057)
- [x] 1280×720과 390×844에서 실제 좌표 포인터로 결절을 수령하고 탭 19→38, 자동 9→18,
      scrollY 0·가로 overflow 없음·상태판 겹침 없음을 확인한다
- [x] 전신 타격의 quick/heavy/critical 준비·접촉 타이밍, 크리티컬 포즈·교대 붕괴와 웹 합성
      8-bit SFX를 결합해 820ms 동일 반복의 기계적인 인상을 줄인다 (D-058)
- [x] 수동 포즈 보호 중 겹친 자동 데미지를 다음 가시 접촉에 합산해 화면 전체 탭을 방치 생산
      위의 순수 가속으로 유지하고, 44px SFX 토글·첫 제스처 오디오 해제를 검증한다
- [x] 장비 구매 뒤 작업조 1~4명·광차 0~4대·적재 0~3칸·작업등 1~5기가 첫 화면에서 즉시
      누적되고 해당 설비만 commissioning 되는 자동 생산 증거를 강화 (D-059)
- [x] 접촉 효과를 암반 폭 76~92%의 면 반응으로 확대하고, 작업조를 통로 폭 데크·보급 설비,
      광차를 복선 레일·좌우 차선, 램프를 광원 구역으로 만들어 내실 단계를 구조적으로 구분 (D-060)
- [x] D-056 첫 뷰포트 행동대를 앱 홈에 포팅. `MiningLoop.forecast`가 예상 광석·남은 내구·
      자동 ETA·남은 탭 수를 만들고 갱도와 강화 버튼 사이에 `WorkFaceForecastBar`를 둔다.
      광차 1레벨에서는 ETA 대신 남은 탭 수를 보여 준다 (D-063)
- [x] D-057 공명 결절을 순수 Core 상태 기계(`ResonanceNodeState`/`ResonanceNodeEngine`)로
      만들고 앱 갱도에 연결. 5.2초 뒤 첫 출현, 이후 2~5분 간격 12초 창, 명시적 탭 수령 시
      18초 ×2, 놓침 무보상, 백그라운드 미출현·미기록. 부스트는 `StrikePower.scaled(by:)`로
      탭·자동 데미지에만 적용하고 크리티컬 확률은 건드리지 않는다 (D-063)
- [x] D-058 타격 변주와 접촉 타임라인을 앱에 연결. `StrikeTimeline.Cadence`가 자동 스윙
      주기·수동 보호·변주 교대를 판정해, 자동화가 시뮬레이션 스텝마다 스윙을 재시작하며
      광부를 예비동작 프레임에 얼어붙게 하던 문제를 없앴다. 막장 반동은 접촉 프레임에서
      변주별 3/5/7pt로 일어난다 (D-063)
- [x] D-059 장비 설비 누적을 앱 갱도 장면에 포팅. `MineInfrastructureEngine`이 작업조 1~4,
      광차 0~4, 적재 0~3, 작업등 1~5를 파생하고 앱이 그것을 그린다. 앱 광차가 티어 경계에서만
      늘어 대부분의 구매가 보이지 않던 문제를 함께 고쳤다. 작업조는 발밑 데크 위에 선다 (D-064)
- [x] D-060 면 단위 충격과 내실 판독을 앱에 포팅. 접촉이 암반 폭 76/84/92%의 압축대·충격파·
      좌우 분기 균열을 만들고, 갱도 접근성 이름이 작업조·광차·작업등 수를 말한다 (D-064)
- [x] 웹 설비 파생 4종을 `coreBalance.ts`로 옮기고 패리티 테스트로 묶었다. 상한 6개를 상수
      대조에 추가하고, 프로토타입이 같은 이름의 로컬 함수를 다시 만들면 실패한다 (D-065)
- [x] 첫 암반을 실제로 끝까지 탭해 보상까지 가는 XCUITest. 온보딩 카드가 씬을 고정 오프셋으로
      그려 작업면이 카드 밖으로 잘려 있었고, 카드 중심 탭이 빈 갱도에 떨어져 통과하지 못했다.
      헤드를 따라가도록 고쳐 `OnboardingHomeUITests` 8/8 (D-062)
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
