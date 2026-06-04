---
title: Build-and-Run
type: note
permalink: glindt-wiki/build-and-run
---

# Build and Run

Glindt is one Xcode project with **two app targets**: `glindt` (the macOS app) and `glindt mobile` (GlindtGo, iOS). Both targets share three local SwiftPM packages (`GlindtCore`, `GlindtIOS`, `GlindtDesign`) and pull in Sparkle (Mac auto-update) + Citadel (iOS pure-Swift SSH) as remote dependencies. No CocoaPods, no Carthage, no submodules.

## Prerequisites

- **macOS 14.6+ (Sonoma)** on the dev machine.
- **Xcode 16.0+**.
- **Hermes** at `~/.hermes/` (so the local Mac window has something to point at — see [First Run](First-Run)).
- For iOS: **Xcode iOS 18.0 simulator** (or a real iPhone running iOS 18+) and a Hermes-running host you can SSH to from the simulator.

## Open in Xcode

```bash
git clone https://github.com/awizemann/glindt.git
cd glindt
open glindt/glindt.xcodeproj
```

The project uses `PBXFileSystemSynchronizedRootGroup` — Xcode auto-discovers any new file you drop into the source tree. You don't need to manually add files to the target.

Build with ⌘B; run with ⌘R.

## Build from the command line

### Mac scheme (`glindt`)

Debug build:

```bash
xcodebuild -project glindt/glindt.xcodeproj -scheme glindt -configuration Debug build
```

Universal release build (matches what the release script produces):

```bash
xcodebuild -project glindt/glindt.xcodeproj -scheme glindt \
  -configuration Release \
  -arch arm64 -arch x86_64 ONLY_ACTIVE_ARCH=NO build
```

#### Without an Apple Developer account

`scripts/local-build.sh` (added in v2.7.1) wraps an unsigned single-arch Debug build for contributors who don't have a signing certificate. It detects arm64 / x86_64, verifies xcode-select / xcrun / xcodebuild are present, probes the Metal toolchain (offers an interactive install on a TTY, errors cleanly on CI), resolves Swift packages, and builds with `CODE_SIGNING_ALLOWED=NO`. Optional one-touch `ditto` to `/Applications/glindt.app` on explicit y/N. See [`BUILDING.md`](https://github.com/awizemann/glindt/blob/main/BUILDING.md) in the repo for the full prerequisites list.

```bash
./scripts/local-build.sh
```

### iOS scheme (`glindt mobile`)

Debug build for the simulator (no physical device needed):

```bash
xcodebuild -project glindt/glindt.xcodeproj -scheme "glindt mobile" \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" build
```

The iOS target is iPhone-only as of v2.5: `TARGETED_DEVICE_FAMILY = 1`, `SUPPORTS_MACCATALYST = NO`, `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO`.

## Project layout

```
glindt/                       repo root
  CLAUDE.md                  project instructions for Claude Code
  CONTRIBUTING.md
  README.md
  icon-v2.5.png              README hero icon
  assets/screenshots/        GlindtGo screenshot gallery (in README)
  design/                    Reference UI kit (JSX mockups + token bundle source)
  releases/v<ver>/           per-version notes (RELEASE_NOTES.md, TESTFLIGHT_CHECKLIST.md, APP_STORE_METADATA.md)
  templates/                 Community .glindttemplate catalog source
  tools/                     build-catalog.py + tests
  scripts/
    release.sh               Mac release pipeline (archive + notarize + appcast + tag)
    wiki.sh                  GitHub wiki helper
    catalog.sh               .glindttemplate catalog publishing
  glindt/                     Xcode project root
    glindt.xcodeproj          Two targets: glindt, glindt mobile
    docs/                    Internal dev notes + PRIVACY_POLICY.md
    Packages/                Local SwiftPM packages
      GlindtCore/             Shared models, services, view-models, transport,
                             ACP, parsing, security — Mac + iOS both link this
      GlindtIOS/              iOS-only: CitadelServerTransport, KeychainSSHKeyStore,
                             SSHExecACPChannel, CitadelSSHService
      GlindtDesign/           Rust palette + tokens + components — Mac + iOS
    glindt/                   MAC TARGET — start here
      glindtApp.swift         @main App, multi-window, ServerLiveStatus polling
      ContentView.swift      window root, detail view switch
      Core/
        Services/            Mac-only services (Sparkle wrapper, etc.)
        Persistence/         ServerRegistry (plist)
      Features/              Mac feature modules
      Navigation/            AppCoordinator + SidebarView
      Assets.xcassets        Mac app icon (rust set), AccentColor
      Info.plist + glindt.entitlements
    Glindt iOS/               iOS TARGET — GlindtGo
      App/                   GlindtGoTabRoot, GlindtGoCoordinator, theme glue
      Onboarding/            SSH key generation + connection test
      Servers/               Multi-server list + Forget flow
      Dashboard/             Stats grid + recent sessions + Switch server button
      Chat/                  Single-column chat + composer + project picker
      Projects/              Project detail tabs (Dashboard / Site / Sessions)
      Skills/                Hub / Installed / Updates sub-tabs
      Memory/                MEMORY.md + USER.md editor
      Cron/                  Read-only list with human-readable schedules
      Settings/              Read view + Quick Edits sheet (7 keys)
      Components/            GlindtDesign-wrapped iOS controls
      Notifications/         APNs skeleton (gated apnsEnabled = false)
      Assets.xcassets        iOS rust app icon set + accent color
    glindtTests/              Mac target unit tests (Swift Testing)
    glindtUITests/            Mac UI tests
    Glindt iOSTests/          iOS unit test placeholder
    Glindt iOSUITests/        iOS UI test placeholder
```

## Swift 6 concurrency

The project compiles with strict concurrency on. Two non-negotiables ([detail in CLAUDE.md](https://github.com/awizemann/glindt/blob/main/CLAUDE.md)):

- `@MainActor` is the default isolation. Services use `nonisolated` async methods and route results back to MainActor for UI updates.
- All closures captured by `Task`, `Task.detached`, or `withCheckedThrowingContinuation` must be `@Sendable`. Don't capture non-Sendable types across concurrency boundaries.

## What to look at first

1. [`glindtApp.swift`](https://github.com/awizemann/glindt/blob/main/glindt/glindt/glindtApp.swift) — Mac app entry point, multi-window setup, `ContextBoundRoot` injecting the `ServerContext` and friends.
2. [`Navigation/AppCoordinator.swift`](https://github.com/awizemann/glindt/blob/main/glindt/glindt/Navigation/AppCoordinator.swift) — single source of truth for Mac navigation.
3. [`Models/ServerContext.swift`](https://github.com/awizemann/glindt/blob/main/glindt/Packages/GlindtCore/Sources/GlindtCore/Models/ServerContext.swift) — the unified handle to a Hermes install (used by both targets).
4. [`Transport/`](https://github.com/awizemann/glindt/tree/main/glindt/Packages/GlindtCore/Sources/GlindtCore/Transport) (LocalTransport + SSHTransport) and [`GlindtIOS/CitadelServerTransport.swift`](https://github.com/awizemann/glindt/blob/main/glindt/Packages/GlindtIOS/Sources/GlindtIOS/CitadelServerTransport.swift) — the three transport implementations.
5. Any feature module under [`glindt/Features/`](https://github.com/awizemann/glindt/tree/main/glindt/glindt/Features) for the Mac MVVM-F shape, or under [`Glindt iOS/`](https://github.com/awizemann/glindt/tree/main/glindt/Glindt%20iOS) for the iOS equivalents.
6. [`GlindtGoTabRoot.swift`](https://github.com/awizemann/glindt/blob/main/glindt/Glindt%20iOS/App/GlindtGoTabRoot.swift) — iOS root, 5-tab navigation, ServerContext wiring.

## Running tests

Mac target tests:

```bash
xcodebuild test -project glindt/glindt.xcodeproj -scheme glindt
```

GlindtCore SwiftPM tests (the bulk of v2.5 coverage — 14 test suites):

```bash
swift test --package-path glindt/Packages/GlindtCore
```

See [Testing](Testing) for the full inventory.

## Releasing

The Mac release runs through `./scripts/release.sh <version>` — don't invoke `xcodebuild archive` / `notarytool` / `gh release create` by hand. The iOS release is a separate Xcode Archive + App Store Connect upload (see [`releases/v<ver>/TESTFLIGHT_CHECKLIST.md`](https://github.com/awizemann/glindt/blob/main/releases/v2.5.0/TESTFLIGHT_CHECKLIST.md) and [`APP_STORE_METADATA.md`](https://github.com/awizemann/glindt/blob/main/releases/v2.5.0/APP_STORE_METADATA.md)). See [Release Process](Release-Process).

---
_Last updated: 2026-04-25 — Glindt v2.5.0 (two targets, GlindtCore + GlindtIOS + GlindtDesign packages, iPhone-only iOS)_