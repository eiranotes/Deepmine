import WidgetKit

struct GamePassiveSurfaceRefresher: Sendable {
    private let reloadTimeline: @Sendable (String) -> Void

    init(
        reloadTimeline: @escaping @Sendable (String) -> Void
    ) {
        self.reloadTimeline = reloadTimeline
    }

    func refresh() {
        reloadTimeline(GamePassiveSurfaceKinds.homeWidget)
    }

    static let none = Self(reloadTimeline: { _ in })

    static let product = Self(
        reloadTimeline: { WidgetCenter.shared.reloadTimelines(ofKind: $0) }
    )
}
