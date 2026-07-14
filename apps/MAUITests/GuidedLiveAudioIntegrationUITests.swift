import XCTest

/// A deliberately separate integration check for the real simulator audio
/// graph. The deterministic product journey tests prove lesson ordering; this
/// test proves that the shipping dependencies cross the Apple permission and
/// AVAudioEngine boundaries without substituting fixture audio.
final class GuidedLiveAudioIntegrationUITests: XCTestCase {
    @MainActor
    func testOneTapModelPlaybackAndRealCaptureStopStayResponsive() {
        let app = XCUIApplication()
        app.launchEnvironment["MA_UI_TEST_ONBOARDING_COMPLETED"] = "true"
        app.launch()

        let language = app.buttons["chrome.language"]
        XCTAssertTrue(language.waitForExistence(timeout: 8))
        if language.label == "Cambiar a inglés" {
            language.tap()
            XCTAssertEqual(language.label, "Switch to Spanish")
        }

        let hero = app.buttons["hero.restaurant"]
        XCTAssertTrue(hero.waitForExistence(timeout: 8))
        hero.tap()
        XCTAssertTrue(
            app.staticTexts["Say you’re dining alone."].waitForExistence(timeout: 5)
        )
        app.buttons["guided.cta.show-phrase"].tap()

        let model = app.buttons["guided.audio.model"]
        XCTAssertTrue(model.waitForExistence(timeout: 5))
        model.tap()

        // This appears only after AVAudioPlayer reports completion. One tap
        // must therefore be sufficient to unlock the learner turn.
        let record = app.buttons["guided.cta.try-voice"]
        XCTAssertTrue(record.waitForExistence(timeout: 8))
        record.tap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let microphoneAlert = springboard.alerts.firstMatch
        if microphoneAlert.waitForExistence(timeout: 3) {
            let purpose = microphoneAlert.staticTexts.matching(
                NSPredicate(
                    format: "label CONTAINS %@ AND label CONTAINS %@",
                    "directly to OpenAI",
                    "does not save a recording"
                )
            ).firstMatch
            XCTAssertTrue(purpose.exists)
            let allow = microphoneAlert.buttons["Allow"]
            XCTAssertTrue(allow.exists)
            allow.tap()
        }

        let stop = app.buttons["guided.capture.stop"]
        XCTAssertTrue(stop.waitForExistence(timeout: 8))
        usleep(500_000)
        stop.tap()

        // A silent CI/simulator microphone may yield a recoverable no-speech
        // state; a host microphone may proceed to provider review. Either is a
        // valid result here. Remaining stuck on the stop control is not.
        let retryAfterError = app.buttons["guided.capture.retry-error"]
        let feedback = app.buttons["guided.feedback.continue"]
        let deadline = Date().addingTimeInterval(25)
        while Date() < deadline,
              !retryAfterError.exists,
              !feedback.exists {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        XCTAssertTrue(app.exists)
        XCTAssertFalse(stop.exists, "Stopping capture must leave the recording state")
        XCTAssertTrue(
            retryAfterError.exists || feedback.exists,
            "Structured review must resolve to feedback or a recoverable error"
        )
    }
}
