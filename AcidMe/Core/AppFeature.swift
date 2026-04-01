import ComposableArchitecture
import Foundation

/// Raíz TCA de la app. Se ampliará en HUs posteriores (audio, secuenciador, UI).
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {}

    enum Action: Equatable {}

    var body: some ReducerOf<Self> {
        Reduce { _, _ in
            .none
        }
    }
}
