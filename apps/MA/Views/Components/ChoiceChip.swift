import SwiftUI

/// Selectable pill used across onboarding. Selection is shown by fill, border,
/// and a checkmark — never color alone. Minimum 44pt hit target.
struct ChoiceChip: View {
    let title: String
    let selected: Bool
    var identifier: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                }
                Text(title)
                    .font(MATheme.body(15, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(selected ? MATheme.ai : MATheme.sumi)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(selected ? MATheme.mist : .white, in: Capsule())
            .overlay(
                Capsule().stroke(
                    selected ? MATheme.ai : MATheme.hairline,
                    lineWidth: selected ? 1.5 : 1
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityIdentifier(identifier ?? "chip.\(title)")
    }
}
