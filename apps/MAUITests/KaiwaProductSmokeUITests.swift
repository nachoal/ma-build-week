import XCTest

/// Confirms the shipping route enters the implemented local-audio product,
/// not the fixture-only PracticeFeature screens.
final class KaiwaProductSmokeUITests: XCTestCase {
    @MainActor
    func testHeroOpensHonestLocalKaiwaLoop() {
        let app = XCUIApplication()
        app.launchEnvironment["MA_UI_TEST_ONBOARDING_COMPLETED"] = "true"
        app.launch()

        let hero = app.buttons["hero.restaurant"]
        XCTAssertTrue(hero.waitForExistence(timeout: 10))
        hero.tap()

        let modelAudio = app.buttons["kaiwa.audio.modelo"]
        XCTAssertTrue(modelAudio.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["kaiwa.cta.practicar"].exists)

        let badge = app.descendants(matching: .any)["chrome.badge"]
        XCTAssertTrue(badge.exists)
        XCTAssertTrue(badge.label.contains("LOCAL · AUDIO INCLUIDO"))

        XCTAssertFalse(app.buttons["chip.hai"].exists)
        XCTAssertFalse(app.buttons["chip.sumimasen"].exists)
        XCTAssertFalse(app.buttons["cta.practicar"].exists)

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "kaiwa-local-setup"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
