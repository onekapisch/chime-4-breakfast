import XCTest
@testable import HornOKPleaseApp

final class UserPreferencesTests: XCTestCase {
    func test_defaults_use_distinct_sound_profiles() {
        let preferences = UserPreferences.defaultValue

        XCTAssertNotEqual(preferences.completionSoundID, preferences.attentionSoundID)
        XCTAssertTrue(preferences.watchCodex)
        XCTAssertTrue(preferences.watchClaude)
    }

    func test_defaults_enable_glow_with_distinct_colors() {
        let preferences = UserPreferences.defaultValue

        XCTAssertTrue(preferences.screenGlowEnabled)
        XCTAssertNotEqual(preferences.completionGlowColorHex, preferences.attentionGlowColorHex)
    }

    func test_decoding_missing_keys_falls_back_to_defaults() throws {
        let legacyJSON = """
        {
            "watchCodex": false,
            "watchClaude": true,
            "completionAlertsEnabled": true,
            "attentionAlertsEnabled": true,
            "completionSoundID": "wave",
            "attentionSoundID": "horn",
            "quietHoursEnabled": false,
            "quietHoursStartHour": 22,
            "quietHoursEndHour": 8
        }
        """

        let decoded = try JSONDecoder().decode(UserPreferences.self, from: Data(legacyJSON.utf8))

        XCTAssertFalse(decoded.watchCodex)
        XCTAssertTrue(decoded.screenGlowEnabled)
        XCTAssertEqual(decoded.completionGlowColorHex, UserPreferences.defaultValue.completionGlowColorHex)
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
            quietHoursEndHour: 8,
            screenGlowEnabled: true,
            completionGlowColorHex: "#30D158",
            attentionGlowColorHex: "#FF453A"
        )

        XCTAssertTrue(preferences.quietHoursContains(lateNight, calendar: calendar))
        XCTAssertFalse(preferences.quietHoursContains(midMorning, calendar: calendar))
    }
}
