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

상태: 구현 완료, Xcode 실행 미검증

변경:

- 현재 암반 예상 광석이 `BigNumber` 지수를 보존하도록 수정
- 탭·자동 출력 HUD가 `BigNumber` 지수를 보존하도록 수정
- 타격·파괴 부유 숫자가 `BigNumber` 지수를 보존하도록 수정
- 일반 타격 숫자의 `−` 접두사를 제거해 자원 손실처럼 읽히는 문제 수정
- 심도 잠금 장비 버튼이 `최대`로 표시되지 않고 필요한 심도를 표시하도록 수정
- 큰 수 포맷터 회귀 테스트 추가

## Checkpoint 3 — 정련 구매 경로와 UI

상태: 구현 완료, Xcode 실행 미검증

변경:

- `GameStore.purchaseRefinement(_:)` 추가
- 성공한 정련 구매만 플레이어 저장소에 커밋
- 잠금 상태는 저장·상태 변경 없음
- 장비 화면에 드릴·광차·램프별 정련 행 추가
- 현재 등급, 다음 등급, ×2.5 축, 해금 레벨, 비용 표시
- 구매 성공 후 플레이어와 추천 상태 재로딩
- 부족 광석·저장 실패·재시도 경로 연결
- 정련 영속화 및 잠금 회귀 테스트 추가

## Static validation

현재 도구 환경에는 Xcode와 iOS Simulator가 없으므로 앱 빌드·렌더 검증은 실행하지 않았다.
대신 다음을 수행했다.

- Swift 6.2.1 `swiftc -parse`:
  - `EquipmentView.swift` 통과
  - `EquipmentView+Rows.swift` 통과
  - `GameStore+Progression.swift` 통과
  - 추가 테스트 구문 통과
- 파일 크기:
  - `EquipmentView.swift`: 299줄
  - `EquipmentView+Rows.swift`: 300줄
- 변경 범위는 리뷰 문서, UI, GameStore, 관련 테스트로 제한

## 아직 검증하지 않은 것

- `xcodebuild test -only-testing:DeepMineAppTests`
- generic iOS unsigned build
- 정련 잠금/구매/부족 광석 화면의 시뮬레이터 캡처
- VoiceOver 정련 행 판독 순서
- Dynamic Type에서 긴 비용·심도 문자열의 줄바꿈
- 실제 정련 구매 직후 갱도 출력 변화의 시각 체감

## 남은 P0

- [ ] 장비·정련 광석 비용 전체 `BigNumber`화
- [ ] 램프 정련 크리티컬 배수 `BigNumber`화
- [ ] ×10/×100/MAX 구매
- [ ] 클리커 전용 추천 엔진
- [ ] 광석/초·층/초 및 구매 전후 변화율 표시
- [ ] 정련 전용 도약 연출과 장비 외형 단계

## 재개 순서

1. macOS/Xcode 환경에서 앱 테스트와 generic build 실행
2. 장비 화면 정련 4상태 캡처: 잠금, 구매 가능, 부족 광석, 구매 완료
3. 발견된 빌드·레이아웃 결함 수정
4. 비용 타입의 `BigNumber` 마이그레이션 설계 및 단계별 적용
5. 대량 구매와 클리커 추천 엔진 구현
