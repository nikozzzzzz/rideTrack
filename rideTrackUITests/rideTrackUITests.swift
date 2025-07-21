//
//  rideTrackUITests.swift
//  rideTrackUITests
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import XCTest

final class rideTrackUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testMainNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify Dashboard tab exists and is the default
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].exists)
        XCTAssertTrue(app.navigationBars["Dashboard"].exists)

        // Navigate to New Ride tab
        app.tabBars.buttons["New Ride"].tap()
        XCTAssertTrue(app.navigationBars["New Ride"].exists)

        // Navigate to Settings tab
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }

    @MainActor
    func testNewRideCreation() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to New Ride tab
        app.tabBars.buttons["New Ride"].tap()

        // Select an activity
        app.buttons["Cycling"].tap()

        // Enter a custom title
        let titleTextField = app.textFields["Custom Title..."]
        XCTAssertTrue(titleTextField.exists)
        titleTextField.tap()
        titleTextField.typeText("Morning Ride")

        // Start the ride
        app.buttons["Start Cycling"].tap()

        // Verify that the current ride tab appears and is selected
        let currentRideTab = app.tabBars.buttons["Current Ride"]
        XCTAssertTrue(currentRideTab.waitForExistence(timeout: 5))

    @MainActor
    func testProfileView() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Settings tab
        app.tabBars.buttons["Settings"].tap()

        // Navigate to Profile View
        app.tables.cells.staticTexts["User Profile"].tap()

        // Verify that the profile view is displayed
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
    }
        XCTAssertTrue(currentRideTab.isSelected)

        // Verify that the current ride view is displayed
        XCTAssertTrue(app.staticTexts["Current Ride"].exists)
    }
}
