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
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                // Tras cualquier binding, mantiene el knob en 0…1 (p. ej. arrastre del AcidKnob).
                state.demoKnobValue = min(1, max(0, state.demoKnobValue))
                return .none
            }
        }
    }
}
