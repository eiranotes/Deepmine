import DeviceActivity
import ManagedSettings

final class DeepMineDeviceActivityMonitor: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(
        named: ManagedSettingsStore.Name(ProbeConstants.shieldStoreName)
    )

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        ProbeDiagnostics.record(
            message: "intervalDidStart · \(activity.rawValue)",
            source: "DeviceActivityMonitor",
            level: .success
        )
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        do {
            let lock = try ProbeProcessLock.acquire(
                filename: ProbeConstants.shieldLifecycleLockFilename
            )
            defer { lock.release() }

            guard let current = try ProbeShieldJournal.load() else {
                store.clearAllSettings()
                ProbeDiagnostics.record(
                    message: "intervalDidEnd · journal 없음, fail-safe shield 해제 · \(activity.rawValue)",
                    source: "DeviceActivityMonitor",
                    level: .warning
                )
                return
            }
            guard current.activityName == activity.rawValue else {
                ProbeDiagnostics.record(
                    message: "stale interval 무시 · \(activity.rawValue)",
                    source: "DeviceActivityMonitor",
                    level: .warning
                )
                return
            }

            store.clearAllSettings()
            try ProbeShieldJournal.removeIfMatching(activityName: activity.rawValue)
        } catch {
            store.clearAllSettings()
            ProbeDiagnostics.record(error: error, source: "DeviceActivityMonitorJournal")
        }
        ProbeDiagnostics.record(
            message: "intervalDidEnd · shield 해제 · \(activity.rawValue)",
            source: "DeviceActivityMonitor",
            level: .success
        )
    }
}
