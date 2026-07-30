import Foundation

enum GameSurfaceText {
    static func localized(_ key: String, locale: Locale) -> String {
        String(
            localized: String.LocalizationValue(key),
            bundle: .main,
            locale: locale
        )
    }

    static func phase(
        _ snapshot: GameSurfaceSnapshot,
        isStale: Bool = false,
        locale: Locale
    ) -> String {
        let phase = snapshot.activityPhase(isStale: isStale)
        let key: String = switch phase {
        case .waiting:
            snapshot.phase == .mining && isStale
                ? "surface.returnReady" : "state.waiting"
        case .mining: "state.mining"
        case .completed:
            snapshot.outcomeID == "abandoned"
                ? "return.outcome.abandoned" : "return.outcome.completed"
        case .vein:
            vein(snapshot.veinID, locale: locale) == nil
                ? "surface.resultReady" : "surface.veinFound"
        case .collapsed: "state.collapsed"
        }
        return localized(key, locale: locale)
    }

    static func compactStatus(
        _ snapshot: GameSurfaceSnapshot,
        isStale: Bool,
        locale: Locale
    ) -> String {
        let key = switch snapshot.activityPhase(isStale: isStale) {
        case .waiting: "surface.compact.waiting"
        case .completed: "surface.compact.completed"
        case .vein: "surface.compact.vein"
        case .collapsed: "surface.compact.collapsed"
        case .mining: "state.mining"
        }
        return localized(key, locale: locale)
    }

    static func plan(_ id: String, locale: Locale) -> String {
        let key = switch id {
        case "deep": "game.deepPlan"
        case "survey": "game.surveyPlan"
        default: "game.safePlan"
        }
        return localized(key, locale: locale)
    }

    static func region(_ id: String, locale: Locale) -> String {
        localized("region.\(id)", locale: locale)
    }

    static func grade(_ id: String?, locale: Locale) -> String {
        localized("state.\(id ?? "open")", locale: locale)
    }

    static func vein(_ id: String?, locale: Locale) -> String? {
        guard let id else { return nil }
        let key: String? = switch id {
        case "blue": "game.blueVein"
        case "crystal": "game.crystalVein"
        case "vault": "game.vaultVein"
        case "resonance": "game.resonanceVein"
        case "abyss": "game.abyssVein"
        default: nil
        }
        guard let key else { return nil }
        return localized(key, locale: locale)
    }

    static func equipment(_ id: String, locale: Locale) -> String {
        localized("game.\(id)", locale: locale)
    }

    static func number(_ value: Double, locale: Locale) -> String {
        let safe = value.isFinite ? max(0, value) : 0
        if safe >= 10_000 {
            let scaled = locale.language.languageCode?.identifier == "ko"
                ? safe / 10_000 : safe / 1_000
            let suffix = locale.language.languageCode?.identifier == "ko" ? "만" : "K"
            return String(format: "%.1f%@", locale: locale, scaled, suffix)
        }
        return Int(safe.rounded()).formatted(.number.locale(locale))
    }

    static func durationShort(_ minutes: Int, locale: Locale) -> String {
        let suffix = locale.language.languageCode?.identifier == "ko" ? "분" : "m"
        return "\(minutes)\(suffix)"
    }

    static func recommendationAccessibilityLabel(
        _ recommendation: GameSurfaceUpgradeRecommendation,
        locale: Locale
    ) -> String {
        [
            localized("surface.recommendationAction", locale: locale),
            equipment(recommendation.equipmentID, locale: locale),
            "\(localized("surface.level", locale: locale)) \(recommendation.nextLevel)",
            "\(localized("surface.cost", locale: locale)) "
                + "\(number(recommendation.cost, locale: locale)) "
                + localized("game.ore", locale: locale)
        ].joined(separator: ", ")
    }

    static func startAccessibilityLabel(
        minutes: Int,
        planID: String,
        locale: Locale
    ) -> String {
        "\(plan(planID, locale: locale)), \(minutes) "
            + "\(localized("game.minutes", locale: locale)), "
            + localized("action.start", locale: locale)
    }

    static func accessibilityLabel(
        _ snapshot: GameSurfaceSnapshot,
        isStale: Bool = false,
        locale: Locale
    ) -> String {
        let phase = snapshot.activityPhase(isStale: isStale)
        var parts = [
            self.phase(snapshot, isStale: isStale, locale: locale),
            plan(snapshot.planID, locale: locale),
            region(snapshot.regionID, locale: locale),
            "\(localized("game.depth", locale: locale)) \(snapshot.depthMeters)m",
            "\(localized("game.streak", locale: locale)) \(snapshot.streakDays)"
        ]
        if phase == .mining {
            parts.append(
                "\(localized("game.expectedReward", locale: locale)) "
                    + number(snapshot.expectedOre, locale: locale)
            )
        } else if phase == .completed || phase == .vein || phase == .collapsed {
            parts.append(
                "\(localized("surface.earnedOre", locale: locale)) "
                    + number(snapshot.earnedOre, locale: locale)
            )
            if let vein = vein(snapshot.veinID, locale: locale) { parts.append(vein) }
            parts.append(grade(snapshot.verificationGradeID, locale: locale))
        }
        return parts.joined(separator: ", ")
    }
}
