import ComposableArchitecture
import Perception
import SwiftUI

struct AppView: View {
    /// `Perception.Bindable` evita la ambigüedad con `SwiftUI.Bindable` y enlaza el `Store` a Perception.
    @Perception.Bindable var store: StoreOf<AppFeature>

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 24) {
                Text("AcidMe!")
                    .font(.largeTitle.bold())
                Text("HU 3 · Knob + Toggle + AcidButton (acción al soltar)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 16) {
                    AcidButton(title: "PLAY", systemImage: "play.fill") {
                        store.send(.demoPlayButtonReleased)
                    }
                    AcidButton(title: "CLEAR", systemImage: "trash") {
                        store.send(.demoClearButtonReleased)
                    }
                    Text("PLAY \(store.demoPlayButtonReleaseCount) · CLEAR \(store.demoClearButtonReleaseCount)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .center, spacing: 48) {
                    VStack(spacing: 8) {
                        AcidKnob(
                            value: $store.demoKnobValue,
                            label: "DEMO"
                        )
                        Text(String(format: "valor: %.3f", store.demoKnobValue))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }

                    AcidToggle(
                        selection: $store.demoToggleSelection,
                        leadingLabel: "SAW",
                        trailingLabel: "SQR"
                    )

                    Text(store.demoToggleSelection == .upper ? "Onda: sierra" : "Onda: cuadrada")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 120, alignment: .leading)
                }

                if AudioKitBootstrap.isModuleLinked {
                    Text("AudioKit enlazado")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.95, green: 0.85, blue: 0.15).opacity(0.15))
        }
    }
}

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
