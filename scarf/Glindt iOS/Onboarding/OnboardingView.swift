import SwiftUI
import GlindtCore

struct OnboardingView: View {
    let onConnect: @MainActor (GlindtAppConfig) async -> Void

    @State private var serverURL = ""
    @State private var apiToken = ""
    @State private var displayName = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field: Hashable { case url, token, name }

    var body: some View {
        NavigationStack {
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
                        .onSubmit { Task { await connectIfValid() } }
                } header: {
                    Text("Server Connection")
                } footer: {
                    Text("Enter the URL of your Hermes server and your API token.")
                }

                Section {
                    Button {
                        Task { await connectIfValid() }
                    } label: {
                        HStack {
                            Spacer()
                            if isConnecting {
                                ProgressView()
                            } else {
                                Text("Connect")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(serverURL.trimmingCharacters(in: .whitespaces).isEmpty || apiToken.trimmingCharacters(in: .whitespaces).isEmpty || isConnecting)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("Glindt")
        }
    }

    private func connectIfValid() async {
        let url = serverURL.trimmingCharacters(in: .whitespaces)
        let token = apiToken.trimmingCharacters(in: .whitespaces)
        let name = displayName.trimmingCharacters(in: .whitespaces)
        guard !url.isEmpty, !token.isEmpty else { return }

        isConnecting = true
        errorMessage = nil

        let config = APIServerConfig(
            serverURL: url,
            apiToken: token,
            displayName: name.isEmpty ? url : name
        )
        let http = HTTPClient(config: config)

        do {
            let healthy = try await http.healthCheck()
            if healthy {
                isConnecting = false
                let appConfig = GlindtAppConfig(apiConfig: config)
                await onConnect(appConfig)
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
