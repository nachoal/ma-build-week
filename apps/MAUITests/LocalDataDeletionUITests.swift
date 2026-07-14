import XCTest

final class LocalDataDeletionUITests: XCTestCase {
    @MainActor
    func testEnglishDeletionFailureKeepsProfileAndExplainsRecovery() {
        runDeletionFailure(inSpanish: false)
    }

    @MainActor
    func testSpanishDeletionFailureKeepsProfileAndExplainsRecovery() {
        runDeletionFailure(inSpanish: true)
    }

    @MainActor
    func testVerifiedDeletionReturnsToOnboarding() {
        let app = XCUIApplication()
        app.launchEnvironment["MA_UI_TEST_SEED_ONBOARDING_COMPLETED"] = "true"
        app.launchEnvironment["MA_UI_TEST_RESET_INTERFACE_LANGUAGE"] = "true"
        app.launch()

        openDeletionConfirmation(in: app, inSpanish: false)
        confirmDeletion(in: app, inSpanish: false)

        XCTAssertTrue(
            app.staticTexts["Starting from zero? Perfect."]
                .waitForExistence(timeout: 8),
            "Verified deletion did not reset the local profile to onboarding"
        )
        XCTAssertFalse(app.buttons["chrome.perfil"].exists)
    }

    @MainActor
    private func runDeletionFailure(inSpanish: Bool) {
        let app = XCUIApplication()
        app.launchEnvironment["MA_UI_TEST_ONBOARDING_COMPLETED"] = "true"
        app.launchEnvironment["MA_UI_TEST_RESET_INTERFACE_LANGUAGE"] = "true"
        app.launchEnvironment["MA_UI_TEST_FORCE_CREDENTIAL_DELETE_FAILURE"] = "true"
        app.launch()

        let language = app.buttons["chrome.language"]
        XCTAssertTrue(language.waitForExistence(timeout: 8))
        if inSpanish {
            language.tap()
            XCTAssertEqual(language.label, "Cambiar a inglés")
        }

        openDeletionConfirmation(in: app, inSpanish: inSpanish)
        confirmDeletion(in: app, inSpanish: inSpanish)

        let title = inSpanish
            ? "No se pudieron borrar todos los datos"
            : "Couldn’t delete all data"
        let message = inSpanish
            ? "MA no pudo verificar que se borró la credencial privada, así que tu perfil no se restableció. Inténtalo de nuevo."
            : "MA couldn’t verify that the private credential was deleted, so your profile was not reset. Please try again."
        let alert = app.alerts[title]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.staticTexts[message].exists)
        let dismiss = alert.buttons[inSpanish ? "Aceptar" : "OK"]
        XCTAssertTrue(dismiss.exists)
        dismiss.tap()

        let profileTitle = inSpanish ? "Tu perfil de práctica" : "Your practice profile"
        XCTAssertTrue(app.staticTexts[profileTitle].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["perfil.borrar.todo"].exists)
    }

    @MainActor
    private func openDeletionConfirmation(
        in app: XCUIApplication,
        inSpanish: Bool
    ) {
        let profile = app.buttons["chrome.perfil"]
        XCTAssertTrue(profile.waitForExistence(timeout: 8))
        profile.tap()

        let delete = app.buttons["perfil.borrar.todo"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.tap()
        let title = inSpanish
            ? "¿Borrar elecciones y credencial local?"
            : "Delete choices and local credential?"
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5))
    }

    @MainActor
    private func confirmDeletion(
        in app: XCUIApplication,
        inSpanish: Bool
    ) {
        let label = inSpanish ? "Borrar todos mis datos" : "Delete all my data"
        let confirmation = app.buttons.matching(NSPredicate(
            format: "label == %@ AND identifier != %@",
            label,
            "perfil.borrar.todo"
        )).firstMatch
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.tap()
    }
}
