import SwiftUI
import GlindtCore

struct ServerListView: View {
    let store: any GlindtConfigStore
    let activeID: ServerID?
    let onSelect: (ServerID) async -> Void
    let onDeleteActive: () async -> Void

    @State private var configs: [GlindtAppConfig] = []
    @State private var editingConfig: GlindtAppConfig?
    @State private var showingAddSheet = false

    var body: some View {
        List {
            ForEach(configs) { config in
                Button {
                    Task { await onSelect(config.id) }
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(config.displayName)
                                .font(.headline)
                                .foregroundStyle(config.id == activeID ? .blue : .primary)
                            Text(config.serverURL)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if config.id == activeID {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }

                        Button {
                            editingConfig = config
                        } label: {
                            Image(systemName: "pencil.circle")
                                .font(.title3)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let id = configs[index].id
                    Task {
                        try? await store.delete(id: id)
                        if id == activeID {
                            await onDeleteActive()
                        }
                        await refresh()
                    }
                }
            }
        }
        .navigationTitle("Servers")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await refresh()
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                ServerEditorView(onSave: { newConfig in
                    try? await store.save(newConfig)
                    await refresh()
                    showingAddSheet = false
                }, onCancel: {
                    showingAddSheet = false
                })
            }
        }
        .sheet(item: $editingConfig) { config in
            NavigationStack {
                ServerEditorView(initialConfig: config, onSave: { updatedConfig in
                    try? await store.save(updatedConfig)
                    await refresh()
                    editingConfig = nil
                }, onCancel: {
                    editingConfig = nil
                })
            }
        }
    }

    private func refresh() async {
        configs = (try? await store.allConfigs()) ?? []
    }
}
