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

    func test_repeated_same_message_does_not_emit_twice() {
        let detector = FinishEdgeDetector()
        detector.reset(watching: [.claude])

        _ = detector.process(app: .claude, generating: true, message: nil, isFrontmost: false, fingerprint: testFingerprint)
        _ = detector.process(app: .claude, generating: false, message: "Same result.", isFrontmost: false, fingerprint: testFingerprint)
        XCTAssertNotNil(detector.process(app: .claude, generating: false, message: "Same result.", isFrontmost: false, fingerprint: testFingerprint))

        _ = detector.process(app: .claude, generating: true, message: nil, isFrontmost: false, fingerprint: testFingerprint)
        _ = detector.process(app: .claude, generating: false, message: "Same result.", isFrontmost: false, fingerprint: testFingerprint)
        XCTAssertNil(detector.process(app: .claude, generating: false, message: "Same result.", isFrontmost: false, fingerprint: testFingerprint))
    }

    func test_emits_fast_completion_when_message_changes_after_user_left_without_stop_edge() {
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
            message: "A short response that finished before polling saw Stop.",
            isFrontmost: false,
            fingerprint: testFingerprint
        )

        XCTAssertEqual(snapshot?.app, .codex)
        XCTAssertEqual(snapshot?.message, "A short response that finished before polling saw Stop.")
        XCTAssertEqual(snapshot?.userWasAway, true)
    }

    func test_frontmost_fast_completion_updates_baseline_without_later_false_away_alert() {
        let detector = FinishEdgeDetector()
        detector.reset(watching: [.codex])

        XCTAssertNil(detector.process(
            app: .codex,
            generating: false,
            message: "Previous finished response.",
            isFrontmost: true,
            fingerprint: testFingerprint
        ))

        XCTAssertNil(detector.process(
            app: .codex,
            generating: false,
            message: "A response the user watched finish.",
            isFrontmost: true,
            fingerprint: testFingerprint
        ))

        XCTAssertNil(detector.process(
            app: .codex,
            generating: false,
            message: "A response the user watched finish.",
            isFrontmost: false,
            fingerprint: testFingerprint
        ))
    }

    func test_away_sample_with_same_message_disarms_fast_completion_fallback() {
        let detector = FinishEdgeDetector()
        detector.reset(watching: [.codex])

        XCTAssertNil(detector.process(
            app: .codex,
            generating: false,
            message: "The last real response.",
            isFrontmost: true,
            fingerprint: testFingerprint
        ))

        XCTAssertNil(detector.process(
            app: .codex,
            generating: false,
            message: "The last real response.",
            isFrontmost: false,
            fingerprint: testFingerprint
        ))

        XCTAssertNil(detector.process(
            app: .codex,
            generating: false,
            message: "A stale transcript candidate exposed after wake.",
            isFrontmost: false,
            fingerprint: testFingerprint
        ))
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
