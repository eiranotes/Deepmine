# DeepMine Agent Guide

`CLAUDE.md`와 `docs/SPEC_v0.2.md`를 이 저장소의 구현 규칙과 제품 사양으로 사용한다.

- 개발 단계의 기본 순서는 `docs/DEV_PLAYBOOK.md`를 따른다.
- 2026-07-29 사용자의 명시적 전체 구현 지시에 따라 P1–P4 게임 코드는 시뮬레이터 우선으로 진행한다. P0 실기기 게이트는 구현 차단이 아니라 릴리스 차단으로 유지한다.
- `docs/SPEC_v0.2.md`가 제품 사양의 최종 기준이며 `PRODUCT.md`는 파생 레지스터다.
- 구현 상태는 `BUILD_REPORT.md`, `docs/PROJECT_STATUS.md`, `docs/TASKS.md`에 사실대로 기록한다.
- 시스템 프레임워크 동작은 빌드 성공과 구분하고, 실기기에서 확인하지 않은 항목을 검증됨으로 표시하지 않는다.
- 커밋과 푸시는 사용자의 명시적 요청이 있을 때만 수행한다.
