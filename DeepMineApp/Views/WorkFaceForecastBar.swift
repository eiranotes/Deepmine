import DeepMineCore
import SwiftUI

/// What the rock in progress pays and how long it has left, directly under the shaft.
///
/// The shaft shows depth and damage; neither answers "what do I get for this". Putting the
/// layer's reward and its unattended ETA next to the upgrade button closes tap → reward →
/// purchase inside the first viewport, which is the loop a clicker opens on (D-056).
struct WorkFaceForecastBar: View {
    let forecast: WorkFaceForecast

    var body: some View {
        VStack(spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(DeepMineStrings.text(.shaftForecastTitle))
                        .font(.caption2)
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.62))
                    Text("\(DeepMineStrings.text(.shaftForecastReward)) ◆\(oreText)")
                        .font(.subheadline.monospacedDigit().weight(.bold))
                        .foregroundStyle(DeepMinePalette.brass.color)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(paceTitle)
                        .font(.caption2)
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.62))
                    Text(paceValue)
                        .font(.subheadline.monospacedDigit().weight(.bold))
                }
            }
            Divider().overlay(DeepMinePalette.limestone.color.opacity(0.16))
            if let oreRate = forecast.automaticOrePerSecond,
               let layerRate = forecast.automaticLayersPerSecond {
                HStack(spacing: 12) {
                    rateLabel(.shaftRateOre, value: oreRate)
                    Spacer(minLength: 0)
                    rateLabel(.shaftRateLayers, value: layerRate)
                }
            } else {
                Label(DeepMineStrings.text(.shaftRateManual), systemImage: "hand.tap.fill")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(
            DeepMinePalette.shale.color.opacity(0.5),
            in: RoundedRectangle(cornerRadius: DeepMineMetrics.buttonCornerRadius)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityIdentifier("shaft-forecast")
    }

    private var oreText: String {
        DeepMineNumberFormatter.string(big: forecast.expectedOre)
    }

    /// Automation is the headline once it exists, because that is the number that keeps
    /// paying with the app closed. Before the first cart there is nothing honest to put
    /// there, so the bar states the work still in the player's hands instead.
    private var paceTitle: String {
        forecast.isAutomated
            ? DeepMineStrings.text(.shaftForecastAutomatic)
            : DeepMineStrings.text(.shaftForecastManualOnly)
    }

    private var paceValue: String {
        if let seconds = forecast.automaticSecondsToBreak {
            return DeepMineDurationFormatter.short(seconds)
        }
        if let oreRate = forecast.automaticOrePerSecond {
            return DeepMineRateFormatter.string(oreRate)
        }
        guard let taps = forecast.tapsToBreak else { return "—" }
        return String(format: DeepMineStrings.text(.shaftForecastTaps), "\(taps)")
    }

    private func rateLabel(_ key: DeepMineStringKey, value: BigNumber) -> some View {
        VStack(alignment: key == .shaftRateOre ? .leading : .trailing, spacing: 1) {
            Text(DeepMineStrings.text(key))
                .font(.caption2)
                .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.62))
            Text(DeepMineRateFormatter.string(value))
                .font(.caption.monospacedDigit().weight(.bold))
        }
    }

    private var accessibilityText: String {
        "\(DeepMineStrings.text(.shaftForecastTitle)), "
            + "\(DeepMineStrings.text(.shaftForecastReward)) \(oreText), "
            + "\(paceTitle) \(paceValue), \(rateAccessibilityText)"
    }

    private var rateAccessibilityText: String {
        guard let ore = forecast.automaticOrePerSecond,
              let layers = forecast.automaticLayersPerSecond else {
            return DeepMineStrings.text(.shaftRateManual)
        }
        return "\(DeepMineStrings.text(.shaftRateOre)) \(DeepMineRateFormatter.string(ore)), "
            + "\(DeepMineStrings.text(.shaftRateLayers)) \(DeepMineRateFormatter.string(layers))"
    }
}

/// Seconds as something readable at a glance.
///
/// Units come from `Duration.formatted` rather than literal suffixes: the shaft is the one
/// screen a player watches continuously, and a hardcoded "초" would be the only untranslated
/// string on it.
enum DeepMineDurationFormatter {
    static func short(_ seconds: TimeInterval, locale: Locale = .current) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "—" }
        let rounded = max(1, seconds.rounded())
        guard rounded < Double(Int.max) else { return "—" }
        let allowed: Set<Duration.UnitsFormatStyle.Unit> = rounded < 3600
            ? [.minutes, .seconds]
            : [.hours, .minutes]
        return Duration.seconds(Int(rounded)).formatted(
            .units(allowed: allowed, width: .narrow, zeroValueUnits: .hide)
                .locale(locale)
        )
    }
}
