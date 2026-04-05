import ComposableArchitecture
import Foundation

/// Raíz TCA de la app. Se ampliará en HUs posteriores (audio, secuenciador, UI).
@Reducer
struct AppFeature {
    enum CancelID: Hashable {
        case sequencerLoop
    }
    @ObservableState
    struct State: Equatable {
        static func == (lhs: AppFeature.State, rhs: AppFeature.State) -> Bool {
            return lhs.demoKnobValue == rhs.demoKnobValue
            && lhs.demoToggleSelection == rhs.demoToggleSelection
            && lhs.demoPlayButtonReleaseCount == rhs.demoPlayButtonReleaseCount
            && lhs.demoClearButtonReleaseCount == rhs.demoClearButtonReleaseCount
            && lhs.pianoRollGridSteps == rhs.pianoRollGridSteps
            && lhs.pianoRollNotes == rhs.pianoRollNotes
            && lhs.keyboardOctaveOffset == rhs.keyboardOctaveOffset
            && lhs.keyboardPressedMidiNotes == rhs.keyboardPressedMidiNotes
            && lhs.keyboardLastNoteOn?.midiNote == rhs.keyboardLastNoteOn?.midiNote
            && lhs.keyboardLastNoteOn?.frequencyHz == rhs.keyboardLastNoteOn?.frequencyHz
            && lhs.audioEnginePrepared == rhs.audioEnginePrepared
            && lhs.audioEnginePrepareError == rhs.audioEnginePrepareError
            && lhs.sequencerIsRunning == rhs.sequencerIsRunning
            && lhs.sequencerCurrentStep == rhs.sequencerCurrentStep
            && lhs.sequencerPlayheadStep == rhs.sequencerPlayheadStep
            && lhs.sequencerBPM == rhs.sequencerBPM
        }

        /// Valor de demostración del AcidKnob (HU 1); más adelante se sustituirá por parámetros reales de síntesis.
        var demoKnobValue: Double = 0.35
        /// Selección del AcidToggle (HU 2); p. ej. onda superior/inferior o FX.
        var demoToggleSelection: AcidToggleSelection = .upper
        /// Contadores de suelta en botones demo (HU 3).
        var demoPlayButtonReleaseCount: Int = 0
        var demoClearButtonReleaseCount: Int = 0
        /// Piano roll: hasta 16 pasos (1 compás); 4/8 = fracciones del compás (HU 4).
        var pianoRollGridSteps: Int = 16
        var pianoRollNotes: [PianoRollNote] = []
        /// Teclado musical (HU 5): octava ±3 respecto a C4; notas actualmente pulsadas.
        var keyboardOctaveOffset: Int = 0
        var keyboardPressedMidiNotes: Set<Int> = []
        /// Último Note On (demo hasta AudioClient en HU 6).
        var keyboardLastNoteOn: (midiNote: Int, frequencyHz: Double)?
        /// HU 6: motor AudioKit listo para recibir comandos.
        var audioEnginePrepared: Bool = false
        var audioEnginePrepareError: String?
        /// HU 8: transporte y puntero del secuenciador (pasos del piano roll).
        var sequencerIsRunning: Bool = false
        /// Paso que se articula en el próximo `sequencerTick`.
        var sequencerCurrentStep: Int = 0
        /// Columna resaltada (último paso articulado); `nil` si el transporte está parado.
        var sequencerPlayheadStep: Int?
        /// Pulsos por minuto (40…220) para el reloj del secuenciador.
        var sequencerBPM: Double = 120
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case demoPlayButtonReleased
        case demoClearButtonReleased
        case pianoRollGridStepsChanged(Int)
        case pianoRollStepToggled(row: Int, step: Int)
        case pianoRollStepsPainted(row: Int, startStep: Int, endStep: Int)
        case pianoRollNoteRemoved(UUID)
        case pianoRollNoteResized(id: UUID, startStep: Int, length: Int)
        case keyboardOctaveOffsetChanged(Int)
        case keyboardNoteOn(midiNote: Int, frequencyHz: Double)
        case keyboardNoteOff(midiNote: Int)
        /// Arranca el motor de audio una vez al iniciar la UI raíz.
        case prepareAudioEngine
        case audioEnginePrepared
        case audioEnginePrepareFailed(String)
        /// Avanza un paso, dispara notas con ataque en ese paso y actualiza el playhead.
        case sequencerTick
        case sequencerStopTapped
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                // Tras cualquier binding, mantiene el knob en 0…1 (p. ej. arrastre del AcidKnob).
                state.demoKnobValue = min(1, max(0, state.demoKnobValue))
                let k = state.demoKnobValue
                let t = state.demoToggleSelection
                return .run { _ in
                    @Dependency(\.audioClient) var audioClient
                    await audioClient.applyDemoSynthParams(k, t)
                }
            case .demoPlayButtonReleased:
                guard !state.sequencerIsRunning else { return .none }
                state.demoPlayButtonReleaseCount += 1
                state.sequencerIsRunning = true
                state.sequencerCurrentStep = 0
                state.sequencerPlayheadStep = nil
                let steps = PianoRollGridMath.normalizedGridSteps(state.pianoRollGridSteps)
                let bpm = state.sequencerBPM
                return .run { send in
                    while !Task.isCancelled {
                        let sec = PianoRollSequencerMath.secondsPerStep(bpm: bpm, stepCount: steps)
                        let ns = min(sec * 1_000_000_000, Double(UInt64.max))
                        do {
                            try await Task.sleep(nanoseconds: UInt64(ns))
                        } catch {
                            return
                        }
                        await send(.sequencerTick)
                    }
                }
                .cancellable(id: CancelID.sequencerLoop, cancelInFlight: true)
            case .demoClearButtonReleased:
                state.demoClearButtonReleaseCount += 1
                state.demoKnobValue = 0
                state.pianoRollNotes = []
                state.sequencerIsRunning = false
                state.sequencerCurrentStep = 0
                state.sequencerPlayheadStep = nil
                let k = state.demoKnobValue
                let t = state.demoToggleSelection
                return .merge(
                    .cancel(id: CancelID.sequencerLoop),
                    .run { _ in
                        @Dependency(\.audioClient) var audioClient
                        await audioClient.applyDemoSynthParams(k, t)
                    }
                )
            case let .pianoRollGridStepsChanged(raw):
                let steps = PianoRollGridMath.normalizedGridSteps(raw)
                state.pianoRollGridSteps = steps
                state.pianoRollNotes = PianoRollGridMath.clampedNotes(
                    state.pianoRollNotes,
                    stepCount: steps
                )
                state.sequencerCurrentStep = min(
                    max(0, state.sequencerCurrentStep),
                    max(0, steps - 1)
                )
                return .none
            case let .pianoRollStepToggled(row, step):
                let steps = PianoRollGridMath.normalizedGridSteps(state.pianoRollGridSteps)
                state.pianoRollNotes = PianoRollGridMath.togglingStep(
                    notes: state.pianoRollNotes,
                    row: row,
                    step: step,
                    stepCount: steps
                )
                return .none
            case let .pianoRollStepsPainted(row, startStep, endStep):
                let steps = PianoRollGridMath.normalizedGridSteps(state.pianoRollGridSteps)
                state.pianoRollNotes = PianoRollGridMath.paintSteps(
                    notes: state.pianoRollNotes,
                    row: row,
                    fromStep: startStep,
                    toStep: endStep,
                    stepCount: steps
                )
                return .none
            case let .pianoRollNoteRemoved(id):
                state.pianoRollNotes.removeAll { $0.id == id }
                return .none
            case let .pianoRollNoteResized(id, startStep, length):
                let steps = PianoRollGridMath.normalizedGridSteps(state.pianoRollGridSteps)
                state.pianoRollNotes = PianoRollGridMath.applyNoteSpan(
                    notes: state.pianoRollNotes,
                    id: id,
                    newStart: startStep,
                    newLength: length,
                    stepCount: steps
                )
                return .none
            case let .keyboardOctaveOffsetChanged(raw):
                state.keyboardOctaveOffset = max(
                    AcidKeyboardMath.minOctaveOffset,
                    min(AcidKeyboardMath.maxOctaveOffset, raw)
                )
                return .none
            case let .keyboardNoteOn(midiNote, frequencyHz):
                state.keyboardPressedMidiNotes.insert(midiNote)
                state.keyboardLastNoteOn = (midiNote, frequencyHz)
                return .none
            case let .keyboardNoteOff(midiNote):
                state.keyboardPressedMidiNotes.remove(midiNote)
                return .none
            case .prepareAudioEngine:
                return .run { send in
                    @Dependency(\.audioClient) var audioClient
                    do {
                        try await audioClient.prepare()
                        await send(.audioEnginePrepared)
                    } catch {
                        await send(.audioEnginePrepareFailed(error.localizedDescription))
                    }
                }
            case .audioEnginePrepared:
                state.audioEnginePrepared = true
                state.audioEnginePrepareError = nil
                let k = state.demoKnobValue
                let t = state.demoToggleSelection
                return .run { _ in
                    @Dependency(\.audioClient) var audioClient
                    await audioClient.applyDemoSynthParams(k, t)
                }
            case let .audioEnginePrepareFailed(message):
                state.audioEnginePrepared = false
                state.audioEnginePrepareError = message
                return .none
            case .sequencerTick:
                guard state.sequencerIsRunning else { return .none }
                let steps = PianoRollGridMath.normalizedGridSteps(state.pianoRollGridSteps)
                guard steps > 0 else { return .none }
                let step = state.sequencerCurrentStep
                let toPlay = PianoRollSequencerMath.notesStarting(atStep: step, in: state.pianoRollNotes)
                let octave = state.keyboardOctaveOffset
                state.sequencerPlayheadStep = step
                state.sequencerCurrentStep = (step + 1) % steps
                if toPlay.isEmpty { return .none }
                return .run { _ in
                    @Dependency(\.audioClient) var audioClient
                    for n in toPlay {
                        let midi = PianoRollSequencerMath.midiForRow(n.row, keyboardOctaveOffset: octave)
                        let hz = AcidKeyboardMath.frequencyHz(midiNote: midi)
                        await audioClient.triggerSequencerNote(midi, hz)
                    }
                }
            case .sequencerStopTapped:
                state.sequencerIsRunning = false
                state.sequencerPlayheadStep = nil
                return .cancel(id: CancelID.sequencerLoop)
            }
        }
    }
}
