// swift-tools-version: 6.0
// Glindt Design System — typed token bridge + SwiftUI component primitives
// for the macOS and iOS apps.
//
// Ships color tokens (rust/amber brand, surfaces, foregrounds, semantic, tool
// kinds) as an Xcode asset catalog and a thin Swift API
// (`GlindtColor`, `GlindtFont`, `GlindtSpace`, `GlindtRadius`, `GlindtShadow`,
//  `GlindtPrimaryButton`, `GlindtCard`, `GlindtBadge`, `GlindtTextField`,
//  `GlindtSectionHeader`, `GlindtDivider`).
//
// Both app targets (`glindt`, `glindt mobile`) link this package and `import
// GlindtDesign`. The asset catalog is bundled as a `.process` resource so the
// `Color(name, bundle: .module)` lookups in `GlindtTheme.swift` resolve at
// runtime regardless of which app is hosting the bundle.
//
// Platform minimums match the rest of the workspace: macOS 14 + iOS 18.

import PackageDescription

let package = Package(
    name: "GlindtDesign",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "GlindtDesign",
            targets: ["GlindtDesign"]
        ),
    ],
    targets: [
        .target(
            name: "GlindtDesign",
            path: "Sources/GlindtDesign",
            resources: [
                .process("GlindtBrand.xcassets"),
            ],
            swiftSettings: [
                // Match GlindtCore / GlindtIOS — Swift 5 language mode pending
                // the workspace-wide bump to strict Swift 6 concurrency.
                .swiftLanguageMode(.v5),
            ]
        ),
    ]
)
