import Testing
@testable import MA

@Suite("Onboarding state and routing")
struct OnboardingStateTests {
    @Test("The standard profile is complete and starts at the restaurant")
    func standardProfile() {
        let profile = LearnerProfile.standard
        #expect(profile.level == .zero)
        #expect(profile.goal == .firstTrip)
        #expect(profile.situations == [.restaurant])
        #expect(profile.dailyMinutes == .regular)
    }

    @Test("Defaults let the learner continue with one tap on every step")
    func defaultsAlwaysContinuable() {
        var progress = OnboardingProgress()
        for _ in OnboardingProgress.Step.allCases {
            #expect(progress.canContinue)
            _ = progress.advance()
        }
    }

    @Test("Steps advance in order and finish exactly on the last step")
    func stepOrder() {
        var progress = OnboardingProgress()
        #expect(progress.step == .start)
        #expect(progress.advance() == false)
        #expect(progress.step == .goal)
        #expect(progress.advance() == false)
        #expect(progress.step == .practice)
        #expect(progress.isLastStep)
        #expect(progress.advance() == true)
        #expect(progress.step == .practice)
    }

    @Test("Back navigation stops at the first step")
    func backStopsAtStart() {
        var progress = OnboardingProgress()
        _ = progress.advance()
        progress.goBack()
        #expect(progress.step == .start)
        progress.goBack()
        #expect(progress.step == .start)
    }

    @Test("The restaurant scene is mandatory and non-toggleable")
    func restaurantIsMandatory() {
        var profile = LearnerProfile.standard
        profile.toggleSituation(.restaurant)
        #expect(profile.situations == [.restaurant])

        // Optional interests toggle freely and never touch the restaurant.
        profile.toggleSituation(.izakaya)
        #expect(profile.situations == [.restaurant, .izakaya])
        #expect(profile.interests == [.izakaya])
        profile.toggleSituation(.izakaya)
        #expect(profile.situations == [.restaurant])
        #expect(profile.interests.isEmpty)
    }

    @Test("Persistence cannot drop the mandatory first scene")
    func restaurantSurvivesRawDecoding() {
        let decoded = LearnerProfile.fromRaw(
            level: "zero", goal: "firstTrip", situations: "train,hotel", dailyMinutes: 10
        )
        #expect(decoded.situations.contains(.restaurant))
        #expect(decoded.interests == [.train, .hotel])
    }

    @Test("Raw persistence round-trips every field")
    func rawRoundTrip() {
        var profile = LearnerProfile.standard
        profile.level = .fewWords
        profile.goal = .bookedTrip
        profile.toggleSituation(.train)
        profile.toggleSituation(.hotel)
        profile.dailyMinutes = .long

        let decoded = LearnerProfile.fromRaw(
            level: profile.rawLevel,
            goal: profile.rawGoal,
            situations: profile.rawSituations,
            dailyMinutes: profile.rawDailyMinutes
        )
        #expect(decoded == profile)
    }

    @Test("Corrupt raw values fall back to the standard profile")
    func corruptRawFallsBack() {
        let decoded = LearnerProfile.fromRaw(
            level: "banana", goal: "", situations: "x,y,", dailyMinutes: 999
        )
        #expect(decoded == .standard)
    }

    @Test("Routing depends only on onboarding completion")
    func routing() {
        #expect(AppRoute.initial(hasCompletedOnboarding: false) == .onboarding)
        #expect(AppRoute.initial(hasCompletedOnboarding: true) == .home)
    }
}
