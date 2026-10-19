//
//  FrameExtractionToolUITests.swift
//  FrameExtractionToolUITests
//
//  Created by Casper Ong on 14/8/2025.
//

import XCTest

final class FrameExtractionToolUITests: XCTestCase {

    override func setUpWithError() throws {
        // Stop the run as soon as something goes wrong.
        continueAfterFailure = false
    }

    /// The app has no arguments, so the first screen the user sees is the tour.
    private func launchApp(onboardingSeen: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-hasSeenOnboarding", onboardingSeen ? "YES" : "NO"]
        app.launch()
        return app
    }

    @MainActor
    func testEmptyStateOffersTheMainActions() throws {
        let app = launchApp()

        XCTAssertTrue(app.navigationBars["Frame Extractor"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Choose Video"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Settings"].exists)
        XCTAssertTrue(app.staticTexts["No Frames Yet"].exists)
    }

    @MainActor
    func testSettingsScreenShowsPreferencesAndVersion() throws {
        let app = launchApp()

        app.buttons["Settings"].tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.switches["Haptic Feedback"].exists)
        XCTAssertTrue(app.switches["Save to an Album"].exists)
        XCTAssertTrue(app.staticTexts["Version"].exists)
        XCTAssertTrue(app.buttons["Show Tutorial"].exists)
    }

    @MainActor
    func testTutorialCanBeWalkedThroughAndSkipped() throws {
        let app = launchApp(onboardingSeen: false)

        // First run: the tour appears before anything else.
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 15))

        continueButton.tap()
        continueButton.tap()
        continueButton.tap()

        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 10))
        getStarted.tap()

        XCTAssertTrue(app.navigationBars["Frame Extractor"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Choose Video"].firstMatch.exists)
    }
}
