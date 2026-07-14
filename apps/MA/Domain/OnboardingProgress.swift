import Foundation

/// Pure step machine for the three-screen onboarding. No side effects; the
/// view layer owns persistence.
struct OnboardingProgress: Equatable, Sendable {
    enum Step: Int, CaseIterable, Sendable {
        case start
        case goal
        case practice

        var kicker: String {
            switch self {
            case .start: "PASO 1 · TU PUNTO DE PARTIDA"
            case .goal: "PASO 2 · TU META"
            case .practice: "PASO 3 · TU PRÁCTICA"
            }
        }
    }

    var step: Step = .start
    var profile: LearnerProfile = .standard

    var isFirstStep: Bool { step == .start }
    var isLastStep: Bool { step == Step.allCases.last }

    /// Defaults are always valid, so the learner can continue with one tap on
    /// every step.
    var canContinue: Bool { true }

    var continueTitle: String { isLastStep ? "Ver mis escenas" : "Continuar" }

    /// Advances one step. Returns true when onboarding just finished.
    mutating func advance() -> Bool {
        if isLastStep { return true }
        step = Step(rawValue: step.rawValue + 1) ?? step
        return false
    }

    mutating func goBack() {
        guard !isFirstStep else { return }
        step = Step(rawValue: step.rawValue - 1) ?? step
    }
}

/// Top-level routing derived from persisted state — pure and testable.
enum AppRoute: Equatable, Sendable {
    case onboarding
    case home

    static func initial(hasCompletedOnboarding: Bool) -> AppRoute {
        hasCompletedOnboarding ? .home : .onboarding
    }
}
