# Changelog

## Unreleased

### Added

- DeepMine v0.2 사양, 픽셀 아트 프롬프트, E2E 개발 플레이북 원본
- P0 기술 검증 하네스의 저장소 규칙, 계획, 체크리스트, 상태 문서
- iOS 26 SwiftUI 프로브 앱, Live Activity/Widget Extension, DeviceActivityMonitor Extension
- AlarmKit 60초 타이머, FamilyControls picker, ManagedSettings shield와 expiry fail-safe
- Date/mach_continuous_time 무결성 분류와 widget→app App Group SwiftData 프로브
- 프로세스 간 잠금과 보존 상한이 있는 공유 JSONL 진단 로그
- 세션 식별자와 App Group 잠금으로 보호되는 shield/Live Activity 수명주기
- 자동 테스트 11개와 iPhone 17 Pro iOS 26.5 시뮬레이터 화면 증거
- 출정 안내와 준비 구역 4종, 실기기 관문을 독립 캡처하는 UI 테스트 및 화면별 PNG 6장
- 고정 팔레트로 후처리한 광산 입구, 출정 보급품, 앱 아이콘 이미지 에셋
- Live Activity를 실제 시작해 compact/expanded Dynamic Island를 캡처하는 UI 테스트
- 4색 광산 인터페이스의 기준 문서 `DESIGN.md`와 도구용 `.impeccable/design.json`
- 코어 루프, 리텐션, 성장 공정성, 잠금화면 역할을 다룬 `docs/GAME_DESIGN_REVIEW.md`
- 실제 Widget과 동일한 최대 160pt 잠금화면 콘텐츠를 검증하는 UI 캡처

### Changed

- P0 앱을 SHAFT 기술 대시보드에서 광산 출정 준비 흐름으로 재설계
- Live Activity와 홈 위젯을 같은 팔레트, 광부 실루엣, 귀환 신호·보급 상자 언어로 통일
- 상태별 표현을 `준비 전/시험 중/준비 완료/확인 필요/문제 발생`으로 교체하고 텔레메트리를 채굴 일지로 전환
- 버튼을 4pt 깊이와 즉시 press-down 반응을 가진 게임형 조작으로 변경
- Dynamic Type에서 헤더·모듈·계측 행이 수평에서 수직으로 전환되도록 적응형 레이아웃 적용
- Increase Contrast 경계 강화와 Reduce Motion용 press/transition 대체 추가
- 보라·청록·주황 네온 역할을 제거하고 석탄·혈암·석회·황동 4색 체계로 앱·위젯·Live Activity·이미지 에셋 통일
- 모듈별 색 테두리와 컬러 타일을 중립 금속판·황동 표찰·리벳으로 교체
- 주 동작만 황동으로 채우고 보조·주의·비상 동작은 문구, 아이콘, 채움/외곽선 구조로 구분
- 채굴 일지 열림 상태를 사각 레일과 금속 손잡이의 광산 레버형 `Toggle`로 교체
- Dynamic Island expanded 레이아웃을 광부·상태, 타이머, 진행·자원·행동의 3단 구조로 재배치해 잘림과 시스템 파랑 제거
- Live Activity 잠금화면 본문을 앱 캡처 하네스와 공유하는 `ProbeLockScreenContent`로 추출
