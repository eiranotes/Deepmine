# Tasks

업데이트: 2026-07-31

## Gameplay-complete MVP — implemented

- [x] 문서 3종 보존, XcodeGen 멀티 타깃 프로젝트와 P0 진단 하네스
- [x] `DeepMineCore` 경제/상태/진행/광맥/스트릭/프레스티지 엔진과 30일 밸런스 시뮬레이션
- [x] SwiftData v1 전체 round-trip, 손상 격리, 세션/보고서 commit, 명령 idempotency
- [x] 두 장 설명 → 90초 연습 → 보상/강화 → 권한 3단계 온보딩
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
- [x] 홈 다음 세 걸음 진행률과 남은 출정 추정
- [x] 광부 파생 함수와 갱도 광부 1~12명 표시, 장비 화면 증가 알림
- [x] 성장 곡선(출정 1회 광석, 12주 스파크라인, 기록 시작 대비 배율)
- [x] 광맥 도감과 장비 상위 레벨 목표치

## Play experience — implemented

- [x] 이벤트 9종 감각 피드백과 CoreHaptics 패턴, 미지원 기기 폴백 (D-030)
- [x] 귀환 보상 카운트업과 진행률 레일 채움, Reduce Motion 분기
- [x] 활성 채굴 광부 작업 루프 (D-031)
- [x] 연습 채굴 10초와 수정 광맥 확정 발견 (D-032)
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
- [ ] 암반 아트 24장 실제 생성과 팔레트 검증
- [ ] 밸런스 CLI를 데미지/내구도 기준으로 재조준

### P2 — 실제로 플레이 가능하게

- [ ] 탭→파괴→광석→구매 수직 슬라이스를 새 루트 화면에
- [ ] 고정 스텝 시뮬레이션 루프
- [ ] 오프라인 계산기와 수령 시트
- [ ] 집중 증폭기 재진입 경로 (기존 preflight/active/Live Activity 재사용)

### P3 — 장기 성장과 리텐션

- [ ] 성장 천장 3종 제거와 재튜닝 (`docs/arc/plans/2026-07-31-long-run-progression.md`)
- [ ] 공명 결절(golden cookie), 지역 전환 규칙
- [ ] 도전과제 지표를 클리커 지표로 재조준
- [ ] 8비트 SFX 실제 제작 (`GameFeedbackEvent.systemSoundID`가 교체 지점)

## Physical-device release gate — pending

- [ ] 승인된 App Group/FamilyControls entitlement로 서명·설치
- [ ] FamilyControls 선택과 ManagedSettings 차단/정상·포기·비정상 종료 해제
- [ ] AlarmKit countdown Activity와 커스텀 실패/완료 Activity 전환, 실제 Dynamic Island
- [ ] SpringBoard 잠금화면 crop/수명주기와 충전 가로 StandBy/Night Mode
- [ ] 실제 Control Center 등록과 extension→app App Group 명령 왕복
- [ ] 앱 종료·재부팅·시간대/자정 경계 복원
- [ ] VoiceOver, Increase Contrast, Reduce Motion, 햅틱과 사운드

## Deferred / not implemented

- [ ] StoreKit, 결제, 구독, 유료 상세 분석
- [ ] 서버/계정/클라우드 동기화
- [ ] 소셜/순위표/퀘스트/시즌
- [ ] 출시 분석 SDK와 원격 설정
