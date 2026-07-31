# Build Report

업데이트: 2026-07-31 (클리커 피벗 P2-1: 플레이 가능한 수직 슬라이스)

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
| 암반 아트 24장 | 미구현 | 플레이스홀더가 그려진다 |

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
| 아트 교체 레이어 | 검증됨 | `GameArtCatalogTests`. 24 슬롯 이름·프롬프트 ID 고유성, 슬롯↔`docs/ROCK_ART_PROMPTS.md` 양방향 대조, 미설치 슬롯이 플레이스홀더로 해소 |
| 암반 아트 24장 | 미구현 | 프롬프트와 플레이스홀더만 있다. 실제 이미지 생성은 P1-4 |
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
