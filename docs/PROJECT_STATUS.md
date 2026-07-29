# Project Status

## Current state

- 단계: P0 기술 검증 하네스 구현 완료, 실기기 게이트 대기
- 플랫폼 기준: iOS 26+, Xcode 26.5 / iOS 26.5 SDK
- 저장소: 신규 로컬 Git 저장소, 현재 P0 기준선 초기 커밋 준비 완료
- 사양 원본 3종을 `docs/`에 해시 일치 상태로 보존함

## Completed

- 제품 사양, 픽셀 아트 프롬프트 팩, 개발 플레이북 수집
- P0 이전에 경제 엔진으로 넘어가지 않는 개발 게이트 확정
- 프로젝트 관리 문서와 구현 계획 초기화
- 앱, Widget Extension, DeviceActivityMonitor Extension, 테스트 타깃 생성
- Live Activity, AlarmKit, Screen Time, 시간 무결성, App Group SwiftData 프로브 구현
- 공유 JSONL의 프로세스 간 파일 잠금/보존 상한, LA 수명주기 잠금, 세션별 shield expiry fail-safe 구현
- iOS 26.5 시뮬레이터 단위 11개 + UI 2개, 총 13/13 및 generic iOS 빌드 통과
- iPhone 17 Pro iOS 26.5 시뮬레이터에서 대시보드 실행과 화면 증거 확인
- 광산 입구, 출정 보급품, 앱 아이콘을 석탄·혈암·석회·황동 4색으로 재양자화하고 앱 Asset Catalog에 편입
- SaaS형 SHAFT 대시보드를 `귀환 신호 → 갱도 문 → 시간·보급품 → 채굴 일지` 출정 준비 흐름으로 교체
- 앱, Live Activity, 홈 위젯의 내부 구현 용어를 목적과 결과가 먼저 보이는 한국어 플레이어 용어로 교체
- 리벳 금속판 버튼, 황동 주 동작, 사각 광산 레버 토글로 조작 문법 통일
- 현재 4색 UI를 기본 Dynamic Type, 표준 대비, 다크 모드에서 화면 육안 검증
- 출정 안내, 준비 구역 4종, 실기기 관문을 독립 렌더링하는 UI 캡처 테스트 추가, iPhone 17 Pro PNG 6장 육안 검증
- iPhone 17 Pro iOS 26.5 시뮬레이터에서 Live Activity 시작 후 Dynamic Island compact/expanded PNG 2장 검증
- 루트 `DESIGN.md`와 `.impeccable/design.json`에 4색 광산 인터페이스 원칙을 영속화
- `docs/GAME_DESIGN_REVIEW.md`에 리텐션, 세션 길이 공정성, 귀환 보고서, 스트릭 계약을 별도 검토
- Widget Extension과 캡처 하네스가 공유하는 160pt 잠금화면 컴포넌트 추가

## In progress

- 승인된 App Group과 FamilyControls entitlement를 포함한 실기기 서명 준비
- `PROBE_CHECKLIST.md` 10항목 물리 기기 판정

## Next

1. 실기기용 App Group과 FamilyControls entitlement/provisioning을 연결한다.
2. Dynamic Island가 있는 iOS 26 기기에 설치해 AlarmKit 동시 운용과 실제 잠금 수명주기를 포함한 `PROBE_CHECKLIST.md` 항목을 판정한다.
3. 결과를 사양과 P1 착수 조건에 반영하며, 그 전에는 P1을 시작하지 않는다.

## Known risks

- FamilyControls Individual entitlement는 별도 승인 전 실제 차단 기능이 동작하지 않을 수 있다.
- Dynamic Island의 compact/expanded 렌더링은 시뮬레이터에서 확인했지만, Live Activity 재시작 AppIntent와 AlarmKit 동시 사용은 실기기 확인이 필요하다.
- App Group의 실제 컨테이너 공유와 DeviceActivityMonitor 실행도 실기기 검증이 필요하다.
- 현재 시뮬레이터의 `Sign to Run Locally` 산출물은 앱과 두 익스텐션 모두 서명 entitlement가 비어 있어 App Group/FamilyControls 경계를 증명하지 못한다.
- P0 코드는 컴파일·단위 검증된 기술 하네스이며 제품 경제 엔진이나 출시 UI를 포함하지 않는다.
- 현재 생성 에셋은 P0의 목적을 설명하기 위한 게임형 시각 언어이며 출시용 지역 아트의 최종본으로 판정하지 않는다.
- 실제 VoiceOver 초점 순서, press-down 촉감, Reduce Motion 전환은 물리 기기 접근성 검증이 남아 있다.
- 이전 v2의 Accessibility Extra Large 증거는 보존하지만, 사용자 요청에 따라 현재 v3 시각 판정은 기본 `medium` 크기만 실행했다.
- Simulator의 `Device → Lock`이 비활성이라 실제 SpringBoard 잠금화면 합성과 시스템 크롭은 확인하지 못했다. 동일한 160pt 공유 컴포넌트의 기본 사양 렌더링만 자동 캡처하고 실제 잠금 수명주기는 실기기 게이트로 남긴다.
- 게임 디자인 검토는 구현 결정이 아니다. 세션 길이 가중치와 심층 실패/일일 스트릭 계약을 Phase 2–3 전에 확정해야 한다.
