import XCTest
@testable import HornOKPleaseApp

final class UserPreferencesTests: XCTestCase {
    func test_defaults_use_distinct_sound_profiles() {
        let preferences = UserPreferences.defaultValue

        XCTAssertNotEqual(preferences.completionSoundID, preferences.attentionSoundID)
        XCTAssertTrue(preferences.watchCodex)
        XCTAssertTrue(preferences.watchClaude)
    }

    func test_quiet_hours_wrap_past_midnight() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 3
        components.hour = 23

        let lateNight = calendar.date(from: components)!
        components.hour = 10
        let midMorning = calendar.date(from: components)!

        let preferences = UserPreferences(
            watchCodex: true,
            watchClaude: true,
            completionAlertsEnabled: true,
            attentionAlertsEnabled: true,
            completionSoundID: "wave",
            attentionSoundID: "horn",
            quietHoursEnabled: true,
            quietHoursStartHour: 22,
            quietHoursEndHour: 8
        )

        XCTAssertTrue(preferences.quietHoursContains(lateNight, calendar: calendar))
        XCTAssertFalse(preferences.quietHoursContains(midMorning, calendar: calendar))
    }
}
