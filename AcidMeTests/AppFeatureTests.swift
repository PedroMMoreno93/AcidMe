import ComposableArchitecture
import Testing

@testable import AcidMe

@MainActor
@Suite
struct AppFeatureTests {
    @Test
    func testInitialState() {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        #expect(store.state == AppFeature.State())
    }
}
