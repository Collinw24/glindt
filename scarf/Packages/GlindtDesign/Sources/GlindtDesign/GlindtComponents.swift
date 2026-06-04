//
//  GlindtComponents.swift
//  Glindt Design System — opinionated SwiftUI component primitives.
//
//  These mirror the buttons, cards, badges, and inputs used in the Glindt UI kit.
//  Keep them small. Reach for them instead of inlining the same `.padding()
//  .background() .clipShape()` chain across screens.
//

import SwiftUI

// MARK: - Buttons

public struct GlindtPrimaryButton: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .glindtStyle(.bodyEmph)
            .foregroundStyle(GlindtColor.onAccent)
            .padding(.horizontal, GlindtSpace.s4)
            .padding(.vertical, GlindtSpace.s2)
            .background(
                RoundedRectangle(cornerRadius: GlindtRadius.md, style: .continuous)
                    .fill(configuration.isPressed ? GlindtColor.accentActive : GlindtColor.accent)
            )
            .glindtShadow(.sm)
            .opacity(configuration.isPressed ? 0.95 : 1)
    }
}

public struct GlindtSecondaryButton: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .glindtStyle(.bodyEmph)
            .foregroundStyle(GlindtColor.foregroundPrimary)
            .padding(.horizontal, GlindtSpace.s4)
            .padding(.vertical, GlindtSpace.s2)
            .background(
                RoundedRectangle(cornerRadius: GlindtRadius.md, style: .continuous)
                    .fill(configuration.isPressed
                          ? GlindtColor.borderStrong
                          : GlindtColor.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: GlindtRadius.md, style: .continuous)
                            .strokeBorder(GlindtColor.borderStrong, lineWidth: 1)
                    )
            )
    }
}

public struct GlindtGhostButton: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .glindtStyle(.bodyEmph)
            .foregroundStyle(GlindtColor.foregroundPrimary)
            .padding(.horizontal, GlindtSpace.s3)
            .padding(.vertical, GlindtSpace.s2)
            .background(
                RoundedRectangle(cornerRadius: GlindtRadius.md, style: .continuous)
                    .fill(configuration.isPressed
                          ? GlindtColor.accentTint
                          : Color.clear)
            )
    }
}

public struct GlindtDestructiveButton: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .glindtStyle(.bodyEmph)
            .foregroundStyle(.white)
            .padding(.horizontal, GlindtSpace.s4)
            .padding(.vertical, GlindtSpace.s2)
            .background(
                RoundedRectangle(cornerRadius: GlindtRadius.md, style: .continuous)
                    .fill(GlindtColor.danger.opacity(configuration.isPressed ? 0.85 : 1.0))
            )
    }
}

// MARK: - Card

public struct GlindtCard<Content: View>: View {
    let padding: CGFloat
    let content: () -> Content

    public init(padding: CGFloat = GlindtSpace.s4, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.content = content
    }

    public var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: GlindtRadius.xl, style: .continuous)
                    .fill(GlindtColor.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GlindtRadius.xl, style: .continuous)
                    .strokeBorder(GlindtColor.border, lineWidth: 1)
            )
            .glindtShadow(.sm)
    }
}

// MARK: - Badge / Pill

public enum GlindtBadgeKind {
    case neutral, brand, success, danger, warning, info

    var fill: Color {
        switch self {
        case .neutral: return GlindtColor.backgroundTertiary
        case .brand:   return GlindtColor.accentTint
        case .success: return GlindtColor.success.opacity(0.16)
        case .danger:  return GlindtColor.danger.opacity(0.16)
        case .warning: return GlindtColor.warning.opacity(0.18)
        case .info:    return GlindtColor.info.opacity(0.16)
        }
    }
    var fg: Color {
        switch self {
        case .neutral: return GlindtColor.foregroundMuted
        case .brand:   return GlindtColor.accent
        case .success: return GlindtColor.success
        case .danger:  return GlindtColor.danger
        case .warning: return GlindtColor.warning
        case .info:    return GlindtColor.info
        }
    }
}

public struct GlindtBadge: View {
    let text: String
    let kind: GlindtBadgeKind

    public init(_ text: String, kind: GlindtBadgeKind = .neutral) {
        self.text = text
        self.kind = kind
    }

    public var body: some View {
        Text(text)
            .glindtStyle(.captionStrong)
            .foregroundStyle(kind.fg)
            .padding(.horizontal, GlindtSpace.s2)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(kind.fill)
            )
    }
}

// MARK: - Inputs

public struct GlindtTextField: View {
    let placeholder: String
    @Binding var text: String

    public init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .glindtStyle(.body)
            .padding(.horizontal, GlindtSpace.s3)
            .padding(.vertical, GlindtSpace.s2)
            .background(
                RoundedRectangle(cornerRadius: GlindtRadius.md, style: .continuous)
                    .fill(GlindtColor.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GlindtRadius.md, style: .continuous)
                    .strokeBorder(GlindtColor.borderStrong, lineWidth: 1)
            )
    }
}

// MARK: - Section header

public struct GlindtSectionHeader: View {
    let title: String
    let subtitle: String?

    public init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .glindtStyle(.captionUppercase)
                .foregroundStyle(GlindtColor.foregroundMuted)
            if let subtitle {
                Text(subtitle)
                    .glindtStyle(.footnote)
                    .foregroundStyle(GlindtColor.foregroundFaint)
            }
        }
    }
}

// MARK: - Divider

public struct GlindtDivider: View {
    public init() {}
    public var body: some View {
        Rectangle()
            .fill(GlindtColor.border)
            .frame(height: 1)
    }
}

// MARK: - Page header

/// Standard page-level title/subtitle/actions header used at the top of
/// every feature route. Mirrors the `ContentHeader` component in the
/// design system's static-site / ui-kit. Drops a hairline divider at the
/// bottom so feature content can flush against it.
public struct GlindtPageHeader<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let trailing: Trailing

    public init(_ title: String,
                subtitle: String? = nil,
                @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: GlindtSpace.s3) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .glindtStyle(.title2)
                    .foregroundStyle(GlindtColor.foregroundPrimary)
                if let subtitle {
                    Text(subtitle)
                        .glindtStyle(.footnote)
                        .foregroundStyle(GlindtColor.foregroundMuted)
                }
            }
            Spacer()
            trailing
        }
        .padding(.horizontal, GlindtSpace.s6)
        .padding(.top, GlindtSpace.s5)
        .padding(.bottom, GlindtSpace.s4)
        .overlay(
            Rectangle()
                .fill(GlindtColor.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}
