import ComposableArchitecture
import SwiftUI

@main
struct AcidMeApp: App {
    @State private var store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
