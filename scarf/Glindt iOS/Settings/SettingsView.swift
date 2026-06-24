import SwiftUI
import GlindtCore

struct SettingsView: View {
    let config: GlindtAppConfig
    let store: any GlindtConfigStore
    let onSwitchServer: (ServerID) async -> Void
    let onDisconnect: () -> Void

    var body: some View {
        List {
            Section("Current Connection") {
                VStack(alignment: .leading) {
                    Text(config.displayName)
                        .font(.headline)
                    Text(config.serverURL)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                NavigationLink {
                    ServerListView(
                        store: store,
                        activeID: config.id,
                        onSelect: onSwitchServer,
                        onDeleteActive: onDisconnect
                    )
                } label: {
                    Label("Manage Servers", systemImage: "server.rack")
                }
            }

            Section {
                Button(role: .destructive) {
                    onDisconnect()
                } label: {
                    Label("Log Out / Switch Server", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Settings")
    }
}
