import XCTest
@testable import Chime4BreakfastApp

final class GenerationIndicatorCachePolicyTests: XCTestCase {
    func test_keeps_using_a_cached_indicator_while_it_still_matches() {
        XCTAssertFalse(GenerationIndicatorCachePolicy.shouldPerformFullTraversal(
            cachedIndicatorMatches: true
        ))
    }

    func test_revalidates_the_full_tree_when_a_cached_indicator_changes_or_is_missing() {
        XCTAssertTrue(GenerationIndicatorCachePolicy.shouldPerformFullTraversal(
            cachedIndicatorMatches: false
        ))
        XCTAssertTrue(GenerationIndicatorCachePolicy.shouldPerformFullTraversal(
            cachedIndicatorMatches: nil
        ))
    }
}
