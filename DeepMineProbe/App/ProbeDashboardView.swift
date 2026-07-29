import SwiftUI

struct ProbeDashboardView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var viewModel = ProbeViewModel()
    @StateObject private var screenTime = ScreenTimeProbe()
    @State private var showsFamilyPicker = false
    @State private var showsTelemetry = false

    var body: some View {
        NavigationStack {
            ZStack {
                ProbePalette.abyss.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 14) {
                        if shouldRenderForScreenshot("overview") {
                            ProbeHeader(
                                activeActivityCount: viewModel.activeActivityCount,
                                passedProbeCount: passedProbeCount
                            )
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("capture-overview")
                        }
                        if screenshotSection == nil, let message = viewModel.transientMessage {
                            ProbeInlineAlert(message: message) {
                                viewModel.transientMessage = nil
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        }
                        if shouldRenderForScreenshot("surfaces") {
                            descentModule
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("capture-surfaces")
                        }
                        if shouldRenderForScreenshot("lock-gate") {
                            shieldModule
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("capture-lock-gate")
                        }
                        if shouldRenderForScreenshot("integrity") {
                            integrityModule
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("capture-integrity")
                        }
                        if shouldRenderForScreenshot("telemetry") {
                            telemetryModule
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("capture-telemetry")
                        }
                        if shouldRenderForScreenshot("lock-screen") {
                            lockScreenPreview
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("capture-lock-screen")
                        }
                        if screenshotSection == nil || screenshotSection == "device-gate" {
                            deviceGateFooter
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("capture-device-gate")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .familyActivityPicker(
                isPresented: $showsFamilyPicker,
                selection: $screenTime.selection
            )
            .onChange(of: screenTime.selection) {
                viewModel.persistSelection(screenTime)
            }
            .onChange(of: scenePhase) {
                guard scenePhase == .active else { return }
                viewModel.recoverShieldIfNeeded(screenTime)
                viewModel.refreshSharedWrites()
            }
            .task {
                viewModel.recoverShieldIfNeeded(screenTime)
                viewModel.refreshSharedWrites()
            }
            .animation(
                reduceMotion ? nil : .interactiveSpring(response: 0.28, dampingFraction: 0.9),
                value: viewModel.transientMessage != nil
            )
        }
        .tint(ProbePalette.brass)
    }

    private var descentModule: some View {
        ProbeModule(
            stage: "첫 번째 준비 · 귀환 신호",
            title: "끝나는 시간을 알려줘요",
            subtitle: "잠금화면 표지와 종료 종이 60초 뒤 제대로 알려주는지 시험합니다.",
            symbol: "bell.badge",
            state: combinedState(liveState, alarmState)
        ) {
            Button {
                Task { await viewModel.startLiveActivity() }
            } label: {
                ProbeActionLabel(
                    title: "잠금화면 표지 켜기",
                    detail: "60초 동안 남은 시간을 보여줘요",
                    symbol: "arrow.down.to.line.compact"
                )
            }
            .buttonStyle(ProbePressButtonStyle(role: .primary))
            .disabled(viewModel.isBusy)

            ProbeAdaptiveActions {
                Button {
                    Task { await viewModel.restartLiveActivity() }
                } label: {
                    ProbeActionLabel(
                        title: "표지 다시 켜기",
                        detail: "기존 표지를 닫고 새로 시작해요",
                        symbol: "arrow.clockwise"
                    )
                }
                .buttonStyle(ProbePressButtonStyle(role: .secondary))
                .disabled(viewModel.isBusy)
            } second: {
                Button {
                    Task { await viewModel.scheduleAlarm() }
                } label: {
                    ProbeActionLabel(
                        title: "종료 종 예약하기",
                        detail: "60초 뒤 알람으로 알려줘요",
                        symbol: "alarm"
                    )
                }
                .buttonStyle(ProbePressButtonStyle(role: .warning))
                .disabled(viewModel.isBusy)
            }
        }
    }

    private var shieldModule: some View {
        ProbeModule(
            stage: "두 번째 준비 · 갱도 문",
            title: "집중할 동안 문을 잠가요",
            subtitle: "\(screenTime.selectionSummary). 막을 앱을 고르면 채굴 중에는 열리지 않게 가립니다.",
            symbol: "door.left.hand.closed",
            state: shieldState
        ) {
            ProbeStepRow(index: "1", title: "차단 권한 열기", detail: "아이폰이 방해 앱을 가릴 수 있게 허용해요") {
                Button("권한 열기", systemImage: "person.badge.key") {
                    Task { await viewModel.requestScreenTimeAuthorization(screenTime) }
                }
                .buttonStyle(ProbePressButtonStyle(role: .secondary))
                .disabled(viewModel.isBusy)
            }

            Divider().overlay(ProbePalette.rockMid)

            ProbeStepRow(index: "2", title: "방해 앱 고르기", detail: "집중할 때 문 밖에 둘 앱을 선택해요") {
                Button("앱 고르기", systemImage: "checklist") {
                    showsFamilyPicker = true
                }
                .buttonStyle(ProbePressButtonStyle(role: .secondary))
            }

            Divider().overlay(ProbePalette.rockMid)

            ProbeAdaptiveActions {
                Button {
                    viewModel.applyShields(screenTime)
                } label: {
                    ProbeActionLabel(
                        title: "갱도 문 잠그기",
                        detail: "선택한 앱을 지금부터 가려요",
                        symbol: "lock.fill"
                    )
                }
                .buttonStyle(ProbePressButtonStyle(role: .warning))
            } second: {
                Button {
                    viewModel.clearShields(screenTime)
                } label: {
                    ProbeActionLabel(
                        title: "비상 해제",
                        detail: "문제가 생기면 즉시 모두 열어요",
                        symbol: "lock.open.fill"
                    )
                }
                .buttonStyle(ProbePressButtonStyle(role: .safety))
            }
        }
    }

    private var integrityModule: some View {
        ProbeModule(
            stage: "세 번째 준비 · 시간과 보급품",
            title: "시간과 기록을 지켜요",
            subtitle: "기기 시계가 바뀌거나 앱을 오가도 채굴 시간과 준비 기록이 온전한지 살펴봅니다.",
            symbol: "backpack.fill",
            state: combinedState(clockState, swiftDataState)
        ) {
            ProbeInstrumentRow(
                symbol: "waveform.path.ecg",
                title: "모래시계",
                detail: "두 시계를 함께 재서 실제로 흐른 시간을 비교해요",
                state: clockState
            ) {
                ProbeAdaptiveActions {
                    Button("시작 시각 남기기", systemImage: "record.circle") {
                        viewModel.startClockObservation()
                    }
                    .buttonStyle(ProbePressButtonStyle(role: .secondary))
                } second: {
                    Button("흐른 시간 확인", systemImage: "stop.circle") {
                        viewModel.finishClockObservation()
                    }
                    .buttonStyle(ProbePressButtonStyle(role: .secondary))
                }
            }

            Divider().overlay(ProbePalette.rockMid)

            ProbeInstrumentRow(
                symbol: "externaldrive.badge.checkmark",
                title: "보급 상자",
                detail: "위젯이 남긴 준비 기록이 앱까지 도착했는지 확인해요",
                state: swiftDataState
            ) {
                Button {
                    viewModel.refreshSharedWrites()
                } label: {
                    ProbeActionLabel(
                        title: "보급 기록 가져오기",
                        detail: "밖에서 남긴 기록을 다시 읽어요",
                        symbol: "arrow.trianglehead.2.clockwise.rotate.90"
                    )
                }
                .buttonStyle(ProbePressButtonStyle(role: .secondary))
            }
        }
    }

    private var telemetryModule: some View {
        ProbeTelemetryPanel(
            entries: viewModel.entries,
            isExpanded: $showsTelemetry,
            refresh: viewModel.refresh
        )
    }

    private var deviceGateFooter: some View {
        ProbeDeviceGateNotice()
    }

    private var lockScreenPreview: some View {
        ProbeLockScreenPreview()
    }

    private var liveState: ProbeDisplayState { state(for: ["LiveActivity", "LiveActivityIntent"]) }
    private var alarmState: ProbeDisplayState { state(for: ["AlarmKit"]) }
    private var shieldState: ProbeDisplayState {
        state(for: ["ManagedSettings", "FamilyControls", "ShieldRecovery"])
    }
    private var clockState: ProbeDisplayState { state(for: ["Clock"]) }
    private var swiftDataState: ProbeDisplayState { state(for: ["SwiftData", "WidgetIntent"]) }

    private var passedProbeCount: Int {
        [liveState, alarmState, shieldState, clockState, swiftDataState]
            .filter { $0 == .passed }
            .count
    }

    private var screenshotSection: String? {
        ProcessInfo.processInfo.environment["DEEPMINE_SCREENSHOT_SECTION"]
    }

    private func shouldRenderForScreenshot(_ section: String) -> Bool {
        screenshotSection == nil || screenshotSection == section
    }

    private func state(for sources: Set<String>) -> ProbeDisplayState {
        ProbeDisplayState(entry: viewModel.entries.first { sources.contains($0.source) })
    }

    private func combinedState(_ states: ProbeDisplayState...) -> ProbeDisplayState {
        if states.contains(.issue) { return .issue }
        if states.contains(.attention) { return .attention }
        if states.contains(.running) { return .running }
        if states.contains(.passed) { return .passed }
        return .untested
    }
}
