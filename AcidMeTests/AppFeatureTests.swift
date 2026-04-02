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
    func binding_propagaParametrosAlAudioClient() async {
        var lastKnob: Double?
        var lastToggle: AcidToggleSelection?
        let store = TestStore(initialState: AppFeature.State(demoKnobValue: 0.2, demoToggleSelection: .upper)) {
            AppFeature()
        } withDependencies: {
            $0.audioClient = AudioClient(
                prepare: {},
                applyDemoSynthParams: { k, t in
                    lastKnob = k
                    lastToggle = t
                }
            )
        }
        await store.send(.binding(.set(\.demoKnobValue, 0.7))) {
            $0.demoKnobValue = 0.7
        }
        #expect(lastKnob == 0.7)
        #expect(lastToggle == .upper)

        await store.send(.binding(.set(\.demoToggleSelection, .lower))) {
            $0.demoToggleSelection = .lower
        }
        #expect(lastKnob == 0.7)
        #expect(lastToggle == .lower)
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
        var lastKnob: Double?
        let store = TestStore(initialState: AppFeature.State(demoKnobValue: 0.8)) {
            AppFeature()
        } withDependencies: {
            $0.audioClient = AudioClient(
                prepare: {},
                applyDemoSynthParams: { k, _ in
                    lastKnob = k
                }
            )
        }
        await store.send(.demoClearButtonReleased) {
            $0.demoClearButtonReleaseCount = 1
            $0.demoKnobValue = 0
            $0.pianoRollNotes = []
        }
        #expect(lastKnob == 0)
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

    @Test
    func keyboardNoteOn_actualizaPulsacionYUltimaNota() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        let hz = AcidKeyboardMath.frequencyHz(midiNote: 64)
        await store.send(.keyboardNoteOn(midiNote: 64, frequencyHz: hz)) {
            $0.keyboardPressedMidiNotes = [64]
            $0.keyboardLastNoteOn = (64, hz)
        }
    }

    @Test
    func keyboardNoteOff_quitaPulsacion() async {
        var state = AppFeature.State()
        state.keyboardPressedMidiNotes = [60, 64]
        let store = TestStore(initialState: state) {
            AppFeature()
        }
        await store.send(.keyboardNoteOff(midiNote: 64)) {
            $0.keyboardPressedMidiNotes = [60]
        }
    }

    @Test
    func keyboardOctaveOffsetChanged_acota() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        await store.send(.keyboardOctaveOffsetChanged(10)) {
            $0.keyboardOctaveOffset = 3
        }
        await store.send(.keyboardOctaveOffsetChanged(-10)) {
            $0.keyboardOctaveOffset = -3
        }
    }

    @Test
    func keyboardOctaveOffsetChanged_valoresIntermedios() async {
        let store = TestStore(initialState: AppFeature.State(keyboardOctaveOffset: 0)) {
            AppFeature()
        }
        await store.send(.keyboardOctaveOffsetChanged(2)) {
            $0.keyboardOctaveOffset = 2
        }
        await store.send(.keyboardOctaveOffsetChanged(-1)) {
            $0.keyboardOctaveOffset = -1
        }
    }

    @Test
    func prepareAudioEngine_invocaClienteYMarcaListo() async {
        var prepareCalls = 0
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.audioClient = AudioClient(
                prepare: { prepareCalls += 1 },
                applyDemoSynthParams: { _, _ in }
            )
        }
        await store.send(.prepareAudioEngine)
        await store.receive(.audioEnginePrepared) {
            $0.audioEnginePrepared = true
            $0.audioEnginePrepareError = nil
        }
        #expect(prepareCalls == 1)
    }

    @Test
    func prepareAudioEngine_errorActualizaEstado() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.audioClient = AudioClient(
                prepare: {
                    throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "fallo simulado"])
                },
                applyDemoSynthParams: { _, _ in }
            )
        }
        await store.send(.prepareAudioEngine)
        await store.receive(.audioEnginePrepareFailed("fallo simulado")) {
            $0.audioEnginePrepared = false
            $0.audioEnginePrepareError = "fallo simulado"
        }
    }

    @Test
    func stateEquality_incluyeTecladoYUltimaNota() {
        var a = AppFeature.State()
        var b = AppFeature.State()
        let hz = AcidKeyboardMath.frequencyHz(midiNote: 60)
        a.keyboardOctaveOffset = 1
        a.keyboardPressedMidiNotes = [60]
        a.keyboardLastNoteOn = (60, hz)
        b.keyboardOctaveOffset = 1
        b.keyboardPressedMidiNotes = [60]
        b.keyboardLastNoteOn = (60, hz)
        #expect(a == b)
        b.keyboardLastNoteOn = (61, hz)
        #expect(a != b)
    }
}
