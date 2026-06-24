import SwiftUI
import GlindtCore

struct ServerEditorView: View {
    let initialConfig: GlindtAppConfig?
    let onSave: @MainActor (GlindtAppConfig) async -> Void
    let onCancel: (() -> Void)?

    @State private var serverURL = ""
    @State private var apiToken = ""
    @State private var displayName = ""

    // SSH Config
    @State private var sshHost = ""
    @State private var sshUser = ""
    @State private var sshPort = ""
    @State private var sshPrivateKeyPEM = ""
    @State private var showSSHAdvanced = false

    @State private var isConnecting = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field: Hashable { case url, token, name, sshHost, sshUser, sshPort, sshKey }

    init(
        initialConfig: GlindtAppConfig? = nil,
        onSave: @escaping @MainActor (GlindtAppConfig) async -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.initialConfig = initialConfig
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        Form {
            Section {
                TextField("Server URL", text: $serverURL)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .url)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .token }

                SecureField("API Token", text: $apiToken)
                    .textContentType(.password)
                    .focused($focusedField, equals: .token)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .name }

                TextField("Display Name (optional)", text: $displayName)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.done)
            } header: {
                Text("Server Connection")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter the URL of your Hermes server and your API token.")
                    Text("Glindt connects to a Hermes instance, which can interface with local LLMs (like Ollama) or cloud providers.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                DisclosureGroup("SSH Streaming (Advanced)", isExpanded: $showSSHAdvanced) {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("SSH Host", text: $sshHost)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .sshHost)

                        TextField("SSH User", text: $sshUser)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .sshUser)

                        TextField("SSH Port (default 22)", text: $sshPort)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .sshPort)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Private Key (PEM)").font(.caption).foregroundStyle(.secondary)
                            TextEditor(text: $sshPrivateKeyPEM)
                                .font(.system(.caption, design: .monospaced))
                                .frame(minHeight: 100)
                                .focused($focusedField, equals: .sshKey)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } footer: {
                Text("Configure SSH for real-time chat streaming. Glindt uses Hermes' Agent Client Protocol over SSH to your server or local machine.")
            }

            Section {
                Button {
                    Task { await validateAndSave() }
                } label: {
                    HStack {
                        Spacer()
                        if isConnecting {
                            ProgressView()
                        } else {
                            Text(initialConfig == nil ? "Connect" : "Save Changes")
                                .bold()
                        }
                        Spacer()
                    }
                }
                .disabled(serverURL.trimmingCharacters(in: .whitespaces).isEmpty || apiToken.trimmingCharacters(in: .whitespaces).isEmpty || isConnecting)

                if let onCancel {
                    Button("Cancel", role: .cancel) {
                        onCancel()
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }
        }
        .navigationTitle(initialConfig == nil ? "Add Server" : "Edit Server")
        .onAppear {
            if let config = initialConfig {
                serverURL = config.serverURL
                apiToken = config.apiToken
                displayName = config.displayName
                if let ssh = config.sshConfig {
                    sshHost = ssh.host
                    sshUser = ssh.user ?? ""
                    sshPort = ssh.port.map(String.init) ?? ""
                    sshPrivateKeyPEM = config.sshPrivateKeyPEM ?? ""
                    showSSHAdvanced = true
                }
            }
        }
    }

    private func validateAndSave() async {
        let url = serverURL.trimmingCharacters(in: .whitespaces)
        let token = apiToken.trimmingCharacters(in: .whitespaces)
        let name = displayName.trimmingCharacters(in: .whitespaces)
        guard !url.isEmpty, !token.isEmpty else { return }

        isConnecting = true
        errorMessage = nil

        let apiConfig = APIServerConfig(
            serverURL: url,
            apiToken: token,
            displayName: name.isEmpty ? url : name
        )
        let http = HTTPClient(config: apiConfig)

        do {
            let healthy = try await http.healthCheck()
            if healthy {
                var sshConfig: SSHConfig?
                if !sshHost.trimmingCharacters(in: .whitespaces).isEmpty {
                    sshConfig = SSHConfig(
                        host: sshHost.trimmingCharacters(in: .whitespaces),
                        user: sshUser.trimmingCharacters(in: .whitespaces).isEmpty ? nil : sshUser.trimmingCharacters(in: .whitespaces),
                        port: Int(sshPort.trimmingCharacters(in: .whitespaces))
                    )
                }

                let appConfig = GlindtAppConfig(
                    id: initialConfig?.id ?? ServerID(),
                    apiConfig: apiConfig,
                    sshConfig: sshConfig,
                    sshPrivateKeyPEM: sshPrivateKeyPEM.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : sshPrivateKeyPEM
                )

                isConnecting = false
                await onSave(appConfig)
            } else {
                errorMessage = "Server returned an unhealthy response."
                isConnecting = false
            }
        } catch {
            errorMessage = "Could not connect: \(error.localizedDescription)"
            isConnecting = false
        }
    }
}
