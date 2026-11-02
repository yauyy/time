import AppKit
import SwiftUI

enum ClockTheme {
    // Semantic AppKit colors follow both the user's accent color and macOS appearance.
    static let accent = Color(nsColor: .controlAccentColor)
    static let sun = Color(nsColor: .systemOrange)
    static let ink = Color(nsColor: .labelColor)
    static let secondaryInk = Color(nsColor: .secondaryLabelColor)
    static let mutedInk = secondaryInk
    static let card = Color(nsColor: .controlBackgroundColor)
    static let softCard = card
    static let border = Color(nsColor: .separatorColor)
    static let top = Color(nsColor: .windowBackgroundColor)
    static let shine = border
}

struct ClockBackdrop: View {
    var body: some View {
        ZStack {
            ClockTheme.top
            LinearGradient(colors: [ClockTheme.accent.opacity(0.035), .clear, ClockTheme.accent.opacity(0.02)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .clipped().allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct ClockGlyph: View {
    let symbol: String
    var color: Color = ClockTheme.accent
    var size: CGFloat = 22

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.5, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct ClockArtwork: View {
    var size: CGFloat = 28

    // AppKit's applicationIconImage may include an OS-supplied backing plate.
    // The in-app artwork uses the original PNG, preserving its transparent edges.
    private static let artwork: NSImage = {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
           let image = NSImage(contentsOf: url) { return image }
        return NSImage(systemSymbolName: "clock", accessibilityDescription: nil)!
    }()

    var body: some View {
        Image(nsImage: Self.artwork)
            .resizable().interpolation(.high).scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct ClockSparkle: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.midX, y = rect.midY
        var path = Path()
        path.move(to: CGPoint(x: x, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: y), control: CGPoint(x: x * 1.12, y: y * 0.88))
        path.addQuadCurve(to: CGPoint(x: x, y: rect.maxY), control: CGPoint(x: x * 1.12, y: y * 1.12))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: y), control: CGPoint(x: x * 0.88, y: y * 1.12))
        path.addQuadCurve(to: CGPoint(x: x, y: rect.minY), control: CGPoint(x: x * 0.88, y: y * 0.88))
        return path
    }
}

private struct ClockSurface: ViewModifier {
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(ClockTheme.card.opacity(0.88), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(ClockTheme.border.opacity(0.8), lineWidth: 0.7)
                .allowsHitTesting(false).accessibilityHidden(true))
            .shadow(color: ClockTheme.accent.opacity(0.045), radius: 8, x: 0, y: 3)
    }
}

extension View {
    func clockSurface(radius: CGFloat = 14) -> some View {
        modifier(ClockSurface(radius: radius))
    }
}
