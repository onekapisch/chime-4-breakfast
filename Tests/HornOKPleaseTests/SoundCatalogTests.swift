import XCTest
@testable import HornOKPleaseApp

final class SoundCatalogTests: XCTestCase {
    func test_catalog_contains_premium_sound_set() {
        let ids = SoundOption.catalog.map(\.id)

        XCTAssertGreaterThan(ids.count, 10)
        XCTAssertTrue(ids.contains("tick"))
        XCTAssertTrue(ids.contains("horn"))
        XCTAssertTrue(ids.contains("coin"))
    }
}
