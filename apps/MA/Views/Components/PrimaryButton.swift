import SwiftUI

/// Full-width ai-blue pill with a 56pt minimum hit region — the single decisive
/// action per screen, always in the thumb zone and allowed to grow with type.
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
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
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
            .frame(minHeight: 40)
            .padding(.vertical, 2)
            .padding(.horizontal, 18)
            .background(solid ? MATheme.ai : .white, in: Capsule())
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
