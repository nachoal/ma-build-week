import XCTest

/// Exercises the shipping route with deterministic simulator dependencies so
/// UI automation can verify the didactic order without faking a production
/// claim about microphone or provider evidence.
final class KaiwaProductSmokeUITests: XCTestCase {
    @MainActor
    func testFreshInstallDefaultsToEnglishAndLanguageChoicePersists() {
        let app = XCUIApplication()
        app.launchEnvironment["MA_UI_TEST_ONBOARDING_COMPLETED"] = "true"
        app.launchEnvironment["MA_UI_TEST_GUIDED_FIXTURE"] = "true"
        app.launchEnvironment["MA_UI_TEST_RESET_INTERFACE_LANGUAGE"] = "true"
        app.launch()

        let language = app.buttons["chrome.language"]
        XCTAssertTrue(language.waitForExistence(timeout: 8))
        XCTAssertEqual(language.label, "Switch to Spanish")
        XCTAssertTrue(app.staticTexts["YOUR NEXT CONVERSATION"].exists)
        XCTAssertFalse(app.staticTexts["TU PRÓXIMA CONVERSACIÓN"].exists)

        language.tap()
        XCTAssertEqual(language.label, "Cambiar a inglés")
        XCTAssertTrue(app.staticTexts["TU PRÓXIMA CONVERSACIÓN"].waitForExistence(timeout: 5))

        app.terminate()
        app.launchEnvironment.removeValue(forKey: "MA_UI_TEST_RESET_INTERFACE_LANGUAGE")
        app.launch()

        let persistedLanguage = app.buttons["chrome.language"]
        XCTAssertTrue(persistedLanguage.waitForExistence(timeout: 8))
        XCTAssertEqual(persistedLanguage.label, "Cambiar a inglés")
        XCTAssertTrue(app.staticTexts["TU PRÓXIMA CONVERSACIÓN"].exists)
        persistedLanguage.tap()
        XCTAssertEqual(persistedLanguage.label, "Switch to Spanish")
    }

    @MainActor
    func testGuidedHeroReviewsBothLearnerTurnsBeforeCompletion() {
        let app = launchGuidedFixture()
        ensureEnglish(app)

        let hero = app.buttons["hero.restaurant"]
        XCTAssertTrue(hero.waitForExistence(timeout: 10))
        hero.tap()

        XCTAssertTrue(app.staticTexts["Say you’re dining alone."].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["guided.capture.start"].exists)
        app.buttons["guided.cta.show-phrase"].tap()

        XCTAssertTrue(app.staticTexts["One person · I’m dining alone."].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["guided.capture.start"].exists)
        let model = app.buttons["guided.audio.model"]
        XCTAssertTrue(model.waitForExistence(timeout: 5))
        model.tap()

        let tryVoice = app.buttons["guided.cta.try-voice"]
        XCTAssertTrue(tryVoice.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["guided.capture.stop"].exists)
        tryVoice.tap()

        let stopFirst = app.buttons["guided.capture.stop"]
        XCTAssertTrue(stopFirst.waitForExistence(timeout: 5))
        stopFirst.tap()
        XCTAssertTrue(
            app.staticTexts["MA APPROXIMATELY UNDERSTOOD"]
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(app.staticTexts["一人です"].exists)
        XCTAssertTrue(app.staticTexts["WHAT WORKED"].exists)
        XCTAssertTrue(app.staticTexts["FOR YOUR NEXT TRY"].exists)

        let continueToScene = app.buttons["guided.feedback.continue"]
        XCTAssertTrue(continueToScene.exists)
        continueToScene.tap()

        XCTAssertTrue(app.staticTexts["NOW AT THE RESTAURANT"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["How many people?"].exists)
        XCTAssertTrue(app.staticTexts["hitori desu"].exists)
        XCTAssertFalse(app.buttons["guided.waiter.respond"].exists)
        app.buttons["guided.waiter.play"].tap()

        let respond = app.buttons["guided.waiter.respond"]
        XCTAssertTrue(respond.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["The server finished. Now you answer."].exists)
        XCTAssertTrue(app.staticTexts["How many people?"].exists)
        respond.tap()

        let stopSecond = app.buttons["guided.capture.stop"]
        XCTAssertTrue(stopSecond.waitForExistence(timeout: 5))
        stopSecond.tap()
        let finish = app.buttons["guided.feedback.continue"]
        XCTAssertTrue(finish.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["MA APPROXIMATELY UNDERSTOOD"].exists)
        finish.tap()

        XCTAssertTrue(app.staticTexts["SCENE COMPLETE"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["MA reviewed 2 attempts. No score or self-rating."].exists)
        XCTAssertTrue(app.staticTexts["NEXT PRACTICE"].exists)
        XCTAssertTrue(app.staticTexts["LOCAL PLAN"].exists)
        let plan = app.buttons["guided.plan.request"]
        if !plan.isHittable { app.swipeUp() }
        XCTAssertTrue(plan.waitForExistence(timeout: 5))
        plan.tap()
        XCTAssertTrue(app.staticTexts["GPT-5.6"].waitForExistence(timeout: 8))

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "guided-realtime-complete"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testFeedbackRetryStaysOnTheSameVisiblePhrase() {
        let app = launchGuidedFixture()
        ensureEnglish(app)
        XCTAssertTrue(app.buttons["hero.restaurant"].waitForExistence(timeout: 10))
        app.buttons["hero.restaurant"].tap()
        app.buttons["guided.cta.show-phrase"].tap()
        app.buttons["guided.audio.model"].tap()
        XCTAssertTrue(app.buttons["guided.cta.try-voice"].waitForExistence(timeout: 5))
        app.buttons["guided.cta.try-voice"].tap()
        XCTAssertTrue(app.buttons["guided.capture.stop"].waitForExistence(timeout: 5))
        app.buttons["guided.capture.stop"].tap()

        let retry = app.buttons["guided.feedback.retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Say hi-to-ri de-su once, at an even pace."].exists)

        let language = app.buttons["chrome.language"]
        XCTAssertEqual(language.label, "Switch to Spanish")
        language.tap()
        XCTAssertTrue(app.staticTexts["PARA EL SIGUIENTE INTENTO"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Di hi-to-ri de-su una vez, a un ritmo parejo."].exists)
        XCTAssertEqual(language.label, "Cambiar a inglés")
        retry.tap()

        let recordAgain = app.buttons["guided.capture.start"]
        XCTAssertTrue(recordAgain.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["一人です"].exists)
        XCTAssertTrue(app.staticTexts["hitori desu"].exists)
        XCTAssertFalse(app.buttons["guided.waiter.play"].exists)
    }

    @MainActor
    private func launchGuidedFixture() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["MA_UI_TEST_ONBOARDING_COMPLETED"] = "true"
        app.launchEnvironment["MA_UI_TEST_GUIDED_FIXTURE"] = "true"
        app.launch()
        return app
    }

    @MainActor
    private func ensureEnglish(_ app: XCUIApplication) {
        let language = app.buttons["chrome.language"]
        XCTAssertTrue(language.waitForExistence(timeout: 5))
        if language.label == "Cambiar a inglés" {
            language.tap()
            XCTAssertEqual(language.label, "Switch to Spanish")
        }
    }
}
