import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 24) {
                Text("AcidMe!")
                    .font(.largeTitle.bold())
                Text("HU 2 · AcidKnob + AcidToggle horizontal (toque → A/B)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(alignment: .center, spacing: 48) {
                    VStack(spacing: 8) {
                        AcidKnob(
                            value: Binding(
                                get: { store.demoKnobValue },
                                set: { store.send(.demoKnobValueChanged($0)) }
                            ),
                            label: "DEMO"
                        )
                        Text(String(format: "valor: %.3f", store.demoKnobValue))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }

                    AcidToggle(
                        selection: Binding(
                            get: { store.demoToggleSelection },
                            set: { store.send(.demoToggleSelectionChanged($0)) }
                        ),
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
