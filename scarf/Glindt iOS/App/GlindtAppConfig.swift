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
}

extension GlindtAppConfig: Hashable {
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: GlindtAppConfig, rhs: GlindtAppConfig) -> Bool { lhs.id == rhs.id }
}

@MainActor
public protocol GlindtConfigStore: Sendable {
    func load() async throws -> GlindtAppConfig?
    func save(_ config: GlindtAppConfig) async throws
    func delete() async throws
}

@MainActor
public final class UserDefaultsConfigStore: GlindtConfigStore {
    private let defaults = UserDefaults.standard
    private let urlKey = "glindt.serverURL"
    private let nameKey = "glindt.displayName"
    private let sshHostKey = "glindt.sshHost"
    private let sshUserKey = "glindt.sshUser"
    private let sshPortKey = "glindt.sshPort"
    private let tokenStore = KeychainTokenStore()

    public func load() async throws -> GlindtAppConfig? {
        guard let url = defaults.string(forKey: urlKey), !url.isEmpty,
              let token = tokenStore.get(),
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

    public func save(_ config: GlindtAppConfig) async throws {
        defaults.set(config.serverURL, forKey: urlKey)
        defaults.set(config.displayName, forKey: nameKey)
        tokenStore.set(config.apiToken)
        if let ssh = config.sshConfig {
            defaults.set(ssh.host, forKey: sshHostKey)
            defaults.set(ssh.user ?? "root", forKey: sshUserKey)
            if let port = ssh.port { defaults.set(port, forKey: sshPortKey) }
        }
    }

    public func delete() async throws {
        defaults.removeObject(forKey: urlKey)
        defaults.removeObject(forKey: nameKey)
        defaults.removeObject(forKey: sshHostKey)
        defaults.removeObject(forKey: sshUserKey)
        defaults.removeObject(forKey: sshPortKey)
        tokenStore.delete()
    }
}

private final class KeychainTokenStore {
    private let service = "com.glindt.app"
    private let account = "apiToken"

    func get() -> String? {
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
              let token = String(data: data, encoding: .utf8)
        else { return nil }
        return token
    }

    func set(_ token: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        let data = token.data(using: .utf8)!
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

public typealias IOSServerConfig = GlindtAppConfig
