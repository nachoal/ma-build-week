import SwiftUI

/// Intent-first home: one hero scene ready now, the road ahead visibly labeled.
/// No tabs, no dashboard — one decision.
struct HomeView: View {
    let profile: LearnerProfile
    let onStartScene: (SceneID) -> Void
    let onReplayOnboarding: () -> Void
    let onResetChoices: () -> Void
    @State private var showingProfile = false

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                ChromeBar(badge: "PROTOTIPO", onProfile: { showingProfile = true })
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
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            MicroCapsLabel(text: "TU PRÓXIMA CONVERSACIÓN", color: MATheme.ai)
            Text("Una escena real, hoy.")
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
            Text("Tu ritmo: \(profile.dailyMinutes.spanishLabel) · \(profile.goal.spanishLabel.lowercased())")
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
                MicroCapsLabel(text: "DESPUÉS · PRONTO")
                Spacer()
                if !profile.interests.isEmpty {
                    Text("ordenado por tus intereses")
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
        Text("Prototipo · tus elecciones se guardan solo en este iPhone.")
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

    var body: some View {
        Button(action: onStart) {
            HStack(spacing: 12) {
                Text(String(format: "%02d", scene.index))
                    .font(MATheme.caption(.semibold))
                    .foregroundStyle(scene.available ? MATheme.ai : MATheme.stone)
                    .frame(width: 26, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(scene.title)
                        .font(MATheme.body(16, weight: .medium))
                        .foregroundStyle(scene.available ? MATheme.sumi : MATheme.stone)
                    Text(scene.subtitle)
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
                    MicroCapsLabel(text: scene.statusLabel)
                }
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!scene.available)
        .accessibilityLabel(
            scene.available
                ? "Escena \(scene.index): \(scene.title). \(scene.subtitle). Disponible."
                : "Escena \(scene.index): \(scene.title). Próximamente, aún no disponible."
        )
        .accessibilityIdentifier("escena.\(scene.id.rawValue)")
        .overlay(Rectangle().fill(MATheme.hairline).frame(height: 1), alignment: .bottom)
    }
}

#Preview("Home") {
    HomeView(
        profile: .standard,
        onStartScene: { _ in },
        onReplayOnboarding: {},
        onResetChoices: {}
    )
}
