import SwiftUI
import GlindtCore

@main
struct GlindtIOSApp: App {
    @State private var root = AppRootModel(store: UserDefaultsConfigStore())

    var body: some Scene {
        WindowGroup {
            AppRootView(model: root)
                .task { await root.load() }
                .dynamicTypeSize(.xSmall ... .accessibility2)
        }
    }
}

@Observable
@MainActor
final class AppRootModel {
    enum State: Equatable {
        case loading
        case onboarding
        case connected(GlindtAppConfig)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading): return true
            case (.onboarding, .onboarding): return true
            case (.connected, .connected): return true
            default: return false
            }
        }
    }

    private(set) var state: State = .loading

    private let store: any GlindtConfigStore

    init(store: any GlindtConfigStore) {
        self.store = store
    }

    func load() async {
        if let config = try? await store.load() {
            state = .connected(config)
        } else {
            state = .onboarding
        }
    }

    func connect(config: GlindtAppConfig) async {
        try? await store.save(config)
        state = .connected(config)
    }

    func disconnect() async {
        try? await store.delete()
        state = .onboarding
    }
}

struct AppRootView: View {
    let model: AppRootModel

    var body: some View {
        switch model.state {
        case .loading:
            ProgressView("Loading...")
        case .onboarding:
            OnboardingView { config in
                await model.connect(config: config)
            }
        case .connected(let config):
            GlindtTabRoot(config: config, onDisconnect: {
                Task { await model.disconnect() }
            })
        }
    }
}
