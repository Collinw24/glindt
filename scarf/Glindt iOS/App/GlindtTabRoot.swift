import SwiftUI
import GlindtCore
import GlindtDesign

struct GlindtTabRoot: View {
    let config: GlindtAppConfig
    let onDisconnect: @MainActor () -> Void

    @State private var selectedTab = Tab.chat
    @State private var capabilities = HermesCapabilitiesStore(context: .local)

    enum Tab: Hashable { case chat }

    init(config: GlindtAppConfig, onDisconnect: @escaping @MainActor () -> Void) {
        self.config = config
        self.onDisconnect = onDisconnect
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ChatView(config: config)
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(Tab.chat)
        }
        .environment(\.glindtCapabilities, capabilities)
        .environment(\.glindtAppConfig, config)
    }
}

struct GlindtCapabilitiesKey: EnvironmentKey {
    static let defaultValue = HermesCapabilitiesStore(context: .local)
}

struct GlindtAppConfigKey: EnvironmentKey {
    static let defaultValue: GlindtAppConfig? = nil
}

extension EnvironmentValues {
    var glindtCapabilities: HermesCapabilitiesStore {
        get { self[GlindtCapabilitiesKey.self] }
        set { self[GlindtCapabilitiesKey.self] = newValue }
    }
    var glindtAppConfig: GlindtAppConfig? {
        get { self[GlindtAppConfigKey.self] }
        set { self[GlindtAppConfigKey.self] = newValue }
    }
}
