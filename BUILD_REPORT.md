# Build Report

업데이트: 2026-07-30 (경제·리텐션 리뷰 반영)

## Result

경제·리텐션 리뷰에서 확인한 구조적 결함을 수정하고 Spec §16 P1–P4 로컬 MVP를 다시
검증했다. 이 결과는 게임 규칙과 production view 렌더링을 검증하지만, 승인 entitlement와
실제 하드웨어 시스템 통합은 여전히 검증하지 않는다.

| 항목 | 상태 | 최신 근거 |
|---|---|---|
| XcodeGen | 검증됨 | `xcodegen generate --spec project.yml` 성공 |
| Core | 검증됨 | SwiftPM 101/101, 실패 0 |
| 앱 전체 suite | 검증됨 | iPhone 17 Pro iOS 26.5에서 182/182, 실패·skip 0 |
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
| 화면 증거 19장 | 미갱신 | 홈·귀환 보고서가 바뀌어 `artifacts/ui/game-mvp-v1/`의 기존 PNG는 stale이다 |
| StoreKit/서버/소셜 | 미구현 | 현재 게임 범위에서 명시적으로 제외 |
| 물리 기기 시스템 통합 | 미검증 | `docs/DEFECTS.md`의 GATE-001~006 |

## Fresh commands

```sh
xcodegen generate --spec project.yml
swift test --package-path DeepMineCore
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

## Known stale evidence

`artifacts/ui/game-mvp-v1/`의 19장 PNG는 이번 변경 이전에 캡처한 것이다. 홈 masthead,
계획 설명, 1탭 추천 강화, 귀환 보고서의 심도·목표·연속 일수·광맥 수량, 장비 화면의 심도
해금 표시가 반영되어 있지 않다. 화면 캡처 테스트는 suite에 포함되어 실행되지만 PNG를
저장소로 내보내는 단계는 이번 작업에서 수행하지 않았다.

## Physical-device release gates

`docs/DEFECTS.md`의 GATE-001~006이 그대로 유효하다. 이번 변경으로 다음 항목의 중요도가
올라갔다.

- Live Activity intent가 백그라운드 앱 프로세스에서 실제로 명령을 적용하는지 (D-027)
- 화면이 꺼진 실제 세션에서 `CLOCK_MONOTONIC_RAW` drift가 임계 안에 있는지
- 포기 버튼이 잠금화면에서 실제로 차단을 즉시 해제하는지
