import ComposableArchitecture
import XCTest

@testable import AcidMe

@MainActor
final class AppFeatureTests: XCTestCase {
    func testInitialState() {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        XCTAssertEqual(store.state, AppFeature.State())
    }
}
