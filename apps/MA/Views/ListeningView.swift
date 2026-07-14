import SwiftUI

/// Paper 02 Listen and 03 Hai in one view: the はい acknowledgement is an
/// overlay on the speaking state, never a different screen.
struct ListeningView: View {
    let state: PracticeState
    let send: (PracticeIntent) -> Void
    let reduceMotion: Bool
    @State private var wakeStartedAt: Date?

    private var overlayActive: Bool { state.backchannel != nil }

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                stateHeader
                inkHero
                captionBlock
                TutorTimelineView(
                    beats: state.timelineBeats,
                    backchannelMarks: state.backchannelMarks,
                    outputActive: state.tutorOutputActive
                )
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 24)
                Spacer(minLength: 10)
                bottomControls
            }
        }
        .onAppear {
            if state.backchannel != nil, wakeStartedAt == nil {
                wakeStartedAt = .now
            }
        }
        .onChange(of: state.backchannelCount) { oldCount, newCount in
            if newCount > oldCount {
                // Count, rather than fixture timestamp, makes every spoken はい
                // restart the visual wake even while the fixture clock is still.
                wakeStartedAt = .now
            }
        }
        .onChange(of: state.backchannel == nil) { _, isNil in
            if isNil { wakeStartedAt = nil }
        }
    }

    private var stateHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(overlayActive ? "HAI MARCADO · LA SECUENCIA SIGUE" : "SIMULACIÓN VISUAL · SECUENCIA SIN AUDIO")
                .font(MATheme.caption(.semibold))
                .tracking(MATheme.capsTracking(fontSize: 13))
                .foregroundStyle(MATheme.ai)
            Text(overlayActive
                 ? "Marcaste «hai». La secuencia no se detiene."
                 : "Así fluirá el tutor real a velocidad natural. Aquí lo ves, no lo oyes.")
                .font(MATheme.heading())
                .tracking(MATheme.tightTracking(fontSize: 20))
                .foregroundStyle(MATheme.sumi)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 24)
    }

    private var inkHero: some View {
        VStack(spacing: 8) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
                VoiceInkView(
                    mode: overlayActive
                        ? .hai(elapsedSinceBackchannel: elapsedSinceBackchannel(now: timeline.date))
                        : .speaking,
                    time: animationTime(now: timeline.date),
                    reduceMotion: reduceMotion
                )
                .frame(width: 320, height: 240)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { inkStatusLabels }
                VStack(spacing: 3) { inkStatusLabels }
            }
            .padding(.horizontal, MATheme.sideMargin)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(overlayActive
            ? "Marcaste はい y la secuencia simulada sigue sin interrupción."
            : "Simulación visual del tutor hablando; esta maqueta no reproduce audio.")
    }

    @ViewBuilder
    private var inkStatusLabels: some View {
        MicroCapsLabel(
            text: overlayActive ? "SIMULACIÓN · SIN PAUSA" : "SIMULACIÓN",
            color: MATheme.ai
        )
        Text(overlayActive ? "tu onda cruzó la tinta sin romperla" : "así respirará la voz del tutor")
            .font(MATheme.micro())
            .foregroundStyle(MATheme.stone)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.center)
    }

    private var captionBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let line = state.tutorLine {
                Text(line.japanese)
                    .font(MATheme.jp(26))
                    .foregroundStyle(MATheme.sumi)
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.romaji)
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                    Text(line.spanish)
                        .font(MATheme.caption(.medium))
                        .foregroundStyle(MATheme.sumi)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 20)
        .overlay(Rectangle().fill(MATheme.hairline).frame(height: 1), alignment: .top)
    }

    private var bottomControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Circle().fill(MATheme.ai).frame(width: 6, height: 6)
                    .padding(.top, 5)
                Text("Maqueta sin micrófono: toca una llave para marcar tu momento.")
                    .font(MATheme.caption(.medium))
                    .foregroundStyle(MATheme.sumi)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 10) {
                keyChip(
                    japanese: "はい",
                    hint: "sigo contigo",
                    active: overlayActive,
                    identifier: "chip.hai",
                    label: "Marcar はい: te sigo, continúa. La secuencia visual no se detendrá."
                ) {
                    send(.sayHai)
                }
                keyChip(
                    japanese: "すみません",
                    hint: "pausa",
                    active: false,
                    identifier: "chip.sumimasen",
                    label: "Marcar すみません: pausa, necesito ayuda. La secuencia visual pasará a reparación."
                ) {
                    send(.saySumimasen)
                }
            }
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.bottom, 10)
    }

    private func keyChip(
        japanese: String, hint: String, active: Bool, identifier: String,
        label: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(japanese)
                    .font(MATheme.jp(16))
                Text(hint)
                    .font(MATheme.caption())
                if active {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .foregroundStyle(active ? MATheme.ai : MATheme.sumi)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(active ? MATheme.mist : .white, in: Capsule())
            .overlay(Capsule().stroke(active ? MATheme.ai : MATheme.hairline, lineWidth: active ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier)
    }

    /// Deterministic anchor: breathing runs on fixture time extended by the
    /// wall clock only for smoothness; Reduce Motion freezes it entirely.
    private func animationTime(now: Date) -> Double {
        reduceMotion
            ? state.fixtureTime
            : state.fixtureTime + now.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 3.6)
    }

    private func elapsedSinceBackchannel(now: Date) -> Double {
        guard state.backchannel != nil else { return 0 }
        guard !reduceMotion else { return 1.0 }
        guard let wakeStartedAt else { return 0 }
        return max(0, now.timeIntervalSince(wakeStartedAt))
    }
}
