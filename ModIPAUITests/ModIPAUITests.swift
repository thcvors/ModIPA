//
//  ModIPAUITests.swift
//  ModIPAUITests
//
//  Created by Daeun Jung on 11/30/24
//

import XCTest

final class ModIPAUITests: XCTestCase {

    override func setUpWithError() throws {
        // Set up initial state for each test
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        click()
        typeText(XCUIKeyboardKey.delete.rawValue)
        typeText(text)
    }
}
