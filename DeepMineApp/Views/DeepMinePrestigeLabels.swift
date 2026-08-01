import DeepMineCore

enum DeepMinePrestigeLabels {
    static func title(_ kind: PermanentUpgradeKind) -> DeepMineStringKey {
        switch kind {
        case .excavationMemory: .prestigeUpgradeMemory
        case .resonanceDetection: .prestigeUpgradeResonance
        case .compressedTime: .prestigeUpgradeTime
        }
    }

    static func effect(_ kind: PermanentUpgradeKind) -> DeepMineStringKey {
        switch kind {
        case .excavationMemory: .prestigeEffectMemory
        case .resonanceDetection: .prestigeEffectResonance
        case .compressedTime: .prestigeEffectTime
        }
    }
}
