import SwiftUI

/// Single navigation flow: setup → tutor speaking (with はい overlay) →
/// yield/repair → proof → reset. Phase comes only from reduced fixture state.
struct PracticeRootView: View {
    let feature: PracticeFeature
    var onExit: (() -> Void)? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            ChromeBar(badge: feature.state.sourceBadge, onExit: onExit)
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MATheme.paper)
        // Haptics only where they clarify a state change the eyes might miss.
        .modifier(BackchannelHaptic(count: feature.state.backchannelCount))
        .modifier(FloorYieldHaptic(phase: feature.state.phase))
        .modifier(FirstSuccessHaptic(phase: feature.state.phase))
        .modifier(ProofHaptic(phase: feature.state.phase))
    }

    @ViewBuilder
    private var content: some View {
        switch feature.state.phase {
        case .setup:
            SetupView(send: { feature.send($0) })
        case .coached:
            CoachedPracticeView(state: feature.state, send: { feature.send($0) })
        case .firstSuccess:
            FirstSuccessView(send: { feature.send($0) })
        case .controlsIntro:
            ControlsIntroView(send: { feature.send($0) })
        case .tutorSpeaking:
            ListeningView(
                state: feature.state,
                send: { feature.send($0) },
                reduceMotion: reduceMotion
            )
        case .floorYielded:
            RepairView(state: feature.state, send: { feature.send($0) })
        case .proof:
            ProofView(state: feature.state, send: { feature.send($0) })
        }
    }
}

private struct BackchannelHaptic: ViewModifier {
    let count: Int

    func body(content: Content) -> some View {
        content.sensoryFeedback(.impact(weight: .light), trigger: count) {
            oldValue, newValue in newValue > oldValue
        }
    }
}

private struct FloorYieldHaptic: ViewModifier {
    let phase: PracticePhase

    func body(content: Content) -> some View {
        content.sensoryFeedback(.impact(weight: .medium), trigger: phase) {
            oldValue, newValue in oldValue != .floorYielded && newValue == .floorYielded
        }
    }
}

private struct FirstSuccessHaptic: ViewModifier {
    let phase: PracticePhase

    func body(content: Content) -> some View {
        content.sensoryFeedback(.success, trigger: phase) {
            oldValue, newValue in oldValue != .firstSuccess && newValue == .firstSuccess
        }
    }
}

private struct ProofHaptic: ViewModifier {
    let phase: PracticePhase

    func body(content: Content) -> some View {
        content.sensoryFeedback(.success, trigger: phase) {
            oldValue, newValue in oldValue != .proof && newValue == .proof
        }
    }
}

// MARK: - Previews for the five Paper states

#Preview("01 Learn") {
    PracticeRootView(feature: PracticeFeature())
}

#Preview("02 Listen") {
    PracticeRootView(feature: .preview(through: .listening))
}

#Preview("03 Hai") {
    PracticeRootView(feature: .preview(through: .haiOverlay))
}

#Preview("04 Sumimasen") {
    PracticeRootView(feature: .preview(through: .yielded))
}

#Preview("05 Proof") {
    PracticeRootView(feature: .preview(through: .proof))
}

extension PracticeFeature {
    enum PreviewStage {
        case coachedFull, coachedRhythm, coachedNoText, firstSuccess, controlsIntro
        case listening, haiOverlay, yielded, proof
    }

    /// Builds a feature advanced through the deterministic fixture logs to a
    /// fixed stage — previews replay events, they never fake state directly.
    static func preview(through stage: PreviewStage) -> PracticeFeature {
        let feature = PracticeFeature()
        let events: [PracticeEvent]
        switch stage {
        case .coachedFull:
            events = [.coachedRoundStarted(.full)]
        case .coachedRhythm:
            events = [
                .coachedRoundStarted(.full),
                .coachedAttemptMarked(.full),
                .coachedAttemptSucceeded(.full),
                .coachedRoundStarted(.rhythmOnly),
            ]
        case .coachedNoText:
            events = RestaurantForOneFixture.coachedLadderEvents.dropLast(3)
        case .firstSuccess:
            events = RestaurantForOneFixture.coachedLadderEvents
        case .controlsIntro:
            events = RestaurantForOneFixture.coachedLadderEvents + [.controlsIntroStarted]
        case .listening:
            events = RestaurantForOneFixture.naturalReadyEvents
                + RestaurantForOneFixture.listeningStageEvents
        case .haiOverlay:
            events = RestaurantForOneFixture.naturalReadyEvents
                + RestaurantForOneFixture.listeningStageEvents
                + RestaurantForOneFixture.haiStageEvents
        case .yielded:
            events = RestaurantForOneFixture.throughYieldEvents
        case .proof:
            events = RestaurantForOneFixture.heroEventLog
        }
        feature.replay(events)
        return feature
    }
}
