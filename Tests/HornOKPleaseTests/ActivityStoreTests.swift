import XCTest
@testable import HornOKPleaseApp

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
}
