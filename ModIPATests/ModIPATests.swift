//
//  ModIPATests.swift
//  ModIPATests
//
//  Created by Daeun Jung on 11/30/24
//

import XCTest
@testable import ModIPA

class ModIPATests: XCTestCase {

    override func setUpWithError() throws {
        // Called before each test method
    }

    override func tearDownWithError() throws {
        // Called after each test method
    }

    func testPlistModification() throws {
        let testPlistPath = "/path/to/test/Info.plist"
        guard let plist = NSMutableDictionary(contentsOfFile: testPlistPath) else {
            XCTFail("Failed to load plist file")
            return
        }

        plist["CFBundleDisplayName"] = "Test App"
        XCTAssertEqual(plist["CFBundleDisplayName"] as? String, "Test App")

        plist.write(toFile: testPlistPath, atomically: true)
        let reloadedPlist = NSMutableDictionary(contentsOfFile: testPlistPath)
        XCTAssertEqual(reloadedPlist?["CFBundleDisplayName"] as? String, "Test App")
    }

    func testIconReplacement() throws {
        let testImagePath = "/path/to/test/icon.png"
        let iconImage = NSImage(contentsOfFile: testImagePath)
        XCTAssertNotNil(iconImage, "Failed to load test icon image")

        let resizedImage = iconImage?.resized(to: NSSize(width: 1024, height: 1024))
        XCTAssertEqual(resizedImage?.size, NSSize(width: 1024, height: 1024), "Image resizing failed")
    }

    func testCategorySelection() throws {
        let testPlistPath = "/path/to/test/Info.plist"
        guard let plist = NSMutableDictionary(contentsOfFile: testPlistPath) else {
            XCTFail("Failed to load plist file")
            return
        }

        plist["LSApplicationCategoryType"] = "public.app-category.utilities"
        XCTAssertEqual(plist["LSApplicationCategoryType"] as? String, "public.app-category.utilities")

        plist.write(toFile: testPlistPath, atomically: true)
        let reloadedPlist = NSMutableDictionary(contentsOfFile: testPlistPath)
        XCTAssertEqual(reloadedPlist?["LSApplicationCategoryType"] as? String, "public.app-category.utilities")
    }

    func testIPAExtractionAndGeneration() throws {
        let testIPAPath = "/path/to/test/app.ipa"
        let extractedPath = "/path/to/extracted"
        let regeneratedIPAPath = "/path/to/regenerated/app.ipa"

        let fileManager = FileManager.default

        try fileManager.unzipItem(at: URL(fileURLWithPath: testIPAPath), to: URL(fileURLWithPath: extractedPath))
        XCTAssertTrue(fileManager.fileExists(atPath: extractedPath), "Extraction failed")

        try fileManager.zipItem(at: URL(fileURLWithPath: extractedPath), to: URL(fileURLWithPath: regeneratedIPAPath))
        XCTAssertTrue(fileManager.fileExists(atPath: regeneratedIPAPath), "Regeneration failed")
    }

    func testPerformanceExtraction() throws {
        self.measure {
            let testIPAPath = "/path/to/test/app.ipa"
            let extractedPath = "/path/to/extracted"
            do {
                try FileManager.default.unzipItem(at: URL(fileURLWithPath: testIPAPath), to: URL(fileURLWithPath: extractedPath))
            } catch {
                XCTFail("Extraction failed: \(error.localizedDescription)")
            }
        }
    }
}
