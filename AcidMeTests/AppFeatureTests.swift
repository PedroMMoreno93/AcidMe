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
    func binding_demoKnobValue_acotaEntreCeroYUno() async {
        let store = TestStore(initialState: AppFeature.State(demoKnobValue: 0.5)) {
            AppFeature()
        }
        await store.send(.binding(.set(\.demoKnobValue, 2))) {
            $0.demoKnobValue = 1
        }
        await store.send(.binding(.set(\.demoKnobValue, -1))) {
            $0.demoKnobValue = 0
        }
    }

    @Test
    func binding_demoToggleSelection_actualizaEstado() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        await store.send(.binding(.set(\.demoToggleSelection, .lower))) {
            $0.demoToggleSelection = .lower
        }
        await store.send(.binding(.set(\.demoToggleSelection, .upper))) {
            $0.demoToggleSelection = .upper
        }
    }
}
