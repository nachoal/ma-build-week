import SwiftUI

/// Permanent app chrome: wordmark plus the honesty badge. The badge is not a
/// debug flag; it must be visible in every phase. Optional leading exit and
/// trailing profile affordances keep navigation chrome-light. At large
/// Dynamic Type sizes the bar stacks so nothing ever renders offscreen.
struct ChromeBar: View {
    let badge: String
    var onExit: (() -> Void)? = nil
    var onProfile: (() -> Void)? = nil

    var body: some View {
        ViewThatFits(in: .horizontal) {
            singleRow
            stackedRows
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 8)
    }

    private var singleRow: some View {
        HStack {
            leadingGroup
            Spacer()
            badgeChip
            profileButton
        }
    }

    private var stackedRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                leadingGroup
                Spacer()
                profileButton
            }
            badgeChip
        }
    }

    @ViewBuilder
    private var leadingGroup: some View {
        if let onExit {
            Button(action: onExit) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MATheme.sumi)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Volver a tus escenas")
            .accessibilityIdentifier("chrome.volver")
            .padding(.leading, -12)
        }
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("MA")
                .font(.system(size: 17, weight: .heavy))
                .tracking(0.34)
                .foregroundStyle(MATheme.sumi)
            Text("間")
                .font(MATheme.jp(11, .w3))
                .foregroundStyle(MATheme.stone)
        }
        .accessibilityLabel("MA, prototipo de tutor de japonés")
    }

    private var badgeChip: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(MATheme.stone)
                .frame(width: 5, height: 5)
            MicroCapsLabel(text: badge)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 9)
        .overlay(Capsule().stroke(MATheme.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Estado de la maqueta: \(badge). Nada de esto es audio en vivo.")
        .accessibilityIdentifier("chrome.badge")
    }

    @ViewBuilder
    private var profileButton: some View {
        if let onProfile {
            Button(action: onProfile) {
                Image(systemName: "person")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MATheme.sumi)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(MATheme.hairline, lineWidth: 1))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tu perfil de práctica")
            .accessibilityIdentifier("chrome.perfil")
            .padding(.trailing, -6)
        }
    }
}
