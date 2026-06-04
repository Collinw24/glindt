---
title: Design-System
type: note
permalink: glindt-wiki/design-system
---

# Design System (GlindtDesign)

Glindt and GlindtGo share a single typed design-token bundle: the **GlindtDesign** Swift Package at [`glindt/Packages/GlindtDesign/`](https://github.com/awizemann/glindt/tree/main/glindt/Packages/GlindtDesign). Both targets `import GlindtDesign` and consume the same `GlindtColor` / `GlindtFont` / `GlindtSpace` / `GlindtRadius` / `GlindtShadow` tokens plus a small set of reusable SwiftUI components.

If you're building a new view or polishing an existing one, reach for these tokens first. Hardcoded colors, fonts, paddings, and corner radii are a code smell — convert them.

## Where the tokens live

```
glindt/Packages/GlindtDesign/
  Sources/GlindtDesign/
    GlindtBrand.xcassets/        # color set: brand rust, grayscale, semantic, tool kinds
    GlindtTheme.swift            # GlindtColor accessors + environment keys
    GlindtTypography.swift       # GlindtFont scale + .glindtStyle modifier
    GlindtComponents.swift       # PageHeader, Card, Badge, TextField, button styles
    GlindtChatView.swift         # 3-pane chat reference (Mac)
    GlindtPreview.swift          # preview canvas helpers
```

The `GlindtBrand.xcassets` color set ships in the package; both targets resolve `Color("AccentColor", bundle: .module)` to the rust accent automatically. No per-target asset duplication.

## Color tokens

| Token | Use |
|---|---|
| `GlindtColor.accent` | Primary brand rust. Buttons, focused states, chat user-bubble fill. |
| `GlindtColor.accentTint` | Translucent accent for chip backgrounds + selection rows. |
| `GlindtColor.onAccent` | Foreground on rust fills (high-contrast). |
| `GlindtColor.foregroundPrimary` | Default body text. |
| `GlindtColor.foregroundMuted` | Secondary text — captions, list-row subtitles. |
| `GlindtColor.foregroundFaint` | Tertiary text — metadata, "12 / 100 chars" hints. |
| `GlindtColor.backgroundPrimary` | Window/page background. |
| `GlindtColor.backgroundSecondary` | Card / list-row background. Elevated one step. |
| `GlindtColor.backgroundTertiary` | Sub-elevation for inset / inner panels. |
| `GlindtColor.border` | Default 1px stroke for cards + inputs. |
| `GlindtColor.borderStrong` | Pronounced stroke for divider rules between sections. |
| `GlindtColor.success` | Green — success badges, "Saved" pill. |
| `GlindtColor.danger` | Red — destructive button accent, error banners. |
| `GlindtColor.warning` | Amber — non-fatal banner, "missing dependency" hint. |
| `GlindtColor.info` | Cool blue — informational chips. |
| `GlindtColor.Tool.bash` | Tool-call card kind tints — `bash`. |
| `GlindtColor.Tool.edit` | `edit` (file changes). |
| `GlindtColor.Tool.search` | `search` / `grep`. |
| `GlindtColor.Tool.web` | `fetch` / browser. |
| `GlindtColor.Tool.think` | reasoning / thinking. |

All colors resolve from `GlindtBrand.xcassets`, so they adapt light/dark automatically. Don't ship terminal or syntax-highlight palettes through GlindtColor — those are content semantics, keep them inline.

## Typography (GlindtFont)

Eleven preset styles, all fixed-size on Mac:

```swift
.glindtStyle(.title1)            // 32pt semibold
.glindtStyle(.title2)            // 24pt semibold
.glindtStyle(.title3)            // 20pt semibold
.glindtStyle(.headline)          // 17pt semibold
.glindtStyle(.body)              // 15pt regular
.glindtStyle(.callout)           // 14pt regular
.glindtStyle(.footnote)          // 13pt regular
.glindtStyle(.caption)           // 12pt regular
.glindtStyle(.captionUppercase)  // 11pt semibold tracked, uppercase
.glindtStyle(.codeInline)        // 13pt monospaced
.glindtStyle(.codeBlock)         // 13pt monospaced, room for tabs
```

**Mac:** adopt `GlindtFont` everywhere. The Mac doesn't have system-wide text scaling, so fixed sizes are correct.

### iOS Dynamic Type policy

iOS users can scale text via Settings → Accessibility → Display & Text Size. GlindtFont uses fixed point sizes; adopting it blanket on iOS would regress accessibility on `.accessibility2` (much larger) or `.xSmall` (smaller) users.

iOS-specific rule:

- **Use `GlindtFont` only for**: status badges, chip labels, intentional-display elements (e.g. onboarding step titles, header chrome that's meant to be a fixed visual size).
- **Keep `.font(.headline)` / `.body` / `.caption` semantic tokens for**: list-row primary + secondary text, body copy, error messages, chat content — anything the user reads.

Decision tree per text element: *"is this read for content?"* → semantic token. *"Is this chrome / a label / a badge?"* → GlindtFont.

The iOS app already clamps Dynamic Type at the scene root (`GlindtIOSApp.swift`: `.dynamicTypeSize(.xSmall ... .accessibility2)`) so the maximum scale factor stays sane — keep that in place.

### iOS page chrome

Don't retrofit `GlindtPageHeader` over iOS tab roots. iOS uses `.navigationTitle(...)` + `.navigationBarTitleDisplayMode(.large)` as its native page-header pattern; stacking GlindtPageHeader on top creates double titles. Use GlindtPageHeader only on iOS sub-views without a native large-title bar (rare).

iOS button styling: only swap `.borderedProminent` → `GlindtPrimaryButton`. **Leave `.bordered` native** — it's the iOS convention and inherits rust through `AccentColor.colorset` automatically. Same for `.plain` (used as compact tap targets in lists).

## Spacing, radius, shadow

```swift
GlindtSpace.s1 = 4    // tight (chip padding)
GlindtSpace.s2 = 8    // small (intra-row gap)
GlindtSpace.s3 = 12   // medium (form fields)
GlindtSpace.s4 = 16   // page padding
GlindtSpace.s5 = 20
GlindtSpace.s6 = 24   // section break
GlindtSpace.s7 = 32
GlindtSpace.s8 = 40
GlindtSpace.s9 = 56
GlindtSpace.s10 = 80

GlindtRadius.sm  = 4
GlindtRadius.md  = 6
GlindtRadius.lg  = 8        // default for cards, inputs
GlindtRadius.xl  = 12
GlindtRadius.xxl = 14
GlindtRadius.pill = 999
```

Hardcoded `.padding(12)` or `cornerRadius: 8` is a code smell — convert. Same for `.glindtShadow(.sm/.md/.lg/.xl)` instead of bespoke `Shadow(...)`.

## Components

Apply with `.buttonStyle(...)` for buttons; the rest are SwiftUI views you compose directly.

| Component | Purpose |
|---|---|
| `GlindtPageHeader("Title", subtitle: "...") { trailing }` | Mac-style page header with title + subtitle + trailing-edge actions slot. |
| `GlindtCard { ... }` | Bordered, elevated container with `backgroundSecondary` fill + border + radius + shadow baked in. |
| `GlindtBadge("text", kind: .success)` | Pill chip with semantic kind (`.success/.danger/.warning/.info/.neutral`). |
| `GlindtTextField` | Themed text field — bordered, rounded, accent on focus. |
| `GlindtSectionHeader("Section")` | Uppercase tracked label used inside cards / lists. |
| `GlindtDivider` | 1px border-colored hairline. |
| `.buttonStyle(GlindtPrimaryButton())` | Rust filled button. |
| `.buttonStyle(GlindtSecondaryButton())` | Bordered button — neutral surface. |
| `.buttonStyle(GlindtGhostButton())` | Text-only button, no chrome. Use for Cancel / dismiss. |
| `.buttonStyle(GlindtDestructiveButton())` | Red filled button. Confirmation actions only. |

## Reference: design folder

Full screen mockups live at [`design/static-site/ui-kit/*.jsx`](https://github.com/awizemann/glindt/tree/main/design/static-site/ui-kit). Open `design/static-site/index.html` in a browser to walk through every screen at fidelity.

The `GlindtChatView.ChatRootView` reference component in the package is a 3-pane chat redesign target — usable for previews but not yet swapped into the live chat (the existing `RichChatView` machinery still owns the real ACP pipeline).

## Common mistakes to avoid

- **Don't introduce purple/violet tones.** v2.5 shifted away; rust is the brand color now.
- **Don't use yellow for success.** `#F0AD4E` is `.warning`. `.success` is green.
- **Don't bypass the type scale** with `.font(.system(size: 13.5))`. Pick the closest preset.
- **Don't ship terminal / syntax-highlight palettes through GlindtColor.** Content semantics — keep them inline in the renderer.
- **Don't double-up page headers on iOS** (large nav title + GlindtPageHeader → looks broken).

## Adding a new component

If you're tempted to add a ninth button style or a new section-header variant: see if an existing component plus a token modifier covers it. New components belong in `GlindtComponents.swift`, must accept `GlindtColor` / `GlindtSpace` / `GlindtRadius` parameters (no hardcoded values), and need a corresponding entry in this page.

---
_Last updated: 2026-04-25 — Glindt v2.5.0 (initial publication)_