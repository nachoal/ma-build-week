import Foundation
import Observation

@MainActor
@Observable
final class KaiwaLoopFeature {
    private(set) var state = KaiwaLoopState()

    @ObservationIgnored private let audio: any ProductAudioControlling
    @ObservationIgnored private let learningPlanner: any LearningPlanning
    @ObservationIgnored private var operationTask: Task<Void, Never>?
    @ObservationIgnored private var resetTask: Task<Void, Never>?
    @ObservationIgnored private var eventTask: Task<Void, Never>?
    @ObservationIgnored private var plannerTask: Task<Void, Never>?
    @ObservationIgnored private var replayTask: Task<Void, Never>?
    @ObservationIgnored private var replayAdapter: ReplayAdapter?
    @ObservationIgnored private var replayGeneration = 0
    @ObservationIgnored private var activeCaptureRequestID: UUID?

    static func production() -> KaiwaLoopFeature {
        KaiwaLoopFeature(
            audio: AudioGraphController(),
            learningPlanner: LearningPlanner.production()
        )
    }

    static func labeledReplay() -> KaiwaLoopFeature {
        KaiwaLoopFeature(
            audio: ReplayDisabledAudioController(),
            learningPlanner: LearningPlanner(),
            presentationSource: .labeledReplay
        )
    }

    init(
        audio: (any ProductAudioControlling)? = nil,
        learningPlanner: any LearningPlanning = LearningPlanner(),
        presentationSource: KaiwaPresentationSource = .localProduct
    ) {
        self.audio = audio ?? AudioGraphController()
        self.learningPlanner = learningPlanner
        state.presentationSource = presentationSource
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
        resetTask?.cancel()
        eventTask?.cancel()
        plannerTask?.cancel()
        replayTask?.cancel()
    }

    func send(_ intent: KaiwaLoopIntent) {
        // Service events are ordered but asynchronous. Refresh from the sole
        // owner before admitting a new intent so a queued `.capturing` event
        // cannot reject the next round after hardware is already idle.
        state.audioState = audio.state
        if state.presentationSource == .labeledReplay {
            if intent == .restart { startLabeledReplay() }
            return
        }
        switch intent {
        case .playModel:
            play(.hitoriDesu)

        case .beginCoachedPractice:
            guard state.phase == .setup else { return }
            transition(.beginCoached(.full))

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
            transition(.confirmFirstExchange)
            transition(.introduceControls)

        case .startNatural:
            guard state.phase == .controls || state.phase == .natural else { return }
            transition(.beginNatural)
            play(.tutorTurn) { [weak self] in
                self?.state.naturalTutorFinished = true
            }

        case .pauseForRepair:
            guard state.phase == .natural, state.canPauseNaturalAudio else { return }
            operationTask?.cancel()
            operationTask = Task { [weak self] in
                guard let self else { return }
                await audio.stop(.explicitRepair)
                transition(.requestRepair)
                transition(.completeRepairStop)
            }

        case .playRepairSegment:
            guard state.phase == .repair else { return }
            play(.repairBeat) { [weak self] in
                self?.transition(.completeControlledSegment)
            }

        case .resumeScene:
            guard (state.phase == .repair || state.phase == .resuming),
                  state.canResumeAfterRepair else { return }
            if state.phase == .repair {
                transition(.beginResume)
            }
            play(.tutorResume) { [weak self] in
                self?.transition(.completeResume)
            }

        case .requestRemotePlan:
            requestRemotePlan()

        case .restart:
            operationTask?.cancel()
            plannerTask?.cancel()
            activeCaptureRequestID = nil
            state = KaiwaLoopState()
            let precedingReset = resetTask
            resetTask = Task { [weak self] in
                guard let self else { return }
                _ = await precedingReset?.result
                guard !Task.isCancelled else { return }
                await audio.stop(.restart)
            }
        }
    }

    func stopForExit() async {
        operationTask?.cancel()
        plannerTask?.cancel()
        replayTask?.cancel()
        replayGeneration += 1
        activeCaptureRequestID = nil
        if let replayAdapter {
            await replayAdapter.disconnect()
            self.replayAdapter = nil
        }
        _ = await resetTask?.result
        resetTask = nil
        await audio.stop(.exit)
        state = KaiwaLoopState()
    }

    /// Drives the same shipping Kaiwa presentation state from a bounded,
    /// provider-neutral fixture. It never invokes audio or LearningPlanning.
    func startLabeledReplay(
        delivery: ReplayDelivery = .paced(
            timeScale: 0.35,
            maximumDelay: .milliseconds(450)
        )
    ) {
        guard state.presentationSource == .labeledReplay else { return }
        replayTask?.cancel()
        if let replayAdapter {
            Task { await replayAdapter.disconnect() }
        }

        replayGeneration += 1
        let generation = replayGeneration
        state = KaiwaLoopState()
        state.presentationSource = .labeledReplay

        let adapter = ReplayAdapter(delivery: delivery)
        replayAdapter = adapter
        let stream = adapter.events

        replayTask = Task { [weak self] in
            let producer = Task {
                do {
                    try await adapter.connect(configuration: KaiwaLoopReplayFixture.configuration)
                    try await adapter.requestResponse()
                } catch {
                    await adapter.disconnect()
                }
            }

            for await event in stream {
                guard !Task.isCancelled,
                      let self,
                      generation == replayGeneration else {
                    producer.cancel()
                    await adapter.disconnect()
                    return
                }
                state = KaiwaLoopReplayReducer.reduce(state, event)
            }
            _ = await producer.result
        }
    }

    private func play(
        _ prompt: BundledPrompt,
        onFinished: (@MainActor () -> Void)? = nil
    ) {
        operationTask?.cancel()
        let pendingReset = resetTask
        operationTask = Task { [weak self] in
            guard let self else { return }
            _ = await pendingReset?.result
            guard !Task.isCancelled else { return }
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
        activeCaptureRequestID = request.id
        operationTask?.cancel()
        let pendingReset = resetTask
        operationTask = Task { [weak self] in
            guard let self else { return }
            _ = await pendingReset?.result
            guard !Task.isCancelled else { return }
            state.lastError = nil
            do {
                try await audio.startCapture(request)
            } catch let failure as ProductAudioFailure {
                if activeCaptureRequestID == request.id {
                    activeCaptureRequestID = nil
                }
                state.lastError = failure
            } catch {
                if activeCaptureRequestID == request.id {
                    activeCaptureRequestID = nil
                }
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
                activeCaptureRequestID = nil
                state.lastError = failure
            } catch {
                activeCaptureRequestID = nil
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
        state.pendingReceipt = nil
        state.awaitingSelfAssessment = false
        transition(.recordAttempt(evidence))

        if completed, state.phase == .proof {
            preparePlanning()
        }
    }

    private func consume(_ event: ProductAudioEvent) {
        switch event {
        case .stateChanged(let audioState):
            state.audioState = audioState
            if audioState == .playing(.tutorTurn) {
                transition(.naturalPlaybackBegan)
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
        guard receipt.id == activeCaptureRequestID else { return }
        activeCaptureRequestID = nil
        guard receipt.disposition == .completed || receipt.disposition == .timeLimit,
              state.phase == .coached || state.phase == .retry,
              state.pendingReceipt?.id != receipt.id,
              !state.attempts.contains(where: { $0.id == receipt.id }) else { return }
        state.pendingReceipt = receipt
        state.awaitingSelfAssessment = true
    }

    private func transition(_ action: KaiwaLoopSemanticAction) {
        state = KaiwaLoopReducer.reduce(state, action)
    }

    private func preparePlanning() {
        guard let report = LearningReport.make(from: state) else { return }
        let policy = DeterministicPedagogyPolicy()
        state.learningReport = report
        state.nextLearningAction = policy.fallback(for: report)
        state.plannerIsRefreshing = false
        state.remotePlannerRequestAttempted = false
    }

    private func requestRemotePlan() {
        guard state.phase == .proof,
              let report = state.learningReport,
              report.isValidForPlannerTransport,
              !state.remotePlannerRequestAttempted,
              !state.plannerIsRefreshing else { return }
        state.remotePlannerRequestAttempted = true
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
