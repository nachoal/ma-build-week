import XCTest

final class KaiwaReplaySmokeUITests: XCTestCase {
    @MainActor
    func testLabeledReplayReachesProofWithoutLiveClaims() {
        let app = XCUIApplication()
        app.launchEnvironment["MA_DEMO_MODE"] = "labeled-replay-no-live"
        app.launch()

        XCTAssertTrue(app.staticTexts["kaiwa.replay.disclosure"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["La muestra reparó y regresó."].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["kaiwa.replay.proof.title"].exists)
        XCTAssertTrue(app.staticTexts["El replay no capturó ni descartó audio."].firstMatch.exists)
        XCTAssertFalse(app.staticTexts["Señal de voz local detectada"].exists)
        XCTAssertFalse(app.staticTexts["Audio crudo descartado"].exists)
        XCTAssertFalse(app.buttons["kaiwa.plan.request"].exists)
        let badge = app.descendants(matching: .any)["chrome.badge"]
        XCTAssertTrue(badge.exists)
        XCTAssertTrue(badge.label.contains("REPLAY · NO EN VIVO"))
    }
}
