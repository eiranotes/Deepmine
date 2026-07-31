# Project Status

업데이트: 2026-07-31 (아이들 클리커 피벗 P0 완료, P1 코어 구현 중)

## Current state

- 단계: **아이들 클리커 피벗 진행 중.** P0(정리·결정·모듈명) 완료, P1(클리커 코어) 구현 중
- 정체성: 방치 생산이 경제의 기본이고 집중 차단은 **선택적 증폭기**다 (D-037).
  Screen Time 권한 없이도 완전한 게임이 성립한다
- 플랫폼: iOS 26+, Xcode 26.5 / iOS 26.5 SDK, Swift 6
- 피벗 이전 상태는 브랜치 `pomodoro-v1-focus-blocking`과 태그 `pre-pivot-v1`로 보존
- 시각 기준: `DESIGN.md`의 네 안료 광산 장비판, 한국어·다크·기본 medium·표준 대비

## 피벗 진행

| 단계 | 내용 | 상태 |
|---|---|---|
| P0-1..4 | 방향 결정, 사양 §1.2 재작성, 소규모 삭제, 모듈명 `DeepMine` | 완료 (커밋 4개) |
| P1-1 | `BigNumber`, `RockSegment`, `RockEngine` | 완료 |
| P1-2 | `StrikeEngine`: 탭·임팩트 미터·자동화 (D-039) | 완료 |
| P1-3 | 교체 가능한 아트 레이어 + 플레이스홀더 24종 + 프롬프트 문서 | 완료 |
| P1-4 | 암반 아트 24장 실제 생성 | 미착수 |
| P2-1 | 탭→파괴→광석→구매 수직 슬라이스를 새 루트 화면에 | 미착수 |
| P2-2 | 오프라인 계산기와 수령 시트 | 미착수 |
| P2-3 | 집중 증폭기 재진입 경로 | 미착수 |

**아직 플레이할 수 없다.** P1은 엔진만이고 UI에 연결되지 않았다. 실제로 탭할 수 있게 되는
것은 P2-1이다.

## Implemented

- Foundation-only `DeepMineCore`: 세션 상태 기계, 시간 무결성, 보상/피로, 장비, 심도, 지역, 광맥, 일일 목표/휴광일/스트릭, 프레스티지, 주간 장부
- 명시적 SwiftData v1 저장소: 전체 플레이어 그래프, 세션/귀환 보고서 원자적 커밋, idempotent 명령 receipt, 손상 격리와 fail-closed 신규 스키마 처리
- 제품 흐름: 2장 설명, 90초 연습, 단계별 권한, 홈, 출정 약속, 활성 채굴, 명시적 포기, 3박자 귀환 보고서
- 진행 화면: 장비, 주간 일지, 무료 기본 기록, 광산 꾸미기, 설정, 손실 우선 심층 진입 확인
- 시스템 표면: Live Activity compact/minimal/expanded, 잠금화면/StandBy-shaped content, small/medium widget, 25분 안전 채굴 Control Widget
- iPhone 잠금화면은 Activity 크기가 아니라 `isActivityFullscreen`으로 StandBy와 구분해
  160pt 잠금화면 콘텐츠가 좌우 균형을 유지
- AlarmKit countdown용 `AlarmAttributes<DeepMineAlarmMetadata>` Widget 구성을 등록하고,
  활성 채굴은 AlarmKit Activity 하나가 소유. 커스텀 Activity는 예약 실패와 귀환 완료 표면에 사용
- 단일 writer 계약: extension은 snapshot을 읽고 명령만 enqueue하며 앱이 제품 SwiftData를 갱신
- 4색 픽셀 광부·완료·광맥·붕괴 스프라이트와 리벳 금속판 UI
- 귀환 보상에 획득량 비례 광석 3–9개가 광차에 적재되는 연출과 낙하→충돌 햅틱 추가.
  Reduce Motion에서는 이동 없이 최종 적재 상태를 즉시 표시
- 도전과제 35종 전용 4색 픽셀 배지와 48/96/144 PNG Asset Catalog, 48pt 목록 렌더링
- 나머지 게임 아트 40종: 광맥·장비 3티어·테마·장식·계획 광부·DI·StandBy·자원·영구
  강화·온보딩. 4색/PNG/브라스 비율/알파 검증과 화면별 실제 소비 경로 포함
- 한국어·영어 현지화와 default-medium 의미 접근성 fixture
- 결정적 화면 19장 및 contact sheet: `artifacts/ui/game-mvp-v1/`
- 복리 장비(드릴 1.12 / 광차 1.05·1.07, 비용 1.34, 상한 60을 심도로 해금)
- lifetime 기준 심도와 굴착 기억 재구매 할인이 적용된 프레스티지
- 30/90/180일 밸런스 시뮬레이션, 심도 역전 금지와 사다리 잔존 회귀 게이트

## Retention systems

- 도전과제 35종 7계열. 보상은 수정·장식·테마·배지뿐이고 생산력은 지급하지 않는다 (D-028).
  기한·갱신·미달성 벌칙이 없어 퀘스트가 아니다 (D-029)
- 미달성 항목의 조건과 진행률을 보여 몇 주~몇 달 거리의 목표를 가시화
- 홈의 다음 세 걸음(장비·지역·연속 일수)으로 1~3세션 거리의 목표를 채움
- 광부 1~12명은 드릴 레벨에서 파생되는 순수 시각 지표로 보상에 관여하지 않는다
- 성장 곡선(출정 1회 광석, 12주 스파크라인)과 광맥 도감, 장비 상위 레벨 목표치

## Retention contract

- 홈에 노출된 연속 일수·휴광일 상태, 계획별 배율과 광맥 확률, 1탭 추천 강화
- 귀환 보고서의 심도 증가·오늘 목표·연속 일수·광맥 실제 수량
- 오늘 목표, 주 1회 자동 휴광일, 심도·장비·지역·테마·영구 강화의 가시적 누적 진행
- 홈에서 한 가지 `다음 약속`, 귀환 보고서의 완료→보상→다음 약속
- 광맥 8회 드라이 스펠 보호와 무료 주간 회고
- `마치기`와 `다음 출정 준비` 동등 위계, 강제 재시작/소급 스트릭 파괴 없음
- 상세 설계: `docs/GAME_IMPLEMENTATION.md`, `docs/GAME_DESIGN_REVIEW.md`

## Verification state

- Core 자동 테스트: 101/101 통과
- 핵심 실제 흐름: 연습 보상→권한 3단계→홈→출정→활성→포기→귀환→장비 handoff 통과
- 화면 캡처: 19/19 생성·육안 확인
- Activity/Widget 독립 검토: 구현·fixture 계약 통과
- 전체 시뮬레이터 suite: 182/182 통과, 실패·skip 0
- generic iOS unsigned build: 통과
- 총 자동 검사: Core 101 + Xcode 182 = 283 통과
- 기계 검사: Swift≤300줄, xcstrings JSON, 네 안료 hex, 19개 PNG, diff whitespace 통과
- 배지 검사: 카탈로그 35 ID와 imageset 35 ID 일치, 불투명 4색 PNG 105개와
  48/96/144 치수 통과. `artifacts/imagegen/achievement-badges-v1/contact-sheet.png`
- 이번 시스템 표면 변경 focused 회귀: 잠금화면 역할·AlarmKit 상태 투영·메타데이터 왕복,
  광석 적재량·완료 햅틱·귀환 UI 흐름 통과
- 게임 아트 검사: 40 고유 ImageGen 원본, imageset 40개/PNG 120개, exact 4 pigments,
  브라스 10% 미만, binary alpha/opaque 정책과 1x/2x/3x 크기 통과
- 게임 아트 focused Xcode 12/12, generic iOS build 통과, fresh 19-screen suite 5/5와
  `artifacts/imagegen/game-assets-v1/ui-captures/final-19-contact-sheet.png`

## Physical-device release gates

1. 승인된 FamilyControls/App Group entitlement와 실제 방해 앱 선택·차단·해제
2. DeviceActivityMonitor 종료/stale callback과 앱 종료·재부팅 복원
3. AlarmKit 소유 countdown Activity와 커스텀 실패/완료 Activity의 실제 전환
4. 실제 Dynamic Island, SpringBoard 잠금화면, StandBy, Control Center 등록·크롭·수명주기
5. 실제 extension→app App Group 명령 왕복과 crash window
6. VoiceOver 초점, Increase Contrast, Reduce Motion, 햅틱·사운드 체감

## Explicit non-goals

- StoreKit/구독/결제와 유료 분석
- 서버, 계정, 클라우드 동기화
- 소셜, 순위표, 퀘스트, 시즌, 경쟁형 스트릭
- 물리 기기 증거 없이 출시 준비 완료 판정
