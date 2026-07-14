import SwiftUI

/// Paper 04 Sumimasen — yield handoff and a provenance-tagged repair window.
struct RepairView: View {
    let state: PracticeState
    let send: (PracticeIntent) -> Void

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                stateHeader
                yieldStrip
                beatSection
                Spacer(minLength: 10)
                VStack(spacing: 10) {
                    PrimaryButton(title: "Seguir donde estaba", identifier: "cta.seguir") {
                        send(.resume)
                    } icon: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text("La simulación visual retomará la frase en el mismo punto.")
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.bottom, 8)
            }
        }
        .sensoryFeedback(.selection, trigger: state.repairTraceHighlightCount)
    }

    private var stateHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SIMULACIÓN VISUAL · PAUSA MARCADA")
                .font(MATheme.caption(.semibold))
                .tracking(MATheme.capsTracking(fontSize: 13))
                .foregroundStyle(MATheme.ai)
            Text("La tinta se recoge. El foco ahora es tuyo.")
                .font(MATheme.heading())
                .tracking(MATheme.tightTracking(fontSize: 20))
                .foregroundStyle(MATheme.sumi)
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 24)
    }

    private var yieldStrip: some View {
        VStack(spacing: 2) {
            YieldStripView()
                .frame(height: 150)
            HStack {
                MicroCapsLabel(text: "TÚ · TIENES EL TURNO", color: MATheme.ai)
                Spacer()
                MicroCapsLabel(text: "SECUENCIA · EN PAUSA")
            }
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("En la simulación visual, la secuencia está en pausa. El foco es tuyo.")
    }

    private var beatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MicroCapsLabel(text: "ÚLTIMOS 4 SEGUNDOS · DE LA SIMULACIÓN")
                .padding(.top, 16)
                .overlay(Rectangle().fill(MATheme.hairline).frame(height: 1), alignment: .top)

            fragmentsRow
            HStack {
                Text("−4 s")
                    .font(MATheme.micro())
                    .foregroundStyle(MATheme.stone)
                Spacer()
                Text("momento de tu «sumimasen»")
                    .font(MATheme.micro())
                    .foregroundStyle(MATheme.stone)
            }
            connector
            lessonCard
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 24)
    }

    private var fragmentsRow: some View {
        HStack(spacing: 8) {
            ForEach(Array(state.repairWindow.enumerated()), id: \.element.id) { index, fragment in
                let chosen = index == state.selectedFragmentIndex
                Capsule()
                    .fill(MATheme.ai.opacity(chosen ? 1.0 : 0.35 + 0.15 * Double(index % 2)))
                    .frame(width: fragmentWidth(fragment), height: chosen ? 22 : 14 + 2 * fragment.amplitude)
                    .overlay(chosen ? Capsule().stroke(MATheme.mist, lineWidth: 3) : nil)
                    .scaleEffect(
                        chosen && state.repairTraceHighlightCount.isMultiple(of: 2) == false ? 1.06 : 1,
                        anchor: .center
                    )
            }
        }
        .animation(
            .spring(response: 0.3, dampingFraction: 0.62),
            value: state.repairTraceHighlightCount
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Los últimos cuatro segundos de la simulación, como \(state.repairWindow.count) trazos. Uno está elegido para la micro-lección."
        )
    }

    /// Derived from the chosen fragment's real layout position — never a
    /// hardcoded offset.
    private var connector: some View {
        let widths = state.repairWindow.map(fragmentWidth)
        let index = state.selectedFragmentIndex ?? 0
        let leading = widths.prefix(index).reduce(0, +)
            + CGFloat(index) * 8
            + (widths.indices.contains(index) ? widths[index] / 2 : 0)
        return Rectangle()
            .fill(MATheme.ai)
            .frame(width: 2, height: 16)
            .padding(.leading, max(0, leading - 1))
            .accessibilityHidden(true)
    }

    private func fragmentWidth(_ fragment: RepairFragment) -> CGFloat {
        (20 + 68 * fragment.amplitude) * fragment.duration
    }

    private var lessonCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            MicroCapsLabel(text: "MICRO-LECCIÓN · ESE TRAZO", color: MATheme.ai)
            Text(RestaurantForOneFixture.repairLine.japanese)
                .font(MATheme.jp(26))
                .foregroundStyle(MATheme.sumi)
            VStack(alignment: .leading, spacing: 2) {
                Text(RestaurantForOneFixture.repairLine.romaji)
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
                Text(RestaurantForOneFixture.repairLine.spanish)
                    .font(MATheme.body())
                    .foregroundStyle(MATheme.sumi)
            }
            Text(RestaurantForOneFixture.repairCue)
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
            // One control, one honest effect: a visible pulse plus the
            // REPLAY VISUAL chip. No second button pretending to change speed.
            BeatActionButton(title: "Repasar el trazo (visual)", solid: true, identifier: "boton.trazo.repasar") {
                send(.highlightRepairTrace)
            }
            .accessibilityLabel("Repasar el trazo visualmente. Esta maqueta no tiene audio.")
            .padding(.top, 6)
            if state.repairTraceHighlightCount > 0 {
                HStack(spacing: 6) {
                    Circle().fill(MATheme.ai).frame(width: 5, height: 5)
                    MicroCapsLabel(text: "TRAZO RESALTADO · SIN AUDIO", color: MATheme.ai)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .accessibilityLabel("Trazo visual resaltado. Esta maqueta no tiene audio.")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 20))
    }
}
