import Foundation

/// Provider-neutral semantic actions for the shipping Kaiwa loop. Both the
/// local product and the labeled replay enter this reducer; hardware/service
/// work stays outside and reports only completed semantic outcomes.
enum KaiwaLoopSemanticAction: Equatable, Sendable {
    case beginCoached(ScaffoldLevel)
    case recordAttempt(PracticeAttemptEvidence)
    case confirmFirstExchange
    case introduceControls
    case beginNatural
    case naturalPlaybackBegan
    case requestRepair
    case completeRepairStop
    case completeControlledSegment
    case beginResume
    case completeResume
    case setLearningAction(NextLearningAction)
    case finishLesson
}

enum KaiwaLoopReducer {
    static func reduce(
        _ state: KaiwaLoopState,
        _ action: KaiwaLoopSemanticAction
    ) -> KaiwaLoopState {
        var next = state

        switch action {
        case .beginCoached(let scaffold):
            guard next.phase == .setup || next.phase == .coached else { return state }
            let expected: ScaffoldLevel = switch next.successfulScaffolds.count {
            case 0: .full
            case 1: .rhythmOnly
            default: .none
            }
            guard scaffold == expected else { return state }
            next.phase = .coached
            next.scaffold = scaffold
            next.lastError = nil

        case .recordAttempt(let attempt):
            guard attempt.obligationID == KaiwaLoopState.obligationID,
                  attempt.capturedDuration.isFinite,
                  attempt.capturedDuration >= 0,
                  !next.attempts.contains(where: { $0.id == attempt.id }) else { return state }

            switch next.phase {
            case .coached:
                guard attempt.scaffold == next.scaffold,
                      attempt.repairCount == 0 else { return state }
                next.attempts.append(attempt)
                guard attempt.selfReportedCompleted,
                      !next.successfulScaffolds.contains(attempt.scaffold) else { return next }
                next.successfulScaffolds.append(attempt.scaffold)
                switch attempt.scaffold {
                case .full:
                    next.scaffold = .rhythmOnly
                case .rhythmOnly:
                    next.scaffold = .none
                case .none:
                    next.phase = .firstSuccess
                }

            case .retry:
                guard attempt.scaffold == .none,
                      attempt.repairCount > 0,
                      next.naturalStopRecorded,
                      next.repairSegmentPlayed,
                      next.resumePlaybackCompleted else { return state }
                next.attempts.append(attempt)
                if attempt.selfReportedCompleted {
                    next.phase = .proof
                }

            default:
                return state
            }

        case .confirmFirstExchange:
            guard next.phase == .firstSuccess,
                  next.successfulScaffolds == [.full, .rhythmOnly, .none],
                  next.completedPreRepairAttempt != nil else { return state }

        case .introduceControls:
            guard next.phase == .firstSuccess else { return state }
            next.phase = .controls

        case .beginNatural:
            guard next.phase == .controls || next.phase == .natural else { return state }
            next.phase = .natural
            next.naturalTutorFinished = false
            next.naturalPlaybackStarted = false
            next.naturalStopRecorded = false
            next.repairSegmentPlayed = false
            next.resumePlaybackCompleted = false

        case .naturalPlaybackBegan:
            guard next.phase == .natural else { return state }
            next.naturalPlaybackStarted = true

        case .requestRepair:
            guard next.phase == .natural,
                  next.naturalPlaybackStarted,
                  !next.naturalStopRecorded else { return state }
            next.naturalStopRecorded = true
            next.repairCount += 1

        case .completeRepairStop:
            guard next.phase == .natural, next.naturalStopRecorded else { return state }
            next.phase = .repair
            next.lastError = nil

        case .completeControlledSegment:
            guard next.phase == .repair, next.naturalStopRecorded else { return state }
            next.repairSegmentPlayed = true

        case .beginResume:
            guard next.phase == .repair, next.canResumeAfterRepair else { return state }
            next.phase = .resuming

        case .completeResume:
            guard next.phase == .resuming,
                  next.naturalStopRecorded,
                  next.repairSegmentPlayed else { return state }
            next.resumePlaybackCompleted = true
            next.phase = .retry

        case .setLearningAction(let action):
            guard next.phase == .proof,
                  action.obligationID == KaiwaLoopState.obligationID else { return state }
            next.nextLearningAction = action

        case .finishLesson:
            guard next.phase == .proof,
                  next.completedPreRepairAttempt != nil,
                  next.completedPostRepairAttempt != nil,
                  next.nextLearningAction != nil else { return state }
            next.naturalTutorFinished = true
        }

        return next
    }
}
