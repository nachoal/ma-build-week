import Foundation
import Observation

@MainActor
@Observable
final class KaiwaLoopFeature {
    private(set) var state = KaiwaLoopState()

    @ObservationIgnored private let audio: any ProductAudioControlling
    @ObservationIgnored private let learningPlanner: any LearningPlanning
    @ObservationIgnored private var operationTask: Task<Void, Never>?
    @ObservationIgnored private var eventTask: Task<Void, Never>?
    @ObservationIgnored private var plannerTask: Task<Void, Never>?

    static func production() -> KaiwaLoopFeature {
        KaiwaLoopFeature(
            audio: AudioGraphController(),
            learningPlanner: LearningPlanner.production()
        )
    }

    init(
        audio: (any ProductAudioControlling)? = nil,
        learningPlanner: any LearningPlanning = LearningPlanner()
    ) {
        self.audio = audio ?? AudioGraphController()
        self.learningPlanner = learningPlanner
        let events = self.audio.events
        eventTask = Task { [weak self] in
            for await event in events {
                guard !Task.isCancelled else { return }
                self?.consume(event)
            }
        }
    }

    deinit {
        operationTask?.cancel()
        eventTask?.cancel()
        plannerTask?.cancel()
    }

    func send(_ intent: KaiwaLoopIntent) {
        // Service events are ordered but asynchronous. Refresh from the sole
        // owner before admitting a new intent so a queued `.capturing` event
        // cannot reject the next round after hardware is already idle.
        state.audioState = audio.state
        switch intent {
        case .playModel:
            play(.hitoriDesu)

        case .beginCoachedPractice:
            guard state.phase == .setup else { return }
            state.phase = .coached
            state.scaffold = .full
            state.lastError = nil

        case .startAttempt:
            guard state.phase == .coached || state.phase == .retry,
                  !state.isCapturing,
                  !state.isRequestingPermission,
                  !state.awaitingSelfAssessment else { return }
            startAttempt()

        case .finishAttempt:
            guard state.isCapturing else { return }
            finishAttempt()

        case .assessSuccess:
            assess(completed: true)

        case .assessRetry:
            assess(completed: false)

        case .acknowledgeFirstSuccess:
            guard state.phase == .firstSuccess else { return }
            state.phase = .controls

        case .startNatural:
            guard state.phase == .controls || state.phase == .natural else { return }
            state.phase = .natural
            state.naturalTutorFinished = false
            state.naturalPlaybackStarted = false
            state.naturalStopRecorded = false
            state.repairSegmentPlayed = false
            state.resumePlaybackCompleted = false
            play(.tutorTurn) { [weak self] in
                self?.state.naturalTutorFinished = true
            }

        case .pauseForRepair:
            guard state.phase == .natural, state.canPauseNaturalAudio else { return }
            operationTask?.cancel()
            operationTask = Task { [weak self] in
                guard let self else { return }
                await audio.stop(.explicitRepair)
                state.repairCount += 1
                state.naturalStopRecorded = true
                state.phase = .repair
                state.lastError = nil
            }

        case .playRepairSegment:
            guard state.phase == .repair else { return }
            play(.repairBeat) { [weak self] in
                self?.state.repairSegmentPlayed = true
            }

        case .resumeScene:
            guard (state.phase == .repair || state.phase == .resuming),
                  state.canResumeAfterRepair else { return }
            state.phase = .resuming
            play(.tutorResume) { [weak self] in
                self?.state.resumePlaybackCompleted = true
                self?.state.phase = .retry
            }

        case .restart:
            operationTask?.cancel()
            plannerTask?.cancel()
            state = KaiwaLoopState()
            operationTask = Task { [weak self] in
                guard let self else { return }
                await audio.stop(.restart)
            }
        }
    }

    func stopForExit() async {
        operationTask?.cancel()
        plannerTask?.cancel()
        await audio.stop(.exit)
        state = KaiwaLoopState()
    }

    private func play(
        _ prompt: BundledPrompt,
        onFinished: (@MainActor () -> Void)? = nil
    ) {
        operationTask?.cancel()
        operationTask = Task { [weak self] in
            guard let self else { return }
            state.lastError = nil
            do {
                try await audio.play(prompt)
                guard !Task.isCancelled else { return }
                state.playedPrompts.insert(prompt)
                onFinished?()
            } catch let failure as ProductAudioFailure {
                guard failure != .interrupted else { return }
                state.lastError = failure
            } catch {
                state.lastError = .hardwareUnavailable
            }
        }
    }

    private func startAttempt() {
        let attemptNumber = state.attempts.count + 1
        let scaffold = state.phase == .retry ? ScaffoldLevel.none : state.scaffold
        let request = CaptureRequest(
            obligationID: KaiwaLoopState.obligationID,
            scaffold: scaffold,
            attemptNumber: attemptNumber
        )
        operationTask?.cancel()
        operationTask = Task { [weak self] in
            guard let self else { return }
            state.lastError = nil
            do {
                try await audio.startCapture(request)
            } catch let failure as ProductAudioFailure {
                state.lastError = failure
            } catch {
                state.lastError = .hardwareUnavailable
            }
        }
    }

    private func finishAttempt() {
        operationTask?.cancel()
        operationTask = Task { [weak self] in
            guard let self else { return }
            do {
                if let receipt = try await audio.finishCapture(.completed) {
                    consumeReceipt(receipt)
                }
            } catch let failure as ProductAudioFailure {
                state.lastError = failure
            } catch {
                state.lastError = .hardwareUnavailable
            }
        }
    }

    private func assess(completed: Bool) {
        guard state.awaitingSelfAssessment,
              let receipt = state.pendingReceipt else { return }
        let evidence = PracticeAttemptEvidence(
            receipt: receipt,
            selfReportedCompleted: completed,
            repairCount: state.phase == .retry ? max(1, state.repairCount) : 0
        )
        if !state.attempts.contains(where: { $0.id == evidence.id }) {
            state.attempts.append(evidence)
        }
        state.pendingReceipt = nil
        state.awaitingSelfAssessment = false

        guard completed else { return }
        if state.phase == .retry {
            guard state.naturalStopRecorded,
                  state.repairSegmentPlayed,
                  state.resumePlaybackCompleted else { return }
            state.phase = .proof
            startPlanning()
            return
        }
        guard state.phase == .coached else { return }
        state.successfulScaffolds.append(state.scaffold)
        switch state.scaffold {
        case .full:
            state.scaffold = .rhythmOnly
        case .rhythmOnly:
            state.scaffold = .none
        case .none:
            state.phase = .firstSuccess
        }
    }

    private func consume(_ event: ProductAudioEvent) {
        switch event {
        case .stateChanged(let audioState):
            state.audioState = audioState
            if audioState == .playing(.tutorTurn) {
                state.naturalPlaybackStarted = true
            }
        case .playbackFinished(let prompt):
            state.playedPrompts.insert(prompt)
        case .captureFinished(let receipt):
            consumeReceipt(receipt)
        case .lifecycleStopped:
            state.lastError = .interrupted
        }
    }

    private func consumeReceipt(_ receipt: CaptureReceipt) {
        guard receipt.disposition == .completed || receipt.disposition == .timeLimit,
              state.pendingReceipt?.id != receipt.id,
              !state.attempts.contains(where: { $0.id == receipt.id }) else { return }
        state.pendingReceipt = receipt
        state.awaitingSelfAssessment = true
    }

    private func startPlanning() {
        guard let report = LearningReport.make(from: state) else { return }
        let policy = DeterministicPedagogyPolicy()
        state.learningReport = report
        state.nextLearningAction = policy.fallback(for: report)
        state.plannerIsRefreshing = true

        plannerTask?.cancel()
        plannerTask = Task { [weak self] in
            guard let self else { return }
            let action = await learningPlanner.nextAction(for: report)
            guard !Task.isCancelled,
                  state.phase == .proof,
                  state.learningReport?.id == report.id,
                  action.reportID == report.id else { return }
            state.nextLearningAction = action
            state.plannerIsRefreshing = false
        }
    }
}
