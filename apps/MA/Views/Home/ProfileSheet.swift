import SwiftUI

/// Compact profile — a summary and two actions, not a settings maze.
struct ProfileSheet: View {
    let profile: LearnerProfile
    let onReplayOnboarding: () -> Void
    let onResetChoices: () -> Void
    let onDeleteAllData: () -> Void
    @State private var confirmingDelete = false

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
                            .frame(minHeight: 52)
                            .padding(.vertical, 4)
                            .background(MATheme.mist, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("perfil.repetir")

                    Button(action: onResetChoices) {
                        Text("Restablecer mis elecciones")
                            .font(MATheme.body(16, weight: .medium))
                            .foregroundStyle(MATheme.sumi)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 52)
                            .padding(.vertical, 4)
                            .overlay(Capsule().stroke(MATheme.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("perfil.restablecer")

                    Button(role: .destructive) {
                        confirmingDelete = true
                    } label: {
                        Text("Borrar todos mis datos")
                            .font(MATheme.body(16, weight: .semibold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 52)
                            .overlay(Capsule().stroke(.red.opacity(0.45), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("perfil.borrar.todo")
                }
                .padding(.top, 28)

                Text("Sin cuenta ni rastreo. Tus elecciones quedan en este iPhone. Cada intento descarta el audio crudo. Solo si tú pides el plan opcional se envían hechos agregados de la práctica; nunca audio ni transcripción.")
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
                    .padding(.top, 18)
            }
            .padding(.horizontal, MATheme.sideMargin)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(MATheme.paper)
        .confirmationDialog(
            "¿Borrar elecciones y credencial local?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Borrar todos mis datos", role: .destructive) {
                onDeleteAllData()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("MA borrará el perfil local, el avance de introducción y la credencial del plan opcional. No conserva grabaciones ni transcripciones.")
        }
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
