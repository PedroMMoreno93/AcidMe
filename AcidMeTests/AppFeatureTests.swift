import ComposableArchitecture
import Foundation
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

    @Test
    func demoPlayButtonReleased_incrementaContador() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        await store.send(.demoPlayButtonReleased) {
            $0.demoPlayButtonReleaseCount = 1
        }
    }

    @Test
    func demoClearButtonReleased_incrementaYReseteaKnob() async {
        let store = TestStore(initialState: AppFeature.State(demoKnobValue: 0.8)) {
            AppFeature()
        }
        await store.send(.demoClearButtonReleased) {
            $0.demoClearButtonReleaseCount = 1
            $0.demoKnobValue = 0
            $0.pianoRollNotes = []
        }
    }

    @Test
    func pianoRollStepToggled_anadeYQuitaNota() async {
        let store = Store(initialState: AppFeature.State()) {
            AppFeature()
        }
        await store.send(.pianoRollStepToggled(row: 3, step: 7))
        #expect(store.pianoRollNotes.count == 1)
        #expect(store.pianoRollNotes[0].row == 3)
        #expect(store.pianoRollNotes[0].startStep == 7)
        #expect(store.pianoRollNotes[0].lengthSteps == 1)
        await store.send(.pianoRollStepToggled(row: 3, step: 7))
        #expect(store.pianoRollNotes.isEmpty)
    }

    @Test
    func demoClearButtonReleased_vaciaPianoRoll() async {
        var state = AppFeature.State()
        state.pianoRollNotes = [
            PianoRollNote(id: UUID(), row: 1, startStep: 2, lengthSteps: 1)
        ]
        let store = TestStore(initialState: state) {
            AppFeature()
        }
        await store.send(.demoClearButtonReleased) {
            $0.demoClearButtonReleaseCount = 1
            $0.demoKnobValue = 0
            $0.pianoRollNotes = []
        }
    }
}
