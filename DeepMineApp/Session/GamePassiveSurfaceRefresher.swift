import WidgetKit

struct GamePassiveSurfaceRefresher: Sendable {
    private let reloadTimeline: @Sendable (String) -> Void
    private let reloadControl: @Sendable (String) -> Void

    init(
        reloadTimeline: @escaping @Sendable (String) -> Void,
        reloadControl: @escaping @Sendable (String) -> Void
    ) {
        self.reloadTimeline = reloadTimeline
        self.reloadControl = reloadControl
    }

    func refresh() {
        reloadTimeline(GamePassiveSurfaceKinds.homeWidget)
        reloadControl(GamePassiveSurfaceKinds.safeControl)
    }

    static let none = Self(reloadTimeline: { _ in }, reloadControl: { _ in })

    static let product = Self(
        reloadTimeline: { WidgetCenter.shared.reloadTimelines(ofKind: $0) },
        reloadControl: { ControlCenter.shared.reloadControls(ofKind: $0) }
    )
}
