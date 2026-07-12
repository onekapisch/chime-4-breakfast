import Foundation

@MainActor
final class ActivityStore: ObservableObject {
    @Published private(set) var items: [ActivityItem]

    private let storageKey = "activity-items"
    private let limit = 8

    init(defaults: UserDefaults = .standard) {
        self.items = []
        // Activity can contain assistant excerpts. Clear the legacy persistent
        // store on launch and retain entries only for the current app session.
        defaults.removeObject(forKey: storageKey)
    }

    func append(_ item: ActivityItem) {
        items.insert(item, at: 0)
        items = Array(items.prefix(limit))
    }

    func clear() {
        items = []
    }
}
