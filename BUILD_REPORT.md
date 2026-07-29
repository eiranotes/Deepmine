# BUILD REPORT

업데이트: 2026-07-29

| 항목 | 상태 | 근거 / 사유 |
|---|---|---|
| 문서 원본 보존 | 검증됨 | 첨부 파일과 저장소 파일의 SHA-256 일치 확인 |
| Xcode 프로젝트 생성 | 검증됨 | XcodeGen으로 앱, Widget, DeviceActivityMonitor, 테스트 타깃 생성 및 목록 확인 |
| generic iOS 빌드 | 검증됨 | iOS 26.5 SDK, Swift 6, 코드 서명 비활성화 빌드 성공 |
| 자동 테스트 | 검증됨 | iOS 26.5 시뮬레이터에서 단위 11개 + UI 2개, 합계 13/13 통과 |
| 화면별 UI 캡처 | 검증됨 | 기본 `medium` 글자 크기·표준 대비·다크 모드에서 출정 안내와 준비 구역 4종, 실기기 관문 PNG 6장을 추출·육안 확인 |
| Live Activity 시작 / Dynamic Island 렌더링 | 검증됨 | iPhone 17 Pro 시뮬레이터에서 앱 버튼으로 Activity를 시작하고 SpringBoard compact/expanded 상태 PNG 2장 육안 확인 |
| 잠금화면 Live Activity 콘텐츠 | 부분 검증 | 실제 Widget과 공유하는 최대 160pt 컴포넌트를 기본 사양에서 캡처해 잘림·정보 위계를 확인. Simulator `Device → Lock`이 비활성이라 SpringBoard 최종 합성과 수명주기는 실기기 확인 필요 |
| Live Activity stale 전환 | 미검증 | 60초 완료 후 상태 전환과 잠금화면 수명주기는 실기기 게이트에서 확인 필요 |
| LiveActivityIntent 재시작 | 미검증 | App Group 프로세스 잠금 아래 end→request 구현됨; 앱/intent 동시 실행은 실기기 필요 |
| AlarmKit 동시 운용 | 미검증 | 권한 요청과 60초 timer schedule 구현됨; 실제 Dynamic Island 충돌 관찰 필요 |
| FamilyControls 권한 / 선택 | 미검증 | Individual 권한, picker, 선택 저장 구현됨; 승인 entitlement 필요 |
| ManagedSettings shield | 미검증 | 세션별 monitor, 프로세스 잠금, expiry journal, rollback/startup fail-safe 구현됨; 실기기 필요 |
| 시간 무결성 관측 | 검증됨 | Date/mach_continuous_time 분류 4개 경계 테스트 통과 |
| App Group SwiftData 왕복 | 미검증 | 메모리/디스크 재개방 테스트는 통과; 실제 widget→app 경계는 실기기 필요 |
| DeepMine 게임형 UI | 검증됨 | 석탄·혈암·석회·황동 네 안료로 양자화한 광산 장면·보급품·앱 아이콘, 리벳 금속판 버튼, 사각 레버 토글, 문양 기반 상태를 앱/Live Activity/위젯에 적용 |
| 시뮬레이터 UI | 검증됨 | 사용자 요청대로 iPhone 17 Pro iOS 26.5의 기본 `medium` 크기·표준 대비·다크 모드만 현재 v3 시각 판정에 사용 |
| Reduce Motion / 실제 터치 반응 | 미검증 | 코드에 Reduce Motion 분기와 press-down spring을 구현했으나 Simulator 접근성 자동화 브리지가 창을 읽지 못해 실제 제스처 검증은 실기기 필요 |
| 시뮬레이터 서명 entitlement | 미검증 | Sign to Run Locally 결과 앱/두 익스텐션의 서명 entitlement가 빈 dict여서 App Group/FamilyControls 실제 경계 검증 불가 |
| 실기기 P0 검증 | 미검증 | 실기기 설치와 사용자 권한 승인 필요 |

## Verification commands

```sh
xcodegen generate --spec project.yml
xcrun simctl ui 64C7804C-355B-4444-90EE-C8ED0D9355CF content_size medium
xcrun simctl ui 64C7804C-355B-4444-90EE-C8ED0D9355CF increase_contrast disabled
xcrun simctl ui 64C7804C-355B-4444-90EE-C8ED0D9355CF appearance dark
xcodebuild -project DeepMine.xcodeproj -scheme DeepMineProbe \
  -destination 'platform=iOS Simulator,id=64C7804C-355B-4444-90EE-C8ED0D9355CF' \
  -derivedDataPath DerivedData/MineUIV3 \
  -resultBundlePath artifacts/ui/mine-ui-v3/FinalTests-8.xcresult test
xcodebuild -project DeepMine.xcodeproj -scheme DeepMineProbe \
  -destination 'generic/platform=iOS' -derivedDataPath DerivedData/MineUIV3Generic \
  CODE_SIGNING_ALLOWED=NO build
xcodebuild -project DeepMine.xcodeproj -scheme DeepMineProbe \
  -destination 'platform=iOS Simulator,id=64C7804C-355B-4444-90EE-C8ED0D9355CF' \
  -only-testing:DeepMineProbeUITests/ProbeScreenshotTests/testCaptureDynamicIsland \
  -resultBundlePath artifacts/ui/mine-ui-v3/DynamicIslandCaptures-3.xcresult test
xcrun xcresulttool get test-results summary \
  --path artifacts/ui/mine-ui-v3/FinalTests-8.xcresult
```

UI 증거: `artifacts/ui/mine-ui-v3/screens/01-overview.png`부터 `06-device-gate.png`까지의 기본 화면 6장, `07-dynamic-island-compact.png`, `08-dynamic-island-expanded.png`, `09-lock-screen-live-activity.png`까지 총 9장. 현재 v3에서는 큰 글씨 테스트를 실행하지 않았다. 09번은 Widget Extension과 동일한 본문 구현의 160pt 제약 캡처이며 실제 잠금화면 전체 합성 캡처는 아니다.

Xcode 26.5 참고: AppIntents를 사용하지 않는 `DeepMineDeviceActivityMonitor`에도 `ExtractAppIntentsMetadata` 단계가 자동 실행되어 `No AppIntents.framework dependency found` 경고 1건이 출력된다. 타깃 빌드와 테스트는 성공하며, 불필요한 framework 링크로 경고를 숨기지 않는다.

마지막 검증: 2026-07-29. `FinalTests-8.xcresult`에서 단위 테스트 11/11, UI 캡처 테스트 2/2, 총 13/13과 코드 서명 비활성 generic iOS build가 성공했다. Dynamic Island compact/expanded와 공유 잠금화면 콘텐츠의 기본 사양 렌더링을 육안 확인했다. 자동 서명 결과의 빈 entitlement, AlarmKit 동시 운용, AppIntent 실행, 실제 잠금 수명주기는 물리 기기 게이트에서 별도로 판정한다.
