import SwiftUI

/// Three short, useful steps — capture, not marketing. Defaults are always
/// valid so Ignacio can finish with one tap ("Usar lo típico") or three.
struct OnboardingView: View {
    let onComplete: (LearnerProfile) -> Void
    var onToggleLanguage: (() -> Void)? = nil
    @State private var progress = OnboardingProgress()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                ChromeBar(
                    badge: language.text(english: "PROTOTYPE", spanish: "PROTOTIPO"),
                    onToggleLanguage: onToggleLanguage
                )
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
                .accessibilityLabel(language.text(
                    english: "Back to the previous step",
                    spanish: "Volver al paso anterior"
                ))
                .accessibilityIdentifier("onboarding.atras")
                .padding(.leading, -14)
            }
            MicroCapsLabel(text: progress.step.kicker(in: language), color: MATheme.ai)
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
            PrimaryButton(
                title: progress.continueTitle(in: language),
                identifier: "onboarding.continuar"
            ) {
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
                    Text(language.text(
                        english: "Use the typical setup and see my scenes",
                        spanish: "Usar lo típico y ver mis escenas"
                    ))
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
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text(
                        english: "Starting from zero? Perfect.",
                        spanish: "Empiezas desde cero. Perfecto."
                    ))
                        .font(MATheme.display())
                        .tracking(MATheme.tightTracking(fontSize: 34))
                        .foregroundStyle(MATheme.sumi)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(language.text(
                        english: "MA guides you in English and gives you Japanese only when you need it.",
                        spanish: "MA te guía en español y te presta el japonés justo cuando lo necesitas."
                    ))
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                        .fixedSize(horizontal: false, vertical: true)
                }
                InkGlyph()
                    .frame(width: 84, height: 64)
                    .padding(.top, 6)
            }

            VStack(alignment: .leading, spacing: 10) {
                MicroCapsLabel(text: language.text(
                    english: "YOUR JAPANESE TODAY",
                    spanish: "TU JAPONÉS HOY"
                ))
                FlowChips {
                    ForEach(JapaneseLevel.allCases, id: \.rawValue) { level in
                        ChoiceChip(
                            title: level.label(in: language),
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
                Text(language.text(
                    english: "Explanations stay in English.",
                    spanish: "Las explicaciones son siempre en español."
                ))
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
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(language.text(
                    english: "What do you need Japanese for?",
                    spanish: "¿Para qué es tu japonés?"
                ))
                    .font(MATheme.display())
                    .tracking(MATheme.tightTracking(fontSize: 34))
                    .foregroundStyle(MATheme.sumi)
                    .fixedSize(horizontal: false, vertical: true)
                Text(language.text(
                    english: "MA teaches the conversations you will actually need, one scene at a time.",
                    spanish: "MA enseña la conversación que vas a necesitar de verdad, una escena a la vez."
                ))
                    .font(MATheme.body(16, weight: .regular))
                    .foregroundStyle(MATheme.stone)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(TripGoal.allCases, id: \.rawValue) { goal in
                    ChoiceChip(
                        title: goal.label(in: language),
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
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(language.text(
                    english: "Your first conversations.",
                    spanish: "Tus primeras conversaciones."
                ))
                    .font(MATheme.display())
                    .tracking(MATheme.tightTracking(fontSize: 34))
                    .foregroundStyle(MATheme.sumi)
                    .fixedSize(horizontal: false, vertical: true)
                Text(language.text(
                    english: "You start at the restaurant—the only scene ready now. Your other interests set what comes next.",
                    spanish: "Empiezas por el restaurante — es la única escena lista. Lo demás son intereses que ordenan lo que llega después."
                ))
                    .font(MATheme.body(16, weight: .regular))
                    .foregroundStyle(MATheme.stone)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                MicroCapsLabel(text: language.text(
                    english: "YOUR FIRST SCENE · INCLUDED",
                    spanish: "TU PRIMERA ESCENA · INCLUIDA"
                ))
                HStack(spacing: 7) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                    Text(SceneCatalog.hero.title(in: language))
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
                .accessibilityLabel(language.text(
                    english: "\(SceneCatalog.hero.title(in: language)): your first scene, always included.",
                    spanish: "\(SceneCatalog.hero.title(in: language)): tu primera escena, siempre incluida."
                ))
                .accessibilityIdentifier("onboarding.escena.incluida")
            }
            .padding(.top, 26)

            VStack(alignment: .leading, spacing: 10) {
                MicroCapsLabel(text: language.text(
                    english: "INTERESTS FOR LATER · COMING SOON",
                    spanish: "INTERESES PARA DESPUÉS · PRONTO"
                ))
                FlowChips {
                    ForEach(SceneCatalog.upcomingScenes(orderedBy: [])) { scene in
                        ChoiceChip(
                            title: scene.chipLabel(in: language),
                            selected: profile.situations.contains(scene.id),
                            identifier: "chip.escena.\(scene.id.rawValue)"
                        ) {
                            profile.toggleSituation(scene.id)
                        }
                    }
                }
                Text(language.text(
                    english: "These scenes are not available yet; your interests only reorder the list.",
                    spanish: "Estas escenas aún no están disponibles; tus intereses solo ordenan la lista."
                ))
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 22)

            VStack(alignment: .leading, spacing: 10) {
                MicroCapsLabel(text: language.text(
                    english: "YOUR PACE",
                    spanish: "TU RITMO"
                ))
                FlowChips {
                    ForEach(DailyPractice.allCases, id: \.rawValue) { pace in
                        ChoiceChip(
                            title: pace.label(in: language),
                            selected: profile.dailyMinutes == pace,
                            identifier: "chip.ritmo.\(pace.rawValue)"
                        ) {
                            profile.dailyMinutes = pace
                        }
                    }
                }
            }
            .padding(.top, 22)

            Text(language.text(
                english: "You can change all of this anytime.",
                spanish: "Puedes cambiar todo esto cuando quieras."
            ))
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
