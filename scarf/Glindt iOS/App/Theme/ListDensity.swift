import SwiftUI

/// GlindtGo's density tokens. Developer-tool context benefits from
/// tighter list rows than Apple's ~60pt default — we aim for ~48pt
/// rows that still meet the 44pt tap-target invariant. Research-
/// backed (M8 density pass): Fantastical, GitHub Mobile, Mona for
/// Mastodon use similar spacing.
public extension View {
    /// Apply to individual `List` rows to shrink vertical padding
    /// while keeping the full row hit-target ≥ 44pt. Use this on
    /// every GlindtGo list that renders more than 3 rows per screen
    /// (Memory, Cron, Skills, Settings, Dashboard recent sessions,
    /// More).
    ///
    /// Pair with `glindtGoListDensity()` on the containing List to
    /// tighten inter-section spacing.
    func glindtGoCompactListRow() -> some View {
        self
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .contentShape(Rectangle())
            .frame(minHeight: 44)
    }

    /// Apply to a `List` to reduce the default minimum row height +
    /// kill the inter-row spacing iOS 18 injects between rows. Works
    /// with `.plain` and `.insetGrouped` list styles. Does not affect
    /// section-header spacing.
    func glindtGoListDensity() -> some View {
        self
            .environment(\.defaultMinListRowHeight, 36)
            .listRowSpacing(0)
    }
}
