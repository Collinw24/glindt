## What's New in 1.6.1

### Auto-updates

Glindt now ships with [Sparkle](https://sparkle-project.org). On launch (and daily thereafter) it checks an EdDSA-signed appcast at [awizemann.github.io/glindt/appcast.xml](https://awizemann.github.io/glindt/appcast.xml). When a new version is available you'll get an in-app update prompt — no more manually downloading zips and dragging into Applications.

You can disable automatic checks or trigger a manual one from **Settings → General → Updates**, the menu bar icon, or the **Glindt → Check for Updates…** menu item.

### Notarized & Developer ID signed

This is the first release that's properly Developer ID signed and notarized by Apple. Gatekeeper accepts it on first launch — no more right-click → Open dance, no more "Glindt cannot be opened because the developer cannot be verified" warnings.

### Fixes

- Chat works correctly when no terminal hermes session is running, and surfaces the real error when it can't reach the agent (b6df…)

### Under the hood

- Tracked `Info.plist` (replacing auto-generation) so signing-relevant keys live in version control
- New `UpdaterService` wraps Sparkle and is injected via SwiftUI `.environment()`
- One-command release pipeline at [scripts/release.sh](https://github.com/awizemann/glindt/blob/main/scripts/release.sh) handles archive → sign → notarize → staple → appcast → GitHub release → tag

---

**Migrating from 1.6.0:** unzip and replace your existing `Glindt.app` in `/Applications`. After this release, future updates install in-place via Sparkle.
