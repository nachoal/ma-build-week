import SwiftUI

/// Compact profile — a summary and two actions, not a settings maze.
struct ProfileSheet: View {
    let profile: LearnerProfile
    let onReplayOnboarding: () -> Void
    let onResetChoices: () -> Void

    private var chosenInterests: String {
        let titles = SceneCatalog.upcomingScenes(orderedBy: profile.interests)
            .filter { profile.interests.contains($0.id) }
            .map(\.title)
        return titles.isEmpty ? "Sin marcar — orden estándar" : titles.joined(separator: " · ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Tu perfil de práctica")
                    .font(MATheme.heading())
                    .tracking(MATheme.tightTracking(fontSize: 20))
                    .foregroundStyle(MATheme.sumi)
                    .padding(.top, 26)

                VStack(alignment: .leading, spacing: 14) {
                    summaryRow(label: "NIVEL", value: profile.level.spanishLabel)
                    summaryRow(label: "META", value: profile.goal.spanishLabel)
                    summaryRow(label: "PRIMERA ESCENA", value: SceneCatalog.hero.title)
                    summaryRow(label: "INTERESES · ORDENAN LO PRÓXIMO", value: chosenInterests)
                    summaryRow(label: "RITMO", value: profile.dailyMinutes.spanishLabel)
                }
                .padding(.top, 20)

                VStack(spacing: 10) {
                    Button(action: onReplayOnboarding) {
                        Text("Repetir la introducción")
                            .font(MATheme.body(16, weight: .semibold))
                            .foregroundStyle(MATheme.ai)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(MATheme.mist, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("perfil.repetir")

                    Button(action: onResetChoices) {
                        Text("Restablecer mis elecciones")
                            .font(MATheme.body(16, weight: .medium))
                            .foregroundStyle(MATheme.sumi)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .overlay(Capsule().stroke(MATheme.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("perfil.restablecer")
                }
                .padding(.top, 28)

                Text("Prototipo · sin cuenta, sin micrófono. Todo vive en este iPhone.")
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
                    .padding(.top, 18)
            }
            .padding(.horizontal, MATheme.sideMargin)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(MATheme.paper)
    }

    private func summaryRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            MicroCapsLabel(text: label)
            Text(value)
                .font(MATheme.body(16, weight: .medium))
                .foregroundStyle(MATheme.sumi)
        }
        .accessibilityElement(children: .combine)
    }
}
