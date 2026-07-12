import XCTest
@testable import Chime4BreakfastApp

final class GlowConfigurationTests: XCTestCase {
    func test_low_and_high_intensity_produce_materially_different_glow_layers() {
        let low = GlowConfiguration(intensity: 0.2)
        let high = GlowConfiguration(intensity: 1.0)

        XCTAssertLessThan(low.bandWidthScale, high.bandWidthScale)
        XCTAssertLessThan(low.haloOpacity, high.haloOpacity)
        XCTAssertLessThan(low.borderWidth, high.borderWidth)
    }
}
