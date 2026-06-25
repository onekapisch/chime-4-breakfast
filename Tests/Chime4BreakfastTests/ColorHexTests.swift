import SwiftUI
import XCTest
@testable import Chime4BreakfastApp

final class ColorHexTests: XCTestCase {
    func test_hex_round_trip_is_stable() {
        XCTAssertEqual(Color(hex: "#30D158")?.hexString(), "#30D158")
        XCTAssertEqual(Color(hex: "#FF453A")?.hexString(), "#FF453A")
    }

    func test_hex_without_hash_is_accepted() {
        XCTAssertEqual(Color(hex: "4F7BFF")?.hexString(), "#4F7BFF")
    }

    func test_invalid_hex_returns_nil() {
        XCTAssertNil(Color(hex: "not-a-color"))
        XCTAssertNil(Color(hex: "#12"))
    }
}
