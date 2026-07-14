import XCTest

/// Runs the complete learner-visible route against the production private
/// broker, gpt-realtime-2.1 WebSocket, structured review validator, actual
/// provider audio playback, and optional gpt-5.6-sol planner. Only microphone
/// input is deterministic: the simulator injects the bundled Japanese model
/// after the same explicit Record/Finish taps.
final class GuidedProductionRealtimeUITests: XCTestCase {
    private let networkTimeout: TimeInterval = 35

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCompleteProductionRealtimeLessonInEnglish() throws {
        try runCompleteProductionRealtimeLesson(inSpanish: false)
    }

    @MainActor
    func testCompleteProductionRealtimeLessonInSpanish() throws {
        try runCompleteProductionRealtimeLesson(inSpanish: true)
    }

    @MainActor
    private func runCompleteProductionRealtimeLesson(inSpanish: Bool) throws {
        let app = XCUIApplication()
        app.launchEnvironment["MA_UI_TEST_ONBOARDING_COMPLETED"] = "true"
        app.launchEnvironment["MA_UI_TEST_GUIDED_LIVE"] = "true"
        app.launchEnvironment["MA_UI_TEST_RESET_INTERFACE_LANGUAGE"] = "true"
        app.launch()

        let language = app.buttons["chrome.language"]
        XCTAssertTrue(language.waitForExistence(timeout: 8))
        XCTAssertEqual(language.label, "Switch to Spanish")
        if inSpanish {
            switchToSpanish(language, in: app)
        }

        XCTAssertTrue(app.buttons["hero.restaurant"].waitForExistence(timeout: 8))
        app.buttons["hero.restaurant"].tap()
        let orientation = inSpanish ? "Di que vienes solo." : "Say you’re dining alone."
        XCTAssertTrue(app.staticTexts[orientation].waitForExistence(timeout: 5))
        app.buttons["guided.cta.show-phrase"].tap()

        // Real AVAudioPlayer completion must unlock Record after one tap.
        let model = app.buttons["guided.audio.model"]
        XCTAssertTrue(model.waitForExistence(timeout: 5))
        model.tap()
        let firstRecord = app.buttons["guided.cta.try-voice"]
        XCTAssertTrue(firstRecord.waitForExistence(timeout: 8))
        firstRecord.tap()
        XCTAssertTrue(app.buttons["guided.capture.stop"].waitForExistence(timeout: 5))
        app.buttons["guided.capture.stop"].tap()

        let firstAdvance = try requireCompletedReview(
            app,
            stage: "first practice turn",
            inSpanish: inSpanish
        )
        try requireCompletedSpokenFeedback(app, stage: "first practice turn")
        firstAdvance.tap()

        let restaurantHeader = inSpanish
            ? "AHORA EN EL RESTAURANTE" : "NOW AT THE RESTAURANT"
        let waiterMeaning = inSpanish ? "¿Cuántas personas?" : "How many people?"
        XCTAssertTrue(app.staticTexts[restaurantHeader].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts[waiterMeaning].exists)
        XCTAssertTrue(app.staticTexts["hitori desu"].exists)
        app.buttons["guided.waiter.play"].tap()

        // This appears only after a real Realtime response has delivered valid
        // PCM16 and the shipping audio owner has finished playing it.
        let respond = app.buttons["guided.waiter.respond"]
        XCTAssertTrue(respond.waitForExistence(timeout: networkTimeout))
        let responseReady = inSpanish
            ? "El mesero terminó. Ahora respondes."
            : "The server finished. Now you answer."
        XCTAssertTrue(app.staticTexts[responseReady].exists)
        respond.tap()
        XCTAssertTrue(app.buttons["guided.capture.stop"].waitForExistence(timeout: 5))
        app.buttons["guided.capture.stop"].tap()

        let secondAdvance = try requireCompletedReview(
            app,
            stage: "restaurant answer",
            inSpanish: inSpanish
        )
        try requireCompletedSpokenFeedback(app, stage: "restaurant answer")
        secondAdvance.tap()

        let completeHeader = inSpanish ? "ESCENA COMPLETA" : "SCENE COMPLETE"
        let reviewCount = inSpanish
            ? "MA revisó 2 intentos. Sin puntuación ni autocalificación."
            : "MA reviewed 2 attempts. No score or self-rating."
        XCTAssertTrue(app.staticTexts[completeHeader].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts[reviewCount].exists)

        let planner = app.buttons["guided.plan.request"]
        if !planner.isHittable { app.swipeUp() }
        XCTAssertTrue(planner.waitForExistence(timeout: 5))
        planner.tap()
        let plannerTerminal = app.staticTexts.matching(NSPredicate(
            format: "identifier IN %@ OR label == %@",
            ["guided.plan.unavailable"],
            "GPT-5.6"
        )).firstMatch
        XCTAssertTrue(
            plannerTerminal.waitForExistence(timeout: networkTimeout),
            "The optional live planner did not resolve within its bounded timeout"
        )
        XCTAssertFalse(
            app.staticTexts["guided.plan.unavailable"].exists,
            "The optional live planner fell back to the safe local plan"
        )

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = inSpanish
            ? "production-realtime-complete-es"
            : "production-realtime-complete-en"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Remove a banner that already exists, prove it is gone, then dispatch
    /// exactly one tap. A later OS interruption is evidence for a separate
    /// rerun, never permission to hide a possible product failure with a retry.
    @MainActor
    private func switchToSpanish(_ language: XCUIElement, in app: XCUIApplication) {
        _ = dismissNotificationBannerIfPresent(timeout: 0.2)
        app.activate()
        XCTAssertTrue(language.isHittable, "The language control is not tappable")

        language.tap()
        XCTAssertTrue(
            waitForLabel("Cambiar a inglés", on: language, timeout: 5),
            "The one dispatched language tap did not switch. Inspect OS interruption evidence and rerun separately; the test will not tap twice."
        )
    }

    @MainActor
    private func dismissNotificationBannerIfPresent(timeout: TimeInterval) -> Bool {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let banner = springboard.descendants(matching: .any)
            .matching(identifier: "NotificationShortLookView")
            .firstMatch
        guard banner.waitForExistence(timeout: timeout) else { return false }
        banner.swipeUp()
        let disappeared = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: banner
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [disappeared], timeout: 2),
            .completed,
            "A pre-existing system notification did not leave before the product tap"
        )
        return true
    }

    @MainActor
    private func waitForLabel(
        _ expected: String,
        on element: XCUIElement,
        timeout: TimeInterval
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", expected),
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func requireCompletedReview(
        _ app: XCUIApplication,
        stage: String,
        inSpanish: Bool
    ) throws -> XCUIElement {
        let terminal = app.buttons.matching(NSPredicate(
            format: "identifier IN %@",
            [
                "guided.feedback.continue",
                "guided.feedback.continue-supported",
                "guided.capture.retry-error",
            ]
        )).firstMatch
        XCTAssertTrue(
            terminal.waitForExistence(timeout: networkTimeout),
            "\(stage) did not resolve within the bounded Realtime timeout"
        )

        let error = app.staticTexts["guided.review.error"]
        if error.exists {
            let code = (error.value as? String) ?? "unknown"
            XCTFail("\(stage) failed [\(code)]: \(error.label)")
        }
        let understood = inSpanish
            ? "MA ENTENDIÓ APROXIMADAMENTE"
            : "MA APPROXIMATELY UNDERSTOOD"
        let worked = inSpanish ? "LO QUE FUNCIONÓ" : "WHAT WORKED"
        XCTAssertTrue(app.staticTexts[understood].exists)
        XCTAssertTrue(app.staticTexts[worked].exists)

        let primary = app.buttons["guided.feedback.continue"]
        if primary.exists { return primary }
        let supported = app.buttons["guided.feedback.continue-supported"]
        XCTAssertTrue(supported.exists, "\(stage) produced no safe progression control")
        return supported
    }

    @MainActor
    private func requireCompletedSpokenFeedback(
        _ app: XCUIApplication,
        stage: String
    ) throws {
        let terminal = app.staticTexts.matching(NSPredicate(
            format: "identifier IN %@",
            [
                "guided.feedback.audio-completed",
                "guided.feedback.audio-unavailable",
            ]
        )).firstMatch
        XCTAssertTrue(
            terminal.waitForExistence(timeout: networkTimeout),
            "\(stage) spoken feedback did not resolve within the bounded timeout"
        )
        XCTAssertFalse(
            app.staticTexts["guided.feedback.audio-unavailable"].exists,
            "\(stage) text review completed but its spoken explanation failed"
        )
        XCTAssertTrue(app.staticTexts["guided.feedback.audio-completed"].exists)
    }
}
