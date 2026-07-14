import XCTest

/// Verifies, against the running app's real accessibility tree, that the hero
/// card is exactly one actionable VoiceOver target and that the visible CTA
/// does not leak a second target.
final class HeroAccessibilityUITests: XCTestCase {
    @MainActor
    func testHeroCardExposesExactlyOneAccessibilityTarget() {
        let app = XCUIApplication()
        app.launchEnvironment["MA_UI_TEST_ONBOARDING_COMPLETED"] = "true"
        app.launch()

        let language = app.buttons["chrome.language"]
        XCTAssertTrue(language.waitForExistence(timeout: 10))
        if language.label == "Cambiar a inglés" { language.tap() }

        let heroTargets = app.buttons.matching(identifier: "hero.restaurant")
        XCTAssertTrue(
            heroTargets.firstMatch.waitForExistence(timeout: 10),
            "hero card accessibility element not found"
        )
        XCTAssertEqual(heroTargets.count, 1, "hero card must be exactly one target")
        XCTAssertEqual(
            heroTargets.firstMatch.elementType, .button,
            "hero card must be a semantic button"
        )

        let heroLabel = heroTargets.firstMatch.label
        XCTAssertTrue(heroLabel.contains("Arrive at a restaurant"))
        XCTAssertTrue(heroLabel.contains("understand, listen, say the phrase, get feedback, and respond"))
        XCTAssertTrue(heroLabel.contains("see what MA understood"))

        // No second interactive target: the CTA capsule must not exist as its
        // own button. (Its text may appear as a static descendant *inside*
        // the hero button — that is one VoiceOver target, not two.)
        let ctaButtons = app.buttons
            .matching(NSPredicate(format: "label CONTAINS 'Start the scene'"))
        XCTAssertEqual(ctaButtons.count, 0, "CTA leaked as a separate interactive target")
        XCTAssertEqual(
            app.buttons.matching(identifier: "cta.hero.empezar").count, 0,
            "old CTA identifier still exposed"
        )
    }

    @MainActor
    func testHeroCardHasACompleteSpanishAccessibilityLabel() {
        let app = XCUIApplication()
        app.launchEnvironment["MA_UI_TEST_ONBOARDING_COMPLETED"] = "true"
        app.launch()
        let language = app.buttons["chrome.language"]
        XCTAssertTrue(language.waitForExistence(timeout: 10))
        if language.label == "Switch to Spanish" { language.tap() }

        let hero = app.buttons["hero.restaurant"]
        XCTAssertTrue(hero.waitForExistence(timeout: 10))
        XCTAssertTrue(hero.label.contains("Llegar a un restaurante"))
        XCTAssertTrue(hero.label.contains("entiende, escucha, di la frase, recibe feedback y responde"))
        XCTAssertTrue(hero.label.contains("MA te muestra qué entendió"))
        XCTAssertEqual(language.label, "Cambiar a inglés")
    }
}
