import XCTest
@testable import Chime4BreakfastApp

final class UserPreferencesTests: XCTestCase {
    func test_defaults_use_distinct_sound_profiles() {
        let preferences = UserPreferences.defaultValue

        XCTAssertNotEqual(preferences.completionSoundID, preferences.attentionSoundID)
        XCTAssertTrue(preferences.watchCodex)
        XCTAssertTrue(preferences.watchClaude)
    }

    func test_defaults_enable_glow() {
        let preferences = UserPreferences.defaultValue

        XCTAssertTrue(preferences.screenGlowEnabled)
        XCTAssertEqual(preferences.glowIntensity, 1.0)
    }

    func test_per_app_sound_routing_uses_the_source_app_sound_for_every_event() {
        var preferences = UserPreferences.defaultValue
        preferences.soundRoutingMode = .app
        preferences.setSoundID("spoken-codex", for: .codex)
        preferences.setSoundID("spoken-claude", for: .claude)

        XCTAssertEqual(preferences.soundID(for: .codex, eventType: .completion), "spoken-codex")
        XCTAssertEqual(preferences.soundID(for: .codex, eventType: .attention), "spoken-codex")
        XCTAssertEqual(preferences.soundID(for: .claude, eventType: .completion), "spoken-claude")
        XCTAssertEqual(preferences.soundID(for: .claude, eventType: .attention), "spoken-claude")
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
        XCTAssertEqual(decoded.glowIntensity, UserPreferences.defaultValue.glowIntensity)
    }

    func test_decoding_preserves_low_glow_intensity() throws {
        let savedJSON = """
        {
            "watchCodex": true,
            "watchClaude": true,
            "completionAlertsEnabled": true,
            "attentionAlertsEnabled": true,
            "completionSoundID": "wave",
            "attentionSoundID": "horn",
            "quietHoursEnabled": false,
            "quietHoursStartHour": 22,
            "quietHoursEndHour": 8,
            "screenGlowEnabled": true,
            "glowIntensity": 0.2
        }
        """

        let decoded = try JSONDecoder().decode(UserPreferences.self, from: Data(savedJSON.utf8))

        XCTAssertEqual(decoded.glowIntensity, 0.2, accuracy: 0.0001)
    }

    func test_decoding_preserves_sound_only_quiet_hours_mode() throws {
        let savedJSON = """
        {
            "watchCodex": true,
            "watchClaude": true,
            "completionAlertsEnabled": true,
            "attentionAlertsEnabled": true,
            "completionSoundID": "wave",
            "attentionSoundID": "horn",
            "quietHoursEnabled": true,
            "quietHoursStartHour": 22,
            "quietHoursEndHour": 8,
            "quietHoursMode": "soundOnly",
            "screenGlowEnabled": true
        }
        """

        let decoded = try JSONDecoder().decode(UserPreferences.self, from: Data(savedJSON.utf8))

        XCTAssertEqual(decoded.quietHoursMode, .soundOnly)
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
            screenGlowEnabled: true
        )

        XCTAssertTrue(preferences.quietHoursContains(lateNight, calendar: calendar))
        XCTAssertFalse(preferences.quietHoursContains(midMorning, calendar: calendar))
    }
}
