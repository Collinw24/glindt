import Testing
import Foundation
@testable import GlindtIOS

/// Smoke test — ensures GlindtIOS links in an Apple-target build.
/// All interesting behavioural coverage for the state-machine and the
/// Keychain / UserDefaults round-trips lives in `GlindtCoreTests`
/// (which runs on Linux CI). This file just guards the compile surface.
@Suite struct GlindtIOSSmokeTests {

    #if canImport(CryptoKit)
    @Test func ed25519GeneratorProducesWellFormedBundle() throws {
        let bundle = try Ed25519KeyGenerator.generate(comment: "test-comment")
        #expect(bundle.comment == "test-comment")
        #expect(bundle.publicKeyOpenSSH.hasPrefix("ssh-ed25519 "))
        #expect(bundle.publicKeyOpenSSH.hasSuffix("test-comment"))
        #expect(bundle.privateKeyPEM.contains("GLINDT ED25519 PRIVATE KEY"))

        // Round-trip: decode PEM back and verify lengths.
        let parts = Ed25519KeyGenerator.decodeRawEd25519PEM(bundle.privateKeyPEM)
        #expect(parts != nil)
        #expect(parts?.privateKey.count == 32)
        #expect(parts?.publicKey.count == 32)

        // Display fingerprint has the right shape.
        #expect(bundle.displayFingerprint.hasPrefix("ssh-ed25519 "))
        #expect(bundle.displayFingerprint.contains("…"))
    }

    @Test func ed25519PublicKeyLineIsDeterministic() {
        // Pin the OpenSSH wire format — wrong encoding would silently
        // break every authorized_keys paste.
        let fakePubKey = Data(repeating: 0xAB, count: 32)
        let line = Ed25519KeyGenerator.makeOpenSSHPublicKeyLine(
            publicKeyBytes: fakePubKey,
            comment: "hello"
        )
        let parts = line.split(separator: " ")
        #expect(parts.count == 3)
        #expect(String(parts[0]) == "ssh-ed25519")
        #expect(String(parts[2]) == "hello")
        // Base64 blob decodes to:
        //   string("ssh-ed25519") + string(<32 bytes of 0xAB>)
        //   = 4 + 11 + 4 + 32 = 51 bytes
        let b64 = String(parts[1])
        let decoded = Data(base64Encoded: b64)
        #expect(decoded?.count == 51)
    }

    @Test func decodeRejectsCorruptedPEM() {
        #expect(Ed25519KeyGenerator.decodeRawEd25519PEM("garbage") == nil)
        #expect(Ed25519KeyGenerator.decodeRawEd25519PEM("""
        -----BEGIN GLINDT ED25519 PRIVATE KEY-----
        not-base64!!
        -----END GLINDT ED25519 PRIVATE KEY-----
        """) == nil)
    }
    #endif
}
