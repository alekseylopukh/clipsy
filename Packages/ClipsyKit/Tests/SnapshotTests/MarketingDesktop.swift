import AppKit
import DesignSystem
import SwiftUI

/// a generated desktop for the README screenshots: wallpaper, menu bar and a stand-in document window
struct MarketingDesktop<Content: View>: View {
    private let backdrop: MarketingBackdrop
    private let showsMenuBar: Bool
    private let content: Content

    init(
        size: CGSize,
        appearance: SnapshotRenderer.Appearance,
        showsMenuBar: Bool = true,
        @ViewBuilder content: () -> Content
    ) throws {
        let wallpaper = try Self.wallpaper(size: size, appearance: appearance)
        backdrop = try MarketingBackdrop(wallpaper: wallpaper, size: size)
        self.showsMenuBar = showsMenuBar
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            Image(decorative: backdrop.wallpaper, scale: 2)
                .resizable()
            content
            if showsMenuBar {
                MarketingMenuBar()
            }
        }
        .environment(\.marketingBackdrop, backdrop)
    }

    /// folded ribbons of colour in the app icon's blue, violet and pink
    private static func wallpaper(size: CGSize, appearance: SnapshotRenderer.Appearance) throws -> CGImage {
        let isDark = appearance == .dark
        let sharp = try MarketingFixtures
            .draw(width: Int(size.width * 2), height: Int(size.height * 2)) { context, size in
                MarketingFixtures.fill(
                    context,
                    size: size,
                    colors: isDark
                        ? [color(0.04, 0.05, 0.16), color(0.10, 0.05, 0.20)]
                        : [color(0.80, 0.87, 1.0), color(0.97, 0.88, 0.95)],
                    from: CGPoint(x: 0, y: size.height),
                    to: CGPoint(x: size.width, y: 0)
                )
                let ribbons: [Ribbon] = [
                    Ribbon(
                        start: 0.95, end: 0.55, bend: (0.75, 1.15), thickness: 0.42,
                        colors: isDark ? [color(0.18, 0.32, 0.95), color(0.08, 0.14, 0.50)]
                            : [color(0.62, 0.76, 1.0), color(0.36, 0.55, 1.0)]
                    ),
                    Ribbon(
                        start: 0.62, end: 0.30, bend: (0.95, 0.10), thickness: 0.36,
                        colors: isDark ? [color(0.55, 0.28, 0.95), color(0.26, 0.10, 0.55)]
                            : [color(0.80, 0.70, 1.0), color(0.58, 0.45, 1.0)]
                    ),
                    Ribbon(
                        start: 0.28, end: 0.05, bend: (0.55, -0.05), thickness: 0.34,
                        colors: isDark ? [color(0.90, 0.30, 0.60), color(0.42, 0.10, 0.36)]
                            : [color(1.0, 0.76, 0.86), color(1.0, 0.50, 0.70)]
                    )
                ]
                for ribbon in ribbons {
                    ribbon.draw(in: context, size: size, highlight: isDark ? 0.18 : 0.45)
                }
            }
        return try MarketingFixtures.blurred(sharp, radius: 3)
    }

    private static func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> NSColor {
        NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
    }
}

private struct Ribbon {
    let start: CGFloat
    let end: CGFloat
    let bend: (CGFloat, CGFloat)
    let thickness: CGFloat
    let colors: [NSColor]

    func draw(in context: CGContext, size: CGSize, highlight: CGFloat) {
        let height = size.height
        let half = thickness * height / 2
        func point(_ x: CGFloat, _ y: CGFloat, _ offset: CGFloat) -> CGPoint {
            CGPoint(x: x * size.width, y: y * height + offset)
        }
        let top = CGMutablePath()
        top.move(to: point(-0.05, start, half))
        top.addCurve(
            to: point(1.05, end, half * 0.6),
            control1: point(0.35, bend.0, half),
            control2: point(0.65, bend.1, half * 0.4)
        )
        let band = CGMutablePath()
        band.addPath(top)
        band.addLine(to: point(1.05, end, -half * 1.2))
        band.addCurve(
            to: point(-0.05, start, -half * 0.8),
            control1: point(0.65, bend.1, -half * 1.4),
            control2: point(0.35, bend.0, -half * 0.6)
        )
        band.closeSubpath()

        context.saveGState()
        context.addPath(band)
        context.clip()
        context.drawLinearGradient(
            MarketingFixtures.gradient(colors),
            start: point(0.5, (start + end) / 2, half * 1.6),
            end: point(0.5, (start + end) / 2, -half * 1.6),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
        context.restoreGState()

        context.addPath(top)
        context.setStrokeColor(NSColor.white.withAlphaComponent(highlight).cgColor)
        context.setLineWidth(height * 0.004)
        context.strokePath()
    }
}

/// the wallpaper and a frosted copy of it, so glass stand-ins can show what lies behind them
struct MarketingBackdrop {
    let wallpaper: CGImage
    let frosted: CGImage
    let size: CGSize

    init(wallpaper: CGImage, size: CGSize) throws {
        self.wallpaper = wallpaper
        frosted = try MarketingFixtures.blurred(wallpaper, radius: 36, saturation: 1.5)
        self.size = size
    }
}

extension EnvironmentValues {
    @Entry var marketingBackdrop: MarketingBackdrop?
}

/// Liquid Glass never reaches `cacheDisplay`, so this draws the frosted wallpaper under a lit rim instead
struct MarketingGlass: View {
    var cornerRadius = DesignTokens.shelfCornerRadius
    @Environment(\.marketingBackdrop) private var backdrop
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let isDark = colorScheme == .dark
        GeometryReader { proxy in
            if let backdrop {
                let frame = proxy.frame(in: .global)
                Image(decorative: backdrop.frosted, scale: 2)
                    .resizable()
                    .frame(width: backdrop.size.width, height: backdrop.size.height)
                    .offset(x: -frame.minX, y: -frame.minY)
            }
        }
        .overlay(isDark ? Color.black.opacity(0.28) : Color.white.opacity(0.34))
        .overlay(LinearGradient(
            stops: [
                .init(color: .white.opacity(isDark ? 0.10 : 0.30), location: 0),
                .init(color: .clear, location: 0.4)
            ],
            startPoint: .top,
            endPoint: .bottom
        ))
        .clipShape(shape)
        .overlay(shape.strokeBorder(
            LinearGradient(
                colors: [
                    .white.opacity(isDark ? 0.45 : 0.9),
                    .white.opacity(isDark ? 0.08 : 0.25),
                    .white.opacity(isDark ? 0.22 : 0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            lineWidth: 1
        ))
        .compositingGroup()
        .shadow(color: .black.opacity(isDark ? 0.5 : 0.16), radius: 28, y: 12)
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
