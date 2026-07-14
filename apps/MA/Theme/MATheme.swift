import SwiftUI

/// Token values from docs/design/paper-ui-handoff.md. Latin text uses SF
/// system typography (Paper used Inter only because SF Pro was unavailable
/// there); Japanese always uses explicit Hiragino Sans runs.
enum MATheme {
    // MARK: Colors

    static let paper = Color.white
    static let sumi = Color(red: 9 / 255, green: 10 / 255, blue: 12 / 255)
    static let stone = Color(red: 111 / 255, green: 116 / 255, blue: 128 / 255)
    static let hairline = Color(red: 231 / 255, green: 233 / 255, blue: 238 / 255)
    static let ai = Color(red: 20 / 255, green: 92 / 255, blue: 255 / 255)
    static let mist = Color(red: 234 / 255, green: 241 / 255, blue: 255 / 255)

    // MARK: Layout

    static let sideMargin: CGFloat = 24

    // MARK: Latin type (SF system)

    static func display(_ size: CGFloat = 36) -> Font {
        .system(.largeTitle, design: .default, weight: .heavy)
    }
    static func title(_ size: CGFloat = 28) -> Font {
        .system(.title, design: .default, weight: .heavy)
    }
    static func heading(
        _ size: CGFloat = 20, weight: Font.Weight = .semibold
    ) -> Font {
        .system(.title3, design: .default, weight: weight)
    }
    static func body(_ size: CGFloat = 16, weight: Font.Weight = .medium) -> Font {
        .system(.body, design: .default, weight: weight)
    }
    static func caption(_ weight: Font.Weight = .regular) -> Font {
        .system(.caption, design: .default, weight: weight)
    }
    static func micro() -> Font {
        .system(.caption2, design: .default, weight: .semibold)
    }

    /// Tracking for ALL-CAPS micro/caption labels (0.12em from the handoff).
    static func capsTracking(fontSize: CGFloat) -> CGFloat { fontSize * 0.12 }
    /// Tight tracking for display sizes (−0.02em).
    static func tightTracking(fontSize: CGFloat) -> CGFloat { fontSize * -0.02 }

    // MARK: Japanese type (explicit Hiragino Sans runs)

    enum JPWeight: String {
        case w3 = "HiraginoSans-W3"
        case w6 = "HiraginoSans-W6"
    }

    static func jp(_ size: CGFloat, _ weight: JPWeight = .w6) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: textStyle(for: size))
    }

    private static func textStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case 34...: .largeTitle
        case 25...: .title2
        case 20...: .title3
        case 16...: .body
        default: .caption2
        }
    }
}

/// Small caps-label used across screens: 10pt/600, 0.12em, ALL CAPS.
struct MicroCapsLabel: View {
    let text: String
    var color: Color = MATheme.stone

    var body: some View {
        Text(text)
            .font(MATheme.micro())
            .tracking(MATheme.capsTracking(fontSize: 10))
            .foregroundStyle(color)
    }
}
