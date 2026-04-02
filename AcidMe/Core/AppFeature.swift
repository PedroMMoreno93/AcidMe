import ComposableArchitecture
import Foundation

/// Raíz TCA de la app. Se ampliará en HUs posteriores (audio, secuenciador, UI).
@Reducer
struct AppFeature {
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
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                // Tras cualquier binding, mantiene el knob en 0…1 (p. ej. arrastre del AcidKnob).
                state.demoKnobValue = min(1, max(0, state.demoKnobValue))
                return .none
            case .demoPlayButtonReleased:
                state.demoPlayButtonReleaseCount += 1
                return .none
            case .demoClearButtonReleased:
                state.demoClearButtonReleaseCount += 1
                state.demoKnobValue = 0
                state.pianoRollNotes = []
                return .none
            case let .pianoRollGridStepsChanged(raw):
                let steps = PianoRollGridMath.normalizedGridSteps(raw)
                state.pianoRollGridSteps = steps
                state.pianoRollNotes = PianoRollGridMath.clampedNotes(
                    state.pianoRollNotes,
                    stepCount: steps
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
                return .none
            case let .audioEnginePrepareFailed(message):
                state.audioEnginePrepared = false
                state.audioEnginePrepareError = message
                return .none
            }
        }
    }
}
