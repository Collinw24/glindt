//
//  GlindtPreview.swift
//  Glindt Design System — quick component preview.
//
//  Open this file in Xcode and the canvas (⌥⌘P) shows every component at once,
//  in light and dark. Use it to sanity-check the bundle works after install.
//

import SwiftUI

public struct GlindtPreviewGallery: View {
    @State private var query = ""
    @State private var draft = "Hello, Glindt"

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlindtSpace.s8) {

                // ── Header ──────────────────────────────────────────────
                VStack(alignment: .leading, spacing: GlindtSpace.s2) {
                    Text("Glindt Design System")
                        .glindtStyle(.largeTitle)
                        .foregroundStyle(GlindtColor.foregroundPrimary)
                    Text("Component preview — light / dark resolves from the asset catalog.")
                        .glindtStyle(.subhead)
                        .foregroundStyle(GlindtColor.foregroundMuted)
                }

                // ── Buttons ─────────────────────────────────────────────
                section("Buttons") {
                    HStack(spacing: GlindtSpace.s3) {
                        Button("Primary") {}.buttonStyle(GlindtPrimaryButton())
                        Button("Secondary") {}.buttonStyle(GlindtSecondaryButton())
                        Button("Ghost") {}.buttonStyle(GlindtGhostButton())
                        Button("Delete") {}.buttonStyle(GlindtDestructiveButton())
                    }
                }

                // ── Badges ──────────────────────────────────────────────
                section("Badges") {
                    HStack(spacing: GlindtSpace.s2) {
                        GlindtBadge("Neutral")
                        GlindtBadge("Brand",   kind: .brand)
                        GlindtBadge("Success", kind: .success)
                        GlindtBadge("Warning", kind: .warning)
                        GlindtBadge("Danger",  kind: .danger)
                        GlindtBadge("Info",    kind: .info)
                    }
                }

                // ── Inputs ──────────────────────────────────────────────
                section("Inputs") {
                    VStack(alignment: .leading, spacing: GlindtSpace.s3) {
                        GlindtTextField("Search", text: $query)
                        GlindtTextField("Compose a message", text: $draft)
                    }
                }

                // ── Card ────────────────────────────────────────────────
                section("Card") {
                    GlindtCard {
                        VStack(alignment: .leading, spacing: GlindtSpace.s2) {
                            GlindtSectionHeader("Connection", subtitle: "anthropic.com")
                            GlindtDivider()
                            HStack {
                                Text("Status")
                                    .glindtStyle(.body)
                                    .foregroundStyle(GlindtColor.foregroundMuted)
                                Spacer()
                                GlindtBadge("Connected", kind: .success)
                            }
                            HStack {
                                Text("Last run")
                                    .glindtStyle(.body)
                                    .foregroundStyle(GlindtColor.foregroundMuted)
                                Spacer()
                                Text("2 min ago")
                                    .glindtStyle(.bodyEmph)
                                    .foregroundStyle(GlindtColor.foregroundPrimary)
                            }
                        }
                    }
                }

                // ── Tool kind swatches (chat) ───────────────────────────
                section("Tool kinds") {
                    HStack(spacing: GlindtSpace.s3) {
                        toolSwatch("Bash",   GlindtColor.Tool.bash)
                        toolSwatch("Edit",   GlindtColor.Tool.edit)
                        toolSwatch("Search", GlindtColor.Tool.search)
                        toolSwatch("Web",    GlindtColor.Tool.web)
                        toolSwatch("Think",  GlindtColor.Tool.think)
                    }
                }

                // ── Brand gradient ──────────────────────────────────────
                section("Brand gradient") {
                    RoundedRectangle(cornerRadius: GlindtRadius.xl, style: .continuous)
                        .fill(GlindtGradient.brand)
                        .frame(height: 80)
                        .overlay(
                            Text("amber → rust → deep")
                                .glindtStyle(.subhead)
                                .foregroundStyle(.white)
                        )
                }
            }
            .padding(GlindtSpace.s8)
        }
        .background(GlindtColor.backgroundPrimary.ignoresSafeArea())
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: GlindtSpace.s3) {
            Text(title)
                .glindtStyle(.captionUppercase)
                .foregroundStyle(GlindtColor.foregroundMuted)
            content()
        }
    }

    private func toolSwatch(_ name: String, _ color: Color) -> some View {
        VStack(spacing: GlindtSpace.s1) {
            Circle().fill(color).frame(width: 24, height: 24)
            Text(name)
                .glindtStyle(.caption)
                .foregroundStyle(GlindtColor.foregroundMuted)
        }
    }
}

#Preview("Light") {
    GlindtPreviewGallery()
        .frame(width: 720, height: 900)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    GlindtPreviewGallery()
        .frame(width: 720, height: 900)
        .preferredColorScheme(.dark)
}
