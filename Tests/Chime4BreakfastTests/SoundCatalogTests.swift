import XCTest
import AppKit
import AVFoundation
@testable import Chime4BreakfastApp

final class SoundCatalogTests: XCTestCase {
    func test_catalog_contains_premium_sound_set() {
        let ids = SoundOption.catalog.map(\.id)

        XCTAssertGreaterThan(ids.count, 10)
        XCTAssertTrue(ids.contains("tick"))
        XCTAssertTrue(ids.contains("horn"))
        XCTAssertTrue(ids.contains("coin"))
        XCTAssertTrue(ids.contains("spoken-codex"))
        XCTAssertTrue(ids.contains("spoken-claude"))
    }

    @MainActor
    func test_sound_engine_prepares_selected_catalog_sound_for_playback() {
        let engine = SoundEngine()

        engine.play(soundID: "wave")

        let player = activePlayer(from: engine)
        XCTAssertNotNil(player)
        XCTAssertEqual(player?.volume, 1.0)
    }

    @MainActor
    func test_system_spoken_cue_starts_speaking_without_a_bundled_audio_file() {
        let engine = SoundEngine()

        XCTAssertTrue(engine.play(soundID: "spoken-codex"))
    }

    @MainActor
    private func activePlayer(from engine: SoundEngine) -> AVAudioPlayer? {
        let mirror = Mirror(reflecting: engine)
        let value = mirror.children.first { $0.label == "activePlayer" }?.value
        guard let value else { return nil }

        let optionalMirror = Mirror(reflecting: value)
        return optionalMirror.children.first?.value as? AVAudioPlayer
    }
}
