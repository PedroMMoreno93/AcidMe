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
                },
                triggerSequencerNote: { _, _ in }
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
    func demoPlayButtonReleased_iniciaTransporteYContador() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.audioClient = AudioClient(
                prepare: {},
                applyDemoSynthParams: { _, _ in },
                triggerSequencerNote: { _, _ in }
            )
        }
        await store.send(.demoPlayButtonReleased) {
            $0.demoPlayButtonReleaseCount = 1
            $0.sequencerIsRunning = true
            $0.sequencerCurrentStep = 0
            $0.sequencerPlayheadStep = nil
        }
        await store.send(.sequencerStopTapped) {
            $0.sequencerIsRunning = false
            $0.sequencerPlayheadStep = nil
        }
    }

    @Test
    func demoPlayButtonReleased_ignoraSiYaCorre() async {
        var state = AppFeature.State()
        state.sequencerIsRunning = true
        let store = TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.audioClient = AudioClient(
                prepare: {},
                applyDemoSynthParams: { _, _ in },
                triggerSequencerNote: { _, _ in }
            )
        }
        await store.send(.demoPlayButtonReleased)
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
                },
                triggerSequencerNote: { _, _ in }
            )
        }
        await store.send(.demoClearButtonReleased) {
            $0.demoClearButtonReleaseCount = 1
            $0.demoKnobValue = 0
            $0.pianoRollNotes = []
            $0.sequencerIsRunning = false
            $0.sequencerCurrentStep = 0
            $0.sequencerPlayheadStep = nil
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
        var applyCount = 0
        let store = TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.audioClient = AudioClient(
                prepare: {},
                applyDemoSynthParams: { _, _ in
                    applyCount += 1
                },
                triggerSequencerNote: { _, _ in }
            )
        }
        await store.send(.demoClearButtonReleased) {
            $0.demoClearButtonReleaseCount = 1
            $0.demoKnobValue = 0
            $0.pianoRollNotes = []
            $0.sequencerIsRunning = false
            $0.sequencerCurrentStep = 0
            $0.sequencerPlayheadStep = nil
        }
        #expect(applyCount == 1)
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
        var applyCalls = 0
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.audioClient = AudioClient(
                prepare: { prepareCalls += 1 },
                applyDemoSynthParams: { _, _ in
                    applyCalls += 1
                },
                triggerSequencerNote: { _, _ in }
            )
        }
        await store.send(.prepareAudioEngine)
        await store.receive(.audioEnginePrepared) {
            $0.audioEnginePrepared = true
            $0.audioEnginePrepareError = nil
        }
        #expect(prepareCalls == 1)
        #expect(applyCalls == 1)
    }

    @Test
    func prepareAudioEngine_sincronizaKnobYToggleTrasEstarListo() async {
        var lastKnob: Double?
        var lastToggle: AcidToggleSelection?
        let store = TestStore(
            initialState: AppFeature.State(demoKnobValue: 0.42, demoToggleSelection: .lower)
        ) {
            AppFeature()
        } withDependencies: {
            $0.audioClient = AudioClient(
                prepare: {},
                applyDemoSynthParams: { k, t in
                    lastKnob = k
                    lastToggle = t
                },
                triggerSequencerNote: { _, _ in }
            )
        }
        await store.send(.prepareAudioEngine)
        await store.receive(.audioEnginePrepared) {
            $0.audioEnginePrepared = true
            $0.audioEnginePrepareError = nil
        }
        #expect(lastKnob == 0.42)
        #expect(lastToggle == .lower)
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
                applyDemoSynthParams: { _, _ in },
                triggerSequencerNote: { _, _ in }
            )
        }
        await store.send(.prepareAudioEngine)
        await store.receive(.audioEnginePrepareFailed("fallo simulado")) {
            $0.audioEnginePrepared = false
            $0.audioEnginePrepareError = "fallo simulado"
        }
    }

    @Test
    func sequencerTick_avanzaPasoYPlayhead() async {
        let store = TestStore(
            initialState: AppFeature.State(
                sequencerIsRunning: true,
                sequencerCurrentStep: 0,
                pianoRollGridSteps: 16,
                pianoRollNotes: []
            )
        ) {
            AppFeature()
        } withDependencies: {
            $0.audioClient = AudioClient(
                prepare: {},
                applyDemoSynthParams: { _, _ in },
                triggerSequencerNote: { _, _ in }
            )
        }
        await store.send(.sequencerTick) {
            $0.sequencerPlayheadStep = 0
            $0.sequencerCurrentStep = 1
        }
    }

    @Test
    func sequencerTick_disparaNotaInicioEnPaso() async {
        let id = UUID()
        var triggered: [(Int, Double)] = []
        let store = TestStore(
            initialState: AppFeature.State(
                sequencerIsRunning: true,
                sequencerCurrentStep: 2,
                pianoRollGridSteps: 16,
                pianoRollNotes: [
                    PianoRollNote(id: id, row: 11, startStep: 2, lengthSteps: 2)
                ],
                keyboardOctaveOffset: 0
            )
        ) {
            AppFeature()
        } withDependencies: {
            $0.audioClient = AudioClient(
                prepare: {},
                applyDemoSynthParams: { _, _ in },
                triggerSequencerNote: { m, h in
                    triggered.append((m, h))
                }
            )
        }
        let expectedMidi = PianoRollSequencerMath.midiForRow(11, keyboardOctaveOffset: 0)
        let expectedHz = AcidKeyboardMath.frequencyHz(midiNote: expectedMidi)
        await store.send(.sequencerTick) {
            $0.sequencerPlayheadStep = 2
            $0.sequencerCurrentStep = 3
        }
        #expect(triggered.count == 1)
        #expect(triggered[0].0 == expectedMidi)
        #expect(abs(triggered[0].1 - expectedHz) < 1e-9)
    }

    @Test
    func sequencerStopTapped_detieneTransporte() async {
        var state = AppFeature.State()
        state.sequencerIsRunning = true
        state.sequencerPlayheadStep = 5
        let store = TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.audioClient = AudioClient(
                prepare: {},
                applyDemoSynthParams: { _, _ in },
                triggerSequencerNote: { _, _ in }
            )
        }
        await store.send(.sequencerStopTapped) {
            $0.sequencerIsRunning = false
            $0.sequencerPlayheadStep = nil
        }
    }

    @Test
    func stateEquality_incluyeFlagsDelMotorDeAudio() {
        var a = AppFeature.State()
        var b = AppFeature.State()
        a.audioEnginePrepared = true
        b.audioEnginePrepared = true
        #expect(a == b)
        b.audioEnginePrepareError = "x"
        #expect(a != b)
    }

    @Test
    func stateEquality_incluyeSequencer() {
        var a = AppFeature.State()
        var b = AppFeature.State()
        a.sequencerIsRunning = true
        a.sequencerCurrentStep = 3
        a.sequencerPlayheadStep = 2
        b.sequencerIsRunning = true
        b.sequencerCurrentStep = 3
        b.sequencerPlayheadStep = 2
        #expect(a == b)
        b.sequencerBPM = 140
        #expect(a != b)
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
