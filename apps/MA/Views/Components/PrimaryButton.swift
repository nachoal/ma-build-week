import SwiftUI

/// Full-width ai-blue pill, 56pt tall — the single decisive action per screen,
/// always in the thumb zone.
struct PrimaryButton<Icon: View>: View {
    let title: String
    let identifier: String
    let action: () -> Void
    let icon: Icon

    init(
        title: String,
        identifier: String,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) {
        self.title = title
        self.identifier = identifier
        self.action = action
        self.icon = icon()
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                icon
                Text(title)
                    .font(MATheme.body(16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(MATheme.ai, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}

/// Small pill used inside the micro-lesson card.
struct BeatActionButton: View {
    let title: String
    let solid: Bool
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if solid {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 10, weight: .bold))
                }
                Text(title)
                    .font(MATheme.caption(.semibold))
            }
            .foregroundStyle(solid ? .white : MATheme.ai)
            .frame(height: 40)
            .padding(.horizontal, 18)
            .background(solid ? MATheme.ai : .white, in: Capsule())
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
