// swift-tools-version: 6.0
// iOS-specific support library: Keychain-backed key storage,
// UserDefaults-backed server config, Citadel-backed SSH connection
// testing + key generation. Consumed by the `glindt-ios` app target.
//
// Not built on Linux CI — Citadel's runtime is Apple-only, and
// `Security.framework` (for iOS Keychain) ships in the Apple SDKs
// only. The testable state-machine logic for onboarding lives in
// `GlindtCore/Security/` so Linux `swift test` still exercises the
// core transitions via `MockSSHConnectionTester` and
// `InMemorySSHKeyStore`.

import PackageDescription

let package = Package(
    name: "GlindtIOS",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        // macOS is included so that (a) Xcode's indexer is happy on a
        // Mac-only developer workstation while the iOS target compiles
        // against the same source tree, and (b) future Mac-catalyst /
        // Designed-for-iPad scenarios work without surgery. Running
        // `glindt-ios` on the Mac is not a supported product today.
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "GlindtIOS",
            targets: ["GlindtIOS"]
        ),
    ],
    dependencies: [
        .package(path: "../GlindtCore"),
        // Pinned tight to the 0.12 minor line. Citadel pre-1.0 has
        // changed its authentication-method variant names between
        // minor versions (0.7 → 0.9 → 0.12) — letting the version
        // float to 0.13+ without a code review risks a silent build
        // break in `CitadelSSHService.buildClientSettings(...)`. When
        // bumping the minor, smoke test onboarding against:
        //   (a) a real host with 1Password SSH agent
        //   (b) a real host with a hand-edited `authorized_keys`
        .package(url: "https://github.com/orlandos-nl/Citadel", .upToNextMinor(from: "0.12.0")),
    ],
    targets: [
        .target(
            name: "GlindtIOS",
            dependencies: [
                .product(name: "GlindtCore", package: "GlindtCore"),
                .product(
                    name: "Citadel",
                    package: "Citadel",
                    // Don't attempt to link Citadel on Linux — SPM won't
                    // build this target on Linux anyway (iOS-only), but
                    // this keeps the resolution graph clean if GlindtIOS
                    // ever ends up as a transitive dep from something
                    // that DOES target Linux.
                    condition: .when(platforms: [.iOS, .macOS])
                ),
            ],
            path: "Sources/GlindtIOS",
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "GlindtIOSTests",
            dependencies: ["GlindtIOS"],
            path: "Tests/GlindtIOSTests"
        ),
    ]
)
