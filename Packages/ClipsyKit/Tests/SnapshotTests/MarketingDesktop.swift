import AppKit
import SwiftUI

/// a generated desktop for the README screenshots: wallpaper, menu bar and a stand-in document window
struct MarketingDesktop<Content: View>: View {
    private let wallpaper: CGImage
    private let showsMenuBar: Bool
    private let content: Content

    init(
        size: CGSize,
        appearance: SnapshotRenderer.Appearance,
        showsMenuBar: Bool = true,
        @ViewBuilder content: () -> Content
    ) throws {
        wallpaper = try Self.wallpaper(size: size, appearance: appearance)
        self.showsMenuBar = showsMenuBar
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            Image(decorative: wallpaper, scale: 2)
                .resizable()
            content
            if showsMenuBar {
                MarketingMenuBar()
            }
        }
    }

    /// soft colour fields in the app icon's blue, violet and pink
    private static func wallpaper(size: CGSize, appearance: SnapshotRenderer.Appearance) throws -> CGImage {
        let isDark = appearance == .dark
        return try MarketingFixtures.draw(width: Int(size.width * 2), height: Int(size.height * 2)) { context, size in
            MarketingFixtures.fill(
                context,
                size: size,
                colors: isDark
                    ? [color(0.05, 0.06, 0.18), color(0.16, 0.07, 0.24)]
                    : [color(0.84, 0.89, 1.0), color(0.98, 0.88, 0.94)],
                from: CGPoint(x: 0, y: size.height),
                to: CGPoint(x: size.width, y: 0)
            )
            let fields: [(CGPoint, NSColor)] = [
                (CGPoint(x: 0.15, y: 0.85), isDark ? color(0.16, 0.30, 0.85) : color(0.45, 0.62, 1.0)),
                (CGPoint(x: 0.85, y: 0.80), isDark ? color(0.50, 0.22, 0.80) : color(0.72, 0.58, 1.0)),
                (CGPoint(x: 0.70, y: 0.15), isDark ? color(0.75, 0.20, 0.45) : color(1.0, 0.62, 0.74)),
                (CGPoint(x: 0.10, y: 0.10), isDark ? color(0.10, 0.40, 0.70) : color(0.55, 0.82, 0.98))
            ]
            for (center, tint) in fields {
                let point = CGPoint(x: center.x * size.width, y: center.y * size.height)
                context.drawRadialGradient(
                    MarketingFixtures.gradient([
                        tint.withAlphaComponent(isDark ? 0.75 : 0.8),
                        tint.withAlphaComponent(0)
                    ]),
                    startCenter: point,
                    startRadius: 0,
                    endCenter: point,
                    endRadius: 0.68 * max(size.width, size.height),
                    options: []
                )
            }
        }
    }

    private static func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> NSColor {
        NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
    }
}

struct MarketingMenuBar: View {
    var body: some View {
        HStack(spacing: 18) {
            Spacer()
            Image(systemName: "paperclip")
            Image(systemName: "wifi")
            Image(systemName: "battery.75percent")
            Text(verbatim: "Fri 9:41")
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.primary)
        .padding(.horizontal, 16)
        .frame(height: 28)
        .background(.background.opacity(0.35))
    }
}

/// a plain window so the desktop reads as a Mac in use
struct MarketingWindow<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack(spacing: 8) {
                    Circle().fill(.red)
                    Circle().fill(.yellow)
                    Circle().fill(.green)
                    Spacer()
                }
                .frame(height: 12)
                Text(verbatim: title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(.windowBackground)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.separator))
        .compositingGroup()
        .shadow(color: .black.opacity(0.25), radius: 30, y: 12)
    }
}

/// placeholder bars instead of text; `widths` must be unique
struct MarketingPlaceholderText: View {
    let widths: [CGFloat]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(widths, id: \.self) { width in
                Capsule()
                    .fill(.quaternary)
                    .frame(width: width, height: 10)
            }
        }
    }
}
