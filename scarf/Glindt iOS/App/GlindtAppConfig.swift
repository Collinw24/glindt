import Foundation
import Security
import GlindtCore

public struct GlindtAppConfig: Sendable, Identifiable {
    public let id: ServerID
    public let apiConfig: APIServerConfig
    public var sshConfig: SSHConfig?
    public var sshPrivateKeyPEM: String?

    public var displayName: String { apiConfig.displayName }
    public var serverURL: String { apiConfig.serverURL }
    public var apiToken: String { apiConfig.apiToken }

    public init(
        id: ServerID = ServerID(),
        apiConfig: APIServerConfig,
        sshConfig: SSHConfig? = nil,
        sshPrivateKeyPEM: String? = nil
    ) {
        self.id = id
        self.apiConfig = apiConfig
        self.sshConfig = sshConfig
        self.sshPrivateKeyPEM = sshPrivateKeyPEM
    }

    public func toAPIServerContext() -> ServerContext {
        ServerContext(id: id, displayName: displayName, kind: .api(apiConfig))
    }

    public func toSSHServerContext() -> ServerContext? {
        guard let ssh = sshConfig else { return nil }
        return ServerContext(id: id, displayName: displayName, kind: .ssh(ssh))
    }

    public func toServerContext(id: ServerID) -> ServerContext {
        ServerContext(id: id, displayName: displayName, kind: .api(apiConfig))
    }

    enum CodingKeys: String, CodingKey {
        case id, apiConfig, sshConfig
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ServerID.self, forKey: .id)
        apiConfig = try container.decode(APIServerConfig.self, forKey: .apiConfig)
        sshConfig = try container.decodeIfPresent(SSHConfig.self, forKey: .sshConfig)
        sshPrivateKeyPEM = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)

        // Exclude secrets from persisted config
        let strippedAPI = APIServerConfig(
            serverURL: apiConfig.serverURL,
            apiToken: "",
            displayName: apiConfig.displayName
        )
        try container.encode(strippedAPI, forKey: .apiConfig)
        try container.encodeIfPresent(sshConfig, forKey: .sshConfig)
    }
}

extension GlindtAppConfig: Hashable {
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: GlindtAppConfig, rhs: GlindtAppConfig) -> Bool { lhs.id == rhs.id }
}

@MainActor
public protocol GlindtConfigStore: Sendable {
    func load() async throws -> GlindtAppConfig?
    func allConfigs() async throws -> [GlindtAppConfig]
    func save(_ config: GlindtAppConfig) async throws
    func setActive(id: ServerID) async throws
    func unsetActive() async throws
    func delete(id: ServerID) async throws
}

@MainActor
public final class UserDefaultsConfigStore: GlindtConfigStore {
    private let defaults = UserDefaults.standard
    private let serversKey = "glindt.servers.v2"
    private let activeServerIDKey = "glindt.activeServerID"

    private let urlKey = "glindt.serverURL"
    private let nameKey = "glindt.displayName"
    private let sshHostKey = "glindt.sshHost"
    private let sshUserKey = "glindt.sshUser"
    private let sshPortKey = "glindt.sshPort"

    private let secretStore = KeychainSecretStore()

    public init() {}

    public func load() async throws -> GlindtAppConfig? {
        let configs = try await allConfigs()
        if let activeIDString = defaults.string(forKey: activeServerIDKey),
           let activeID = UUID(uuidString: activeIDString),
           let config = configs.first(where: { $0.id == activeID }) {
            return config
        }

        if let legacy = try await loadLegacy(), !configs.contains(where: { $0.serverURL == legacy.serverURL }) {
            try await save(legacy)
            return legacy
        }

        return nil
    }

    private func loadLegacy() async throws -> GlindtAppConfig? {
        guard let url = defaults.string(forKey: urlKey), !url.isEmpty,
              let token = secretStore.get(for: "apiToken"),
              !token.isEmpty
        else { return nil }
        let name = defaults.string(forKey: nameKey) ?? url
        let apiConfig = APIServerConfig(serverURL: url, apiToken: token, displayName: name)
        var sshConfig: SSHConfig?
        if let host = defaults.string(forKey: sshHostKey), !host.isEmpty {
            let user = defaults.string(forKey: sshUserKey) ?? "root"
            let port = defaults.integer(forKey: sshPortKey)
            sshConfig = SSHConfig(host: host, user: user, port: port > 0 ? port : nil)
        }
        return GlindtAppConfig(apiConfig: apiConfig, sshConfig: sshConfig)
    }

    public func allConfigs() async throws -> [GlindtAppConfig] {
        guard let data = defaults.data(forKey: serversKey) else { return [] }
        let decoder = JSONDecoder()
        var configs = try decoder.decode([GlindtAppConfig].self, from: data)
        for i in 0..<configs.count {
            let id = configs[i].id.uuidString
            let token = secretStore.get(for: "token.\(id)")
            let sshKey = secretStore.get(for: "sshkey.\(id)")

            let api = APIServerConfig(
                serverURL: configs[i].apiConfig.serverURL,
                apiToken: token ?? "",
                displayName: configs[i].apiConfig.displayName
            )
            configs[i] = GlindtAppConfig(
                id: configs[i].id,
                apiConfig: api,
                sshConfig: configs[i].sshConfig,
                sshPrivateKeyPEM: sshKey
            )
        }
        return configs
    }

    public func save(_ config: GlindtAppConfig) async throws {
        var configs = try await allConfigs()
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
        } else {
            configs.append(config)
        }

        let id = config.id.uuidString
        secretStore.set(config.apiToken, for: "token.\(id)")
        if let sshKey = config.sshPrivateKeyPEM {
            secretStore.set(sshKey, for: "sshkey.\(id)")
        }

        let encoder = JSONEncoder()
        let data = try encoder.encode(configs)
        defaults.set(data, forKey: serversKey)
        defaults.set(config.id.uuidString, forKey: activeServerIDKey)
    }

    public func setActive(id: ServerID) async throws {
        defaults.set(id.uuidString, forKey: activeServerIDKey)
    }

    public func unsetActive() async throws {
        defaults.removeObject(forKey: activeServerIDKey)
    }

    public func delete(id: ServerID) async throws {
        var configs = try await allConfigs()
        configs.removeAll(where: { $0.id == id })

        let idString = id.uuidString
        secretStore.delete(for: "token.\(idString)")
        secretStore.delete(for: "sshkey.\(idString)")

        let encoder = JSONEncoder()
        let data = try encoder.encode(configs)
        defaults.set(data, forKey: serversKey)

        if defaults.string(forKey: activeServerIDKey) == id.uuidString {
            defaults.removeObject(forKey: activeServerIDKey)
        }
    }
}

private final class KeychainSecretStore {
    private let service = "com.glindt.app"

    func get(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let secret = String(data: data, encoding: .utf8)
        else { return nil }
        return secret
    }

    func set(_ secret: String, for account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        let data = secret.data(using: .utf8)!
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func delete(for account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

public typealias IOSServerConfig = GlindtAppConfig
