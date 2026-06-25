import Foundation

@MainActor
final class PreferencesStore: ObservableObject {
    @Published var preferences: UserPreferences {
        didSet {
            persist()
        }
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let storageKey = "user-preferences"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        guard
            let data = defaults.data(forKey: storageKey),
            let decoded = try? decoder.decode(UserPreferences.self, from: data)
        else {
            self.preferences = .defaultValue
            return
        }

        self.preferences = decoded
    }

    private func persist() {
        guard let data = try? encoder.encode(preferences) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
