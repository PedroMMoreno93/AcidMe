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

    @Test
    func demoKnobValueChanged_acotaEntreCeroYUno() async {
        let store = TestStore(initialState: AppFeature.State(demoKnobValue: 0.5)) {
            AppFeature()
        }
        await store.send(.demoKnobValueChanged(2)) {
            $0.demoKnobValue = 1
        }
        await store.send(.demoKnobValueChanged(-1)) {
            $0.demoKnobValue = 0
        }
    }

    @Test
    func demoToggleSelectionChanged_actualizaEstado() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        await store.send(.demoToggleSelectionChanged(.lower)) {
            $0.demoToggleSelection = .lower
        }
        await store.send(.demoToggleSelectionChanged(.upper)) {
            $0.demoToggleSelection = .upper
        }
    }
}
