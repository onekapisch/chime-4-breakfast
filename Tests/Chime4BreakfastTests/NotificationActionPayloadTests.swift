import XCTest
@testable import Chime4BreakfastApp

final class NotificationActionPayloadTests: XCTestCase {
    func test_source_app_round_trips_through_notification_user_info() {
        let payload = NotificationActionPayload.userInfo(for: .claude)

        XCTAssertEqual(NotificationActionPayload.sourceApp(from: payload), .claude)
    }

    func test_unknown_notification_source_is_ignored() {
        XCTAssertNil(NotificationActionPayload.sourceApp(from: [NotificationActionPayload.sourceAppKey: "unknown"]))
    }
}
