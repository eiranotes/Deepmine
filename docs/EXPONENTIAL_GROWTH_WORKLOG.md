# Exponential Growth UI Work Log

업데이트: 2026-08-02  
브랜치: `agent/exponential-growth-ui-review`  
기준: `main@62600d8ed513c8cbb0ed5b2f7475a2679f41e87d`

## 완료된 전체 흐름

- 실제 탭·자동 DPS 기반 추천과 첫 광차 자동화 우선 정책
- 집중 세션과 `MiningLoop` 통합
- 귀환 심도, 채굴일, 통계, 수정 소비, 프레스티지 손실 고지
- 장비 ×10/×100/MAX와 기억 레벨 복원
- 장비·정련 비용 및 램프 정련 크리티컬 `BigNumber` 경로
- 온보딩·오프라인·프레스티지 큰 수 표기
- Core 통합 회귀와 화면 이탈 중 자동 채굴 UI E2E

## 웹 로직 통일

`web/app/coreBalance.ts`가 현재 Swift `Balance`와 `Balance+Clicker`를 직접 미러링한다.

- 모든 장비 Lv.1 시작
- 광차 Lv.1 자동 DPS 0, Lv.2부터 자동화
- 고정 200레벨 상한 제거, 산술 경계 100,000
- 구매 가능 기본 레벨 5, 심도 15m마다 1레벨 증가
- 기억 장비 재구매 할인 50%
- 정련 6레벨 간격, ×2.5, 비용 ×20
- 램프 정련 크리티컬 배수 반영
- 최저가 추천 제거
- 기대 탭 데미지·자동 DPS 효율 추천
- 자동화 미보유 시 첫 광차 우선

기본 웹 화면은 `UnifiedMinePrototype`으로 전환했다. 기존 시각 프로토타입은 비교용으로 보존했다.

## GitHub Pages 검증

- `.github/workflows/pages.yml` 추가
- `web/pages-static`을 Pages 전용 소스로 분리
- `coreBalance.ts`를 esbuild 브라우저 ESM으로 번들
- 배포 전 Node 스모크 테스트 수행
- 브라우저에서 11개 성장 규칙을 자동 검사하는 검증 화면 추가
- Pages 소스를 `web/pages`에 두면 Vinext가 Pages Router로 오인하는 문제를 재현하고 분리로 해결

## 확인된 검증 결과

GitHub Actions Validation run #60:

- 웹 `npm ci`: 통과
- ESLint: 통과
- Vinext production build: 통과
- Node 테스트: 통과
- Core/iOS job: 실행 중

Pages 전용 워크플로는 저장소에 등록하고 자동 활성화 옵션까지 설정했다. 현재 사용 가능한 GitHub 커넥터는 PR 이벤트 Validation run만 조회하므로 Pages deploy run과 공개 URL 응답은 별도 확인이 필요하다.

## 2026-08-03 Pages 사용자 표면 교정

위 `pages-static` 결과표는 배포 파이프라인 검증에는 성공했지만 사용자가 플레이할 게임은
아니었다. Vinext 기본 화면과 Pages artifact를 `MinePrototype`으로 되돌리고, Pages는 Vite
정적 build로 패키징한다. 최신 Core 계약대로 장비 Lv.1·자동 DPS 0·첫 광차 Lv.2 ◆180
저축에서 시작하도록 교정했다. 로컬 브라우저에서 직접 타격, 광석 증가, 첫 광차 구매,
자동 하강과 390px 무가로-overflow를 확인했다.
