import SwiftUI

/// App-level routing: onboarding until completed, then the intent-first home,
/// with the local Kaiwa Loop pushed as a full-screen destination. Persistence
/// is local AppStorage only; the bounded post-lesson planner is optional.
struct RootFlowView: View {
    @AppStorage("ma.onboarding.completed") private var onboardingCompleted = false
    @AppStorage("ma.profile.level") private var rawLevel = LearnerProfile.standard.rawLevel
    @AppStorage("ma.profile.goal") private var rawGoal = LearnerProfile.standard.rawGoal
    @AppStorage("ma.profile.situations") private var rawSituations = LearnerProfile.standard.rawSituations
    @AppStorage("ma.profile.dailyMinutes") private var rawDailyMinutes = LearnerProfile.standard.rawDailyMinutes

    @State private var path: [SceneID] = []
    @State private var kaiwaFeature = KaiwaLoopFeature.production()
    @State private var replayFeature = KaiwaLoopFeature.labeledReplay()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var profile: LearnerProfile {
        .fromRaw(
            level: rawLevel, goal: rawGoal,
            situations: rawSituations, dailyMinutes: rawDailyMinutes
        )
    }

    /// UI tests choose a route without mutating the learner's persisted
    /// AppStorage. Production launches never set this environment value.
    private var effectiveOnboardingCompleted: Bool {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["MA_UI_TEST_ONBOARDING_COMPLETED"] {
            return raw == "true"
        }
        #endif
        return onboardingCompleted
    }

    /// Explicit operator-only fallback. The value is intentionally verbose so
    /// it cannot be enabled accidentally or mistaken for a live product path.
    private var labeledReplayRequested: Bool {
        ProcessInfo.processInfo.environment["MA_DEMO_MODE"] == "labeled-replay-no-live"
            || ProcessInfo.processInfo.arguments.contains("--ma-labeled-replay-no-live")
    }

    var body: some View {
        Group {
            if labeledReplayRequested {
                KaiwaLoopView(feature: replayFeature, onExit: nil)
                    .task { replayFeature.startLabeledReplay() }
            } else {
                switch AppRoute.initial(hasCompletedOnboarding: effectiveOnboardingCompleted) {
                case .onboarding:
                    OnboardingView { completedProfile in
                        save(completedProfile)
                        withRouteAnimation { onboardingCompleted = true }
                    }
                    .transition(.opacity)
                case .home:
                    NavigationStack(path: $path) {
                        HomeView(
                            profile: profile,
                            onStartScene: { sceneID in
                                guard SceneCatalog.info(for: sceneID)?.available == true else { return }
                                kaiwaFeature.send(.restart)
                                path.append(sceneID)
                            },
                            onReplayOnboarding: {
                                withRouteAnimation { onboardingCompleted = false }
                            },
                            onResetChoices: {
                                save(.standard)
                            },
                            onDeleteAllData: {
                                deleteAllData()
                            }
                        )
                        .navigationDestination(for: SceneID.self) { _ in
                            KaiwaLoopView(feature: kaiwaFeature) {
                                kaiwaFeature.send(.restart)
                                path.removeAll()
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
    }

    private func save(_ profile: LearnerProfile) {
        rawLevel = profile.rawLevel
        rawGoal = profile.rawGoal
        rawSituations = profile.rawSituations
        rawDailyMinutes = profile.rawDailyMinutes
    }

    private func deleteAllData() {
        try? PlannerInstallCredentialStore().deleteToken()
        kaiwaFeature.send(.restart)
        path.removeAll()
        save(.standard)
        onboardingCompleted = false
    }

    private func withRouteAnimation(_ change: () -> Void) {
        if reduceMotion {
            change()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { change() }
        }
    }
}

#Preview("Root flow") {
    RootFlowView()
}
