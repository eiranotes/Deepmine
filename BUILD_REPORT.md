# Build Report

업데이트: 2026-08-01 (웹 연속 암반·자동 하강 기준안)

## 2026-08-01 web continuous rock and idle descent baseline

| 항목 | 상태 | 근거 |
|---|---|---|
| 연속 암반 | 검증됨(로컬 브라우저) | 과거 통로와 현재 작업면을 별도 장면으로 쌓지 않고, `headDepth` 하나로 암반 텍스처·지표·보어 이력·심도 눈금을 같은 속도로 위로 이동 |
| 무입력 하강 | 검증됨(로컬 브라우저) | 광차 자동 데미지를 120ms 고정 스텝으로 적용. 입력 없이 1초 동안 18.9m→19.2m 증가 |
| 화면 전체 탭 | 검증됨(로컬 브라우저) | `main`의 Pointer Events로 버튼이 아닌 제목 영역 탭도 굴착에 반영. 19.2m→20.0m 즉시 증가. 18px 이동 시 스크롤로 판정해 취소 |
| 곡괭이·세로 균열 | 검증됨(브라우저 육안) | 생성 `MiningPickaxe`를 광부와 독립 회전시키고, 생성 `ShaftFractureVertical_*`를 진행률에 따라 위→아래 공개 |
| 파괴 연속성 | 구현·정적 검증됨 | 4m 돌파 전후 `headDepth`가 동일 좌표를 유지하고, 좌우 암반 붕괴 뒤 같은 `rock-phase`에서 다음 굴착을 계속함 |
| 첫 화면 | 검증됨(390×844) | 상단 설명·외부 상태줄을 줄이고 제목 다음에 즉시 갱도 배치. 과거 구간은 빈 여백이 아니라 지지대·레일·광차가 있는 열린 통로로 표시 |
| 웹 검사 | 검증됨 | `npm run lint`, `npm test` 4/4, vinext production build 통과. 브라우저 console warning/error 0 |
| 배포 | 미수행 | 이번 기준안은 로컬 웹 검증만 수행. 기존 비공개 version 2 배포에는 반영하지 않았고 iOS 포팅도 시작하지 않음 |

이 기준안은 D-054의 앱 포팅 전 승인 대상으로 둔다. 실제 앱의 지반 버튼과 D-053 모션은
이번 웹 변경으로 교체하지 않았으며, 웹 체감 확정 뒤 같은 좌표·자동화 계약으로 옮긴다.

## 2026-08-01 breakable ground and visible pickaxe strike

| 항목 | 상태 | 근거 |
|---|---|---|
| 큰 파괴 대상 | 검증됨(시뮬레이터) | 갱도 전체 탭 제스처를 제거하고 현재 `ShaftRock_*` 지반을 화면 폭 대부분의 실제 `Button`으로 노출. 한국어·다크·medium 캡처 육안 확인 |
| 곡괭이 타격 | 검증됨(시뮬레이터 영상) | 독립 `MiningPickaxe`가 준비 각도에서 약 70° 내려찍고 spring으로 복귀. 0.9초 클립과 16프레임 판독에서 연속 동작 확인 |
| 세로 균열 | 검증됨(시뮬레이터·정적) | 진행률 0에서는 숨기고 첫 타격부터 위→아래 공개. damage stage에 따라 light/medium/heavy로 교체. 캡처에서 중앙 세로 경로 확인 |
| 타격 피드백 | 검증됨(UI) | `testGroundStrikeChangesVisibleIntegrity` 1/1. `rock-face` 탭 뒤 내구 레이블 100%→89%, 작은 파편과 타격 숫자 표시 |
| 파괴 전환 | 검증됨(UI·시뮬레이터 영상) | `testGroundBreakDescendsToTheNextSegment` 1/1. 9회 타격 뒤 `rock-face`가 0m→4m로 바뀌며, 이전 지반 전체 폭이 중앙에서 벌어져 좌우 회전·낙하하는 장면을 2.33초 클립과 키프레임으로 확인 |
| Reduce Motion | 구현·빌드 검증됨 | 도구 상태·균열·보상은 유지하고 지반 흔들림·분할 낙하·카메라 보간을 축소 |
| ImageGen 자산 4종 | 검증됨 | `MiningPickaxe`, `ShaftFractureVertical_*` 3종을 내장 ImageGen으로 생성/편집. `provenance.json`에 원본 참조와 계보 보존 |
| shaft asset validator | 검증됨 | `PYTHONDONTWRITEBYTECODE=1 uv run --with pillow python scripts/process_shaft_assets.py --validate-only` → 11/11 imageset 통과 |
| 아트 카탈로그 | 검증됨 | `GameArtCatalogTests` 12/12, 실패 0. 11개 shaft 슬롯 설치·프롬프트·폴백 계약 포함 |
| Core 전체 | 검증됨 | `swift test --package-path DeepMineCore` 195/195, 실패 0 |
| generic iOS build | 검증됨 | `xcodebuild ... -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` → BUILD SUCCEEDED |
| 시뮬레이터 build | 검증됨 | iPhone 17 Pro iOS 26.5 대상 build → BUILD SUCCEEDED |
| 실기기 타격감 | 미검증(실기기 필요) | 실제 손가락 아래 press-down 지연, 햅틱 강도, OLED 대비, VoiceOver·Reduce Motion 체감 |

### Visual evidence

- 정적 전체 화면: `artifacts/imagegen/shaft-assets-v1/ui-captures/breakable-ground.png`
- 타격 핵심 프레임: `artifacts/imagegen/shaft-assets-v1/ui-captures/ground-strike-keyframes.png`
- 짧은 런타임 클립: `artifacts/imagegen/shaft-assets-v1/ui-captures/ground-strike-motion.mp4`
- 파괴·하강 핵심 프레임: `artifacts/imagegen/shaft-assets-v1/ui-captures/ground-break-keyframes.png`
- 파괴·하강 클립: `artifacts/imagegen/shaft-assets-v1/ui-captures/ground-break-motion.mp4`
- 자산 비교판: `artifacts/imagegen/shaft-assets-v1/contact-sheet.png`

컴퓨터 제어로 Simulator 창을 직접 읽으려 했으나 macOS 접근성 제공자가 보이는 창을
접근성 창으로 반환하지 않아 중단했다. 권한은 granted였으므로 같은 시도를 반복하지 않고,
`simctl` 녹화와 실제 XCUITest 탭을 결합해 타격 프레임을 검증했다. 최초 정적 캡처도 앱 전환
중 검은 프레임이라 폐기하고 정상 실행 뒤 다시 캡처했다.

파괴 UI 테스트 작성 중 1차는 `mine-depth`를 `StaticText`라고 가정해 타격 전에 실패했고,
2차는 레이블 전체 변화로 반복을 끊어 첫 타격 뒤 실패했다. 제품 파괴 실패가 아니라 테스트
조회·반복 조건 문제였으며, `rock-face`의 심도가 0m인 동안 반복하도록 고친 최종 실행은 1/1 통과했다.

홈의 실제 작업면을 끝까지 깨는 0m→4m 경로는 검증했다. 남은 범위는 온보딩 첫 암반의
보상→강화→홈까지를 같은 신규 표현으로 한 번에 보는 전체 UI 경로다. 시뮬레이터 영상을
실제 손가락 아래 press-down·햅틱·OLED 체감까지 검증된 것으로 확대하지 않는다.

## 2026-08-01 clicker-first onboarding

| 항목 | 상태 | 근거 |
|---|---|---|
| 첫 행동 | 구현·검증됨(코어) | 설명/대기 대신 실제 `MiningLoop.strike`. `OnboardingEngineTests` 4/4 |
| 보상·강화 | 구현·검증됨(코어·저장) | 첫 4m 파괴 뒤 광석 100·수정 1개, 드릴 2레벨 구매 뒤 홈. `GameStoreOnboardingTests` 2/2 |
| 권한 없는 진입 | 구현됨 | 강화 직후 `.complete`; FamilyControls·AlarmKit·알림은 온보딩에서 호출하지 않음 |
| 옛 저장 복구 | 검증됨(코어·UI 일부) | 옛 설명 단계는 첫 암반으로, 옛 권한 단계는 3회 유예 뒤 홈으로 이동. 레거시 UI 경로 통과 |
| 접근성 | 검증됨(시뮬레이터) | 갱도 장식 레이어를 숨기고 홈 암반을 단일 기본 액션 버튼으로 노출. 신규/진행 홈 focused XCUITest 1/1 |
| 시각 증거 | 검증됨(시뮬레이터) | 한국어·다크·medium 상단 정렬 화면을 육안 확인. `artifacts/ui/onboarding-clicker-first/first-rock.png` |
| Core 전체 | 검증됨 | `swift test --package-path DeepMineCore` 195/195, 실패 0 |
| generic simulator build | 검증됨 | `xcodebuild ... -destination 'generic/platform=iOS Simulator' build` 성공 |
| focused UI | 검증됨 | 신규/진행 홈 단일 갱도·집중 패널 1/1, 코어 루프 5화면 캡처 1/1. 전체 UI 스위트로 확대하지 않음 |
| 범위 밖 회귀 | 기록 | 온보딩+디자인 계약 묶음 실행 8통과/1실패. 현재 dirty 장비 티어 계약이 tier2 대신 tier3을 반환; 이번 작업에서는 수정하지 않음 |

### UI 판단

- 첫 캡처에서 콘텐츠가 화면 중앙에 걸려 상단이 과도하게 비어 있었다. `minHeight` 컨테이너를
  상단 정렬해 제목→진척도→암반→방치 안내가 첫 뷰포트에서 바로 이어지게 했다.
- 갱도 아트는 새 자산을 더 만들지 않고 D-048의 생성 지표·벽면·구조물을 재사용했다. 암반
  크기와 질감 밀도가 충분해 별도 온보딩 삽화보다 실제 게임 장면이 더 정직했다.
- 물리 탭 감각, VoiceOver 실제 초점, 햅틱과 고대비는 실기기 릴리스 게이트다.

## 2026-08-01 continuous shaft and visible equipment

| 항목 | 상태 | 근거 |
|---|---|---|
| 연속 하강 모델 | 검증됨(단위) | `ShaftSceneEngine`이 `faceDepth + brokenFraction × 4m`로 헤드 심도를 산출. 지층은 지역 경계에서만 분할하고 보어 이력을 별도 보존 |
| 장비 분기 6종 | 검증됨(단위) | 레벨 5 잠금, 비용 460/560/660, 장비별 상호 배타, 명령 멱등, 프레스티지 리셋, 수치 효과 테스트 |
| 장비 시각 계약 | 검증됨(코드·웹) | 드릴=보어 폭/도구/스윙/파편, 광차=레일/대수/속도/적재량, 램프=설비/조사 거리/약점 광택 |
| 지표 작업선 | 검증됨(시뮬레이터) | 첫 UI 영상에서 찾은 0m 헤드 잘림을 surface inset으로 수정. 한국어·다크·medium 캡처에서 광부·드릴·램프와 가운데 축 확인 |
| 저장 | 검증됨(focused unit) | `equipmentModificationsData`, `mineFaceBoreHistoryData` 왕복과 옛 빈 Data의 안전 기본값을 focused App unit 14/14로 확인 |
| 웹 정적 검사 | 검증됨 | 현 기준 `npm run lint`, `npm test` 4/4, `npm run build` 통과 |
| 웹 실제 좌표 | 대체됨(D-054) | 헤드를 화면 안에서 4m씩 이동하던 version 2 기준은 과거 기록. 현 로컬 기준은 막장 경계를 고정하고 전체 암반 좌표를 무입력 상태에서도 연속 이동 |
| 웹 비공개 배포 | 배포됨 | version 2, commit `ca4296fdcda98a5543f60abdd41e8d5def845b70`, `https://deepmine-shaft-prototype.eiraworks-9813.chatgpt.site` |
| Core 전체 | 검증됨 | `swift test --package-path DeepMineCore` **195/195**, 실패 0 |
| generic iOS build | 검증됨 | `xcodebuild ... -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` 성공 |
| App focused unit | 검증됨 | `GamePersistenceTests` + `GameStoreProgressionTests` **14/14**, 실패·skip 0 |
| App 전체 unit | **미검증** | 제품 assertion 실패는 없었지만 `Mach error -308`, runner 연결 전 exit, 고아 UI 빌드 간섭, result-record finalize 대기로 네 차례 유효한 전체 결과를 만들지 못함 |
| UI focused | 검증됨 | `OnboardingHomeUITests/testFreshAndProgressedHomeUseOneMineControlScene` 1/1, `GameSurfaceScreenshotTests/testCaptureCoreLoopScreens` 1/1. 한국어·다크·medium 캡처 5장 육안 확인 |
| UI 전체 | **미검증** | 위 focused 2건을 전체 `DeepMineAppUITests` 통과로 확대하지 않음 |
| 실기기 체감 | 미검증(실기기 필요) | 실제 OLED 대비, 연속 탭/햅틱, 광차 왕복의 멀미·과밀, Reduce Motion·VoiceOver |

### 구사양 판정

- 집중 출정·앱 차단·AlarmKit·Live Activity는 D-037의 선택적 증폭기 전용 기능이라 유지한다.
- 계획·시간·오늘 집중·연속 일수는 접힌 집중 패널과 집중 귀환 화면에만 격리한다.
- 기본 홈의 다음 약속·다음 세 걸음·중복 광산 장면은 제거했다.
- 귀환의 `nextPromise` 타입과 카피는 다음 지역까지의 `nextGoal`/“다음 굴착 목표”로 교체했다.

## 2026-07-31 clicker audit and shaft visual payoff

| 항목 | 상태 | 근거 |
|---|---|---|
| 클리커 코어 루프 | 검증됨 | 탭→4단계 파괴→광석→장비→8시간 오프라인→프레스티지가 Core·SwiftData·홈에 연결. `swift test --package-path DeepMineCore` 188/188 |
| 권한 없는 완결성 | 검증됨(코드·30일 시뮬레이션) | 심도·장비 해금·프레스티지 자격은 암반 파괴를 읽고 집중은 선택 배율. 30일 heavy/light 광석 3.462배 |
| 피벗 잔여 흔적 | 부분 해소 | 온보딩 차단 설명/대기 데모는 D-052로 제거. 공명 결절·지역 전환·8-bit SFX는 아직 없음 |
| 장기 수치 모델 | 위험 기록 | 데미지/암반은 `BigNumber`지만 `Resources.ore`는 `Double`. `RockEngine` 512층 절단 시 남은 데미지를 호출부가 재정산하지 않음. 180일 모델의 장기 위험 |
| 생성 갱도 아트 | 검증됨(정적) | 내장 ImageGen 7종. `scripts/process_shaft_assets.py --validate-only`가 7 imageset/21 PNG의 해시·1x/2x/3x·네 안료·역할별 알파를 검증 |
| 갱도 아트 소비 경로 | 검증됨(단위·빌드·화면) | 지역 벽면 4, 지표 1, 구조·광맥 2를 배경/구조/상태로 분리. `GameArtCatalogTests`와 generic build, 홈 캡처 통과 |
| 타격 피드백 | 검증됨(시뮬레이터) | 일반 탭은 데미지, 파괴는 광석+파편, 충격 배율/다음 광맥 HUD. 약점 48pt target과 관련 UI 14/14 통과 |
| 심도 계약 | 검증됨(단위) | 장비 상한은 최고 기록, 심연 보너스는 실제 막장 이동, foreground 틱은 최신 정산 시각을 읽는다 |
| 장기 밸런스 | 위험 기록 | 30일 heavy/light 광석 3.462배는 대역 안. 180일은 0.406배로 역전되어 P4 재튜닝 대상 |
| `DeepMineAppTests` | 검증됨 | 132/132, 저장·프레스티지·심도 계약 포함 |
| generic iOS build | 검증됨 | `xcodebuild build -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO` 성공 |
| 최종 화면 증거 | 검증됨(시뮬레이터) | `artifacts/imagegen/shaft-assets-v1/ui-captures/mine-home-final.png`, 한국어·다크·medium |
| 관련 UI suite | 검증됨 | `ActiveMineUITests` 13건 + 코어 루프 캡처 1건 = 14/14. 새 홈 시작 스크롤 경로 포함 |
| 전체 UI suite | 미실행 | 관련 14건 결과를 전체 60건 통과로 확대하지 않는다 |
| 실기기 타격감 | 미검증(실기기 필요) | 햅틱 강도, 연속 탭 체감, Reduce Motion·VoiceOver·Increase Contrast는 릴리스 게이트 |

### ImageGen provenance

- 모드: 내장 ImageGen. 입구 벽면 초안은 둥근 암석 반복이 강해 이미지 편집으로 연속 지층으로
  다시 만들었고, 투명 자산은 후처리에서 크로마를 제거했다
- 원본: `artifacts/imagegen/shaft-assets-v1/raw/`의 `ShaftRock_*` 4종,
  `ShaftSurface`, `ShaftGantry`, `SeamVein`
- 최종 프롬프트: `docs/SHAFT_ART_PROMPTS.md`
- 검증/해시: `artifacts/imagegen/shaft-assets-v1/manifest.json`, `validation-report.json`
- 비교판: `artifacts/imagegen/shaft-assets-v1/contact-sheet.png`

### Fresh verification commands and artifacts

```sh
/Users/tofu/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  scripts/process_shaft_assets.py --validate-only
swift test --package-path DeepMineCore
swift run --package-path DeepMineCore -c release DeepMineBalanceCLI \
  --seed 260729 --days 180 --output /tmp/deepmine-codex-balance-180.csv
xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp \
  -destination 'generic/platform=iOS' -derivedDataPath /tmp/DeepMineCodexDerivedFinal \
  CODE_SIGNING_ALLOWED=NO build
xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp \
  -destination 'platform=iOS Simulator,id=64C7804C-355B-4444-90EE-C8ED0D9355CF' \
  -derivedDataPath /tmp/DeepMineCodexAppFinal \
  -only-testing:DeepMineAppTests test
```

- 앱 단위 결과: `/tmp/DeepMineCodexAppTestsPass.xcresult` — 132/132, 실패·skip 0
- 관련 UI 결과: `/tmp/DeepMineCodexFocusedUI.xcresult` — 14/14
- 최종 홈 캡처: `artifacts/imagegen/shaft-assets-v1/ui-captures/mine-home-final.png`

마감 분리 뒤 첫 자산 검증은 계약 모듈의 `ROOT` import 누락으로 실행 전에 실패했고 바로
보완했다. 첫 앱 단위 재실행은 묶은 enum case 하나의 raw key가
`statistics.growth.notEnough` 대신 `statistics.growthNotEnough`여서 130/132였으며, 원래 키로
복구한 focused 7/7과 최종 132/132가 통과했다. 중간 실패를 최종 통과로 덮어쓰지 않는다.

## 2026-07-31 progression rebuild and shaft screen (P3 intermediate snapshot)

> 아래는 진행 중 실행 이력이다. 최종 판정과 최신 테스트 수는 위 표를 따른다.

| 항목 | 상태 | 근거 |
|---|---|---|
| 진행 벽 진단 | 검증됨 | `DeepMineBalanceCLI` 실측 CSV. 수정 전 30일차 라이트가 광석 222만을 쥐고 장비는 심도 상한에 붙어 정지. 세그먼트 150에 927,813탭 필요 |
| 성장률 재설계 (D-044) | 검증됨 | `swift test --package-path DeepMineCore` 185/185. `testIntegrityOutrunsThePurchasedDamageItFunds`가 감속률 1.00~1.05 대역을 고정 |
| 새 진행 곡선 | 검증됨 | `swift run -c release DeepMineBalanceCLI --days 90`. 1일 208–428m, 7일 852–1,060m, 90일 1,640–4,332m |
| 증폭기 대역 (D-041) | 검증됨 | heavy/light 광석 격차 4.03배. 대역 1.5~20배 |
| 밸런스 시뮬레이터 정직화 | 검증됨 | 하루 86,400초 무제한 자동화 → 실제 8시간 캡×0.75 + 페르소나별 탭 단위 손 채굴. 탭은 `MiningLoop.strike`를 그대로 호출한다 |
| 프레스티지 자격 전환 (D-045) | 검증됨(단위) | `PrestigeTests` 10/10. 집중 크레딧 10,000인 상태가 자격 미달임을 단정 |
| 프레스티지 위치 리셋 (D-046) | 검증됨(단위) | `testPrestigeReturnsToTheSurfaceButKeepsWhatWasOpened`가 위치 0·기록 유지·상한 유지·테마 유지를 확인 |
| 세로 갱도 시야 계산 (D-047) | 검증됨(단위) | `ShaftVisionTests` 5/5. 막장 1개, 지표에서 음수 인덱스 없음, 램프가 시야를 넓히고 상한에서 멈춤, 조도 단조 감소, 지역 진입 표시 |
| 도전과제 클리커 경로 연결 | 검증됨(단위) | `MiningLoop.commit`이 파괴 시 평가·테마 해금. 멱등이므로 중복 지급 없음 |
| iOS 빌드 | 검증됨 | `xcodebuild build -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO` → BUILD SUCCEEDED |
| 오프라인 이중 지급 | 검증됨(단위) | `testOnScreenTicksAreNotPaidAgainAsOfflineTime`. 화면 틱이 정산 시각을 옮기지 않아 화면에서 본 시간이 복귀 시 다시 지급되던 문제 |
| **클리커 진행이 저장되지 않던 문제** | 수정함, 검증 진행 중 | `mineFace`·`deepestSegmentIndex`·`runSegmentsBroken`·`lastSettledAt`이 SwiftData 스키마에 아예 없었다. 앱을 껐다 켜면 지표에서 다시 시작했다. 전체 왕복 테스트가 이 필드들을 기본값으로 두고 있어 잡히지 않았고, 실제 값을 넣도록 고쳤다 |
| `DeepMineAppTests` (단위) | 검증됨 | 131/131. 갱신된 저장 왕복 테스트가 새 클리커 필드를 실제 값으로 비교한다 |
| `DeepMineAppUITests` (UI) | **미검증** | 아래 참조. 사용자 지시로 중단했다 |
| 갱도 화면의 실제 조작 감각 | 미검증(실기기 필요) | 탭 반응성, 층 전환 애니메이션의 체감, 햅틱은 시뮬레이터로 판정 불가 |
| 온보딩 클리커 재작성 | 이후 완료 | D-052와 이 문서의 2026-08-01 clicker-first onboarding 절이 이 중간 상태를 대체한다 |
| 다음 걸음·스트릭의 층 단위 표기 | 미구현 | 여전히 "남은 출정 N회"와 세션 기반 스트릭이다 |

### 당시 UI 스위트를 미검증으로 남긴 이유

`CLAUDE.md`가 요구하는 검증은 `swift test`와 generic iOS 빌드 둘이며 **둘 다 통과했다.**
UI 스위트는 그 위에 얹은 자체 판단이었고, 시간이 과해져 사용자 지시로 중단했다.

중단 시점까지 확인된 것:

| 실행 | 결과 |
|---|---|
| 1차 (갱도 도입 직후, 전체) | 186 통과 / 7 실패 — 전부 프레스티지·테마 픽스처가 자격을 집중 크레딧으로 표현 |
| 2차 (픽스처 층 기준 전환 후, 실패 스위트만) | 14 통과 / 5 실패 — 단정 값 3건과 홈 라우팅 2건 |
| 3차 (스크린샷 스위트) | 4 통과 / 1 실패 — `prestige-losses` 미도달 |
| 4차 (`DeepMineAppTests`만) | **131 통과 / 0 실패** |
| 5차 (`DeepMineAppUITests`) | 중단 |

3차의 실패를 추적한 것이 이번 작업에서 가장 값진 수확이었다. UI 계층 덤프에
`prestige-ineligible`이 찍혀 있었고, 픽스처는 자격을 채우고 있었다. 원인은 픽스처가 아니라
**저장소가 클리커 상태를 아예 저장하지 않는 것**이었다.

이 중간 위험은 후속 마감에서 해소했다. `mine-home-start`를 최대 5회 스크롤한 뒤 hittable을
단정하는 helper로 바꾸고 `ActiveMineUITests` 13건과 홈 캡처 1건을 14/14로 재검증했다.

### 이번에 바꾼 수치

| 상수 | 이전 | 이후 |
|---|---|---|
| `segmentIntegrityGrowthRate` | 1.085 | 1.058 |
| `equipmentLevelUnlockDepthStep` | 60m | 15m |
| `maximumEquipmentLevel` | 60 | 200 |
| `crystalRegionDepth` / `ruinsRegionDepth` / `abyssRegionDepth` | 120 / 480 / 1,200 | 240 / 800 / 1,600 |
| `initialPrestigeTarget` | 집중 크레딧 40 | 부순 암반 120층 |
| `prestigeTargetGrowthRate` | 1.6 | 1.5 |
| `prestigeShardCreditDivisor` → `prestigeShardSegmentDivisor` | 10 | 40 |

## 2026-07-31 playable vertical slice (P2-1)

## 2026-07-31 playable vertical slice (P2-1)

| 항목 | 상태 | 근거 |
|---|---|---|
| 탭→파괴→광석→구매 루프 | 검증됨(단위) | `swift test --package-path DeepMineCore` 167/167. MiningLoopTests 14건이 타격·파괴·광석 적립·심도 전진을 덮는다 |
| 심도의 진실 공급원 전환 (D-040) | 검증됨(단위) | 집중 크레딧 5,000인 플레이어의 심도가 0이고, 세그먼트 30인 플레이어가 120m임을 대조 |
| 피벗 이전 세이브 마이그레이션 | 검증됨(단위) | `mineFace` 키를 제거한 JSON을 디코딩해 옛 심도가 세그먼트로 환산돼 보존되는지 확인 |
| 긴 정산 = 짧은 틱 반복 | 검증됨(단위) | 600초 1회와 1초 600회가 같은 세그먼트·같은 광석에 도달 |
| 밸런스 시뮬레이터 방치 정산 | 검증됨(단위) | 추가 전에는 심도가 오르지 않아 장비 상한이 고정된 상태를 모델링하고 있었다 |
| 가드레일 3등급 정리 (D-042) | 검증됨(단위) | 핀 1개·전제 소멸 4개 제거, 심도 역행 1개 재조준. 불변식·대역 완화 없음, 테스트 수 불변 |
| iOS 빌드 | 검증됨 | `generic/platform=iOS`, `CODE_SIGNING_ALLOWED=NO` |
| 시뮬레이터 전체 스위트 | **미검증** | 아래 사유 참조 |
| 화면 실제 조작 감각 | 미검증(실기기 필요) | 탭 반응성과 햅틱은 시뮬레이터로 판정 불가 |
| 암반 아트 24장 | 검증됨 | ImageGen 원본 24개, 4색 64/128/192 PNG 72개와 imageset 24개. validator, `GameArtCatalogTests` 11/11, generic iOS build 통과 |

### 시뮬레이터 스위트를 검증됨으로 적지 않는 이유

오늘 실행 6회 중 4회가 **테스트를 실행하지 않고 exit 0으로 끝났다.**

| 원인 | 증상 |
|---|---|
| `-destination`을 `name:`으로 지정 | 이 환경의 시뮬레이터명은 `Adelie iPhone 17 Pro iOS 26.5`. 목적지 목록만 출력하고 종료 |
| 동시 실행 (2회) | 같은 시뮬레이터에 두 개가 붙으면 `Executed 0 tests` |
| `-only-testing` 필터 (2회) | 위 동시 실행과 겹쳐 0건 |

**종료 코드가 거짓말을 한다.** 실행 건수를 봐야 한다. `scratchpad/run_suite.sh`에 동시 실행
거부와 실행 건수 100 미만 시 `SUSPECT` 경고를 넣었다.

마지막 유효한 실행에서 확인된 실패 4건은 전부 수정했다.

- 프레스티지 결정체 10 vs 16 — 픽스처가 깊이를 집중 크레딧으로 표현. 세그먼트로 재표현
- 스냅샷 지역 entry vs crystal — 같은 원인
- `mine-home-start` 없음 2건 — **기능 회귀**. 루트를 암반 화면으로 바꾸면서 집중 세션
  진입 경로가 사라졌다. 테스트가 아니라 코드를 고쳤고 증폭기 진입점을 추가했다

수정 후 스위트는 아직 유효하게 완주하지 못했다.

## 2026-07-31 clicker core (P1-1 ~ P1-3)

| 항목 | 상태 | 근거 |
|---|---|---|
| `BigNumber` | 검증됨 | `swift test --package-path DeepMineCore` BigNumberTests 20/20. 정규화·자릿수 초과 덧셈 절단·1.02^40000 지수 344·Double 포화·Codable 왕복 포함 |
| `RockSegment` 생성 | 검증됨 | RockEngineTests 23/23. 동일 인덱스 결정성, 내구도가 광석보다 빠르게 성장하는 밸런스 불변식, 광맥층 주기, 약점 좌표가 실루엣 안에 유지 |
| `RockEngine` 넘침 이월 | 검증됨 | 큰 데미지가 여러 세그먼트를 연속 파괴하고 광석 합계가 실제 파괴 세그먼트와 일치. 상한 초과 시 `wasTruncated` 보고 |
| `StrikeEngine` 탭·크리티컬 | 검증됨 | StrikeEngineTests 23/23. 크리티컬 발생률을 20,000회 시뮬레이션으로 설정값과 대조(오차 2% 이내), 동일 시드 결정성 50회 |
| 자동화 데미지 | 검증됨 | 수레 기본 레벨 0 산출, 첫 업그레이드에서 켜짐, 경과 시간 비례. 수레 15레벨 8시간이 실제로 세그먼트 10개 이상 파괴 |
| 아트 교체 레이어 | 검증됨 | `GameArtCatalogTests`. 24 슬롯 이름·프롬프트 ID 고유성, 슬롯↔`docs/ROCK_ART_PROMPTS.md` 양방향 대조, 설치 자산 우선·미설치 이름의 플레이스홀더 폴백 |
| 암반 아트 24장 | 검증됨 | `scripts/process_rock_assets.py --validate-only`: 24 고유 원본, 24 imageset/72 PNG, 네 안료, 이진 알파·불투명 정책, 64/128/192 치수 통과. `GameArtCatalogTests` 11/11과 generic iOS build 통과 |
| 클리커 플레이 가능 여부 | 미구현 | P1은 엔진뿐이고 UI에 연결되지 않았다. 탭할 수 있게 되는 것은 P2-1 |
| 밸런스 CLI 재조준 | 미구현 | 기존 CLI는 집중 세션 기준으로 시뮬레이션한다. 데미지 입력이 UI에 연결된 뒤 재조준 |

**주의**: `-destination 'platform=iOS Simulator,name=iPhone 17 Pro'`는 이 환경의 시뮬레이터
이름과 일치하지 않아 xcodebuild가 테스트를 실행하지 않고 **exit 0으로 종료**했다. 목적지는
`id=`로 지정해야 한다. 종료 코드만 보고 통과로 판단하면 안 되는 사례다.

## 2026-07-31 complete game-art set

| 항목 | 상태 | 근거 |
|---|---|---|
| 게임 아트 원본 | 검증됨 | 내장 ImageGen으로 40개 고유 PNG 원본 생성. 매니페스트의 raw SHA 40개가 모두 고유 |
| 후처리 계약 | 검증됨 | `process_game_assets.py --validate-only`: 40 imageset, 120 PNG, 정확한 네 안료, 브라스 10% 미만, 선언 크기와 알파·Contents.json 통과 |
| 앱·시스템 표면 배선 | 검증됨(빌드) | 광맥 5, 장비 9, 테마 4, 장식 4, 광부 2, DI 4, StandBy 4, 자원 3, 영구 강화 3, 온보딩 2를 app/widget asset consumer와 함께 generic iOS build |
| ID fallback·장비 티어 | 검증됨(단위) | plan/region/vein unknown fallback과 레벨 1/20/21/40/41/60·범위 밖 clamp, focused Xcode 12/12 |
| 화면 증거 | 검증됨(시뮬레이터) | `GameSurfaceScreenshotTests` 5/5, PNG 19장과 contact sheet를 `artifacts/imagegen/game-assets-v1/ui-captures/`에 내보냄 |
| Dynamic Island·StandBy Night Mode | 미검증(실기기 필요) | 시뮬레이터 fixture와 safe-zone overlay는 확인. 실제 SpringBoard crop·적색 단색 가독성은 물리 기기 게이트 |

## 2026-07-31 system surface and ore payoff

| 항목 | 상태 | 근거 |
|---|---|---|
| iPhone 잠금화면 정렬 | 검증됨(시뮬레이터) | `ActivityFamily.medium`을 StandBy로 오인하던 분기를 `isActivityFullscreen` 역할 판정으로 교체. 160pt UI 회귀와 fixture 육안 확인 |
| AlarmKit Live Activity 계약 | 검증됨(빌드·단위) | `AlarmAttributes<DeepMineAlarmMetadata>`용 `ActivityConfiguration`을 Widget bundle에 등록하고 countdown/alert 투영 및 4KB 미만 왕복 검사 |
| 실제 Dynamic Island 표시 | 미검증(실기기 필요) | 활성 세션은 AlarmKit countdown 하나가 소유하고, 커스텀 Activity는 AlarmKit 실패 또는 귀환 완료 표면에만 사용. 실제 SpringBoard 표시는 물리 기기 게이트 |
| 귀환 광석 적재 연출 | 검증됨(시뮬레이터) | 획득량에 따라 3–9개 광석이 광차에 적재되고 완료 햅틱이 낙하→광차 충돌 리듬으로 변경. Reduce Motion은 최종 상태로 즉시 표시 |
| 광석 적재 햅틱 체감 | 미검증(실기기 필요) | CoreHaptics 패턴과 UIKit 성공 폴백은 테스트됨. 실제 강도·스피커 조합은 물리 기기에서 확인 필요 |

## Result

도전과제 35종에 이어 나머지 게임 아트 40종도 생성·양자화·Asset Catalog 편입을 완료했다.
홈과 진행 화면, 온보딩, 귀환, 프레스티지, Dynamic Island/StandBy fixture에서 실제로
렌더링한다. 정적 자산 계약·컴파일·시뮬레이터 화면은 검증됐고 실제 시스템 표면은 별도다.

| 항목 | 상태 | 최신 근거 |
|---|---|---|
| XcodeGen | 검증됨 | `xcodegen generate --spec project.yml` 성공 |
| Core | 검증됨 | SwiftPM 101/101, 실패 0 |
| 앱 전체 suite | 검증됨 | iPhone 17 Pro iOS 26.5에서 182/182, 실패·skip 0 |
| 도전과제 배지 자산 | 검증됨 | 35 ID 일치, 35 imageset/105 PNG, 정확한 4색, 불투명 RGB, 48/96/144 치수 |
| 도전과제 집중 회귀 | 검증됨 | `RetentionSurfaceTests` 7/7, 실패 0 |
| 도전과제 배지 앱 빌드 | 검증됨 | 새 Asset Catalog를 포함한 generic iOS code-signing-disabled build 성공 |
| 복리 장비 곡선 | 검증됨 | 레벨 1/10/25/59에서 상대 이득이 항상 1.12배임을 회귀 테스트 |
| 심도 역전 방지 | 검증됨 | 180일 시뮬레이션에서 집중이 많은 페르소나가 더 얕지 않음 |
| 사다리 잔존 | 검증됨 | 180일에 네 페르소나 모두 드릴 상한 미달 |
| 심도 해금 상한 | 검증됨 | `maximumEquipmentLevel(forDepth:)` 경계와 `depthLocked` 구매 결과 |
| 기억 재구매 할인 | 검증됨 | 최고 레벨 이하 50%, 초과 정가 회귀 테스트 |
| 스트릭 감쇠 1회 | 검증됨 | 2일 결석 시 7→3, 결석일당 누적 아님 |
| generic iOS build | 검증됨 | `generic/platform=iOS`, `CODE_SIGNING_ALLOWED=NO` 성공 |
| Swift 파일 크기 | 부분 검증 | 15개 파일 분리. `DeepMineLocalization.swift`만 309줄로 9줄 초과 — enum case는 extension으로 분리할 수 없고 두 enum으로 쪼개면 현지화 parity 계약과 모든 호출부가 깨진다. 로직 없는 키 목록이라 초과 상태로 둔다 |
| 시계 소스 교체 | 미검증(실기기 필요) | 코드는 `CLOCK_MONOTONIC_RAW`로 교체. 실제 슬립 구간 drift는 기기에서만 확인 가능 |
| Live Activity intent 즉시 적용 | 미검증(실기기 필요) | 앱 프로세스 등록·drain 경로는 구현. 실제 백그라운드 intent 실행은 기기 게이트 |
| 화면 증거 19장 | 검증됨 | 새 게임 아트를 포함한 19장과 contact sheet를 `artifacts/imagegen/game-assets-v1/ui-captures/`에 fresh export |
| StoreKit/서버/소셜 | 미구현 | 현재 게임 범위에서 명시적으로 제외 |
| 물리 기기 시스템 통합 | 미검증 | `docs/DEFECTS.md`의 GATE-001~006 |

## Fresh commands

```sh
xcodegen generate --spec project.yml
python3 scripts/process_achievement_badges.py \
  --manifest artifacts/imagegen/achievement-badges-v1/sources.json \
  --catalog DeepMineProbe/Shared/SharedAssets.xcassets \
  --contact-sheet artifacts/imagegen/achievement-badges-v1/contact-sheet.png \
  --report artifacts/imagegen/achievement-badges-v1/verification.json
/Users/tofu/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  scripts/process_game_assets.py --validate-only
swift test --package-path DeepMineCore
xcodebuild test -quiet -project DeepMine.xcodeproj -scheme DeepMineApp \
  -destination 'platform=iOS Simulator,id=64C7804C-355B-4444-90EE-C8ED0D9355CF' \
  -derivedDataPath /tmp/DMTestAchievementBadges \
  -only-testing:DeepMineAppTests/RetentionSurfaceTests CODE_SIGNING_ALLOWED=NO
swift run --package-path DeepMineCore DeepMineBalanceCLI --seed 260729 --days 180 \
  --output /tmp/deepmine-balance.csv
xcodebuild build-for-testing -quiet \
  -project DeepMine.xcodeproj -scheme DeepMineApp \
  -destination 'platform=iOS Simulator,id=64C7804C-355B-4444-90EE-C8ED0D9355CF' \
  -derivedDataPath /tmp/DMTest CODE_SIGNING_ALLOWED=NO
xcodebuild test-without-building -quiet \
  -project DeepMine.xcodeproj -scheme DeepMineApp \
  -destination 'platform=iOS Simulator,id=64C7804C-355B-4444-90EE-C8ED0D9355CF' \
  -derivedDataPath /tmp/DMTest -resultBundlePath /tmp/DMResultFinal.xcresult \
  CODE_SIGNING_ALLOWED=NO
xcodebuild build -quiet \
  -project DeepMine.xcodeproj -scheme DeepMineApp \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/DMGeneric CODE_SIGNING_ALLOWED=NO
```

## Simulator suite

최종 `/tmp/DMShip.xcresult` 요약은 `result: Passed`, `passedTests: 182`, `failedTests: 0`,
`skippedTests: 0`이다. 경제 수정 단계는 175/175, 리텐션 단계는 180/180이었고 플레이 경험
작업의 테스트가 더해져 182가 되었다. Core는 별도 SwiftPM 실행에서 101/101이다. 경제 수정만 반영한 중간
게이트는 175/175였고, 리텐션 기능과 그 테스트 5개가 더해져 180이 되었다.

리텐션 기능을 얹은 첫 실행에서 3건이 실패했고 모두 코드·계약 문제였다. 프레스티지가
도전과제를 평가하게 되어 fixture가 이미 충족한 항목이 소급 지급된 것(의도된 동작, 단정값
갱신), 홈의 단일 약속 문장이 세 걸음으로 바뀌어 UI 테스트의 식별자가 사라진 것, 그리고
`rewardProjection`이 렌더링 중 저장소를 다시 읽어 복구 fixture의 실패 예산을 먼저 소진한
것이다. 마지막 항목은 `rewardProjection(for:)` 오버로드를 추가해 렌더링 경로에서 저장소
읽기를 제거했다.

직전 실행은 174/175였고 유일한 실패는 `GameSurfaceScreenshotTests`의 캡처 대기 5초가 전체
suite 부하에서 타임아웃한 것이었다. 단독 실행에서는 42초로 통과했으므로 결함이 아니라 스케줄
지연이며, 캡처 하네스의 대기를 15초로 올려 해소했다.

그 전 실행에서 나온 실제 회귀 2건은 코드로 수정했다. 홈의 추천 강화를 computed property로
둔 탓에 `body` 평가마다 저장소를 다시 읽었고(낭비되는 I/O이자 복구 fixture의 실패 예산을
먼저 소진), `recommendedUpgrade(for:)` 오버로드와 `@State` 캐시로 렌더링 중 읽기를 없앴다.
나머지 1건은 UI 테스트가 제거된 `equipment-task14-handoff` 식별자를 참조한 것이다.

## Retention systems verification

| 항목 | 상태 | 근거 |
|---|---|---|
| 도전과제 보상 정책 | 검증됨 | `AchievementReward`에 생산력 케이스가 없고, 수정 지급 상한과 지표 화이트리스트를 회귀 테스트 |
| 도전과제 멱등성 | 검증됨 | 재평가 시 재지급 없음, 이미 보유한 외형은 대체 지급 없이 nil |
| 저장 호환 | 검증됨 | `earnedAchievementIDs` 없는 이전 저장이 빈 집합으로 디코드 |
| 프레스티지 보존 | 검증됨 | 달성 기록이 프레스티지에서 유지 |
| 광부 파생 | 검증됨 | 5레벨 단위 증가, 12명 상한, 보상식에 광부 항이 없음을 배율 비교로 확인 |
| 다음 세 걸음 | 검증됨 | 근거리 우선 정렬, 3개 상한, 추정 불가 시 숫자 생성 안 함 |
| 성장 곡선 | 검증됨 | 노력과 성장 분리, 기록 1주면 배율 withhold, 포기 세션 제외 |
| 광맥 도감 | 검증됨 | 발견 횟수 집계와 최초 발견일 최소값, 미발견 5종 표시 |

## Play experience verification

| 항목 | 상태 | 근거 |
|---|---|---|
| 이벤트별 햅틱 구분 | 검증됨 | 9종 모두 transient 비어 있지 않고 폴백 존재. 갱도 문과 광맥의 강도·예리도 대비를 회귀 테스트 |
| 피드백 설정 반영 | 검증됨 | 햅틱·사운드 개별 비활성 시 재생 0 |
| 귀환 보상 1회 재생 | 검증됨 | 재실행 시 재생 안 함 (기존 receipt 계약 유지) |
| 연습 채굴 10초 | 검증됨 | `beginOrResumeDemo().remainingSeconds`가 `demoDurationSeconds`와 일치 |
| 연습 광맥 확정 | 검증됨 | 수정 1개가 실제 지급되고 집중 진행에는 반영 안 됨 |
| 카운트업·레일 애니메이션 | 미검증(시각) | Reduce Motion 분기는 코드로 존재. 실제 모션 체감은 실기기 게이트 |
| 광부 작업 루프 | 미검증(시각) | 붕괴 시 정지 분기 존재. 모션 체감은 실기기 게이트 |
| 커스텀 오디오 자산 | **미구현** | 시스템 사운드 ID를 이벤트별로 배정한 상태. 8-bit SFX 저작은 별도 작업이며 `GameFeedbackEvent.systemSoundID`가 교체 지점 |

## Balance verification

30/90/180일 시뮬레이션 결과와 판정은 `docs/BALANCE_REPORT.md`에 있다. 요약:

- 첫 강화 1세션, 스탠다드 첫 프레스티지 10일 — 이전과 동일
- 심도가 집중량에 대해 단조. 동일 집중은 심연 광맥 보너스 차이 내에서 동일 심도
- 180일에 라이트 드릴 23 / 스탠다드 28 / 헤비 21(직전 프레스티지) — 상한 60 미달
- 30일 헤비/라이트 광석 격차 60.29배. 가드레일을 25배에서 80배로 재설정 (D-026)
- 집중 크레딧 격차 10.0배, 심도 격차 14.64배 — 플레이 양 지표는 기존 기준 유지

## Fresh visual evidence

새 19장 PNG와 contact sheet는
`artifacts/imagegen/game-assets-v1/ui-captures/`에 있다. 기존
`artifacts/ui/game-mvp-v1/`은 역사적 baseline으로만 유지한다.

## Physical-device release gates

`docs/DEFECTS.md`의 GATE-001~006이 그대로 유효하다. 이번 변경으로 다음 항목의 중요도가
올라갔다.

- Live Activity intent가 백그라운드 앱 프로세스에서 실제로 명령을 적용하는지 (D-027)
- 화면이 꺼진 실제 세션에서 `CLOCK_MONOTONIC_RAW` drift가 임계 안에 있는지
- 포기 버튼이 잠금화면에서 실제로 차단을 즉시 해제하는지
