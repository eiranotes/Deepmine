# DeepMine Context

## Goal

DeepMine은 집중 세션 동안 사용자가 선택한 방해 앱을 실제로 차단하고, 완료 세션을 광산 성장으로 전환하는 iOS 26+ 집중 도구다.

## Product boundary

- 집중만이 성장 연료다. 오프라인 보상, 수면 채굴, 광고는 없다.
- 서버, 계정, 클라우드 동기화 없이 기기 로컬에서 동작한다.
- StandBy와 잠금화면 Live Activity가 세션 중 주 표시 계층이고 Dynamic Island는 확인·재시작 보조 표면이다.
- 게임 규칙은 Foundation-only `DeepMineCore`, UI와 시스템 연동은 앱/익스텐션에서 담당한다.

## Current milestone

Spec §16의 gameplay-complete 로컬 MVP를 시뮬레이터에서 구현한다. P0 프로브와 진단 경로는 유지하며 Live Activity, AlarmKit, FamilyControls, ManagedSettings, DeviceActivity, 실제 App Group 경계는 물리 기기 릴리스 게이트로 분리한다.

## Non-goals for the current implementation

- StoreKit 2와 유료 상품 게이트
- 서버·계정·클라우드 동기화
- 친구·랭킹·시즌·퀘스트·전투·인벤토리
- iPad 또는 Watch 전용 앱, 외부 배포와 스토어 자산

## Decision principles

1. 사양과 실기기 증거가 추정보다 우선한다.
2. 빌드 성공과 기기 동작 확인을 구분한다.
3. 권한 거부·entitlement 미승인 상태에서도 나머지 프로브는 계속 동작한다.
4. 사용자를 방해하는 백그라운드 갱신을 만들지 않는다.
5. 시뮬레이터 게임 완성과 실기기 시스템 검증을 별도 상태로 기록한다.
6. 집중 크레딧으로 시간 선택의 공정성을 지키고, 이미 획득한 일일 스트릭을 심층 실패로 소급 취소하지 않는다.
