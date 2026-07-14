import Foundation

/// Pure step machine for the three-screen onboarding. No side effects; the
/// view layer owns persistence.
struct OnboardingProgress: Equatable, Sendable {
    enum Step: Int, CaseIterable, Sendable {
        case start
        case goal
        case practice

        func kicker(in language: MAInterfaceLanguage) -> String {
            switch self {
            case .start:
                language.text(
                    english: "STEP 1 · YOUR STARTING POINT",
                    spanish: "PASO 1 · TU PUNTO DE PARTIDA"
                )
            case .goal:
                language.text(english: "STEP 2 · YOUR GOAL", spanish: "PASO 2 · TU META")
            case .practice:
                language.text(
                    english: "STEP 3 · YOUR PRACTICE",
                    spanish: "PASO 3 · TU PRÁCTICA"
                )
            }
        }

        var kicker: String { kicker(in: .spanish) }
    }

    var step: Step = .start
    var profile: LearnerProfile = .standard

    var isFirstStep: Bool { step == .start }
    var isLastStep: Bool { step == Step.allCases.last }

    /// Defaults are always valid, so the learner can continue with one tap on
    /// every step.
    var canContinue: Bool { true }

    func continueTitle(in language: MAInterfaceLanguage) -> String {
        if isLastStep {
            return language.text(english: "See my scenes", spanish: "Ver mis escenas")
        }
        return language.text(english: "Continue", spanish: "Continuar")
    }

    var continueTitle: String { continueTitle(in: .spanish) }

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
