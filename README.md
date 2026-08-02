# DeepMine

DeepMine은 플레이어가 실제 암반을 깨고, 광차 자동 굴착과 오프라인 생산으로 세로 갱도를
누적해 내려가는 iOS 방치형 클리커다. 집중 차단은 게임의 입장권이 아니라 선택형 증폭기이며,
권한 없이도 채굴·정련·프레스티지까지 진행할 수 있다.

## 현재 플레이 루프

```text
암반 탭 → 광석 획득·4m 하강 → 장비 강화 → 광차 자동 굴착
→ 오프라인 정산 → 6레벨마다 정련 → 120층 뒤 프레스티지·재구축
```

- 옛 Lv.200 제품 상한은 제거됐지만 Lv.100,000 산술 안전 천장은 남는다. 현재 검증 범위는
  500km이며, 지갑·데미지·장비/정련 비용은 그 범위와 극후반 표면에서 `BigNumber`를 보존한다.
- 홈은 현재 암반 보상, 남은 탭/자동 ETA, 자동 광석/초·층/초와 구매 전후 변화를 보여 준다.
- 5km·20km·100km는 새 경제 지역이 아니라 심연 내부의 시각 지질 세대다.
- 집중 세션 복구·시작 준비·활성 구간에는 홈 자동 채굴과 오프라인 정산을 멈춰 같은 시간을
  두 번 지급하지 않는다.

## 저장소 구조

- `DeepMineCore/`: Foundation-only 경제, 채굴, 정련, 프레스티지와 밸런스 시뮬레이터
- `DeepMineApp/`: SwiftUI 앱, 저장소, 세션·오프라인·장비 화면
- `DeepMineProbe/`: Widget/Live Activity 공유 모델과 Asset Catalog
- `web/`: Core 공식을 미러링하는 Vinext/Pages 조기·중기 formula harness. JavaScript
  `number` 범위를 iOS `BigNumber`와 동일하게 보장하지 않는다
- `docs/`: 최신 상태, 결정, 작업, 검증과 제품 사양
- `artifacts/imagegen/`: 생성 에셋 원본·처리본·provenance·검증 보고서

현재 제품 계약은 `docs/SPEC_v0.2.md`의 2026-08-02 amendment와 `docs/DECISIONS.md` D-067~D-079,
실측 상태는 `docs/PROJECT_STATUS.md`와 `BUILD_REPORT.md`를 따른다. 각 문서의 명시적 역사적
스냅샷은 현재 판정에 사용하지 않는다.

## 개발 환경

- macOS, Xcode 26.5, iOS 26.5 SDK, Swift 6
- Node.js 22 이상
- Python 3(장기 진행 PNG 검증은 표준 라이브러리만 사용)

## 검증

```bash
swift test --package-path DeepMineCore

xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build

xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:DeepMineAppTests test

python3 scripts/validate_long_progression_assets.py

cd web
npm ci
npm test
npm run lint
npm run build
```

로컬 웹은 `web/`에서 다음처럼 연다.

```bash
npm run dev -- --hostname 0.0.0.0 --port 4173
```

## 장기 진행 에셋

`artifacts/imagegen/long-progression-v2/`에 7종의 매니페스트, SHA, 원본/처리본,
contact sheet와 검증 보고서를 보존한다. 이번 작업에서 손상된 pressure rock과 cart badge 2종은
ImageGen으로 새로 만들었고, 나머지 5종은 이전 PR 원본을 네 안료 팔레트로 정규화했다.

## 아직 열린 항목

- 실제 앱의 홈 추천·정련·MAX 구매 정책을 그대로 쓰는 30/90/180일 장기 시뮬레이션
- 집중 세션의 별도 보상을 실제 `MiningLoop` 가속으로 통합하는 경제 구조
- 정련 MAX와 프레스티지 뒤 기억 정련 일괄 재설치
- `NextStepPlanner` 극후반 진행도의 `BigNumber` 전환
- 전체 XCUITest, 실제 VoiceOver·Reduce Motion·햅틱과 FamilyControls/AlarmKit 실기기 게이트
- main push 뒤 GitHub Actions와 Pages 실제 원격 배포 확인
