//
//  ModIPAUITests.swift
//  ModIPAUITests
//
//  Created by Daeun Jung on 11/30/24
//

import XCTest

class ModIPAUITests: XCTestCase {

    override func setUpWithError() throws {
        // Set up initial state for each test
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Clean up resources after each test
    }

    func testSelectIPAFile() throws {
        let app = XCUIApplication()
        app.launch()

        // Tap the "Choose IPA" button
        let chooseIPAButton = app.buttons["Choose IPA"]
        XCTAssertTrue(chooseIPAButton.exists, "The 'Choose IPA' button should exist")
        chooseIPAButton.click()
        
        // Interact with the file dialog
        let openPanel = app.dialogs.firstMatch
        XCTAssertTrue(openPanel.exists, "The file selection dialog should appear")
        
        // Simulate file selection (file path may vary)
        let filePath = "/path/to/test/app.ipa"
        openPanel.typeText(filePath)
        openPanel.buttons["Open"].click()
        
        // Verify that the selected file name appears in the UI
        let fileNameLabel = app.staticTexts["SelectedFileName"]
        XCTAssertTrue(fileNameLabel.exists, "The file name label should exist")
        XCTAssertEqual(fileNameLabel.label, "app.ipa", "The selected file name should match")
    }

    func testModifyAppDisplayName() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to the Edit screen
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.exists, "The 'Edit' button should exist")
        editButton.click()
        
        // Modify the display name
        let displayNameField = app.textFields["DisplayName"]
        XCTAssertTrue(displayNameField.exists, "The 'Display Name' field should exist")
        displayNameField.clearAndEnterText("New Display Name")
        
        // Save changes and verify
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.exists, "The 'Save' button should exist")
        saveButton.click()
        
        let successAlert = app.alerts["Success"]
        XCTAssertTrue(successAlert.exists, "A success alert should appear after saving")
        XCTAssertEqual(successAlert.label, "Changes Saved", "The success alert should confirm the changes")
        successAlert.buttons["OK"].click()
    }

    func testGenerateModifiedIPA() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to the Edit screen
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.exists, "The 'Edit' button should exist")
        editButton.click()
        
        // Tap the "Generate New IPA" button
        let generateButton = app.buttons["Generate New IPA"]
        XCTAssertTrue(generateButton.exists, "The 'Generate New IPA' button should exist")
        generateButton.click()
        
        // Verify that the progress indicator appears
        let progressBar = app.progressIndicators["ProgressBar"]
        XCTAssertTrue(progressBar.exists, "The progress bar should appear during generation")
        
        // Wait for the progress bar to complete
        expectation(for: NSPredicate(format: "value == 100"), evaluatedWith: progressBar, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        
        // Verify the success of the operation
        let successAlert = app.alerts["Success"]
        XCTAssertTrue(successAlert.exists, "A success alert should appear after generation")
        XCTAssertEqual(successAlert.label, "IPA Generated Successfully", "The success alert should confirm the operation")
        successAlert.buttons["OK"].click()
    }

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
