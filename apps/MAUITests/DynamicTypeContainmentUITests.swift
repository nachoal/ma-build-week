import UIKit
import XCTest

/// Exercises every onboarding step in the running app at Accessibility Extra
/// Large. Unit rendering catches pixel regressions; this test verifies the
/// actual accessibility frames of the controls a learner must use.
final class DynamicTypeContainmentUITests: XCTestCase {
    @MainActor
    func testOnboardingControlsStayInsideTheScreenAtAccessibilityExtraLarge() {
        let app = XCUIApplication()
        app.launchEnvironment["MA_UI_TEST_ONBOARDING_COMPLETED"] = "false"
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            UIContentSizeCategory.accessibilityExtraLarge.rawValue,
        ]
        app.launch()

        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 10))

        assertContained("chrome.badge", in: app, window: window)
        assertContained("chip.nivel.zero", in: app, window: window)
        assertContained("chip.nivel.fewWords", in: app, window: window)
        advanceOnboarding(in: app)
        assertStepResetToTop(in: app)

        for identifier in ["chip.meta.firstTrip", "chip.meta.bookedTrip", "chip.meta.practicalNoTrip"] {
            assertContained(identifier, in: app, window: window)
        }
        advanceOnboarding(in: app)
        assertStepResetToTop(in: app)

        assertContained("onboarding.escena.incluida", in: app, window: window)
        for identifier in [
            "chip.escena.izakaya", "chip.escena.konbini",
            "chip.escena.train", "chip.escena.hotel",
            "chip.ritmo.5", "chip.ritmo.10", "chip.ritmo.15",
        ] {
            assertContained(identifier, in: app, window: window)
        }
    }

    @MainActor
    private func advanceOnboarding(in app: XCUIApplication) {
        let button = app.buttons["onboarding.continuar"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        for _ in 0..<6 where !button.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(button.isHittable, "Continue button never became hittable")
        button.tap()
    }

    @MainActor
    private func assertStepResetToTop(in app: XCUIApplication) {
        let back = app.buttons["onboarding.atras"]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        XCTAssertTrue(back.isHittable, "New onboarding step did not reset to its top")
        let badge = app.descendants(matching: .any)["chrome.badge"]
        XCTAssertTrue(badge.waitForExistence(timeout: 5))
        XCTAssertTrue(badge.isHittable, "Honesty badge remained above the visible scroll position")
    }

    @MainActor
    private func assertContained(
        _ identifier: String, in app: XCUIApplication, window: XCUIElement,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        let element = app.descendants(matching: .any)[identifier]
        XCTAssertTrue(
            element.waitForExistence(timeout: 5),
            "Missing element: \(identifier)", file: file, line: line
        )
        XCTAssertGreaterThanOrEqual(
            element.frame.minX, window.frame.minX - 0.5,
            "\(identifier) escaped the left edge", file: file, line: line
        )
        XCTAssertLessThanOrEqual(
            element.frame.maxX, window.frame.maxX + 0.5,
            "\(identifier) escaped the right edge", file: file, line: line
        )
    }
}
