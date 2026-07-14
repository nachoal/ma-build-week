import XCTest

final class KaiwaReplaySmokeUITests: XCTestCase {
    @MainActor
    func testLabeledReplayReachesProofWithoutLiveClaims() {
        let app = XCUIApplication()
        app.launchEnvironment["MA_DEMO_MODE"] = "labeled-replay-no-live"
        app.launchEnvironment["MA_UI_TEST_RESET_INTERFACE_LANGUAGE"] = "true"
        app.launch()

        let disclosure = app.staticTexts["kaiwa.replay.disclosure"]
        XCTAssertTrue(disclosure.waitForExistence(timeout: 3))
        XCTAssertEqual(
            disclosure.label,
            "Controlled visual replay · no microphone, network, or live audio."
        )
        XCTAssertTrue(
            app.staticTexts["The sample repaired and returned."]
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(app.staticTexts["kaiwa.replay.proof.title"].exists)
        XCTAssertTrue(
            app.staticTexts["The replay did not capture or discard audio."].firstMatch.exists
        )
        XCTAssertFalse(app.staticTexts["Señal de voz local detectada"].exists)
        XCTAssertFalse(app.staticTexts["Audio crudo descartado"].exists)
        XCTAssertFalse(app.buttons["kaiwa.plan.request"].exists)
        let badge = app.descendants(matching: .any)["chrome.badge"]
        XCTAssertTrue(badge.exists)
        XCTAssertTrue(badge.label.contains("REPLAY · NOT LIVE / NO EN VIVO"))

        let language = app.buttons["chrome.language"]
        XCTAssertEqual(language.label, "Switch to Spanish")
        language.tap()
        XCTAssertTrue(app.staticTexts["La muestra reparó y regresó."].waitForExistence(timeout: 5))
        XCTAssertEqual(
            app.staticTexts["kaiwa.replay.disclosure"].label,
            "Replay visual controlado · sin micrófono, red ni audio en vivo."
        )
        XCTAssertEqual(language.label, "Cambiar a inglés")
        language.tap()
    }
}
