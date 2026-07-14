import SwiftUI

/// Three short, useful steps — capture, not marketing. Defaults are always
/// valid so Ignacio can finish with one tap ("Usar lo típico") or three.
struct OnboardingView: View {
    let onComplete: (LearnerProfile) -> Void
    @State private var progress = OnboardingProgress()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                ChromeBar(badge: "PROTOTIPO")
                stepIndicator
                stepContent
                    .padding(.top, 20)
                Spacer(minLength: 16)
                bottomActions
            }
        }
        // A new scroll identity resets every step to its own top. Without
        // this, Accessibility-size users arrive mid-page after scrolling to
        // the previous step's Continue button.
        .id(progress.step)
    }

    private var stepIndicator: some View {
        HStack(spacing: 10) {
            if !progress.isFirstStep {
                Button {
                    withStepAnimation { progress.goBack() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MATheme.stone)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Volver al paso anterior")
                .accessibilityIdentifier("onboarding.atras")
                .padding(.leading, -14)
            }
            MicroCapsLabel(text: progress.step.kicker, color: MATheme.ai)
            Spacer()
            HStack(spacing: 5) {
                ForEach(OnboardingProgress.Step.allCases, id: \.rawValue) { step in
                    Capsule()
                        .fill(step == progress.step ? MATheme.ai : MATheme.hairline)
                        .frame(width: step == progress.step ? 18 : 6, height: 6)
                }
            }
            .accessibilityHidden(true)
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 18)
        .frame(minHeight: 44)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch progress.step {
        case .start: StartStepView(profile: $progress.profile)
        case .goal: GoalStepView(profile: $progress.profile)
        case .practice: PracticeStepView(profile: $progress.profile)
        }
    }

    private var bottomActions: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: progress.continueTitle, identifier: "onboarding.continuar") {
                if progress.isLastStep {
                    onComplete(progress.profile)
                } else {
                    withStepAnimation { _ = progress.advance() }
                }
            } icon: {
                Image(systemName: progress.isLastStep ? "arrow.right" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            if progress.isFirstStep {
                Button {
                    onComplete(.standard)
                } label: {
                    Text("Usar lo típico y ver mis escenas")
                        .font(MATheme.caption(.medium))
                        .foregroundStyle(MATheme.stone)
                        .frame(minHeight: 44)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("onboarding.atajo")
            }
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.bottom, 8)
    }

    private func withStepAnimation(_ change: () -> Void) {
        if reduceMotion {
            change()
        } else {
            withAnimation(.easeInOut(duration: 0.22)) { change() }
        }
    }
}

// MARK: - Steps

private struct StartStepView: View {
    @Binding var profile: LearnerProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Empiezas desde cero. Perfecto.")
                        .font(MATheme.display())
                        .tracking(MATheme.tightTracking(fontSize: 34))
                        .foregroundStyle(MATheme.sumi)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("MA te guía en español y te presta el japonés justo cuando lo necesitas.")
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                        .fixedSize(horizontal: false, vertical: true)
                }
                InkGlyph()
                    .frame(width: 84, height: 64)
                    .padding(.top, 6)
            }

            VStack(alignment: .leading, spacing: 10) {
                MicroCapsLabel(text: "TU JAPONÉS HOY")
                FlowChips {
                    ForEach(JapaneseLevel.allCases, id: \.rawValue) { level in
                        ChoiceChip(
                            title: level.spanishLabel,
                            selected: profile.level == level,
                            identifier: "chip.nivel.\(level.rawValue)"
                        ) {
                            profile.level = level
                        }
                    }
                }
            }
            .padding(.top, 28)

            HStack(spacing: 8) {
                Circle().fill(MATheme.ai).frame(width: 5, height: 5)
                Text("Las explicaciones son siempre en español.")
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
            }
            .padding(.top, 18)
        }
        .padding(.horizontal, MATheme.sideMargin)
    }
}

private struct GoalStepView: View {
    @Binding var profile: LearnerProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("¿Para qué es tu japonés?")
                    .font(MATheme.display())
                    .tracking(MATheme.tightTracking(fontSize: 34))
                    .foregroundStyle(MATheme.sumi)
                    .fixedSize(horizontal: false, vertical: true)
                Text("MA enseña la conversación que vas a necesitar de verdad, una escena a la vez.")
                    .font(MATheme.body(16, weight: .regular))
                    .foregroundStyle(MATheme.stone)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(TripGoal.allCases, id: \.rawValue) { goal in
                    ChoiceChip(
                        title: goal.spanishLabel,
                        selected: profile.goal == goal,
                        identifier: "chip.meta.\(goal.rawValue)"
                    ) {
                        profile.goal = goal
                    }
                }
            }
            .padding(.top, 28)
        }
        .padding(.horizontal, MATheme.sideMargin)
    }
}

private struct PracticeStepView: View {
    @Binding var profile: LearnerProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tus primeras conversaciones.")
                    .font(MATheme.display())
                    .tracking(MATheme.tightTracking(fontSize: 34))
                    .foregroundStyle(MATheme.sumi)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Empiezas por el restaurante — es la única escena lista. Lo demás son intereses que ordenan lo que llega después.")
                    .font(MATheme.body(16, weight: .regular))
                    .foregroundStyle(MATheme.stone)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                MicroCapsLabel(text: "TU PRIMERA ESCENA · INCLUIDA")
                HStack(spacing: 7) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                    Text(SceneCatalog.hero.title)
                        .font(MATheme.body(15, weight: .medium))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(MATheme.ai)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(minHeight: 44)
                .background(MATheme.mist, in: Capsule())
                .overlay(Capsule().stroke(MATheme.ai, lineWidth: 1.5))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(SceneCatalog.hero.title): tu primera escena, siempre incluida.")
                .accessibilityIdentifier("onboarding.escena.incluida")
            }
            .padding(.top, 26)

            VStack(alignment: .leading, spacing: 10) {
                MicroCapsLabel(text: "INTERESES PARA DESPUÉS · PRONTO")
                FlowChips {
                    ForEach(SceneCatalog.upcomingScenes(orderedBy: [])) { scene in
                        ChoiceChip(
                            title: scene.chipLabel,
                            selected: profile.situations.contains(scene.id),
                            identifier: "chip.escena.\(scene.id.rawValue)"
                        ) {
                            profile.toggleSituation(scene.id)
                        }
                    }
                }
                Text("Estas escenas aún no están disponibles; tus intereses solo ordenan la lista.")
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 22)

            VStack(alignment: .leading, spacing: 10) {
                MicroCapsLabel(text: "TU RITMO")
                FlowChips {
                    ForEach(DailyPractice.allCases, id: \.rawValue) { pace in
                        ChoiceChip(
                            title: pace.spanishLabel,
                            selected: profile.dailyMinutes == pace,
                            identifier: "chip.ritmo.\(pace.rawValue)"
                        ) {
                            profile.dailyMinutes = pace
                        }
                    }
                }
            }
            .padding(.top, 22)

            Text("Puedes cambiar todo esto cuando quieras.")
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
                .padding(.top, 18)
        }
        .padding(.horizontal, MATheme.sideMargin)
    }
}

/// Simple wrapping layout for chips so Dynamic Type never truncates a choice.
private struct FlowChips<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        FlowLayout(spacing: 8) { content }
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        let arrangement = arrange(proposal: proposal, subviews: subviews)
        for (subview, position) in zip(subviews, arrangement.positions) {
            subview.place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: arrangement.childProposal
            )
        }
    }

    private func arrange(
        proposal: ProposedViewSize, subviews: Subviews
    ) -> (size: CGSize, positions: [CGPoint], childProposal: ProposedViewSize) {
        let maxWidth = proposal.width ?? .infinity
        // Bound every child to the available width so an Accessibility-size
        // chip wraps its own text instead of widening past the screen.
        let childProposal = ProposedViewSize(
            width: maxWidth.isFinite ? maxWidth : nil, height: nil
        )
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            var size = subview.sizeThatFits(childProposal)
            size.width = min(size.width, maxWidth)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalWidth = max(totalWidth, x - spacing)
        }
        return (CGSize(width: totalWidth, height: y + rowHeight), positions, childProposal)
    }
}

#Preview("Onboarding") {
    OnboardingView { _ in }
}
