import Foundation

protocol LearningPlanning: Sendable {
    func nextAction(for report: LearningReport) async -> NextLearningAction
}

struct LearningPlanner: LearningPlanning {
    private let remote: (any RemoteLearningPlanning)?
    private let policy: DeterministicPedagogyPolicy

    init(
        remote: (any RemoteLearningPlanning)? = nil,
        policy: DeterministicPedagogyPolicy = DeterministicPedagogyPolicy()
    ) {
        self.remote = remote
        self.policy = policy
    }

    static func production() -> LearningPlanner {
        let credentials = PlannerInstallCredentialStore()
        try? credentials.provisionFromProcessEnvironment()
        return LearningPlanner(
            remote: BrokerLearningPlanner(credentials: credentials)
        )
    }

    func nextAction(for report: LearningReport) async -> NextLearningAction {
        let fallback = policy.fallback(for: report)
        guard report.isValidForPlannerTransport,
              let remote else { return fallback }
        do {
            let candidate = try await remote.requestNextAction(for: report)
            guard !Task.isCancelled,
                  let validated = policy.validatedModelAction(candidate, for: report) else {
                return fallback
            }
            return validated
        } catch {
            return fallback
        }
    }
}
