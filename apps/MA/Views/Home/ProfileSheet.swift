import SwiftUI

/// Compact profile — a summary and two actions, not a settings maze.
struct ProfileSheet: View {
    let profile: LearnerProfile
    let onReplayOnboarding: () -> Void
    let onResetChoices: () -> Void
    let onDeleteAllData: () throws -> Void
    @State private var confirmingDelete = false
    @State private var deletionFailed = false
    @Environment(\.maInterfaceLanguage) private var language

    private var chosenInterests: String {
        let titles = SceneCatalog.upcomingScenes(orderedBy: profile.interests)
            .filter { profile.interests.contains($0.id) }
            .map { $0.title(in: language) }
        return titles.isEmpty
            ? language.text(english: "None selected—standard order", spanish: "Sin marcar — orden estándar")
            : titles.joined(separator: " · ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(language.text(
                    english: "Your practice profile",
                    spanish: "Tu perfil de práctica"
                ))
                    .font(MATheme.heading())
                    .tracking(MATheme.tightTracking(fontSize: 20))
                    .foregroundStyle(MATheme.sumi)
                    .padding(.top, 26)

                VStack(alignment: .leading, spacing: 14) {
                    summaryRow(
                        label: language.text(english: "LEVEL", spanish: "NIVEL"),
                        value: profile.level.label(in: language)
                    )
                    summaryRow(
                        label: language.text(english: "GOAL", spanish: "META"),
                        value: profile.goal.label(in: language)
                    )
                    summaryRow(
                        label: language.text(english: "FIRST SCENE", spanish: "PRIMERA ESCENA"),
                        value: SceneCatalog.hero.title(in: language)
                    )
                    summaryRow(
                        label: language.text(
                            english: "INTERESTS · ORDER WHAT COMES NEXT",
                            spanish: "INTERESES · ORDENAN LO PRÓXIMO"
                        ),
                        value: chosenInterests
                    )
                    summaryRow(
                        label: language.text(english: "PACE", spanish: "RITMO"),
                        value: profile.dailyMinutes.label(in: language)
                    )
                }
                .padding(.top, 20)

                VStack(spacing: 10) {
                    Button(action: onReplayOnboarding) {
                        Text(language.text(
                            english: "Replay the introduction",
                            spanish: "Repetir la introducción"
                        ))
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
                        Text(language.text(
                            english: "Reset my choices",
                            spanish: "Restablecer mis elecciones"
                        ))
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
                        Text(language.text(
                            english: "Delete all my data",
                            spanish: "Borrar todos mis datos"
                        ))
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

                Text(language.text(
                    english: "No account or tracking. Your choices stay on this iPhone. When you record, that short turn goes directly to OpenAI for transcription and review; MA does not create a local recording. The optional plan uses only aggregate results, without audio or transcripts.",
                    spanish: "Sin cuenta ni rastreo. Tus elecciones quedan en este iPhone. Cuando grabas, ese turno breve va directo a OpenAI para transcripción y revisión; MA no crea un archivo local. El plan opcional usa solo hechos agregados, sin audio ni transcripción."
                ))
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
            language.text(
                english: "Delete choices and local credential?",
                spanish: "¿Borrar elecciones y credencial local?"
            ),
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button(language.text(
                english: "Delete all my data",
                spanish: "Borrar todos mis datos"
            ), role: .destructive) {
                do {
                    try onDeleteAllData()
                } catch {
                    deletionFailed = true
                }
            }
            Button(language.text(english: "Cancel", spanish: "Cancelar"), role: .cancel) {}
        } message: {
            Text(language.text(
                english: "MA will delete the local profile, introduction progress, and private credential. The app does not store recordings or transcripts on this iPhone.",
                spanish: "MA borrará el perfil local, el avance de introducción y la credencial privada. La app no guarda grabaciones ni transcripciones en este iPhone."
            ))
        }
        .alert(
            language.text(
                english: "Couldn’t delete all data",
                spanish: "No se pudieron borrar todos los datos"
            ),
            isPresented: $deletionFailed
        ) {
            Button(language.text(english: "OK", spanish: "Aceptar"), role: .cancel) {}
        } message: {
            Text(language.text(
                english: "MA couldn’t verify that the private credential was deleted, so your profile was not reset. Please try again.",
                spanish: "MA no pudo verificar que se borró la credencial privada, así que tu perfil no se restableció. Inténtalo de nuevo."
            ))
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
