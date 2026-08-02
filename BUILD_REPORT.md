# Build Report

업데이트: 2026-08-02 (현재 코드·PR·Pro 교차 감사 closeout)

## 2026-08-02 current-audit closeout

**판정: 계획 전체 완료가 아니다.** 이번 closeout은 single-clock, 장시간 정산, 첫 자동화
저축, 주요 `BigNumber` 구매 표면, 생산률/구매·정련 피드백, 장기 지질/에셋과 Pages 로컬
계약을 구현·검증했다. 실제 UI 정책 장기 시뮬레이션, 집중 경제 통합, 정련 재설치,
`NextStepPlanner` 극후반 진행도, Lv.100,000 산술 안전 천장 이후 성장, 전체 UI/실기기/원격
배포 게이트는 열린 상태다.

| 항목 | 현재 결과 | 근거/경계 |
|---|---|---|
| Core 전체 | **282/282 통과** | `swift test --package-path DeepMineCore`, 실패 0. 150/500km 정산, exponent 383 구매 표면, 정련 preview 포함 |
| App 단위 전체 | **150/150 통과** | 전용 iPhone 17 Pro / iOS 26.5 시뮬레이터, 실패·skip 0. xcresult `/tmp/deepmine-current-audit-tests/Logs/Test/Test-DeepMineApp-2026.08.02_23-33-56-+0900.xcresult` |
| 저장 경로 집중 회귀 | **9/9 통과** | 직접 재열기, 레거시 빈 필드, 원자적 명령, 세션 종료가 기억 장비·정련·업적을 보존 |
| 최종 persistence/명령 큐 회귀 | **23/23 통과** | 원자적 명령 책임 분리와 테스트 재배치 뒤 세션 저장까지 포함해 실패·skip 0. xcresult `/tmp/deepmine-current-audit-tests/Logs/Test/Test-DeepMineApp-2026.08.02_23-55-35-+0900.xcresult` |
| 정련 실화면 | **1/1 통과** | `testRefinementExplainsTierLeapAndActualOutputImpact`; R0→R1 저장, 전용 notice, 실제 출력 변화. xcresult `/tmp/deepmine-growth-feedback-tests/Logs/Test/Test-DeepMineApp-2026.08.02_23-32-49-+0900.xcresult` |
| 생산/정련 계산 집중 회귀 | **17/17 통과** | `WorkFaceForecastTests`; 잠긴 행은 최소 해금 레벨 preview, 램프는 실제 총 치명타 배율 비율 |
| generic iOS device build | **통과** | code signing 비활성 build exit 0. 기존 `OfflineSettlement.swift`·`ShaftView.swift`의 unused `try?` warning은 남음 |
| 웹 | **15/15 통과** | `npm test`가 production build와 패리티/계약을 실행, `npm run lint` 통과. 웹은 JavaScript `number` formula harness이며 앱의 `BigNumber` 범위 증거가 아님 |
| 정적 Pages 로컬 계약 | **11/11 통과** | 정적 페이지 DOM 로직과 첫 광차 저축 readout, workflow bundle/module smoke 확인. PR은 build만, main push만 deploy |
| 장기 진행 에셋 | **7/7 통과** | strict PNG/SHA/정확한 ID 집합/카탈로그/웹 복사본과 provenance ID·raw-source 대응 검사 |
| Swift 파일 크기 | **통과** | 이번 변경 파일은 모두 300줄 이하. 기존 baseline `GameActivitySurfaceContent.swift` 302줄만 남음 |
| 웹 개발 서버 | **HTTP 200** | `http://127.0.0.1:4173`. 첫 로컬 이동 실패 뒤 인앱 Browser 보안 정책이 재시도를 막아 최종 화면 육안 판독은 수행하지 못함 |
| 원격/실기기 | **미검증** | push 전 GitHub Actions/Pages, FamilyControls·AlarmKit·Live Activity, 실제 VoiceOver/Reduce Motion/햅틱은 출시 차단 게이트 |

## Historical verification log

아래 날짜별 표는 해당 단계에서 사실이었던 기록이다. `Double` 지갑, 정련 UI 미구현,
6,144 총상한, D-056~D-060 앱 미포팅 같은 판정은 위 current-audit closeout이 대체하며
현재 상태로 읽지 않는다.

## 2026-08-02 ore capacity and the 180-day inversion

| 항목 | 상태 | 근거 |
|---|---|---|
| 광석 `Double` 한계 실측 | 검증됨 | 포화는 세그먼트 10,470 = **41,881m**. 180일 헤비 도달점(5,640m)의 7배이며 같은 속도로 3.7년 연속 플레이에 해당한다. 상대 정밀도는 전 구간 ~1e-16으로 일정 |
| 한계의 테스트 고정 | 검증됨 | `OreCapacityTests` 4/4. 헤드룸, 상대 정밀도, 포화 시 클램프, 클램프 상태의 구매 성립을 검사한다. 곡선이 가팔라지면 실패한다 |
| `BigNumber` 마이그레이션 | 미실행(판단) | 저장 스키마와 25개 호출부를 바꾸는 위험만 있고 현재 곡선에서 실익이 없다. 근거는 위 실측 |
| 180일 역전 분해 | 검증됨 | 시뮬레이터에 `--prestige immediate\|never` 추가. 프레스티지를 꺼도 역전이 남는다(0.406 → 0.483배) |
| 실제 원인 | 검증됨(CSV) | 일별 획득 광석이 시간이 지나도 늘지 않고 불규칙은 90일 이후 **0**이다. 심도는 깊어지는데 생산이 멈춘다 |
| 구조적 원인 | 검증됨(계산) | 레벨 200이 심도 2,925m에서 전부 해금되어 데미지 성장이 끝나는 반면 내구는 계속 `1.058^n`으로 자란다. D-044가 고친 60레벨 벽과 같은 종류가 더 깊은 곳에 남아 있다 |
| 수치 변경 | 미실행 | 상한 이후의 성장 축 선택은 사양 결정이다. 선택지 3종을 `docs/BALANCE_REPORT.md`에 정리 |
| Core 회귀 | 검증됨 | `swift test --package-path DeepMineCore` → **242/242**, 실패 0 |


## 2026-08-02 truncated-resolution fix and infrastructure parity

| 항목 | 상태 | 근거 |
|---|---|---|
| 절단 손실 결함 | 검증됨 | `RockEngine.resolve`가 512세그먼트에서 멈추면 남은 데미지를 버렸다. 잔여를 `unspentDamage`로 전달하고 `MiningLoop.advance`가 최대 12패스까지 재적용한다. 같은 총 데미지를 한 번에 넣은 경우와 16회로 나눈 경우의 도달 세그먼트 차이가 2 이하임을 테스트로 고정 |
| 재적용 종료 보장 | 검증됨 | 상한을 넘는 입력(드릴·광차 200, 8시간)에서도 `segmentsBroken ≤ 512 × 12`로 끝난다 |
| 합산 보고 | 검증됨 | 여러 패스를 하나의 `MineFaceUpdate`로 합쳐, 한 틱이 실제로 만든 광석·세그먼트를 보고한다. `update.face.segmentIndex`가 커밋된 상태와 일치함을 확인 |
| 설비 파생 패리티 | 검증됨 | 웹 설비 함수 4종을 `coreBalance.ts`로 옮기고 상한 6개를 상수 대조에 추가. 프로토타입이 같은 이름의 로컬 함수를 다시 만들면 실패하는 `doesNotMatch`도 걸었다 |
| Core 회귀 | 검증됨 | `swift test --package-path DeepMineCore` → **238/238**, 실패 0 (232 + 절단 6) |
| 웹 회귀 | 검증됨 | `npm run lint` 통과, `npm test` → **12/12**(패리티 4 + 계약 8) |
| 웹 브라우저 확인 | 검증됨 | Core 파생으로 작업조 1·광차 1·조명 1을 표시하고 console error 0 |
| 앱 회귀 | 검증됨 | `xcodebuild test -only-testing:DeepMineAppTests -only-testing:DeepMineAppUITests/OnboardingHomeUITests` → **142/142**, 실패·skip 0 |
| generic iOS build | 검증됨 | `CODE_SIGNING_ALLOWED=NO build` → exit 0, error 0 |


## 2026-08-02 porting D-059 and D-060 into the app

| 항목 | 상태 | 근거 |
|---|---|---|
| 설비 파생의 단일화 | 검증됨 | `MineInfrastructureEngine`이 작업조 1~4, 광차 0~4, 적재 0~3, 작업등 1~5를 장비 레벨·분기에서 파생한다. 7건으로 상한, 분기 가산, 레벨 상승 시 축소 없음, 광차 레벨 1에서 0대를 고정 |
| 광차 가시성 결함 수정 | 검증됨(코드) | 앱 광차 수가 `visualTier` 기반이라 5·15레벨에서만 늘었다. 그 사이의 모든 광차 구매가 갱도에서 보이지 않았다. Core 파생으로 교체해 레벨 두 칸마다 한 대씩 는다 |
| 작업조 데크 | 검증됨(시뮬레이터) | 통로에 떠 있던 작업조에 발밑 데크를 붙였다. 조정 전/후 캡처로 확인 |
| 면 단위 충격 | 검증됨(코드·빌드) | 접촉 시 암반 폭 76/84/92%(quick/heavy/critical)의 압축대·타원 충격파·좌우 분기 균열을 `StrikeTimeline`의 같은 접촉 시점에 그린다. 72ms 창이라 정지 캡처로는 잡히지 않았다 |
| 내실 판독 | 검증됨(코드) | 갱도 접근성 이름이 작업조·광차·작업등 수를 말한다 |
| Core 회귀 | 검증됨 | `swift test --package-path DeepMineCore` → **232/232**, 실패 0 (225 + 설비 7) |
| 앱 회귀 | 검증됨 | `xcodebuild test -only-testing:DeepMineAppTests -only-testing:DeepMineAppUITests/OnboardingHomeUITests` → **142/142**, 실패·skip 0 |
| generic iOS build | 검증됨 | `CODE_SIGNING_ALLOWED=NO build` → exit 0, error 0 |
| 파일 크기 | 검증됨 | 300줄 초과는 기존 `GameActivitySurfaceContent.swift`(302줄) 1건뿐이며 이번 변경과 무관하다 |
| 웹 정렬 | 미완 | 웹의 설비 파생 함수는 값이 Core와 같지만 아직 `coreBalance.ts`에 없다. 패리티 계약이 없으므로 드리프트가 다시 열릴 수 있다 (D-065) |


## 2026-08-02 porting D-056, D-057 and D-058 into the app

| 항목 | 상태 | 근거 |
|---|---|---|
| Core 회귀 | 검증됨 | `swift test --package-path DeepMineCore` → **225/225**, 실패 0. 이번 단계에서 30건 추가(`StrikeTimelineTests` 10, `WorkFaceForecastTests` 7, `ResonanceNodeTests` 13) |
| D-056 예보 계산 | 검증됨 | `MiningLoop.forecast(for:)`가 예상 광석·남은 내구·자동 ETA·남은 탭 수를 만든다. 광차 1레벨에서 ETA가 `nil`이고, 첫 암반이 정확히 10탭임을 테스트로 고정 |
| D-056 앱 화면 | 검증됨(시뮬레이터) | 신규 홈에서 `현재 암반 / 파쇄 시 ◆4`와 `광차를 사면 탭 없이 굴착합니다 / 9탭 남음`을 확인. 갱도와 강화 버튼 사이에 위치 |
| D-057 상태 기계 | 검증됨 | 첫 출현 5.2초, 이후 120~300초 무작위, 12초 창, 놓침 무보상, 백그라운드 미출현·미기록·부스트 유지, 창 밖 수령 무효를 13건으로 검사 |
| D-057 부스트 적용 | 검증됨 | `StrikePower.scaled(by:)`가 탭·자동 데미지만 2배로 하고 크리티컬 확률·배율은 그대로 둔다. 부스트된 자동화가 실제로 암반을 더 깎는지 테스트로 확인 |
| D-057 앱 동작 | 검증됨(시뮬레이터) | 실행 9초 뒤 갱도 우측에 결절이 출현하고, 실제 포인터 탭으로 수령한 뒤 심도가 0m→28m로 급증했다. 부스트가 자동 굴착에 실제로 반영된다 |
| D-058 스윙 시계 분리 | 검증됨 | 자동화의 0.25초 스텝 3주기 동안 스윙이 정확히 3회만 시작됨을 테스트로 고정. 이전에는 스텝마다 재시작돼 광부가 예비동작 프레임에 얼어붙었다 |
| D-058 앱 동작 | 검증됨(시뮬레이터) | 자동 굴착 중 연속 캡처 6장에서 ready → anticipation → **contact** → 복귀가 실제로 재생됨을 확인 |
| 앱 회귀 | 검증됨 | `xcodebuild test -only-testing:DeepMineAppTests -only-testing:DeepMineAppUITests/OnboardingHomeUITests` → **142/142**(유닛 134 + UI 8), 실패·skip 0 |
| generic iOS build | 검증됨 | `xcodebuild -quiet -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` → exit 0, error 0 |
| 웹 회귀 | 검증됨 | `npm test` → **11/11**. `Balance`에 타격 타임라인·공명 결절 상수를 추가했지만 웹이 쓰는 상수는 그대로여서 패리티가 유지된다 |
| 파일 크기 | 검증됨 | `ShaftView.swift` 308줄 초과분을 `ShaftView+Overlays.swift`로 분리해 전 파일 300줄 이하 유지 |
| D-059·D-060 | 미구현 | 설비 누적과 면 단위 충격은 여전히 웹에만 있다. 앱에는 D-051의 장비→장면 연결이 있어 두 단계는 그 위의 체급·수량 강화다 |
| 실기기 | 미검증(실기기 필요) | 햅틱, VoiceOver, Reduce Motion 실제 감각 |

## 2026-08-01 core balance parity and the D-055 app port

## 2026-08-01 core balance parity and the D-055 app port

| 항목 | 상태 | 근거 |
|---|---|---|
| 스테일 테스트 수정 | 검증됨 | `DesignSystemContractTests.testEquipmentArtTierBoundariesClampToShippedRange`가 피벗 이전 경계(20/40)를 기대해 실패하던 것을 `EquipmentEngine.visualTier`의 4/14로 교체. 수정 전 133/1 실패 → 수정 후 **134/134** |
| 전체 `DeepMineAppTests` | 검증됨 | `xcodebuild test -only-testing:DeepMineAppTests -destination 'platform=iOS Simulator,id=64C7804C…'` → **134 통과 / 0 실패 / 0 skip**. 이 변경 전체를 포함한 최종 코드로 재실행한 결과다. 이전 문서의 "미검증(`Mach error -308`)" 기록은 실측으로 대체했다. 스위트는 정상 완주하며, 환경 문제로 분류된 구간이 스테일 테스트 1건을 가리고 있었다 |
| 웹 경제의 Core 정렬 | 검증됨(브라우저·코드) | `web/app/coreBalance.ts`가 Swift `Balance` 상수를 그대로 담고, 프로토타입이 자체 수치를 쓰지 않는다. 브라우저 첫 화면에서 탭 1, 자동 0.6/초(0.56), 드릴 강화 ◆100, 광차 ◆242, 램프 ◆200, 급소 5%, 파쇄 보상 ◆4.6을 확인 |
| 패리티 테스트 실효성 | 검증됨 | `SEGMENT_INTEGRITY_GROWTH_RATE`를 1.058→1.06으로 변조하자 `must equal Balance.segmentIntegrityGrowthRate`로 실패하고, 복구 후 3/3 통과. 상수를 문자열이 아니라 Swift 소스에서 파싱해 대조한다 |
| 웹 검사 | 검증됨 | `npm run lint`, `npm test` → **11/11**(패리티 3 + 기존 계약 8), vinext production build 통과 |
| Core 회귀 | 검증됨 | `swift test --package-path DeepMineCore` → **201/201**, 실패 0 (기존 195 + `StrikeTimelineTests` 6) |
| 타격 타임라인 계약 | 검증됨 | quick/heavy/critical의 duration·contact를 `Balance`로 옮기고 `StrikeTimeline`이 소비. 접촉 순간의 프레임이 반드시 접촉 프레임(index 2)임을 세 변주 모두에서 검사 |
| 에셋 편입 | 검증됨 | `scripts/process_web_gamefeel_assets.py` → `Validated 2 web game-feel assets`. `MinerMiningStrip`·`ShaftFrontierLip`의 1x/2x/3x imageset 생성, 네 안료·이진 알파·1x SHA 일치 검사 포함 |
| 아트 카탈로그 계약 | 검증됨 | `GameArtCatalogTests` **12/12**. 갱도 슬롯 11→13, 프롬프트 문서 대응, `missingEntries.isEmpty`(실제 설치 확인) 포함 |
| generic iOS build | 검증됨 | `xcodebuild -quiet -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` → exit 0, error 0 |
| 앱 갱도 육안 | 검증됨(시뮬레이터) | iPhone 17 Pro / iOS 26.5 한국어 다크에서 `ShaftFrontierLip`의 좌우 어깨가 통로와 암반을 잇고, 광부·양손·곡괭이가 한 액터로 지반 위에 선다. `artifacts/imagegen/web-gamefeel-v1/ui-captures/` |
| 간트리 간섭 수정 | 검증됨(시뮬레이터) | 124pt 간트리가 액터의 머리를 가로지르던 것을 44pt 상부 지지대로 축소. 조정 전/후 캡처로 확인 |
| 액터 탭 표적 제외 | 검증됨(코드) | 92pt 액터는 지반 버튼 위를 덮으므로 `allowsHitTesting(false)`로 뺐다. 광부에 떨어진 탭은 플레이어가 암반을 노린 탭이다. 아래 온보딩 실패의 원인은 아니었다 |
| 온보딩 데모 갱도 클리핑 | 검증됨(시뮬레이터) | `testFreshLaunchStartsOnTheBreakableRockAndPersistsTheReward` 실패를 추적한 결과, 온보딩 카드가 씬을 고정 오프셋 48로 그려 0m의 24m 지표 inset 아래에 있는 작업면이 카드 밖으로 밀려 있었다. 암반은 바닥에 잘린 조각으로만 보이고, 카드 중심(= XCUITest가 실제로 탭하는 지점)은 빈 갱도였다. 헤드를 따라가도록 오프셋을 계산하고 카드를 250pt로 키워 해소. 조정 전/후 캡처 보존 |
| PIL 호환 | 참고 | 에셋 스크립트가 이 머신에 없는 `get_flattened_data()`를 쓰고 있어 실행 중이던 `process_web_gamefeel_assets.py`만 표준 `getdata()`로 교체했다. `process_shaft_assets.py`·`process_rock_assets.py`는 같은 문제가 남아 있고 이번 변경 범위 밖이다 |
| `OnboardingHomeUITests` | 검증됨 | 클리핑 수정 전 7/8(같은 케이스가 두 번 실패) → 수정 후 **8/8**, 실패·skip 0. `TASKS.md`에 미완으로 남아 있던 "첫 암반을 실제로 끝까지 탭해 보상까지" 경로가 이제 실제로 통과한다 |
| D-056~D-060 앱 포팅 | 미구현 | 첫 뷰포트 행동대, 공명 결절, 타격 변주, 설비 누적, 면 단위 충격은 여전히 웹에만 있다. 공명 결절은 Core에 대응 개념이 없어 엔진 확장이 선행 조건 |
| 실기기 | 미검증(실기기 필요) | 햅틱 체감, VoiceOver 초점, Reduce Motion 실제 감각 |

## 2026-08-01 web full-face strike and structural infrastructure

| 항목 | 상태 | 근거 |
|---|---|---|
| 전신 공격 체급 | 검증됨(브라우저·코드) | 주 광부를 128→152px로 확대하고 quick/heavy/critical 접촉 변위를 강화. 준비→접촉 프레임에서 몸통·무릎·양손과 곡괭이가 함께 내려옴 |
| 암반 면 반응 | 검증됨(브라우저·DOM) | 접촉 섬광 22→36px, 충격 압축대·타원파·좌우 분기 균열·분진을 quick 76%, heavy 84%, critical 92% 폭으로 확장. `data-impact-coverage=wide` 확인 |
| 내실 단계 | 검증됨(브라우저·DOM) | 새 로드 `내실 1단계 · 작업조1 · 광차2 · 조명2`. 드릴 또는 광차 강화 뒤 내실 2단계·작업 데크 1→2층과 지지대·보급 상자가 함께 증가 |
| 운송 구조 증설 | 검증됨(브라우저·DOM) | 광차 Lv.6 구매 뒤 광차 2→3대, 적재 2→3칸, 레일 28→66px 복선, 광차 x좌표 599/635px 좌우 차선 분리 확인 |
| 광원·작업조 체급 | 검증됨(코드·브라우저) | 작업조 29→42px 전신과 통로 폭 188~195px 데크, 램프 19→28px 설치물과 92px 광원 구역으로 확대 |
| 데스크톱 | 검증됨(1280×720) | 초기·내실 2단계·광차 3대 장면에서 scrollY 0, documentWidth 1280, 첫 화면 행동대 유지·가로 넘침 없음 |
| 모바일 | 검증됨(390×844) | 광부 152px, 충격 면 276.6px/갱도 366px. documentWidth 390, scrollY 0, 갱도 bottom 797.6px, 행동대 bottom 791.6px |
| 접근성·Reduce Motion | 검증됨(코드·계약) | 갱도 이름에 내실 단계·작업조·광차·조명 수를 포함하고 `data-infrastructure-tier` 노출. Reduce Motion은 넓은 이동 충격파를 숨기고 포즈·균열·데크·복선·광원 최종 구조 유지 |
| 브라우저 로그 | 검증됨 | 데스크톱·모바일 reload, 타격, 드릴/광차 구매 뒤 warning/error 0. Vite debug와 React 개발 안내 info만 존재 |
| 개발 HMR | 참고 | 소스 편집 중 여러 테스트 탭을 동시에 reload할 때 vinext 서버가 React `multiple renderers` 경고를 출력. 최종 새 탭 warning/error 0과 production build 통과로 제품 런타임 회귀는 재현되지 않음 |
| 웹 검사 | 검증됨 | `git diff --check`, lint, vinext production build, 계약 테스트 8/8 통과 |
| Core 회귀 | 검증됨 | `swift test --package-path DeepMineCore` → 195/195, 실패 0 |
| generic iOS build | 검증됨 | `xcodebuild -quiet -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'generic/platform=iOS' -derivedDataPath /tmp/DeepMineD060Derived CODE_SIGNING_ALLOWED=NO build` → exit 0 |
| 새 자산·의존성 | 추가 없음 | 기존 `MinerMiningStrip`·광부·장비 PNG를 같은 네 안료 체계에서 확대·구조화. 새 화풍 에셋·런타임 의존성 없음 |
| 앱 포팅 | 미구현 | D-060 면 단위 충격과 구조적 내실은 웹 기준이며 SwiftUI 홈 갱도에는 아직 연결하지 않음 |
| 배포 | 미배포 | 로컬 웹에서 검증. 사용자 요청 전이므로 Sites와 원격 저장소는 변경하지 않음 |

## 2026-08-01 web equipment infrastructure accumulation

| 항목 | 상태 | 근거 |
|---|---|---|
| 초기 생산 설비 | 검증됨(브라우저·DOM) | 1280×720 새 로드에서 광차 2대·대당 적재 2칸·작업조 1명·작업등 2기이며 `data-cart-count/load`, `data-crew-count`, `data-service-light-count`와 실제 렌더 수가 일치 |
| 드릴 증설 | 검증됨(실제 포인터·DOM) | 드릴 Lv.5 구매 뒤 작업조 1→2명·비트 tier 2, 드릴/신규 작업조 commissioning과 `설비 증설 완료 · 드릴 Lv.5 · 작업조 2명 · 비트 티어 2` 확인 |
| 광차 증설·분기 | 검증됨(브라우저·DOM) | 광차 Lv.6 구매 시 운행 2→3대·적재 2→3칸·화물 표식 9개. 새 로드의 쌍선 레일 분기에서도 2→3대와 광차 commissioning 확인 |
| 램프 증설 | 검증됨(실제 포인터·DOM) | 램프 Lv.3 구매 뒤 작업등 2→3기, 작업조 2→3명, 신규 램프 점등과 `작업등 3기 · 급소 16%` 설치 상태 확인 |
| 데스크톱 | 검증됨(1280×720) | 실제 포인터 램프 구매 전후 `scrollY == 0`, documentWidth 1280. 설치 패널은 갱도 오른쪽·행동대 위에 있고 첫 화면 가로 넘침 없음 |
| 모바일 | 검증됨(390×844) | 새 로드의 실제 포인터 드릴 구매로 작업조 1→2명. documentWidth 390, scrollY 0, 갱도 bottom 797.6px, 행동대 bottom 791.6px이며 설치 패널이 행동대를 가리지 않음 |
| 접근성·Reduce Motion | 검증됨(코드·계약) | 갱도 접근성 이름에 작업조·광차·작업등 수, 설치 패널은 `role=status`/`aria-live=polite`. Reduce Motion은 광차를 `--cart-rest`의 서로 다른 정적 위치에 두고 commissioning 이동 제거 |
| 브라우저 콘솔 | 검증됨 | 최종 소스의 새 데스크톱·모바일 탭에서 구매·분기 상호작용 뒤 warning/error 0 |
| 웹 검사 | 검증됨 | `git diff --check`, lint, vinext production build, 계약 테스트 8/8 통과 |
| Core 회귀 | 검증됨 | `swift test --package-path DeepMineCore` → 195/195, 실패 0 |
| generic iOS build | 검증됨 | `xcodebuild -quiet -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'generic/platform=iOS' -derivedDataPath /tmp/DeepMineD059Derived CODE_SIGNING_ALLOWED=NO build` → exit 0 |
| 새 자산·의존성 | 추가 없음 | 기존 프로젝트 광부·장비 PNG와 네 안료 CSS를 재사용. 새 런타임 의존성·다른 화풍 에셋 없음 |
| 앱 포팅 | 미구현 | D-059 설비 수량·commissioning·설치 패널은 웹 체감 기준이며 SwiftUI 홈 갱도에는 아직 연결하지 않음 |
| 배포 | 미배포 | 로컬 웹에서 검증. 사용자 요청 전이므로 Sites version 4와 원격 저장소는 변경하지 않음 |

## 2026-08-01 web strike rhythm and contact SFX

| 항목 | 상태 | 근거 |
|---|---|---|
| 전신 타격 변주 | 검증됨(브라우저·코드) | 실제 화면 탭에서 quick/heavy/critical이 각각 `miner-quick-strike`, `miner-heavy-strike`, `miner-critical-strike`로 전환. 크리티컬은 전신 확대·하강과 `급소 −57`, 38px 접촉 섬광 확인 |
| 접촉 동기화 | 검증됨(코드·계약) | 560/202ms, 690/249ms, 760/274ms의 동작/접촉 정의를 전신 포즈·막장 반동·균열·섬광·파편·수치·데미지·SFX가 공동 사용. Reduce Motion은 160/80ms |
| 자동 생산 보존 | 검증됨(브라우저·코드) | 무입력 1.8초 동안 16.6m→17.2m, hit pulse 32→35. 수동 포즈 보호 구간에 걸린 자동 틱은 보류 후 다음 가시 접촉에 합산해 누락·비접촉 붕괴를 방지 |
| 웹 8-bit SFX | 검증됨(코드·DOM) | 새 의존성 없이 Web Audio square-wave로 quick/heavy/critical/collapse를 저음량 합성. 첫 제스처 뒤에만 컨텍스트를 열고 SFX 토글로 상태 제어 |
| 데스크톱 | 검증됨(1280×720) | scrollY 0, documentWidth 1280, 갱도 bottom 708.6px, 행동대 bottom 698.6px. SFX 버튼 48×55.6px, 실제 포인터 타격과 변주 확인 |
| 모바일 | 검증됨(390×844) | documentWidth 390, scrollY 0, 갱도 bottom 797.6px, 행동대 bottom 791.6px. SFX 버튼 44×55.6px, 제목 영역 포인터가 `manual/quick` 타격으로 기록 |
| 입력 분리 | 검증됨(실제 포인터) | SFX 버튼을 눌러 `aria-pressed true→false`가 바뀌는 동안 타격 source는 `auto`로 유지. 다시 켜기와 화면 전체 수동 탭 정상 |
| 브라우저 콘솔 | 부분 검증 | 데스크톱·모바일·SFX 토글·8회 타격·크리티컬·무입력 하강 뒤 warning/error 0. 이후 자동 데미지 접촉 합산과 AudioContext 실패 폴백을 정적 보강했으며 final production build는 통과했지만 브라우저 세션을 다시 열지는 않음 |
| 웹 검사 | 검증됨 | lint, vinext production build, 계약 테스트 7/7, `git diff --check` 통과 |
| Core 회귀 | 검증됨 | `swift test --package-path DeepMineCore` → 195/195, 실패 0 |
| generic iOS build | 검증됨 | `xcodebuild -quiet -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'generic/platform=iOS' -derivedDataPath /tmp/DeepMineD058Derived CODE_SIGNING_ALLOWED=NO build` → exit 0 |
| 앱 포팅 | 미구현 | D-058은 웹 체감 기준. iOS 저작 8-bit 자산과 `GameFeedbackEvent.systemSoundID` 교체, SwiftUI 전신 포즈 포팅은 별도 |
| 배포 | 미배포 | 현재 로컬 작업트리에서 검증. 사용자 요청 전이므로 Sites version 4와 원격 저장소는 변경하지 않음 |

## 2026-08-01 web resonance event

| 항목 | 상태 | 근거 |
|---|---|---|
| 기존 생성 에셋 재사용 | 검증됨 | `ResonanceNode.imageset/resonancenode@3x.png`와 `web/public/assets/events/ResonanceNode.png`가 192×192 RGB, SHA-256 `b2d2f971…ca98e25a`로 동일 |
| 등장·놓침 | 검증됨(브라우저·코드) | 첫 체험 5.2초, 이후 보이는 화면에서 120~300초 간격, 활성 12초. 미수령 시 `공명 결절을 놓쳤습니다. 보상 없이 신호가 사라졌습니다.` 확인 |
| 실제 수령·배율 | 검증됨(실제 좌표 포인터) | 데스크톱과 모바일에서 결절 중심을 실제 좌표로 눌러 `공명 회수`·18초 과충전 확인. 탭 19→38, 자동 9→18/초, 종료 후 19·9/초 복귀 |
| 채굴 루프 보존 | 검증됨(브라우저) | 과충전 중 제목 영역 탭 뒤 접촉 프레임에서 헤드 22.9m→23.8m 진행. 자동 굴착은 계속되며 개별 광석 지급이나 자동 결절 수령 없음 |
| 데스크톱 배치 | 검증됨(1280×720) | scrollY 0, 가로 overflow 없음. 상태판 rect 279~799px와 과충전 rect 851~999px가 겹치지 않음 |
| 모바일 배치 | 검증됨(390×844) | 결절 실제 버튼 104×126px, scrollY 0, scrollWidth 390px, 가로 overflow 없음. 상태판 bottom 213.0px와 과충전 top 213.6px가 겹치지 않음 |
| 접근성·모션 | 검증됨(DOM·코드) | 고정 접근성 이름의 독립 버튼, `aria-live=assertive`, 회수/놓침/종료 텍스트 상태. Reduce Motion은 사건 의미를 남기고 5개 애니메이션 제거 |
| 웹 검사 | 검증됨 | lint, vinext production build, 계약 테스트 6/6, `git diff --check` 통과 |
| 최종 클린 콘솔 | 해소됨(D-058 재검증) | 새 개발 서버와 전체 reload에서 D-057을 포함한 페이지를 다시 열고 데스크톱·모바일 상호작용 뒤 브라우저 warning/error 0 확인 |
| Core 회귀 | 검증됨 | `swift test --package-path DeepMineCore` → 195/195, 실패 0 |
| generic iOS build | 검증됨 | `xcodebuild -quiet -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'generic/platform=iOS' -derivedDataPath /tmp/DeepMineD057Derived CODE_SIGNING_ALLOWED=NO build` → exit 0 |
| 앱 포팅 | 미구현 | D-057 공명 사건은 웹 체감 승인 전이며 SwiftUI 홈과 Core 경제에는 아직 연결하지 않음 |

## 2026-08-01 first-viewport reward and upgrade loop

| 항목 | 상태 | 근거 |
|---|---|---|
| 층 보상 예고 | 검증됨(브라우저) | 작업 접점에 남은 파쇄율과 `파쇄 시 ◆29~30`, 행동대에 현재 암반 예상 광석과 자동 완료 ETA를 실시간 표시 |
| 빠른 추천 강화 | 검증됨(실제 포인터) | 드릴 Lv.5 구매 뒤 탭 위력 19→22, 다음 추천 램프 Lv.3, 설치 상태 알림이 한 번에 갱신. 버튼 외 제목 탭도 260ms 뒤 22.4m→23.2m 진행 |
| 데스크톱 첫 화면 | 검증됨(1280×720) | shaft bottom 708.6px, 행동대 bottom 698.6px, 초기 scrollY 0. 실제 좌표 포인터 구매 뒤에도 scrollY 0 |
| 모바일 첫 화면 | 검증됨(390×844) | shaft bottom 797.6px, 행동대 bottom 791.6px, horizontal overflow 없음. 실제 포인터 구매 뒤 scrollY 0·console warning/error 0 |
| 접근성 | 검증됨(DOM) | 행동대는 `role=img` 밖의 `aside`이며 `현재 암반 보상과 추천 강화` 이름 보유. 구매는 고유 접근성 이름, 결과는 `role=status`/`aria-live=polite`로 노출 |
| 경제 보존 | 검증됨(코드) | 개별 탭 광석 지급을 추가하지 않고 기존 4m 파쇄 보상만 사용. 추천 강화도 명시적 클릭에서만 구매 |
| 웹 검사 | 검증됨 | lint, vinext production build, 계약 테스트 5/5, `git diff --check` 통과 |
| 앱 포팅 | 미구현 | D-056 행동대와 보상 예고는 웹 체감 승인 전이며 SwiftUI 홈에는 아직 없음 |

## 2026-08-01 Sites v4 and Cookie Clicker comparison

| 항목 | 상태 | 근거 |
|---|---|---|
| 웹 배포 | 배포됨(소유자 전용) | Sites version 4, source `7a0f29d35`, `https://deepmine-shaft-prototype.eiraworks-9813.chatgpt.site`. 배포 상태 `succeeded` |
| 배포 응답 | 검증됨 | 소유자 우회 헤더로 HTML 200, `MinerMiningStrip.png` 200/3,021B, `ShaftFrontierLip.png` 200/3,708B. 일반 브라우저에는 의도한 ChatGPT 로그인 게이트가 먼저 표시됨 |
| 웹 검사 | 검증됨 | `npm run lint && npm test` 통과. vinext production build와 계약 테스트 5/5 성공 |
| 실제 첫 화면 | 검증됨(1280×720) | 자동 굴착으로 입력 없이 심도·광석이 증가하고, 제목 영역 클릭에서도 620ms 전신 타격·접촉 `−19`가 표시됨. console warning/error 0 |
| Cookie Clicker 직접 비교 | 검증됨(공식 웹판) | 첫 쿠키 클릭이 0→1 자원 증가, 20개 파티클, 첫 업적 토스트를 한 번에 발생. 큰 쿠키·자원/CPS·상점이 같은 뷰포트에 있음 |
| DeepMine 우위 | 확인됨 | 지나온 통로·현재 파쇄 경계·미개척 암반이 한 깊이 좌표로 이어지고, 자동 생산이 실제 세계 이동과 전신 채굴 동작으로 보임 |
| DeepMine 핵심 격차 | D-056 1차 해소 | 타격 접점의 층 보상 예고와 첫 화면 추천 강화 행동대를 추가. 공명 결절·타격/SFX 변주·자동 생산의 장면 누적은 후속 |
| 모바일 D-055/D-056 시각 증거 | 검증됨 | viewport capability 390×844에서 D-055 자산·전신 타격과 D-056 행동대가 첫 화면에 함께 보이며 가로 넘침·console 오류 없음 |

후속 구현은 Cookie Clicker의 화면을 복제하지 않고, `타격→현재 층 보상/남은 시간→바로 살 수 있는
장비→자동 생산 증가`를 첫 뷰포트 안에서 닫는 것을 1순위로 둔다. 간헐 보상은 Golden Cookie의
역할만 참고해 기존 `ResonanceNode`를 사용하는 공명 결절 이벤트로 DeepMine 고유 표현을 유지한다.

## 2026-08-01 web cohesive frontier and full-body strike

| 항목 | 상태 | 근거 |
|---|---|---|
| 파쇄 경계 연속성 | 검증됨(로컬 브라우저) | 생성 `ShaftFrontierLip`의 하단 387px과 중앙 절삭 홈 시작 384px이 3px 겹침. 열린 통로→U자형 립→검은 절삭부→세로 균열이 같은 중심축 사용 |
| 전신 채굴 액터 | 검증됨(브라우저 육안·정적) | 생성 `MinerMiningStrip` 4프레임에서 양손이 곡괭이를 잡고 준비·예비동작·무릎/몸통 하강 접촉·반동을 수행. 기존 독립 `miningPickaxe` 소비 제거 |
| 접촉 데미지 | 검증됨(코드·계약) | 수동/자동 모두 `queueStrike`를 사용하고 230ms 접촉 뒤 `applyDamage`. 자동은 820ms 주기이며 브라우저에서 입력 없이 1.1초 동안 72.5m→72.7m 증가 |
| 직접 조작 우선 | 검증됨(코드) | 수동 타격 뒤 640ms 동안 자동 스윙이 같은 액터 타임라인을 덮어쓰지 않음. 화면 전체 Pointer Events·18px 스크롤 취소 계약 유지 |
| ImageGen 자산 2종 | 검증됨 | 내장 ImageGen 원본·명시 프롬프트·크로마 추출·네 안료·이진 알파·SHA·웹 복사본을 `web-gamefeel-v1`에 보존. validator 2/2 통과 |
| 웹 검사 | 검증됨 | `npm run lint`, `npm test` 4/4 및 vinext production build 통과. 로컬 브라우저 console 로그 0 |
| Core 회귀 | 검증됨 | `swift test --package-path DeepMineCore` → 195/195, 실패 0 |
| generic iOS build | 검증됨 | `xcodebuild -quiet -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'generic/platform=iOS' -derivedDataPath /tmp/DeepMineD055Derived CODE_SIGNING_ALLOWED=NO build` → exit 0 |
| 앱 포팅 | 미구현 | 웹 체감 승인 전 단계이므로 SwiftUI Asset Catalog와 앱 채굴 장면은 변경하지 않음 |
| 배포 | 배포됨(소유자 전용) | 후속 요청으로 Sites version 4에 D-055 기준을 배포하고 production 상태 `succeeded` 확인 |

웹 조사는 GDC의 강한 키프레임·anticipation/timing, Apple의 직접 입력에 정확히 묶인 짧은
피드백 원칙을 구조 기준으로 사용했다. SteamWorld Dig 2·Dome Keeper·Cookie Clicker의 공식
페이지는 채굴/방치/직접 조작 루프의 제품 맥락 확인에만 사용했으며 아트·레이아웃은 복제하지 않았다.

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
| 배포 | 배포됨(소유자 전용) | Sites version 3, source `b2499fe`, `https://deepmine-shaft-prototype.eiraworks-9813.chatgpt.site`. 배포 상태 `succeeded`; 비로그인 브라우저에서 ChatGPT 로그인 게이트 확인 |

이 기준안은 D-054의 앱 포팅 전 승인 대상으로 둔다. 실제 앱의 지반 버튼과 D-053 모션은
이번 웹 변경으로 교체하지 않았으며, 배포본 체감 확정 뒤 같은 좌표·자동화 계약으로 옮긴다.

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
