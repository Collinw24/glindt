<p align="center">
  <img src="icon-v2.5.png" width="128" height="128" alt="Glindt app icon">
</p>

<h1 align="center">Glindt</h1>

<p align="center">
  An iOS client for the <a href="https://github.com/hermes-ai/hermes-agent">Hermes AI agent</a>.<br>
  Chat over SSH ACP, browse sessions over HTTP.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-18.0+-blue" alt="iOS">
  <img src="https://img.shields.io/badge/Swift-6-orange" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</p>

## What it is

Glindt is a native iOS app that connects to a Hermes AI agent running on a server. You type prompts, the agent streams responses in real-time, and you can browse your session history — all from your phone.

- **Chat** streams through an SSH exec channel using Hermes' Agent Client Protocol (ACP) — the same protocol the CLI uses, just over the wire
- **Session history** loads over a REST API — fast, no SQLite-over-SSH dance
- **Onboarding** is a single screen: server URL and API key

## How it works

```
 Telegram / Slack / etc.
         │
         ▼
┌──────────────────┐      HTTP (REST)       ┌────────────┐
│  Hermes server   │ ◄─────────────────── │   Glindt   │
│  (your machine)  │                       │  (iPhone)  │
│                  │      SSH (ACP chat)    │            │
│  hermes acp ─────┼───────────────────────►  ChatView  │
└──────────────────┘                       └────────────┘
```

- **HTTP** handles everything except chat: session list, message history, capabilities, skills, health checks
- **SSH** handles chat streaming only — opens a single `hermes acp` exec channel per session, stays alive until you disconnect
- No local SQLite snapshots. No SFTP. No `sqlite3` binary needed on the server.

## Build

```bash
xcodebuild -project glindt/glindt.xcodeproj -scheme glindt -configuration Debug build
```

Requires Xcode 16.0+ and iOS 18.0+.

## Architecture

```
Packages/
  GlindtCore/        Shared models, ACP client, HTTP transport, chat VM
  GlindtDesign/      Design tokens — colors, spacing, radii, shadows
  GlindtIOS/         iOS glue — SSH ACP channel, network reachability

Glindt iOS/
  App/               Entry point + onboarding + tab root
  Chat/              Chat view + controller
  Transport/         ACPClient factory + SSH key handling
```

### What's kept from upstream

- `ACPChannel` protocol and `ACPClient` actor — the JSON-RPC engine unchanged
- `HermesMessage`, `HermesToolCall`, `ACPEvent`, `ACPPromptResult` — message models unchanged
- `RichChatViewModel` — chat state machine, streaming, message grouping

### What's removed from upstream

- macOS app target entirely
- All SSH-based file I/O, SQLite backends, remote backup/restore
- Citadel as a general-purpose transport — used only for the ACP chat pipe
- Multi-server management, project dashboards, skills browser, cron, kanban, memory editor, logs, settings, gateway, webhooks, plugins, profiles, curator, insights, activity feed

## License

[MIT](LICENSE)
