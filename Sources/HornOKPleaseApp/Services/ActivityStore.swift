import Foundation

@MainActor
final class ActivityStore: ObservableObject {
    @Published private(set) var items: [ActivityItem]

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let storageKey = "activity-items"
    private let limit = 8

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.items = []
        load()
    }

    func append(_ item: ActivityItem) {
        items.insert(item, at: 0)
        items = Array(items.prefix(limit))
        persist()
    }

    private func load() {
        guard
            let data = defaults.data(forKey: storageKey),
            let decoded = try? decoder.decode([ActivityItem].self, from: data)
        else {
            return
        }

        items = decoded
    }

    private func persist() {
        guard let data = try? encoder.encode(items) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
