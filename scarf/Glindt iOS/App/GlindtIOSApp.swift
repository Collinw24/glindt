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
        case selection
        case connected(GlindtAppConfig)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading): return true
            case (.onboarding, .onboarding): return true
            case (.selection, .selection): return true
            case (.connected, .connected): return true
            default: return false
            }
        }
    }

    private(set) var state: State = .loading

    let store: any GlindtConfigStore

    init(store: any GlindtConfigStore) {
        self.store = store
    }

    func load() async {
        if let config = try? await store.load() {
            state = .connected(config)
        } else if let configs = try? await store.allConfigs(), !configs.isEmpty {
            state = .selection
        } else {
            state = .onboarding
        }
    }

    func connect(config: GlindtAppConfig) async {
        try? await store.save(config)
        state = .connected(config)
    }

    func switchServer(id: ServerID) async {
        try? await store.setActive(id: id)
        await load()
    }

    func logOut() async {
        try? await store.unsetActive()
        await load()
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
        case .selection:
            NavigationStack {
                ServerListView(
                    store: model.store,
                    activeID: nil,
                    onSelect: { id in
                        await model.switchServer(id: id)
                    },
                    onDeleteActive: {
                        await model.load()
                    }
                )
            }
        case .connected(let config):
            GlindtTabRoot(
                config: config,
                store: model.store,
                onSwitchServer: { id in
                    await model.switchServer(id: id)
                },
                onDisconnect: {
                    Task { await model.logOut() }
                }
            )
        }
    }
}
