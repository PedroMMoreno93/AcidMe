import ComposableArchitecture
import Foundation

/// Raíz TCA de la app. Se ampliará en HUs posteriores (audio, secuenciador, UI).
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
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
            }
        }
    }
}
