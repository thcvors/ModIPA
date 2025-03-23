//
//  ModIPATests.swift
//  ModIPATests
//
//  Created by Daeun Jung on 11/30/24
//

import XCTest
import Cocoa
@testable import ModIPA

class ModIPATests: XCTestCase {

    override func setUpWithError() throws {
        // Setup code if needed
    }

    override func tearDownWithError() throws {
        // Teardown code if needed
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
        guard let iconImage = NSImage(contentsOfFile: testImagePath) else {
            XCTFail("Failed to load test icon image")
            return
        }

        let resizedImage = iconImage.resized(to: NSSize(width: 1024, height: 1024))
        XCTAssertEqual(resizedImage.size, NSSize(width: 1024, height: 1024), "Image resizing failed")
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
        let fileManager = FileManager.default
        let testIPAPath = "/path/to/test/app.ipa"
        let extractedPath = "/path/to/extracted"
        let regeneratedIPAPath = "/path/to/regenerated/app.ipa"

        try fileManager.unzipItem(at: URL(fileURLWithPath: testIPAPath), to: URL(fileURLWithPath: extractedPath))
        XCTAssertTrue(fileManager.fileExists(atPath: extractedPath), "Extraction failed")

        try fileManager.zipItem(at: URL(fileURLWithPath: extractedPath), to: URL(fileURLWithPath: regeneratedIPAPath))
        XCTAssertTrue(fileManager.fileExists(atPath: regeneratedIPAPath), "Regeneration failed")
    }

    func testPerformanceExtraction() throws {
        measure {
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

// ✅ Utility extension for image resizing
extension NSImage {
    func resized(to targetSize: NSSize) -> NSImage {
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        let context = NSGraphicsContext.current
        context?.imageInterpolation = .high
        self.draw(in: NSRect(origin: .zero, size: targetSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy,
                  fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}
