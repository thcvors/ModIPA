//
//  ModIPAUITests.swift
//  ModIPAUITests
//
//  Created by Daeun Jung on 11/30/24
//

import XCTest

final class ModIPAUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Clean-up if necessary
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()

        // Example: Tap the upload button
        let uploadButton = app.buttons["Upload File"]
        XCTAssertTrue(uploadButton.exists, "Upload File button should exist")
        uploadButton.tap()
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

// ✅ Extension for typing into text fields
extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        click()
        typeText(XCUIKeyboardKey.delete.rawValue)
        typeText(text)
    }
}
