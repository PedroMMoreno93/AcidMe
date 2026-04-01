import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 16) {
                Text("AcidMe!")
                    .font(.largeTitle.bold())
                Text("HU 0 · iPad · Landscape · TCA + AudioKit")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
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
