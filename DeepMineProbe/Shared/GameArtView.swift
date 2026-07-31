import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Renders a catalog entry, preferring the shipped image and falling back to a procedural
/// placeholder when none is installed.
///
/// This is the whole swap mechanism: nothing here names a specific asset, so adding real
/// art is a change to the asset catalog alone.
struct GameArtView: View {
    let entry: GameArtEntry
    var size: CGFloat = 96
    var tint: Color?

    var body: some View {
        Group {
            if GameArtAvailability.isInstalled(entry.name) {
                Image(entry.name)
                    .resizable()
                    .interpolation(.none)
                    .antialiased(false)
                    .scaledToFit()
            } else {
                GameArtPlaceholderView(placeholder: entry.placeholder)
            }
        }
        .frame(width: size, height: size)
        .foregroundStyle(tint ?? ProbePalette.limestone)
        .accessibilityHidden(true)
    }
}

/// Asset lookups hit the filesystem on a miss, and the rock face is rendered every frame
/// while a player taps. Resolving each name once and remembering the answer keeps a
/// missing asset from becoming a per-frame cost.
enum GameArtAvailability {
    #if canImport(UIKit)
    private static let cache = Cache()

    private final class Cache: @unchecked Sendable {
        private var storage: [String: Bool] = [:]
        private let lock = NSLock()

        func value(for name: String) -> Bool {
            lock.lock()
            defer { lock.unlock() }
            if let known = storage[name] { return known }
            let installed = UIImage(named: name) != nil
            storage[name] = installed
            return installed
        }

        func reset() {
            lock.lock()
            defer { lock.unlock() }
            storage.removeAll()
        }
    }

    static func isInstalled(_ name: String) -> Bool {
        cache.value(for: name)
    }

    /// Test seam. Nothing in the app clears this — asset membership cannot change while
    /// the process is running.
    static func resetCache() {
        cache.reset()
    }
    #else
    static func isInstalled(_ name: String) -> Bool { false }
    static func resetCache() {}
    #endif

    /// Slots still waiting on real art. Read by `GameArtCatalogTests`; no screen shows it
    /// yet, so during development this is a debugger or test-log query rather than
    /// something visible while playing.
    static var missingEntries: [GameArtEntry] {
        GameArtCatalog.allEntries.filter { !isInstalled($0.name) }
    }
}
