import XCTest
@testable import Chime4BreakfastApp

final class FinishEdgeDetectorTests: XCTestCase {
    func test_emits_after_confirmed_stop_edge_and_preserves_away_state() {
        let detector = FinishEdgeDetector()
        detector.reset(watching: [.claude])

        XCTAssertNil(detector.process(
            app: .claude,
            generating: true,
            message: nil,
            isFrontmost: true,
            fingerprint: testFingerprint
        ))

        detector.noteActivation(bundleIdentifier: "com.apple.finder")

        XCTAssertNil(detector.process(
            app: .claude,
            generating: false,
            message: "The implementation is complete and ready to review.",
            isFrontmost: false,
            fingerprint: testFingerprint
        ))

        let snapshot = detector.process(
            app: .claude,
            generating: false,
            message: "The implementation is complete and ready to review.",
            isFrontmost: true,
            fingerprint: testFingerprint
        )

        XCTAssertEqual(snapshot?.app, .claude)
        XCTAssertEqual(snapshot?.message, "The implementation is complete and ready to review.")
        XCTAssertEqual(snapshot?.userWasAway, true)
    }

    func test_waits_for_confirm_message_instead_of_dropping_finish() {
        let detector = FinishEdgeDetector()
        detector.reset(watching: [.codex])

        _ = detector.process(
            app: .codex,
            generating: true,
            message: nil,
            isFrontmost: false,
            fingerprint: testFingerprint
        )

        XCTAssertNil(detector.process(
            app: .codex,
            generating: false,
            message: nil,
            isFrontmost: false,
            fingerprint: testFingerprint
        ))

        XCTAssertNil(detector.process(
            app: .codex,
            generating: false,
            message: nil,
            isFrontmost: false,
            fingerprint: testFingerprint
        ))

        let snapshot = detector.process(
            app: .codex,
            generating: false,
            message: "Finished configuring the entitlement checks.",
            isFrontmost: false,
            fingerprint: testFingerprint
        )

        XCTAssertEqual(snapshot?.message, "Finished configuring the entitlement checks.")
        XCTAssertEqual(snapshot?.userWasAway, true)
    }

    func test_consecutive_stop_edges_with_same_selected_message_both_emit() {
        // Rapid short replies ("Hi." → "I'm good…") can select the same
        // transcript candidate twice; each confirmed Stop edge is still a real
        // completion and must alert.
        let detector = FinishEdgeDetector()
        detector.reset(watching: [.claude])
        let start = Date()

        _ = detector.process(app: .claude, generating: true, message: nil, isFrontmost: false, now: start, fingerprint: testFingerprint)
        _ = detector.process(app: .claude, generating: false, message: "Same result.", isFrontmost: false, now: start.addingTimeInterval(1), fingerprint: testFingerprint)
        XCTAssertNotNil(detector.process(app: .claude, generating: false, message: "Same result.", isFrontmost: false, now: start.addingTimeInterval(2), fingerprint: testFingerprint))

        _ = detector.process(app: .claude, generating: true, message: nil, isFrontmost: false, now: start.addingTimeInterval(8), fingerprint: testFingerprint)
        _ = detector.process(app: .claude, generating: false, message: "Same result.", isFrontmost: false, now: start.addingTimeInterval(9), fingerprint: testFingerprint)
        XCTAssertNotNil(detector.process(app: .claude, generating: false, message: "Same result.", isFrontmost: false, now: start.addingTimeInterval(10), fingerprint: testFingerprint))
    }

    func test_stop_edge_flicker_within_debounce_does_not_double_fire() {
        let detector = FinishEdgeDetector()
        detector.reset(watching: [.claude])
        let start = Date()

        _ = detector.process(app: .claude, generating: true, message: nil, isFrontmost: false, now: start, fingerprint: testFingerprint)
        _ = detector.process(app: .claude, generating: false, message: "Result.", isFrontmost: false, now: start.addingTimeInterval(0.5), fingerprint: testFingerprint)
        XCTAssertNotNil(detector.process(app: .claude, generating: false, message: "Result.", isFrontmost: false, now: start.addingTimeInterval(1), fingerprint: testFingerprint))

        // Indicator flickers back on and off within the debounce window.
        _ = detector.process(app: .claude, generating: true, message: nil, isFrontmost: false, now: start.addingTimeInterval(1.5), fingerprint: testFingerprint)
        _ = detector.process(app: .claude, generating: false, message: "Result.", isFrontmost: false, now: start.addingTimeInterval(2), fingerprint: testFingerprint)
        XCTAssertNil(detector.process(app: .claude, generating: false, message: "Result.", isFrontmost: false, now: start.addingTimeInterval(2.5), fingerprint: testFingerprint))
    }

    func test_does_not_emit_when_streaming_text_changes_after_user_left_without_stop_edge() {
        let detector = FinishEdgeDetector()
        detector.reset(watching: [.codex])

        XCTAssertNil(detector.process(
            app: .codex,
            generating: false,
            message: "Previous finished response.",
            isFrontmost: true,
            fingerprint: testFingerprint
        ))

        let snapshot = detector.process(
            app: .codex,
            generating: false,
            message: "A streamed status update that arrived before Codex finished.",
            isFrontmost: false,
            fingerprint: testFingerprint
        )

        XCTAssertNil(snapshot)
    }

    func test_reset_app_discards_inflight_generation() {
        let detector = FinishEdgeDetector()
        detector.reset(watching: [.codex])

        _ = detector.process(
            app: .codex,
            generating: true,
            message: nil,
            isFrontmost: false,
            fingerprint: testFingerprint
        )

        detector.reset(app: .codex)

        XCTAssertNil(detector.process(
            app: .codex,
            generating: false,
            message: "A stale message after relaunch should not fire.",
            isFrontmost: false,
            fingerprint: testFingerprint
        ))
    }

    private func testFingerprint(app: TargetApp, message: String) -> String {
        "\(app.rawValue)|\(message)"
    }
}
