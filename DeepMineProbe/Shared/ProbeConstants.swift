import Foundation

enum ProbeConstants {
    static let appGroupIdentifier = "group.com.eiraworks.deepmine"
    static let logFilename = "ProbeLog.jsonl"
    static let selectionFilename = "FamilyActivitySelection.json"
    static let shieldExpiryFilename = "ShieldExpiry.json"
    static let shieldLifecycleLockFilename = "ShieldLifecycle.lock"
    static let liveActivityLifecycleLockFilename = "LiveActivityLifecycle.lock"
    static let swiftDataFilename = "ProbeShared.store"
    static let logRetentionBytes: UInt64 = 256 * 1_024
    static let retainedLogLineCount = 500
    static let shieldStoreName = "DeepMineProbeShield"
    static let activityName = "DeepMineProbeSession"
    static let probeDuration: TimeInterval = 60
}
