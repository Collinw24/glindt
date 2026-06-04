#if canImport(Citadel)

import Foundation
import Citadel
import CryptoKit
import GlindtCore
import GlindtIOS

public extension ACPClient {
    static func forGlindt(
        context: ServerContext,
        sshConfig: SSHConfig,
        keyProvider: @escaping @Sendable () async throws -> SSHKeyBundle
    ) -> ACPClient {
        ACPClient(context: context) { ctx in
            try await SSHMaker.openChannel(for: ctx, sshConfig: sshConfig, keyProvider: keyProvider)
        }
    }
}

public struct SSHKeyBundle: Sendable {
    let privateKeyPEM: String
    let publicKeySSHLine: String
}

enum SSHKeyStoreError: Error, LocalizedError {
    case backendFailure(message: String, osStatus: Int32?)
    case keyNotFound

    var errorDescription: String? {
        switch self {
        case .backendFailure(let msg, _): return msg
        case .keyNotFound: return "No SSH key found."
        }
    }
}

enum SSHMaker {
    static func openChannel(
        for context: ServerContext,
        sshConfig: SSHConfig,
        keyProvider: @Sendable () async throws -> SSHKeyBundle
    ) async throws -> any ACPChannel {
        let key = try await keyProvider()
        let client = try await openSSHClient(config: sshConfig, key: key)
        let hermesCmd = context.paths.hermesBinary + " acp"
        let command = "PATH=\"$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$HOME/.hermes/bin:$PATH\" exec \(hermesCmd)"
        return try await SSHACPChannel(client: client, command: command)
    }

    private static func openSSHClient(
        config: SSHConfig,
        key: SSHKeyBundle
    ) async throws -> SSHClient {
        guard let parts = decodeEd25519PEM(key.privateKeyPEM) else {
            throw ACPChannelError.launchFailed("Stored private key is not in the expected Ed25519 PEM format")
        }
        guard let ck = try? Curve25519.Signing.PrivateKey(rawRepresentation: parts.privateKey) else {
            throw ACPChannelError.launchFailed("Stored private key is malformed")
        }
        let username = config.user ?? "root"
        let auth: SSHAuthenticationMethod = .ed25519(username: username, privateKey: ck)
        var settings = SSHClientSettings(
            host: config.host,
            authenticationMethod: { auth },
            hostKeyValidator: .acceptAnything()
        )
        if let port = config.port { settings.port = port }
        do {
            return try await SSHClient.connect(to: settings)
        } catch {
            throw ACPChannelError.launchFailed("SSH connect to \(config.host) failed: \(error.localizedDescription)")
        }
    }

    private static func decodeEd25519PEM(_ pem: String) -> (privateKey: Data, publicKeyLine: String?)? {
        let lines = pem.components(separatedBy: "\n")
        guard let headerIdx = lines.firstIndex(where: { $0.hasPrefix("-----BEGIN") }),
              let footerIdx = lines.firstIndex(where: { $0.hasPrefix("-----END") }),
              footerIdx > headerIdx else { return nil }
        let b64 = lines[(headerIdx + 1)..<footerIdx].joined()
        guard let raw = Data(base64Encoded: b64), raw.count >= 32 else { return nil }
        return (raw, nil)
    }
}

#endif
