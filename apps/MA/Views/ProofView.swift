import SwiftUI

/// Paper 05 Proof — attempt one versus attempt two on one scale.
struct ProofView: View {
    let state: PracticeState
    let send: (PracticeIntent) -> Void
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @State private var highlightedAttemptID: Int?

    private var attemptOne: AttemptRecord? { state.attempts.first }
    private var attemptTwo: AttemptRecord? { state.attempts.dropFirst().first }

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                header
                if let one = attemptOne {
                    attemptRow(one, brokenPattern: true)
                        .padding(.top, 28)
                }
                if let two = attemptTwo {
                    attemptRow(two, brokenPattern: false)
                        .padding(.top, 22)
                }
                deltaBlock
                repairedBeat
                Spacer(minLength: 10)
                bottomBlock
            }
        }
        .sensoryFeedback(.selection, trigger: highlightedAttemptID)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FIN DE LA ESCENA · DATOS DE MUESTRA")
                .font(MATheme.caption(.semibold))
                .tracking(MATheme.capsTracking(fontSize: 13))
                .foregroundStyle(MATheme.ai)
            Text("Así medirá MA tu progreso.")
                .font(MATheme.display())
                .tracking(MATheme.tightTracking(fontSize: 36))
                .foregroundStyle(MATheme.sumi)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(coachedDisclosure)
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 24)
    }

    private var coachedDisclosure: String {
        if state.coachedAttempts == [.full, .rhythmOnly, .none] {
            return "Lo único tuyo aquí: confirmaste tres repeticiones y la última fue sin texto. Los números de abajo son un ejemplo, no una medición."
        }
        return "Los números de abajo son datos de muestra, no una medición ni evidencia personal."
    }

    private func attemptRow(_ attempt: AttemptRecord, brokenPattern: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                MicroCapsLabel(
                    text: "EJEMPLO · INTENTO \(attempt.id)",
                    color: brokenPattern ? MATheme.stone : MATheme.ai
                )
                Rectangle().fill(MATheme.hairline).frame(height: 1)
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        highlightedAttemptID = highlightedAttemptID == attempt.id ? nil : attempt.id
                    }
                } label: {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(brokenPattern ? MATheme.stone : .white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle().fill(brokenPattern ? .white : MATheme.ai)
                        )
                        .overlay(
                            Circle().stroke(
                                highlightedAttemptID == attempt.id ? MATheme.ai : MATheme.hairline,
                                lineWidth: highlightedAttemptID == attempt.id ? 2 : 1
                            )
                        )
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Resaltar el trazo de muestra \(attempt.id). Acción visual sin audio.")
                .accessibilityIdentifier("visual.intento\(attempt.id)")
            }
            strokesRow(
                brokenPattern: brokenPattern,
                rescues: attempt.rescueCount,
                active: highlightedAttemptID == attempt.id
            )
            Text(
                highlightedAttemptID == attempt.id
                    ? "Trazo resaltado · datos de muestra · \(caption(for: attempt))"
                    : caption(for: attempt)
            )
                .font(MATheme.caption())
                .foregroundStyle(brokenPattern ? MATheme.stone : MATheme.sumi)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
        .padding(.horizontal, MATheme.sideMargin)
    }

    /// Both rows share one height scale so the comparison is honest: hesitant
    /// broken strokes with a rescue ring versus continuous confident strokes.
    private func strokesRow(brokenPattern: Bool, rescues: Int, active: Bool) -> some View {
        HStack(spacing: brokenPattern ? 10 : 8) {
            if brokenPattern {
                Capsule().fill(MATheme.ai.opacity(0.4)).frame(width: 34, height: 10)
                Capsule().fill(MATheme.ai.opacity(0.3)).frame(width: 18, height: 8)
                Capsule().fill(MATheme.ai.opacity(0.4)).frame(width: 26, height: 10)
                if rescues > 0 {
                    Circle()
                        .stroke(MATheme.ai.opacity(0.55), lineWidth: 2)
                        .frame(width: 12, height: 12)
                }
                Capsule().fill(MATheme.ai.opacity(0.4)).frame(width: 44, height: 10)
            } else {
                Capsule().fill(MATheme.ai).frame(width: 68, height: 16)
                Capsule().fill(MATheme.ai).frame(width: 96, height: 20)
                Capsule().fill(MATheme.ai).frame(width: 52, height: 14)
            }
        }
        .frame(height: 22, alignment: .center)
        .scaleEffect(active ? 1.035 : 1, anchor: .leading)
        .opacity(active ? 1 : 0.82)
        .accessibilityHidden(true)
    }

    private func caption(for attempt: AttemptRecord) -> String {
        let latency = decimalComma(attempt.onsetLatency)
        let rescues = attempt.rescueCount == 1 ? "1 rescate" : "\(attempt.rescueCount) rescates"
        return "\(attempt.scaffold.spanishDescription) · inicio a los \(latency) s · \(rescues)"
    }

    private var deltaBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            MicroCapsLabel(text: "EJEMPLO DE MEJORA · NO MEDIDO")
            if let one = attemptOne, let two = attemptTwo {
                Text("\(decimalComma(one.onsetLatency - two.onsetLatency)) s menos de duda.")
                    .font(MATheme.title())
                    .tracking(MATheme.tightTracking(fontSize: 28))
                    .foregroundStyle(MATheme.ai)
            }
            Text("Cuando el audio en vivo exista, MA comparará intentos reales: cuándo empiezas, cuánta ayuda ves y cuántos rescates pides.")
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 28)
    }

    private var repairedBeat: some View {
        VStack(alignment: .leading, spacing: 10) {
            MicroCapsLabel(text: "EL TRAZO REPARADO · EJEMPLO")
                .padding(.top, 16)
                .overlay(Rectangle().fill(MATheme.hairline).frame(height: 1), alignment: .top)
            HStack(spacing: 12) {
                Capsule().fill(MATheme.ai).frame(width: 40, height: 12)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(RestaurantForOneFixture.repairLine.japanese)
                            .font(MATheme.jp(17))
                            .foregroundStyle(MATheme.sumi)
                        Text(RestaurantForOneFixture.repairLine.romaji)
                            .font(MATheme.caption())
                            .foregroundStyle(MATheme.stone)
                    }
                    Text("\(RestaurantForOneFixture.repairLine.spanish) · repasado en la reparación")
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                }
            }
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 24)
    }

    private var bottomBlock: some View {
        VStack(spacing: 10) {
            HStack {
                MicroCapsLabel(text: "SIGUIENTE OBJETIVO")
                Spacer()
                Text(RestaurantForOneFixture.nextObjective)
                    .font(MATheme.caption(.medium))
                    .foregroundStyle(MATheme.sumi)
            }
            // Honest label: restarting returns to full scaffold — there is no
            // no-help route in this fixture yet.
            PrimaryButton(title: "Reiniciar la escena", identifier: "cta.reiniciar") {
                send(.restart)
            } icon: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.bottom, 8)
    }

    private func decimalComma(_ value: Double) -> String {
        String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
    }
}
