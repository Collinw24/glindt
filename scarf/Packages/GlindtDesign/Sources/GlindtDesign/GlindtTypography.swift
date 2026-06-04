//
//  GlindtTypography.swift
//  Glindt Design System — Apple HIG-aligned type scale
//
//  Uses SF Pro (system) for UI text and SF Mono for code/transcripts.
//  Sizes mirror the CSS tokens (--text-caption ... --text-largeTitle).
//
//  Usage:
//    Text("Settings").font(GlindtFont.title2)
//    Text(message).font(GlindtFont.body)
//    Text("v1.2.0").font(GlindtFont.caption).foregroundStyle(GlindtColor.foregroundMuted)
//

import SwiftUI

public enum GlindtFont {
    // Display / titles — use rounded SF Pro Display (`.default` design + tight tracking).
    public static let largeTitle = Font.system(size: 34, weight: .semibold, design: .default)
    public static let title1     = Font.system(size: 28, weight: .semibold, design: .default)
    public static let title2     = Font.system(size: 22, weight: .semibold, design: .default)
    public static let title3     = Font.system(size: 20, weight: .semibold, design: .default)

    // Body & labels
    public static let headline   = Font.system(size: 17, weight: .semibold)
    public static let subhead    = Font.system(size: 16, weight: .medium)
    public static let callout    = Font.system(size: 15, weight: .regular)
    public static let body       = Font.system(size: 14, weight: .regular)
    public static let bodyEmph   = Font.system(size: 14, weight: .medium)
    public static let footnote   = Font.system(size: 13, weight: .regular)
    public static let caption    = Font.system(size: 12, weight: .regular)
    public static let captionStrong = Font.system(size: 12, weight: .semibold)
    public static let caption2   = Font.system(size: 10, weight: .medium)

    // Code / mono — for transcripts, command output, file paths.
    public static let mono       = Font.system(size: 13, weight: .regular, design: .monospaced)
    public static let monoSmall  = Font.system(size: 12, weight: .regular, design: .monospaced)
}

/// Convenience text styles. Apply with `.glindtStyle(.headline)`.
public enum GlindtTextStyle {
    case largeTitle, title1, title2, title3
    case headline, subhead, body, bodyEmph, callout, footnote
    case caption, captionStrong, captionUppercase
    case mono, code

    var font: Font {
        switch self {
        case .largeTitle:        return GlindtFont.largeTitle
        case .title1:            return GlindtFont.title1
        case .title2:            return GlindtFont.title2
        case .title3:            return GlindtFont.title3
        case .headline:          return GlindtFont.headline
        case .subhead:           return GlindtFont.subhead
        case .body:              return GlindtFont.body
        case .bodyEmph:          return GlindtFont.bodyEmph
        case .callout:           return GlindtFont.callout
        case .footnote:          return GlindtFont.footnote
        case .caption,
             .captionUppercase:  return GlindtFont.caption
        case .captionStrong:     return GlindtFont.captionStrong
        case .mono, .code:       return GlindtFont.mono
        }
    }
}

public extension View {
    /// Apply a Glindt type style. Handles font + tracking + (for `captionUppercase`) text-case.
    @ViewBuilder
    func glindtStyle(_ style: GlindtTextStyle) -> some View {
        switch style {
        case .largeTitle:
            self.font(style.font).tracking(-0.7)
        case .title1:
            self.font(style.font).tracking(-0.5)
        case .title2, .title3:
            self.font(style.font).tracking(-0.3)
        case .captionUppercase:
            self.font(GlindtFont.captionStrong)
                .textCase(.uppercase)
                .tracking(0.5)
        default:
            self.font(style.font)
        }
    }
}
