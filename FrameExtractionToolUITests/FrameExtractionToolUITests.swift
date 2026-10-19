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
        // CI runners can be slow to bring the simulator up; wait for the app
        // before interacting with it.
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 60))
        return app
    }

    @MainActor
    func testEmptyStateOffersTheMainActions() throws {
        let app = launchApp()

        XCTAssertTrue(app.navigationBars["Frame Extractor"].waitForExistence(timeout: 60))
        XCTAssertTrue(app.buttons["Choose Video"].firstMatch.waitForExistence(timeout: 30))
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts["No Frames Yet"].waitForExistence(timeout: 30))
    }

    @MainActor
    func testSettingsScreenShowsPreferencesAndVersion() throws {
        let app = launchApp()

        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 60))
        settingsButton.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 60))
        XCTAssertTrue(app.switches["Haptic Feedback"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.switches["Save to an Album"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts["Version"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.buttons["Show Tutorial"].waitForExistence(timeout: 30))
    }

    @MainActor
    func testTutorialCanBeWalkedThroughAndSkipped() throws {
        let app = launchApp(onboardingSeen: false)

        // First run: the tour appears before anything else.
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 60))

        continueButton.tap()
        continueButton.tap()
        continueButton.tap()

        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 30))
        getStarted.tap()

        XCTAssertTrue(app.navigationBars["Frame Extractor"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.buttons["Choose Video"].firstMatch.exists)
    }
}
