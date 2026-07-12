import XCTest
@testable import Chime4BreakfastApp

@MainActor
final class ActivityStoreTests: XCTestCase {
    func test_store_keeps_latest_eight_items() {
        let store = ActivityStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)

        for index in 0..<10 {
            store.append(
                ActivityItem(
                    id: UUID(),
                    sourceApp: .codex,
                    eventType: .completion,
                    timestamp: Date(),
                    excerpt: "Item \(index)",
                    fingerprint: "\(index)"
                )
            )
        }

        XCTAssertEqual(store.items.count, 8)
        XCTAssertEqual(store.items.first?.fingerprint, "9")
        XCTAssertEqual(store.items.last?.fingerprint, "2")
    }

    func test_clear_removes_all_items() {
        let store = ActivityStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        store.append(
            ActivityItem(
                id: UUID(),
                sourceApp: .claude,
                eventType: .attention,
                timestamp: Date(),
                excerpt: "Needs input?",
                fingerprint: "1"
            )
        )

        store.clear()

        XCTAssertTrue(store.items.isEmpty)
    }

    func test_activity_does_not_survive_a_new_app_session() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let firstSession = ActivityStore(defaults: defaults)
        firstSession.append(
            ActivityItem(
                id: UUID(),
                sourceApp: .codex,
                eventType: .completion,
                timestamp: Date(),
                excerpt: "Session-only item",
                fingerprint: "session-only"
            )
        )

        let nextSession = ActivityStore(defaults: defaults)

        XCTAssertTrue(nextSession.items.isEmpty)
    }
}
