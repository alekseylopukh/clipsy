import SwiftUI

public struct SwatchValueLabel: View {
    let value: String
    let swatch: Color

    @Environment(\.self) private var environment

    public init(_ value: String, on swatch: Color) {
        self.value = value
        self.swatch = swatch
    }

    public var body: some View {
        let resolved = swatch.resolve(in: environment)
        let usesDarkText = Self.usesDarkText(
            red: Double(resolved.red),
            green: Double(resolved.green),
            blue: Double(resolved.blue)
        )
        Text(verbatim: value)
            .font(.callout.monospaced().weight(.semibold))
            .foregroundStyle(usesDarkText ? Color.black : Color.white)
    }

    /// components are gamma-encoded sRGB in 0...1
    public nonisolated static func usesDarkText(red: Double, green: Double, blue: Double) -> Bool {
        relativeLuminance(red: red, green: green, blue: blue) > DesignTokens.swatchLabelLuminanceThreshold
    }

    nonisolated static func relativeLuminance(red: Double, green: Double, blue: Double) -> Double {
        0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    private nonisolated static func linear(_ component: Double) -> Double {
        component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
    }
}
