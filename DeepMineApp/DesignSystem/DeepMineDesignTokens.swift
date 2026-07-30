import Foundation
import SwiftUI

struct DeepMinePigment: Equatable, Sendable {
    let name: String
    let hex: String
    let red: UInt8
    let green: UInt8
    let blue: UInt8

    var color: Color {
        Color(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: 1
        )
    }
}

enum DeepMinePalette {
    static let coal = DeepMinePigment(
        name: "coal", hex: "#10100F", red: 16, green: 16, blue: 15
    )
    static let shale = DeepMinePigment(
        name: "shale", hex: "#373630", red: 55, green: 54, blue: 48
    )
    static let limestone = DeepMinePigment(
        name: "limestone", hex: "#E7E0CF", red: 231, green: 224, blue: 207
    )
    static let brass = DeepMinePigment(
        name: "brass", hex: "#C58C39", red: 197, green: 140, blue: 57
    )

    static let all = [coal, shale, limestone, brass]
}

enum DeepMineMetrics {
    static let minimumHitTarget: CGFloat = 44
    static let buttonHeight: CGFloat = 50
    static let toggleWidth: CGFloat = 52
    static let toggleHeight: CGFloat = 28
    static let buttonCornerRadius: CGFloat = 6
    static let panelCornerRadius: CGFloat = 9
    static let badgeCornerRadius: CGFloat = 5
    static let metalDepth: CGFloat = 4
    static let pressedTravel: CGFloat = 3
    static let panelPadding: CGFloat = 17
}

enum DeepMineMotion {
    static func pressOffset(isPressed: Bool, reduceMotion: Bool) -> CGFloat {
        isPressed && !reduceMotion ? DeepMineMetrics.pressedTravel : 0
    }

    static func revealOffset(isRevealed: Bool, reduceMotion: Bool) -> CGFloat {
        isRevealed || reduceMotion ? 0 : 8
    }

    static func pressAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .interactiveSpring(response: 0.18, dampingFraction: 1)
    }
}

enum DeepMineStatus: String, CaseIterable, Sendable {
    case notStarted
    case preparing
    case mining
    case completed
    case attention
    case failed

    var titleKey: DeepMineStringKey {
        switch self {
        case .notStarted: .stateNotStarted
        case .preparing: .statePreparing
        case .mining: .stateMining
        case .completed: .stateCompleted
        case .attention: .stateAttention
        case .failed: .stateFailed
        }
    }

    var symbol: String {
        switch self {
        case .notStarted: "circle.dashed"
        case .preparing, .mining: "hourglass"
        case .completed: "checkmark.seal.fill"
        case .attention: "exclamationmark.triangle.fill"
        case .failed: "xmark.octagon.fill"
        }
    }

    var pigment: DeepMinePigment {
        switch self {
        case .notStarted: DeepMinePalette.limestone
        case .preparing, .mining, .attention, .failed: DeepMinePalette.brass
        case .completed: DeepMinePalette.limestone
        }
    }

    var isFilled: Bool { self == .mining || self == .failed }
}
