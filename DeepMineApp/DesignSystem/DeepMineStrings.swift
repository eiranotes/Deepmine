import Foundation

private final class DeepMineBundleToken {}

enum DeepMineStrings {
    static var bundle: Bundle { Bundle(for: DeepMineBundleToken.self) }

    static func text(_ key: DeepMineStringKey, locale: Locale = .current) -> String {
        let language = locale.identifier.lowercased().hasPrefix("ko") ? "ko" : "en"
        guard let url = bundle.url(forResource: language, withExtension: "lproj"),
              let localizedBundle = Bundle(url: url) else {
            return key.rawValue
        }
        return localizedBundle.localizedString(
            forKey: key.rawValue,
            value: key.rawValue,
            table: "Localizable"
        )
    }
}
