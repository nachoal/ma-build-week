import SwiftUI

/// Intent-first home: one hero scene ready now, the road ahead visibly labeled.
/// No tabs, no dashboard — one decision.
struct HomeView: View {
    let profile: LearnerProfile
    let onToggleLanguage: () -> Void
    let onStartScene: (SceneID) -> Void
    let onReplayOnboarding: () -> Void
    let onResetChoices: () -> Void
    let onDeleteAllData: () -> Void
    @State private var showingProfile = false
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                ChromeBar(
                    badge: language.text(
                        english: "GPT REALTIME · GUIDED",
                        spanish: "GPT REALTIME · GUIADO"
                    ),
                    onProfile: { showingProfile = true },
                    onToggleLanguage: onToggleLanguage
                )
                header
                HeroSceneCard(scene: SceneCatalog.hero) {
                    onStartScene(SceneCatalog.hero.id)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 24)
                practiceLine
                sceneList
                Spacer(minLength: 16)
                footer
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileSheet(
                profile: profile,
                onReplayOnboarding: {
                    showingProfile = false
                    onReplayOnboarding()
                },
                onResetChoices: {
                    showingProfile = false
                    onResetChoices()
                },
                onDeleteAllData: {
                    showingProfile = false
                    onDeleteAllData()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            MicroCapsLabel(text: language.text(
                english: "YOUR NEXT CONVERSATION",
                spanish: "TU PRÓXIMA CONVERSACIÓN"
            ), color: MATheme.ai)
            Text(language.text(
                english: "One real scene, today.",
                spanish: "Una escena real, hoy."
            ))
                .font(MATheme.display())
                .tracking(MATheme.tightTracking(fontSize: 34))
                .foregroundStyle(MATheme.sumi)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 20)
    }

    private var practiceLine: some View {
        HStack(spacing: 8) {
            Circle().fill(MATheme.ai).frame(width: 5, height: 5)
            Text(language.text(
                english: "Your pace: \(profile.dailyMinutes.label(in: language)) · \(profile.goal.label(in: language).lowercased())",
                spanish: "Tu ritmo: \(profile.dailyMinutes.label(in: language)) · \(profile.goal.label(in: language).lowercased())"
            ))
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
                .lineLimit(2)
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 14)
        .accessibilityElement(children: .combine)
    }

    /// Only what comes after the hero — ordered by the learner's onboarding
    /// interests, so those choices visibly shape the roadmap.
    private var sceneList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                MicroCapsLabel(text: language.text(
                    english: "NEXT · COMING SOON",
                    spanish: "DESPUÉS · PRONTO"
                ))
                Spacer()
                if !profile.interests.isEmpty {
                    Text(language.text(
                        english: "ordered by your interests",
                        spanish: "ordenado por tus intereses"
                    ))
                        .font(.system(size: 10))
                        .foregroundStyle(MATheme.stone)
                }
            }
            .padding(.top, 16)
            .overlay(Rectangle().fill(MATheme.hairline).frame(height: 1), alignment: .top)
            .padding(.bottom, 4)
            ForEach(SceneCatalog.upcomingScenes(orderedBy: profile.interests)) { scene in
                SceneListRow(scene: scene) {
                    onStartScene(scene.id)
                }
            }
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 26)
    }

    private var footer: some View {
        Text(language.text(
            english: "Short model · your voice · GPT Realtime review · local profile.",
            spanish: "Modelo breve · tu voz · revisión GPT Realtime · perfil local."
        ))
            .font(MATheme.caption())
            .foregroundStyle(MATheme.stone)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.horizontal, MATheme.sideMargin)
            .padding(.bottom, 10)
    }
}

/// One row per scene: fixed index lane, title/subtitle, honest status lane.
/// Upcoming scenes are visible but explicitly "PRONTO" and not tappable.
struct SceneListRow: View {
    let scene: SceneInfo
    let onStart: () -> Void
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        Button(action: onStart) {
            HStack(spacing: 12) {
                Text(String(format: "%02d", scene.index))
                    .font(MATheme.caption(.semibold))
                    .foregroundStyle(scene.available ? MATheme.ai : MATheme.stone)
                    .frame(width: 26, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(scene.title(in: language))
                        .font(MATheme.body(16, weight: .medium))
                        .foregroundStyle(scene.available ? MATheme.sumi : MATheme.stone)
                    Text(scene.subtitle(in: language))
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                }
                Spacer(minLength: 8)

                if scene.available {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(MATheme.ai, in: Circle())
                } else {
                    MicroCapsLabel(text: scene.statusLabel(in: language))
                }
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!scene.available)
        .accessibilityLabel(
            scene.available
                ? language.text(
                    english: "Scene \(scene.index): \(scene.title(in: language)). \(scene.subtitle(in: language)). Available.",
                    spanish: "Escena \(scene.index): \(scene.title(in: language)). \(scene.subtitle(in: language)). Disponible."
                )
                : language.text(
                    english: "Scene \(scene.index): \(scene.title(in: language)). Coming soon, not available yet.",
                    spanish: "Escena \(scene.index): \(scene.title(in: language)). Próximamente, aún no disponible."
                )
        )
        .accessibilityIdentifier("escena.\(scene.id.rawValue)")
        .overlay(Rectangle().fill(MATheme.hairline).frame(height: 1), alignment: .bottom)
    }
}

#Preview("Home") {
    HomeView(
        profile: .standard,
        onToggleLanguage: {},
        onStartScene: { _ in },
        onReplayOnboarding: {},
        onResetChoices: {},
        onDeleteAllData: {}
    )
}
