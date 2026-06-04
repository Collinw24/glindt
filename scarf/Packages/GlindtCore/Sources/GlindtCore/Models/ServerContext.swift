import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

public typealias ServerID = UUID

public struct SSHConfig: Sendable, Hashable, Codable {
    public var host: String
    public var user: String?
    public var port: Int?
    public var identityFile: String?
    public var remoteHome: String?
    public var projectsRoot: String?
    public var hermesBinaryHint: String?

    public init(
        host: String,
        user: String? = nil,
        port: Int? = nil,
        identityFile: String? = nil,
        remoteHome: String? = nil,
        projectsRoot: String? = nil,
        hermesBinaryHint: String? = nil
    ) {
        self.host = host
        self.user = user
        self.port = port
        self.identityFile = identityFile
        self.remoteHome = remoteHome
        self.projectsRoot = projectsRoot
        self.hermesBinaryHint = hermesBinaryHint
    }
}

public enum ServerKind: Sendable, Hashable, Codable {
    case api(APIServerConfig)
    case ssh(SSHConfig)
    case local
}

public enum ServerContextError: Error, LocalizedError {
    case fileIOUnsupported

    public var errorDescription: String? {
        switch self {
        case .fileIOUnsupported:
            return "File I/O is not supported for this server kind."
        }
    }
}

public struct ServerContext: Sendable, Hashable, Identifiable {
    public let id: ServerID
    public var displayName: String
    public var kind: ServerKind

    public init(
        id: ServerID,
        displayName: String,
        kind: ServerKind
    ) {
        self.id = id
        self.displayName = displayName
        self.kind = kind
    }

    public nonisolated var paths: HermesPathSet {
        switch kind {
        case .local:
            return HermesPathSet(
                home: HermesPathSet.defaultLocalHome,
                isRemote: false,
                binaryHint: nil
            )
        case .ssh(let config):
            return HermesPathSet(
                home: config.remoteHome ?? HermesPathSet.defaultRemoteHome,
                isRemote: true,
                binaryHint: config.hermesBinaryHint
            )
        case .api:
            return HermesPathSet(
                home: HermesPathSet.defaultRemoteHome,
                isRemote: true,
                binaryHint: nil
            )
        }
    }

    public nonisolated var isRemote: Bool {
        switch kind {
        case .local: return false
        case .ssh, .api: return true
        }
    }

    public nonisolated var defaultProjectsRoot: String {
        switch kind {
        case .local:
            return NSHomeDirectory() + "/Projects"
        case .ssh(let config):
            if let configured = config.projectsRoot,
               !configured.trimmingCharacters(in: .whitespaces).isEmpty {
                return configured
            }
            return "~/projects"
        case .api:
            return "~/projects"
        }
    }

    nonisolated private static let localID = ServerID(uuidString: "00000000-0000-0000-0000-000000000001")!

    public nonisolated static let local = ServerContext(
        id: localID,
        displayName: "Local",
        kind: .local
    )

    public func resolvedUserHome() -> String {
        switch kind {
        case .local:
            return NSHomeDirectory()
        case .ssh:
            return "~"
        case .api(let config):
            return config.serverURL
        }
    }
}

// MARK: - File I/O (throws on .api and .local)

extension ServerContext {
    public nonisolated func readText(_ path: String) -> String? {
        try? readTextThrowing(path)
    }

    public nonisolated func readTextThrowing(_ path: String) throws -> String? {
        switch kind {
        case .local, .api:
            throw ServerContextError.fileIOUnsupported
        case .ssh:
            let transport = makeTransport()
            guard transport.fileExists(path) else { return nil }
            let data = try transport.readFile(path)
            guard let text = String(data: data, encoding: .utf8) else {
                throw TransportError.other(message: "File at \(path) is not valid UTF-8.")
            }
            return text
        }
    }

    public nonisolated func readData(_ path: String) -> Data? {
        switch kind {
        case .local, .api:
            return nil
        case .ssh:
            return try? makeTransport().readFile(path)
        }
    }

    @discardableResult
    public nonisolated func writeText(_ path: String, content: String) -> Bool {
        switch kind {
        case .local, .api:
            return false
        case .ssh:
            guard let data = content.data(using: .utf8) else { return false }
            do {
                try makeTransport().writeFile(path, data: data)
                return true
            } catch {
                return false
            }
        }
    }

    public nonisolated func fileExists(_ path: String) -> Bool {
        switch kind {
        case .local, .api:
            return false
        case .ssh:
            return makeTransport().fileExists(path)
        }
    }

    public nonisolated func hermesBinaryProbablyResolvable() -> Bool {
        let bin = paths.hermesBinary
        if bin.contains("/") {
            return fileExists(bin)
        }
        return true
    }

    public nonisolated func modificationDate(_ path: String) -> Date? {
        switch kind {
        case .local, .api:
            return nil
        case .ssh:
            return makeTransport().stat(path)?.mtime
        }
    }

    public nonisolated func makeTransport() -> any ServerTransport {
        switch kind {
        case .local, .api:
            return NoOpTransport(contextID: id)
        case .ssh(let config):
            if let factory = ServerContext.sshTransportFactory {
                return factory(id, config, displayName)
            }
            return NoOpTransport(contextID: id)
        }
    }

    public typealias SSHTransportFactory = @Sendable (
        _ id: ServerID,
        _ config: SSHConfig,
        _ displayName: String
    ) -> any ServerTransport

    nonisolated(unsafe) public static var sshTransportFactory: SSHTransportFactory?

    public static func invalidateCachedHome(forServerID id: ServerID) async {}
}

// MARK: - SwiftUI environment plumbing

#if canImport(SwiftUI)
private struct ServerContextEnvironmentKey: EnvironmentKey {
    static let defaultValue: ServerContext = .local
}

extension EnvironmentValues {
    public var serverContext: ServerContext {
        get { self[ServerContextEnvironmentKey.self] }
        set { self[ServerContextEnvironmentKey.self] = newValue }
    }
}
#endif
