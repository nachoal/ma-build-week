import SwiftUI

/// Paper 01 Learn — phrase setup with full scaffold. The two conversation
/// keys are deliberately NOT here: they are taught only after the learner's
/// first success (todo.md §3 — don't introduce the superpower before the
/// learner has something to say).
struct SetupView: View {
    let send: (PracticeIntent) -> Void

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                goalHeader
                phraseBlock
                rhythmRow
                Spacer(minLength: 12)
                VStack(spacing: 10) {
                    PrimaryButton(title: "Practicar mi frase", identifier: "cta.practicar") {
                        send(.beginCoachedPractice)
                    } icon: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text("Tres rondas guiadas, con menos ayuda cada vez.")
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.bottom, 8)
            }
        }
    }

    private var goalHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(RestaurantForOneFixture.sceneKicker)
                .font(MATheme.caption(.semibold))
                .tracking(MATheme.capsTracking(fontSize: 13))
                .foregroundStyle(MATheme.ai)
            Text(RestaurantForOneFixture.goal)
                .font(MATheme.display())
                .tracking(MATheme.tightTracking(fontSize: 36))
                .foregroundStyle(MATheme.sumi)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(RestaurantForOneFixture.goalSubtitle)
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 22)
    }

    /// The ink rail is an overlay on the text column, so its height always
    /// matches the phrase content — including under Dynamic Type — instead of
    /// absorbing the screen's flexible whitespace.
    private var phraseBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
                Text(RestaurantForOneFixture.phraseJapanese)
                    .font(MATheme.jp(40))
                    .foregroundStyle(MATheme.sumi)
                // No play affordance: this build has no audio, so there is no
                // control pretending otherwise.
                HStack(spacing: 10) {
                    Text(RestaurantForOneFixture.phraseRomaji)
                        .font(MATheme.heading(weight: .regular))
                        .foregroundStyle(MATheme.stone)
                    MicroCapsLabel(text: "SIN AUDIO AÚN")
                }
                Text(RestaurantForOneFixture.phraseSpanish)
                    .font(MATheme.body())
                    .foregroundStyle(MATheme.sumi)
        }
        .padding(.leading, 24)
        .overlay(alignment: .leading) {
            Capsule()
                .fill(MATheme.ai)
                .frame(width: 4)
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 24)
    }

    private var rhythmRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            MicroCapsLabel(text: "RITMO · 5 GOLPES")
            HStack(spacing: 8) {
                ForEach(RestaurantForOneFixture.rhythmBeats, id: \.self) { syllable in
                    Text(syllable)
                        .font(MATheme.caption(.semibold))
                        .foregroundStyle(MATheme.ai)
                        .frame(width: 48)
                        .padding(.vertical, 8)
                        .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            Text(RestaurantForOneFixture.scaffoldNote)
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
        }
        .padding(.leading, 48)
        .padding(.trailing, MATheme.sideMargin)
        .padding(.top, 20)
    }

}
