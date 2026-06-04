---
title: Uninstalling
type: note
permalink: glindt-wiki/uninstalling
---

# Uninstalling

> **Removing GlindtGo from your iPhone?** Standard iOS app delete — long-press the icon → Remove App → Delete App. iOS purges the Keychain group (your SSH keys) and app container along with the binary, so nothing lingers. The Hermes host's `~/.ssh/authorized_keys` line you added during onboarding stays — clean it up manually if you want.

This page covers the macOS app. Glindt is a self-contained `.app` bundle with no installers, launch agents, or kernel extensions. Removing it is two steps; cleaning up its caches is one more.

## Quit and remove the app

1. Quit Glindt (⌘Q).
2. Drag **Glindt.app** from `/Applications` to the Trash.

That's the minimum. Glindt is gone.

## Clean up Glindt's caches and prefs

If you want a complete uninstall, also remove:

```bash
rm -rf ~/Library/Caches/glindt            # remote SQLite snapshots
rm -rf /tmp/glindt-ssh-$(id -u)           # ssh ControlMaster sockets (auto-cleared on reboot)
rm -f  ~/Library/Preferences/com.glindt.app.plist   # app preferences + server registry
```

The Caches dir holds atomic SQLite snapshots pulled from remote Hermes hosts. The `/tmp` dir holds SSH ControlMaster sockets — both are safe to delete; Glindt rebuilds them on demand. (As of v2.0.2 the ssh sockets live under `/tmp` rather than Caches, to stay within the 104-byte macOS Unix domain socket path limit. Older versions kept them at `~/Library/Caches/glindt/ssh/`.)

## What Glindt does NOT touch

Glindt reads Hermes's data; it does not own it. The following are **not** removed by uninstalling:

- `~/.hermes/` — your Hermes install, sessions, memory, config, etc.
- `~/.ssh/` — SSH keys and config used to reach remote servers.
- `~/.local/bin/hermes` (or wherever your `hermes` CLI lives).

To uninstall Hermes itself, follow the Hermes documentation — that's a separate process.

## What about the wiki?

Just for completeness: the GitHub wiki at <https://github.com/awizemann/glindt/wiki> is a separate git repo from the main one. Uninstalling the app has no effect on the wiki.

---
_Last updated: 2026-04-25 — Glindt v2.5.0 (added GlindtGo iOS uninstall note)_