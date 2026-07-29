import SwiftUI

enum ProbeDisplayState: Int, CaseIterable {
    case untested
    case running
    case passed
    case attention
    case issue

    init(entry: ProbeLogEntry?) {
        switch entry?.level {
        case .none: self = .untested
        case .info: self = .running
        case .success: self = .passed
        case .warning: self = .attention
        case .error: self = .issue
        }
    }

    var label: String {
        switch self {
        case .untested: "준비 전"
        case .running: "시험 중"
        case .passed: "준비 완료"
        case .attention: "확인 필요"
        case .issue: "문제 발생"
        }
    }

    var symbol: String {
        switch self {
        case .untested: "circle.dashed"
        case .running: "hourglass"
        case .passed: "checkmark.seal.fill"
        case .attention: "exclamationmark.triangle.fill"
        case .issue: "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .untested: ProbePalette.metal
        case .passed: ProbePalette.limestone
        case .running, .attention, .issue: ProbePalette.brass
        }
    }

    var isFilled: Bool {
        self == .running || self == .issue
    }
}

enum ProbeButtonRole {
    case primary
    case secondary
    case safety
    case warning

    var fill: Color {
        switch self {
        case .primary: ProbePalette.brass
        case .secondary, .warning: ProbePalette.shale
        case .safety: ProbePalette.coal
        }
    }

    var foreground: Color {
        switch self {
        case .primary: ProbePalette.coal
        case .secondary, .safety: ProbePalette.limestone
        case .warning: ProbePalette.brass
        }
    }

    var edge: Color {
        switch self {
        case .primary, .secondary, .warning: ProbePalette.coal
        case .safety: ProbePalette.brass
        }
    }

    var rim: Color {
        switch self {
        case .primary: ProbePalette.coal.opacity(0.46)
        case .secondary: ProbePalette.rockLight
        case .safety, .warning: ProbePalette.brass
        }
    }
}

extension View {
    func probeTechnicalTextSize() -> some View {
        dynamicTypeSize(.xSmall ... .xxxLarge)
    }
}
