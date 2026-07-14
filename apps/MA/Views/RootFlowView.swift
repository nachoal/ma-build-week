import SwiftUI

/// App-level routing: onboarding until completed, then the intent-first home,
/// with the guided Realtime lesson pushed as a full-screen destination.
/// Persistence is local AppStorage only; the bounded post-lesson planner is
/// optional.
struct RootFlowView: View {
    @AppStorage("ma.onboarding.completed") private var onboardingCompleted = false
    @AppStorage("ma.profile.level") private var rawLevel = LearnerProfile.standard.rawLevel
    @AppStorage("ma.profile.goal") private var rawGoal = LearnerProfile.standard.rawGoal
    @AppStorage("ma.profile.situations") private var rawSituations = LearnerProfile.standard.rawSituations
    @AppStorage("ma.profile.dailyMinutes") private var rawDailyMinutes = LearnerProfile.standard.rawDailyMinutes
    @AppStorage("ma.interface.language") private var rawInterfaceLanguage = MAInterfaceLanguage.defaultLanguage.rawValue

    @State private var path: [SceneID] = []
    @State private var guidedFeature = GuidedLessonFeature.production()
    @State private var replayFeature = KaiwaLoopFeature.labeledReplay()
    @State private var isOpeningScene = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let deleteCredential: () throws -> Void

    init() {
        deleteCredential = Self.deleteProductionCredential
    }

    init(deleteCredential: @escaping () throws -> Void) {
        self.deleteCredential = deleteCredential
    }

    private var profile: LearnerProfile {
        .fromRaw(
            level: rawLevel, goal: rawGoal,
            situations: rawSituations, dailyMinutes: rawDailyMinutes
        )
    }

    private var interfaceLanguage: MAInterfaceLanguage {
        MAInterfaceLanguage(rawValue: rawInterfaceLanguage) ?? .defaultLanguage
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
                KaiwaLoopView(
                    feature: replayFeature,
                    onExit: nil,
                    onToggleLanguage: toggleLanguage
                )
                    .task { replayFeature.startLabeledReplay() }
            } else {
                switch AppRoute.initial(hasCompletedOnboarding: effectiveOnboardingCompleted) {
                case .onboarding:
                    OnboardingView(
                        onComplete: { completedProfile in
                            save(completedProfile)
                            withRouteAnimation { onboardingCompleted = true }
                        },
                        onToggleLanguage: toggleLanguage
                    )
                    .transition(.opacity)
                case .home:
                    NavigationStack(path: $path) {
                        HomeView(
                            profile: profile,
                            onToggleLanguage: toggleLanguage,
                            onStartScene: { sceneID in
                                guard SceneCatalog.info(for: sceneID)?.available == true,
                                      !isOpeningScene else { return }
                                isOpeningScene = true
                                Task { @MainActor in
                                    guidedFeature.setInterfaceLanguage(interfaceLanguage)
                                    await guidedFeature.resetForNewLesson()
                                    path.append(sceneID)
                                    isOpeningScene = false
                                }
                            },
                            onReplayOnboarding: {
                                withRouteAnimation { onboardingCompleted = false }
                            },
                            onResetChoices: {
                                save(.standard)
                            },
                            onDeleteAllData: {
                                try deleteAllData()
                            }
                        )
                        .navigationDestination(for: SceneID.self) { _ in
                            GuidedLessonView(
                                feature: guidedFeature,
                                onExit: {
                                    Task {
                                        await guidedFeature.stopForExit()
                                        path.removeAll()
                                    }
                                },
                                onToggleLanguage: toggleLanguage
                            )
                            .toolbar(.hidden, for: .navigationBar)
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .environment(\.maInterfaceLanguage, interfaceLanguage)
    }

    private func save(_ profile: LearnerProfile) {
        rawLevel = profile.rawLevel
        rawGoal = profile.rawGoal
        rawSituations = profile.rawSituations
        rawDailyMinutes = profile.rawDailyMinutes
    }

    private func deleteAllData() throws {
        try LocalDataDeletionTransaction(deleteCredential: deleteCredential).perform {
            guidedFeature.send(.restart)
            path.removeAll()
            save(.standard)
            rawInterfaceLanguage = MAInterfaceLanguage.defaultLanguage.rawValue
            onboardingCompleted = false
        }
    }

    private static func deleteProductionCredential() throws {
        #if DEBUG
        if ProcessInfo.processInfo.environment["MA_UI_TEST_FORCE_CREDENTIAL_DELETE_FAILURE"]
            == "true" {
            throw PlannerCredentialError.deletionNotVerified
        }
        #endif
        try PlannerInstallCredentialStore().deleteTokenAndVerify()
    }

    private func toggleLanguage() {
        let next = interfaceLanguage.toggled
        rawInterfaceLanguage = next.rawValue
        guidedFeature.setInterfaceLanguage(next)
    }

    private func withRouteAnimation(_ change: () -> Void) {
        if reduceMotion {
            change()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { change() }
        }
    }
}

struct LocalDataDeletionTransaction {
    let deleteCredential: () throws -> Void

    func perform(resetLocalData: () -> Void) throws {
        try deleteCredential()
        resetLocalData()
    }
}

#Preview("Root flow") {
    RootFlowView()
}
