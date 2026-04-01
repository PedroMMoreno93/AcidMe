import ComposableArchitecture
import Foundation

/// Raíz TCA de la app. Se ampliará en HUs posteriores (audio, secuenciador, UI).
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        /// Valor de demostración del AcidKnob (HU 1); más adelante se sustituirá por parámetros reales de síntesis.
        var demoKnobValue: Double = 0.35
    }

    enum Action: Equatable {
        case demoKnobValueChanged(Double)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .demoKnobValueChanged(v):
                state.demoKnobValue = min(1, max(0, v))
                return .none
            }
        }
    }
}
