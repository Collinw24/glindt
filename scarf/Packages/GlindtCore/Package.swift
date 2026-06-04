// swift-tools-version: 6.0
// Platform-neutral core for the Glindt app family (macOS and iOS).
//
// `GlindtCore` holds types that do not depend on AppKit, UIKit, or any
// platform-specific system service. The macOS and iOS app targets each link
// this package and provide their own platform shells (Sparkle + SwiftTerm on
// macOS; Citadel-based SSH transport on iOS).
//
// Minimums are chosen to match the Mac app (macOS 14.6) and the locked
// v1 iOS decision (iOS 18). Raising iOS later is free; lowering is not —
// the ViewModels on `@Observable` / `NavigationStack` are iOS 17+ features
// and we standardize on iOS 18 for feature parity with the Mac codebase.

import PackageDescription

let package = Package(
    name: "GlindtCore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "GlindtCore",
            targets: ["GlindtCore"]
        ),
    ],
    targets: [
        .target(
            name: "GlindtCore",
            path: "Sources/GlindtCore",
            exclude: [
                "ViewModels/ActivityViewModel.swift",
                "ViewModels/ConnectionStatusViewModel.swift",
                "ViewModels/CuratorViewModel.swift",
                "ViewModels/InsightsViewModel.swift",
                "ViewModels/LogsViewModel.swift",
                "ViewModels/ProjectSessionsViewModel.swift",
                "ViewModels/ProjectsViewModel.swift",
                "ViewModels/SkillsViewModel.swift",
                "ViewModels/SettingsViewModel.swift",
                "ViewModels/GatewayViewModel.swift",
                "ViewModels/CronViewModel.swift",
                "ViewModels/KanbanViewModel.swift",
                "ViewModels/MemoryViewModel.swift",
                "ViewModels/ModelCatalogViewModel.swift",
                "ViewModels/MCPViewModel.swift",
                "ViewModels/ProfilesViewModel.swift",
                "ViewModels/SessionListViewModel.swift",
            ],
            swiftSettings: [
                // Swift 5 language mode mirrors the Mac app target's
                // `SWIFT_VERSION = 5.0` build setting. Moving to strict
                // Swift 6 concurrency is a real refactor — several types
                // (`ACPEvent.availableCommands` carrying `[[String: Any]]`,
                // `ACPToolCallEvent.rawInput: [String: Any]?`) claim
                // `Sendable` without being strictly-Sendable. A follow-up
                // phase will replace those with typed payloads, then this
                // setting can bump to `.v6`.
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "GlindtCoreTests",
            dependencies: ["GlindtCore"],
            path: "Tests/GlindtCoreTests",
            exclude: [
                "M5FeatureVMTests.swift",
                "M9SlashCommandTests.swift",
                "M1ACPTests.swift",
                "M0dViewModelsTests.swift",
                "SkillsViewModelHubFilterTests.swift",
                "M0cServicesTests.swift",
                "M0eUpdaterTests.swift",
                "HermesGatewayListServiceTests.swift",
                "GatewayConfigWriterTests.swift",
                "KanbanModelsTests.swift",
                "HermesCuratorParserTests.swift",
            ]
        ),
    ]
)
