import Foundation
import Observation

@MainActor
@Observable
final class GuidedLessonFeature {
    private(set) var state = GuidedLessonState()

    @ObservationIgnored private let audio: any GuidedLessonAudioControlling
    @ObservationIgnored private let realtime: any GuidedRealtimeProviding
    @ObservationIgnored private let planner: (any GuidedLearningPlanning)?
    @ObservationIgnored private let pedagogyPolicy: GuidedPedagogyPolicy
    @ObservationIgnored private var interfaceLanguage: MAInterfaceLanguage
    @ObservationIgnored private var operationTask: Task<Void, Never>?
    @ObservationIgnored private var connectionTask: Task<Void, Never>?
    @ObservationIgnored private var recordingTimeoutTask: Task<Void, Never>?
    @ObservationIgnored private var eventTask: Task<Void, Never>?
    @ObservationIgnored private var spokenFeedbackTask: Task<Void, Never>?
    @ObservationIgnored private var resetTask: Task<Void, Never>?
    @ObservationIgnored private var resetGeneration: UInt64?
    @ObservationIgnored private var activeRequest: GuidedAttemptRequest?
    @ObservationIgnored private var activeCaptureRequest: CaptureRequest?
    @ObservationIgnored private var generation: UInt64 = 0

    static func production() -> GuidedLessonFeature {
        #if DEBUG
        if ProcessInfo.processInfo.environment["MA_UI_TEST_GUIDED_FIXTURE"] == "true" {
            return GuidedLessonFeature(
                audio: GuidedLessonUITestAudioController(),
                realtime: GuidedLessonUITestRealtimeProvider(),
                planner: GuidedLessonUITestLearningPlanner()
            )
        }
        #endif
        let credentials = PlannerInstallCredentialStore()
        try? credentials.provisionFromProcessEnvironment()
        return GuidedLessonFeature(
            audio: AudioGraphController(),
            realtime: DidacticRealtimeProvider(
                broker: GuidedRealtimeSessionBrokerClient(credentials: credentials)
            ),
            planner: GuidedLearningPlanner(
                remote: GuidedBrokerLearningPlanner(credentials: credentials)
            )
        )
    }

    init(
        audio: any GuidedLessonAudioControlling,
        realtime: any GuidedRealtimeProviding,
        planner: (any GuidedLearningPlanning)? = nil,
        pedagogyPolicy: GuidedPedagogyPolicy = GuidedPedagogyPolicy(),
        interfaceLanguage: MAInterfaceLanguage = .defaultLanguage
    ) {
        self.audio = audio
        self.realtime = realtime
        self.planner = planner
        self.pedagogyPolicy = pedagogyPolicy
        self.interfaceLanguage = interfaceLanguage
        let events = audio.events
        eventTask = Task { [weak self] in
            for await event in events {
                guard !Task.isCancelled else { return }
                self?.consumeAudioEvent(event)
            }
        }
    }

    func setInterfaceLanguage(_ language: MAInterfaceLanguage) {
        interfaceLanguage = language
    }

    deinit {
        operationTask?.cancel()
        connectionTask?.cancel()
        recordingTimeoutTask?.cancel()
        eventTask?.cancel()
        spokenFeedbackTask?.cancel()
        resetTask?.cancel()
    }

    func send(_ intent: GuidedLessonIntent) {
        if resetTask != nil, intent != .restart { return }
        switch intent {
        case .showPhrase:
            guard state.phase == .orientation else { return }
            state.phase = .model(.ready)
            warmRealtimeConnection()

        case .playModel:
            playModel()

        case .beginAttempt:
            beginAttempt()

        case .finishAttempt:
            finishAttempt(disposition: .completed)

        case .retryAttempt:
            retryAttempt()

        case .continueWithFeedback:
            continueWithFeedback()

        case .playWaiterTurn:
            playWaiterTurn()

        case .requestNextPlan:
            requestNextPlan()

        case .restart:
            beginRestart()
        }
    }

    func stopForExit() async {
        generation &+= 1
        operationTask?.cancel()
        connectionTask?.cancel()
        recordingTimeoutTask?.cancel()
        spokenFeedbackTask?.cancel()
        resetTask?.cancel()
        let pendingSpokenFeedback = spokenFeedbackTask
        let pendingReset = resetTask
        spokenFeedbackTask = nil
        resetTask = nil
        resetGeneration = nil
        activeRequest = nil
        activeCaptureRequest = nil
        await audio.stop(.exit)
        await pendingSpokenFeedback?.value
        await pendingReset?.value
        await realtime.disconnect()
        state = GuidedLessonState()
    }

    /// Completes all prior audio/provider teardown before the next lesson can
    /// expose an actionable control. Root navigation awaits this method, so a
    /// quick first tap can never race an old restart task.
    func resetForNewLesson() async {
        let reset = startResetIfNeeded()
        await reset.task.value
        finishReset(generation: reset.generation)
    }

    private func playModel() {
        guard case .model(let step) = state.phase,
              step == .ready || step == .completed,
              !state.isBusy else { return }
        operationTask?.cancel()
        let operationGeneration = generation
        state.phase = .model(.playing)
        operationTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await audio.play(.hitoriDesu)
                guard !Task.isCancelled, generation == operationGeneration else { return }
                state.phase = .model(.completed)
            } catch {
                guard !Task.isCancelled, generation == operationGeneration else { return }
                state.phase = .model(.ready)
            }
        }
    }

    private func beginAttempt() {
        let context: GuidedAttemptContext
        switch state.phase {
        case .model(.completed):
            context = .taughtPhrase
        case .attempt(let currentContext, .ready),
             .attempt(let currentContext, .recoverableError):
            context = currentContext
        case .tutorTurn(.responseReady):
            context = .restaurantTurn
        default:
            return
        }
        guard !state.isBusy else { return }

        operationTask?.cancel()
        recordingTimeoutTask?.cancel()
        let request = GuidedAttemptRequest(
            context: context,
            attemptNumber: state.attemptCount + 1,
            feedbackLanguage: interfaceLanguage
        )
        let capture = CaptureRequest(
            id: request.id,
            obligationID: KaiwaLoopState.obligationID,
            // The answer remains visible in both stages. Never report this as
            // an unsupported attempt until the UI genuinely hides it.
            scaffold: .full,
            attemptNumber: request.attemptNumber,
            maximumDuration: .seconds(8)
        )
        activeRequest = request
        activeCaptureRequest = capture
        state.spokenFeedbackUnavailable = false
        state.phase = .attempt(context: context, step: .requestingPermission)
        let operationGeneration = generation

        operationTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await audio.startRealtimeCapture(capture)
                guard !Task.isCancelled,
                      generation == operationGeneration,
                      activeRequest?.id == request.id else {
                    await audio.stop(.replacement)
                    return
                }
                state.attemptCount = request.attemptNumber
                state.phase = .attempt(
                    context: context,
                    step: .recording(attemptID: request.id)
                )
                scheduleRecordingTimeout(requestID: request.id)
            } catch let failure as ProductAudioFailure {
                guard !Task.isCancelled,
                      generation == operationGeneration,
                      activeRequest?.id == request.id,
                      activeCaptureRequest?.id == request.id else { return }
                activeRequest = nil
                activeCaptureRequest = nil
                state.phase = .attempt(
                    context: context,
                    step: .recoverableError(
                        failure == .microphoneDenied ? .microphoneDenied : .interrupted
                    )
                )
            } catch {
                guard !Task.isCancelled,
                      generation == operationGeneration,
                      activeRequest?.id == request.id,
                      activeCaptureRequest?.id == request.id else { return }
                activeRequest = nil
                activeCaptureRequest = nil
                state.phase = .attempt(
                    context: context,
                    step: .recoverableError(.interrupted)
                )
            }
        }
    }

    private func finishAttempt(disposition: CaptureDisposition) {
        guard case .attempt(let context, .recording(let attemptID)) = state.phase,
              let request = activeRequest,
              request.id == attemptID,
              activeCaptureRequest?.id == attemptID else { return }

        recordingTimeoutTask?.cancel()
        recordingTimeoutTask = nil
        state.phase = .attempt(context: context, step: .reviewing(attemptID: attemptID))
        let operationGeneration = generation
        operationTask?.cancel()
        operationTask = Task { [weak self] in
            guard let self else { return }
            do {
                guard let payload = try await audio.finishRealtimeCapture(disposition),
                      payload.receipt.id == attemptID,
                      payload.receipt.speechPresenceDetected,
                      payload.pcm16Data.count >= 9_600 else {
                    throw GuidedRealtimeError.noSpeech
                }
                let result = try await realtime.reviewAttempt(
                    request,
                    pcm16Data: payload.pcm16Data
                )
                guard !Task.isCancelled,
                      generation == operationGeneration,
                      activeRequest?.id == attemptID,
                      result.request.id == attemptID else { return }

                activeRequest = nil
                activeCaptureRequest = nil
                state.reviewedAttempts.append(
                    GuidedAttemptFact(result: result, scaffold: .full)
                )
                state.phase = .attempt(context: context, step: .feedback(result))
                startSpokenFeedback(for: result, generation: operationGeneration)
            } catch let error as GuidedRealtimeError {
                guard !Task.isCancelled, generation == operationGeneration else { return }
                activeRequest = nil
                activeCaptureRequest = nil
                state.phase = .attempt(
                    context: context,
                    step: .recoverableError(error == .noSpeech ? .noSpeech : .reviewUnavailable)
                )
            } catch {
                guard !Task.isCancelled, generation == operationGeneration else { return }
                activeRequest = nil
                activeCaptureRequest = nil
                state.phase = .attempt(
                    context: context,
                    step: .recoverableError(.reviewUnavailable)
                )
            }
        }
    }

    private func retryAttempt() {
        guard state.feedbackTransition == nil else { return }
        let context: GuidedAttemptContext
        switch state.phase {
        case .attempt(let currentContext, .feedback),
             .attempt(let currentContext, .recoverableError):
            context = currentContext
        default:
            return
        }
        operationTask?.cancel()
        recordingTimeoutTask?.cancel()
        let pendingSpokenFeedback = spokenFeedbackTask
        pendingSpokenFeedback?.cancel()
        spokenFeedbackTask = nil
        activeRequest = nil
        activeCaptureRequest = nil
        state.feedbackTransition = .retrying
        let operationGeneration = generation
        operationTask = Task { [weak self] in
            guard let self else { return }
            await audio.stop(.replacement)
            await pendingSpokenFeedback?.value
            guard !Task.isCancelled,
                  generation == operationGeneration,
                  state.feedbackTransition == .retrying else { return }
            state.feedbackTransition = nil
            state.phase = .attempt(context: context, step: .ready)
        }
    }

    private func continueWithFeedback() {
        guard state.feedbackTransition == nil,
              case .attempt(let context, .feedback(let result)) = state.phase else { return }
        operationTask?.cancel()
        let pendingSpokenFeedback = spokenFeedbackTask
        pendingSpokenFeedback?.cancel()
        spokenFeedbackTask = nil
        state.feedbackTransition = .continuing
        let operationGeneration = generation
        operationTask = Task { [weak self] in
            guard let self else { return }
            await audio.stop(.replacement)
            await pendingSpokenFeedback?.value
            guard !Task.isCancelled,
                  generation == operationGeneration,
                  state.feedbackTransition == .continuing else { return }
            state.feedbackTransition = nil
            state.answerSupportVisible = result.review.targetMatch == .different
                || result.review.targetMatch == .unclear
            if context == .taughtPhrase {
                state.phase = .situationBrief
            } else {
                completeLesson()
            }
        }
    }

    private func completeLesson() {
        state.phase = .complete
        guard let report = GuidedLearningReport.make(from: state.reviewedAttempts) else {
            state.learningReport = nil
            state.plannerStep = nil
            return
        }
        state.learningReport = report
        state.plannerStep = .local(pedagogyPolicy.fallback(for: report))
    }

    private func requestNextPlan() {
        guard state.phase == .complete,
              let planner,
              let report = state.learningReport,
              let current = state.plannerStep else { return }
        switch current {
        case .requesting, .model:
            return
        case .local, .unavailable:
            break
        }

        let fallback = pedagogyPolicy.fallback(for: report)
        state.plannerStep = .requesting(fallback)
        operationTask?.cancel()
        let operationGeneration = generation
        operationTask = Task { [weak self] in
            guard let self else { return }
            do {
                let action = try await planner.improvedAction(for: report)
                guard !Task.isCancelled,
                      generation == operationGeneration,
                      state.phase == .complete,
                      state.learningReport?.id == report.id else { return }
                state.plannerStep = .model(action)
            } catch {
                guard !Task.isCancelled,
                      generation == operationGeneration,
                      state.phase == .complete,
                      state.learningReport?.id == report.id else { return }
                state.plannerStep = .unavailable(fallback)
            }
        }
    }

    private func playWaiterTurn() {
        switch state.phase {
        case .situationBrief, .tutorTurn(.ready), .tutorTurn(.recoverableError):
            break
        default:
            return
        }
        operationTask?.cancel()
        let operationGeneration = generation
        state.phase = .tutorTurn(.preparing)
        operationTask = Task { [weak self] in
            guard let self else { return }
            do {
                let turn = try await realtime.requestRestaurantTurn()
                guard !Task.isCancelled, generation == operationGeneration else { return }
                state.phase = .tutorTurn(.speaking)
                try await audio.playRealtimePCM16(turn.pcm16Data)
                guard !Task.isCancelled, generation == operationGeneration else { return }
                state.phase = .tutorTurn(.responseReady)
            } catch {
                guard !Task.isCancelled, generation == operationGeneration else { return }
                state.phase = .tutorTurn(.recoverableError)
            }
        }
    }

    private func warmRealtimeConnection() {
        guard connectionTask == nil, !state.connectionReady else { return }
        let operationGeneration = generation
        connectionTask = Task { [weak self] in
            guard let self else { return }
            defer { connectionTask = nil }
            do {
                try await realtime.connect()
                guard !Task.isCancelled, generation == operationGeneration else { return }
                state.connectionReady = true
            } catch {
                // Recording remains available; the visible review state owns
                // the actionable retry if a later connection also fails.
            }
        }
    }

    private func scheduleRecordingTimeout(requestID: UUID) {
        recordingTimeoutTask?.cancel()
        recordingTimeoutTask = Task { [weak self] in
            try? await ContinuousClock().sleep(for: .seconds(8))
            guard !Task.isCancelled,
                  let self,
                  activeRequest?.id == requestID else { return }
            finishAttempt(disposition: .timeLimit)
        }
    }

    private func consumeAudioEvent(_ event: ProductAudioEvent) {
        switch event {
        case .stateChanged(let audioState):
            state.audioState = audioState
        case .lifecycleStopped:
            recordingTimeoutTask?.cancel()
            spokenFeedbackTask?.cancel()
            activeRequest = nil
            activeCaptureRequest = nil
            if case .attempt(let context, let step) = state.phase {
                if case .feedback = step {
                    state.spokenFeedbackUnavailable = true
                } else {
                    state.phase = .attempt(
                        context: context,
                        step: .recoverableError(.interrupted)
                    )
                }
            }
        case .playbackFinished, .captureFinished:
            break
        }
    }

    private func startSpokenFeedback(
        for result: GuidedRealtimeReviewResult,
        generation operationGeneration: UInt64
    ) {
        spokenFeedbackTask?.cancel()
        state.spokenFeedbackUnavailable = false
        spokenFeedbackTask = Task { [weak self] in
            guard let self else { return }
            do {
                let spoken = try await realtime.requestSpokenFeedback(for: result)
                guard !Task.isCancelled,
                      generation == operationGeneration,
                      isShowingFeedback(for: result.request.id) else { return }
                try await audio.playRealtimePCM16(spoken.pcm16Data)
            } catch {
                guard !Task.isCancelled,
                      generation == operationGeneration,
                      isShowingFeedback(for: result.request.id) else { return }
                state.spokenFeedbackUnavailable = true
            }
        }
    }

    private func isShowingFeedback(for requestID: UUID) -> Bool {
        guard case .attempt(_, .feedback(let result)) = state.phase else { return false }
        return result.request.id == requestID
    }

    private func beginRestart() {
        let reset = startResetIfNeeded()
        Task { [weak self] in
            await reset.task.value
            self?.finishReset(generation: reset.generation)
        }
    }

    private func startResetIfNeeded() -> (task: Task<Void, Never>, generation: UInt64) {
        if let resetTask, let resetGeneration {
            return (resetTask, resetGeneration)
        }

        generation &+= 1
        operationTask?.cancel()
        connectionTask?.cancel()
        recordingTimeoutTask?.cancel()
        let pendingSpokenFeedback = spokenFeedbackTask
        pendingSpokenFeedback?.cancel()
        spokenFeedbackTask = nil
        activeRequest = nil
        activeCaptureRequest = nil
        let operationGeneration = generation
        let task = Task { [audio, realtime] in
            await audio.stop(.restart)
            await pendingSpokenFeedback?.value
            await realtime.disconnect()
        }
        resetTask = task
        resetGeneration = operationGeneration
        return (task, operationGeneration)
    }

    private func finishReset(generation operationGeneration: UInt64) {
        guard resetGeneration == operationGeneration else { return }
        resetTask = nil
        resetGeneration = nil
        guard generation == operationGeneration else { return }
        state = GuidedLessonState()
    }
}
