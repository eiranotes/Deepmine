# Exponential Growth UI Work Log

업데이트: 2026-08-02  
브랜치: `agent/exponential-growth-ui-review`  
기준: `main@62600d8ed513c8cbb0ed5b2f7475a2679f41e87d`

## Checkpoint 1 — 전체 리뷰 저장

상태: 완료

- 지수 성장 수식과 실제 앱 플레이의 차이 분석
- 이미지 에셋·갱도 UI·장기 시각 성장 분석
- P0/P1/P2 우선순위와 완료 판정 기준 작성
- 문서: `docs/EXPONENTIAL_GROWTH_UI_REVIEW.md`

## Checkpoint 2 — 큰 수 UI와 잠금 상태 수정

상태: 구현·원격 Xcode 검증 완료

변경:

- 현재 암반 예상 광석이 `BigNumber` 지수를 보존하도록 수정
- 탭·자동 출력 HUD가 `BigNumber` 지수를 보존하도록 수정
- 타격·파괴 부유 숫자가 `BigNumber` 지수를 보존하도록 수정
- 일반 타격 숫자의 `−` 접두사를 제거해 자원 손실처럼 읽히는 문제 수정
- 심도 잠금 장비 버튼이 `최대`로 표시되지 않고 필요한 심도를 표시하도록 수정
- 큰 수 포맷터 회귀 테스트 추가

## Checkpoint 3 — 정련 구매 경로와 UI

상태: 구현·원격 Xcode 검증 완료, 렌더 캡처 미완료

변경:

- `GameStore.purchaseRefinement(_:)` 추가
- 성공한 정련 구매만 플레이어 저장소에 커밋
- 잠금 상태는 저장·상태 변경 없음
- 장비 화면에 드릴·광차·램프별 정련 행 추가
- 현재 등급, 다음 등급, ×2.5 축, 해금 레벨, 비용 표시
- 구매 성공 후 플레이어와 추천 상태 재로딩
- 부족 광석·저장 실패·재시도 경로 연결
- 정련 영속화 및 잠금 회귀 테스트 추가

## Checkpoint 4 — 전체 게임플레이 흐름 재감사

상태: 완료, 문서 저장

문서:

- `docs/GAMEPLAY_FLOW_REVIEW.md`

범위:

- 실제 `main`에 반영된 Claude Opus 5 공동작성 커밋 재검토
- 최초 실행 → 첫 암반 → 홈 → 자동화 → 장비 분기 → 정련 → 집중 → 귀환 → 오프라인 → 메타 → 프레스티지 → 장기 게임 전 흐름
- 오래된 `claude/deepmine-repo-upload-plan-f0nivi` 브랜치를 현재 제품 기준에서 제외
- 실제 UI 추천과 밸런스 시뮬레이터 구매 정책 차이 확인
- 첫 자동화가 현재 홈 추천으로 늦어지는 구조 확인
- 집중 증폭기가 실제 갱도 배수가 아니라 별도 광석 지급 경제라는 점 확인
- 세션 귀환의 심도 증가, 스트릭, 통계, 도전과제가 클리커 피벗과 완전히 통합되지 않은 점 확인
- 수정 통화의 현재 소비처 부재 확인
- 프레스티지 손실 고지에서 정련·장비 분기가 빠진 점 확인
- 홈이 가려진 화면에서 자동 채굴이 계속되는지 E2E가 없음을 확인

## Validation

### 정적 검증

- Swift 6.2.1 `swiftc -parse`:
  - `EquipmentView.swift` 통과
  - `EquipmentView+Rows.swift` 통과
  - `GameStore+Progression.swift` 통과
  - 추가 테스트 구문 통과
- 변경 파일 크기:
  - `EquipmentView.swift`: 299줄
  - `EquipmentView+Rows.swift`: 300줄

### GitHub Actions 원격 검증

PR #3의 macOS 26 / Xcode 26.5 실행에서:

- `DeepMineCore`: **256/256 통과**
- `DeepMineAppTests`: 통과
- generic iOS unsigned build: 통과
- 웹 `npm ci`: 통과
- 웹 lint: 통과

전체 워크플로가 빨간 이유는 기능 코드 빌드 실패가 아니다.

1. Swift 줄 수 검사가 `DeepMineCore/.build` 생성 파일까지 검사하고,
   기존 `ProgressionTests.swift` 301줄·`MineFace.swift` 303줄을 잡음
2. 웹 `vite.config.ts`가 저장소에 없는 `./build/sites-vite-plugin`을 import함

## 아직 검증하지 않은 것

- 정련 잠금/구매 가능/부족 광석/구매 완료 시뮬레이터 캡처
- VoiceOver 정련 행 판독 순서
- Dynamic Type에서 긴 비용·심도 문자열 줄바꿈
- 실제 정련 구매 직후 갱도 출력 변화의 시각 체감
- 홈이 장비·통계·집중 화면에 가려진 동안 자동 생산 유지 여부
- 집중 세션과 실제 `MiningLoop`의 통합 동작
- 40km·150km·500km 비용·크리티컬·표기 회귀

## 남은 P0

- [ ] 홈 추천을 실제 암반 ETA/광석·초 기준으로 교체
- [ ] 첫 자동화 미보유 시 광차를 최우선 마일스톤으로 처리
- [ ] 집중 세션을 실제 `MiningLoop` 출력 배수로 통합
- [ ] 귀환 보고·스트릭·통계·도전과제를 클리커 지표 중심으로 재편
- [ ] 수정 통화 소비처 정의 또는 제거
- [ ] 프레스티지 손실에 정련·장비 분기 표시
- [ ] 장비·정련 광석 비용 전체 `BigNumber`화
- [ ] 램프 정련 크리티컬 배수 `BigNumber`화
- [ ] ×10/×100/MAX 및 기억 장비 재설치
- [ ] OfflineReturnSheet·온보딩 등 남은 `doubleValue` UI 경로 정리
- [ ] 홈이 가려진 화면의 자동 생산 E2E

## 남은 P1

- [ ] 광석/초·층/초 및 구매 전후 변화율 표시
- [ ] 정련 전용 도약 연출과 장비 외형 단계
- [ ] 5km·20km·100km 이후 장기 지질 세대
- [ ] 장식 보상 실제 갱도 연결 확인
- [ ] km 이상 심도 단위 포맷

## 재개 순서

1. GitHub Actions 줄 수 검사에서 `.build` 제외 및 기존 기준선 정리
2. Sites 전용 Vite 플러그인의 CI 대체 경로 정리
3. 홈이 가려진 화면의 자동 생산 E2E 추가
4. 홈 추천을 클리커 효율로 교체하고 첫 광차 우선 정책 추가
5. 집중 세션을 같은 `MiningLoop` 배수로 통합하는 설계·구현
6. 비용 타입의 `BigNumber` 마이그레이션
7. 대량 구매·프레스티지 재설치
8. 정련·오프라인·프레스티지 화면 캡처와 접근성 검증
