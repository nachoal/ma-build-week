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

        let heroPredicate = NSPredicate(format: "label CONTAINS 'Escena 1, disponible'")
        let heroTargets = app.descendants(matching: .any).matching(heroPredicate)
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
        XCTAssertTrue(heroLabel.contains("Llegar a un restaurante"))
        XCTAssertTrue(heroLabel.contains("aprende, conversa, repara y repite"))
        XCTAssertTrue(heroLabel.contains("cuántas personas"))
        XCTAssertFalse(heroLabel.contains("sois"), "Spain-specific vosotros form leaked")

        // No second interactive target: the CTA capsule must not exist as its
        // own button. (Its text may appear as a static descendant *inside*
        // the hero button — that is one VoiceOver target, not two.)
        let ctaButtons = app.buttons
            .matching(NSPredicate(format: "label CONTAINS 'Empezar la escena'"))
        XCTAssertEqual(ctaButtons.count, 0, "CTA leaked as a separate interactive target")
        XCTAssertEqual(
            app.buttons.matching(identifier: "cta.hero.empezar").count, 0,
            "old CTA identifier still exposed"
        )
    }
}
