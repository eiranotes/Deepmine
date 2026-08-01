# Project Status

업데이트: 2026-07-31 (클리커 전환 감사와 갱도 시각 피드백 마감)

## Current state

- 단계: **아이들 클리커 P3 완료, P4 제품 전환 마감 대기.**
  탭→파괴→광석→구매→방치→프레스티지의 코어 루프가 실제 저장·진행 곡선과 함께
  플레이 가능하다. 첫 경험과 리텐션 언어에는 아직 피벗 이전 세션 중심 흔적이 남아 있다
- 정체성: 방치 생산이 경제의 기본이고 집중 차단은 **선택적 증폭기**다 (D-037).
  Screen Time 권한 없이도 완전한 게임이 성립한다. 프레스티지와 도전과제까지
  집중 없이 도달 가능하다 (D-045, D-047)
- 플랫폼: iOS 26+, Xcode 26.5 / iOS 26.5 SDK, Swift 6
- 피벗 이전 상태는 브랜치 `pomodoro-v1-focus-blocking`과 태그 `pre-pivot-v1`로 보존
- 시각 기준: `DESIGN.md`의 네 안료 광산 장비판, 한국어·다크·기본 medium·표준 대비

## 피벗 진행

| 단계 | 내용 | 상태 |
|---|---|---|
| P0-1..4 | 방향 결정, 사양 §1.2 재작성, 소규모 삭제, 모듈명 `DeepMine` | 완료 |
| P1-1 | `BigNumber`, `RockSegment`, `RockEngine` | 완료 |
| P1-2 | `StrikeEngine`: 탭·임팩트 미터·자동화 (D-039) | 완료 |
| P1-3 | 교체 가능한 아트 레이어 + 플레이스홀더 24종 + 프롬프트 문서 | 완료 |
| P1-4 | 암반 아트 24장 실제 생성 | 완료 |
| P2-1 | 탭→파괴→광석→구매 수직 슬라이스 | 완료 |
| P2-2 | 오프라인 계산기와 수령 시트 | 완료 |
| P2-3 | 집중 증폭기를 홈의 선택 패널로 재배치 (D-047) | 완료 |
| P3-1 | 진행 곡선 재설계와 밸런스 시뮬레이터 정직화 (D-044) | 완료 |
| P3-2 | 프레스티지를 부순 암반 기준으로 전환 (D-045, D-046) | 완료 |
| P3-3 | 세로 갱도 단면 UI (D-047) | 완료 |
| P3-4 | 지역 벽면·지표·구조물·광맥 생성 아트와 타격 보상 피드백 (D-048) | 완료 |
| P3-5 | 현재/최고 심도·정산 시각 계약 통일 (D-049) | 완료 |

## 진행 곡선 (D-044 이후)

`DeepMineBalanceCLI --days 180` 실측. 탭 입력과 오프라인 8시간 캡이 모두 반영된 값이다.
프레스티지로 현재 위치가 돌아가므로 `현재 / 최고`를 함께 적는다.

| 시점 | 라이트 | 스탠다드 | 헤비 | 불규칙 |
|---|---:|---:|---:|---:|
| 30일 | 1,140 / 1,140m | 1,212 / 1,380m | 1,448 / 1,560m | 1,192 / 1,192m |
| 90일 | 1,740 / 1,740m | 2,400 / 2,460m | 3,128 / 3,240m | 1,568 / 1,568m |
| 180일 | 2,400 / 2,400m | 3,540 / 3,600m | 5,528 / 5,640m | 1,748 / 1,748m |

30일 heavy/light 광석 격차는 3.462배로 D-041 대역(1.5~20배) 안이다. 180일에는
0.406배로 역전되므로 장기 통화 흐름을 P4 위험으로 남긴다.

## Implemented

- Foundation-only `DeepMineCore`: 세션 상태 기계, 시간 무결성, 보상/피로, 장비, 심도, 지역, 광맥, 일일 목표/휴광일/스트릭, 프레스티지, 주간 장부
- 명시적 SwiftData v1 저장소: 전체 플레이어 그래프, 세션/귀환 보고서 원자적 커밋, idempotent 명령 receipt, 손상 격리와 fail-closed 신규 스키마 처리
- 제품 흐름: 2장 설명, 90초 연습, 단계별 권한, 홈, 출정 약속, 활성 채굴, 명시적 포기, 3박자 귀환 보고서
- 진행 화면: 장비, 주간 일지, 무료 기본 기록, 광산 꾸미기, 설정, 손실 우선 심층 진입 확인
- 시스템 표면: 집중 출정용 Live Activity compact/minimal/expanded·잠금화면, 방치용 small/medium 홈 위젯
- iPhone 잠금화면은 `isActivityFullscreen` 역할 판정으로 160pt 콘텐츠의 좌우 균형을 유지
- AlarmKit countdown용 `AlarmAttributes<DeepMineAlarmMetadata>` Widget 구성을 등록하고,
  활성 채굴은 AlarmKit Activity 하나가 소유. 커스텀 Activity는 예약 실패와 귀환 완료 표면에 사용
- 단일 writer 계약: extension은 snapshot을 읽고 명령만 enqueue하며 앱이 제품 SwiftData를 갱신
- 4색 픽셀 광부·완료·광맥·붕괴 스프라이트와 리벳 금속판 UI
- 귀환 보상에 획득량 비례 광석 3–9개가 광차에 적재되는 연출과 낙하→충돌 햅틱 추가.
  Reduce Motion에서는 이동 없이 최종 적재 상태를 즉시 표시
- 도전과제 35종 전용 4색 픽셀 배지와 48/96/144 PNG Asset Catalog, 48pt 목록 렌더링
- 나머지 게임 아트 40종: 광맥·장비 3티어·테마·장식·계획 광부·DI·StandBy·자원·영구
  강화·온보딩. 4색/PNG/브라스 비율/알파 검증과 화면별 실제 소비 경로 포함
- 클리커 암반 아트 24종: 지역별 4단계 암반 16, 투명 균열 3, 약점 2, 파편 2, 공명 결절 1.
  고유 ImageGen 원본과 64/128/192 PNG imageset, 네 안료·이진 알파 검증 포함
- 갱도 장면 아트 7종: 지역별 와이드 벽면 4, 지표 캐노피 1, 작업면 구조물과 광맥 상태 2.
  ImageGen 원본, 역할별 320×128/320×90, 1x/2x/3x PNG, 정확한 네 안료·알파·프롬프트
  provenance를 별도 매니페스트로 보존
- 한국어·영어 현지화와 default-medium 의미 접근성 fixture
- 결정적 화면 19장 및 contact sheet: `artifacts/ui/game-mvp-v1/`
- 클리커 장비(드릴=탭, 광차=자동화, 램프=크리티컬·시야), 비용 1.34, 최고 심도로 상한 200 해금
- 현재 위치 리셋·최고 심도 보존과 굴착 기억 재구매 할인이 적용된 프레스티지
- 30/90/180일 밸런스 시뮬레이션, 심도 역전 금지와 사다리 잔존 회귀 게이트

## Shaft screen (D-047)

- 갱도를 세로 단면으로 그린다. 위는 이미 뚫은 갱도, 가운데는 작업 중인 막장, 아래는
  어둠으로 사라지는 미개척 암반이다
- 막장의 화면 위치는 고정이고 부수면 기둥이 한 칸 올라간다. 카메라가 내려가는 연출이다
- 램프 레벨이 아래로 보이는 층 수를 2에서 최대 8까지 늘린다. 시야가 곧 구매 가능한 성장이다
- 좌측 심도 눈금 20m 간격, 지역 첫 층에 이름 명판
- 홈 순서: 갱도 → 장비 → 다음 걸음·장식 → 진행 화면 → 집중 출정 패널
- 작업면은 생성 구조물로 프레이밍하고, 광맥층은 생성 광맥 오버레이로 일반 암반과 구분한다
- 정사각 암반 반복 대신 지역별 와이드 벽면을 쓰고, 지표는 생성 캐노피로 빈 공간을 채운다
- 상단 HUD가 탭/자동 데미지, 내구, 충격 배율, 다음 광맥층을 보여준다. 탭은 데미지,
  파괴는 광석과 파편으로 즉시 구분한다
- 약점은 36pt 표식에 48×48pt 조작 영역을 부여하고 층 이동은 네이티브 spring으로 연결한다.
  Reduce Motion에서는 위치 이동 대신 제자리 교차 페이드를 쓴다

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

## Verification state (2026-07-31 P3 visual payoff)

- `swift test --package-path DeepMineCore`: **188/188 통과**
- `xcodebuild -destination 'generic/platform=iOS' build`: **통과**
- `DeepMineAppTests`: **132/132 통과**
- 생성 갱도 아트 validator: **7/7 imageset 통과** (21 PNG, 네 안료·알파·크기·해시)
- `ActiveMineUITests` 13건 + `GameSurfaceScreenshotTests/testCaptureCoreLoopScreens` 1건:
  **14/14 통과**, 새 홈 시작 스크롤 경로 포함
- 홈 캡처: **1/1 통과**, 한국어 다크/medium
  최종 홈 캡처 `artifacts/imagegen/shaft-assets-v1/ui-captures/mine-home-final.png`
- 전체 `DeepMineAppUITests`: **미실행.** 관련 14건 결과를 전체 suite 통과로 확대하지 않는다
- `DeepMineBalanceCLI --days 30/180`: 진행 곡선과 증폭기 대역 실측 (위 표)
- 갱도 화면의 조작 감각·전환 체감·어두운 층 대비: 미검증(실기기 필요)

## Verification state (이전 단계)

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
- 암반 아트 검사: `scripts/process_rock_assets.py --validate-only`로 24 고유 원본,
  imageset 24개/PNG 72개, 정확한 네 안료, 이진 알파/불투명 정책과 64/128/192 크기 통과.
  `GameArtCatalogTests` 11/11과 generic iOS unsigned build도 통과

## Physical-device release gates

1. 승인된 FamilyControls/App Group entitlement와 실제 방해 앱 선택·차단·해제
2. DeviceActivityMonitor 종료/stale callback과 앱 종료·재부팅 복원
3. AlarmKit 소유 countdown Activity와 커스텀 실패/완료 Activity의 실제 전환
4. 실제 Dynamic Island와 SpringBoard 잠금화면 Live Activity의 등록·크롭·수명주기
5. 실제 extension→app App Group 명령 왕복과 crash window
6. VoiceOver 초점, Increase Contrast, Reduce Motion, 햅틱·사운드 체감

## Explicit non-goals

- StoreKit/구독/결제와 유료 분석
- 서버, 계정, 클라우드 동기화
- 소셜, 순위표, 퀘스트, 시즌, 경쟁형 스트릭
- 물리 기기 증거 없이 출시 준비 완료 판정

## Known clicker risks

- 온보딩과 다음 걸음·스트릭 문구가 아직 집중 세션을 먼저 가르쳐, 구현된 코어 루프보다
  이전 제품 정체성을 먼저 노출한다
- `RockEngine`의 512층 절단 뒤 남은 데미지를 호출부가 재정산하지 않는다. 현재 90일 곡선에는
  닿지 않지만 극단적 오프라인/프레스티지 성장에서는 생산 손실이 될 수 있다
- 데미지와 암반은 `BigNumber`지만 지갑의 광석은 `Double`이다. 현재 범위는 충분하나 장기
  클리커의 지수 성장을 끝까지 표현하는 저장 모델은 아직 아니다
- 30일 증폭기 대역은 통과하지만 180일 heavy/light 누적 광석은 0.406배로 역전된다.
  장비 구매와 즉시 프레스티지 정책을 분해하기 전에는 장기 경제를 완료로 판정하지 않는다
