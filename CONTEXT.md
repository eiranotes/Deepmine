# DeepMine Context

## Goal

DeepMine은 집중 세션 동안 사용자가 선택한 방해 앱을 실제로 차단하고, 완료 세션을 광산 성장으로 전환하는 iOS 26+ 집중 도구다.

## Product boundary

- 집중만이 성장 연료다. 오프라인 보상, 수면 채굴, 광고는 없다.
- 서버, 계정, 클라우드 동기화 없이 기기 로컬에서 동작한다.
- StandBy와 잠금화면 Live Activity가 세션 중 주 표시 계층이고 Dynamic Island는 확인·재시작 보조 표면이다.
- 게임 규칙은 Foundation-only `DeepMineCore`, UI와 시스템 연동은 앱/익스텐션에서 담당한다.

## Current milestone

게임 코드보다 먼저 Live Activity, AlarmKit, FamilyControls, ManagedSettings, DeviceActivity 및 App Group 경계를 실기기에서 검증하는 P0 프로브를 완성한다.

## Non-goals for P0

- 경제·장비·광맥·스트릭·프레스티지 구현
- 출시용 픽셀 아트 제작
- StoreKit 및 제품 UI 구현

## Decision principles

1. 사양과 실기기 증거가 추정보다 우선한다.
2. 빌드 성공과 기기 동작 확인을 구분한다.
3. 권한 거부·entitlement 미승인 상태에서도 나머지 프로브는 계속 동작한다.
4. 사용자를 방해하는 백그라운드 갱신을 만들지 않는다.
