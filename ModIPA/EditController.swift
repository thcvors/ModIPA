//
//  EditController.swift
//  ModIPA
//
//  Created by CVPRO on 12/01/24.
//

import Cocoa
import ZIPFoundation

class EditController: NSViewController, NSTextFieldDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var displayName: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var version: NSTextField!
    @IBOutlet weak var iconImg: NSImageView!
    @IBOutlet weak var categoryPicker: NSPopUpButton!
    @IBOutlet weak var bundleID: NSTextField!
    @IBOutlet weak var backButton: NSButton!

    // MARK: - Variables
    var appPath = URL(fileURLWithPath: "")
    var plistPath = ""
    var ipaPlist = NSMutableDictionary()
    var iconImages: [URL] = []
    var ipaFileName = ""
    var lastVersion = ""

    let app_categories = [
        "public.app-category.business", "public.app-category.developer-tools", "public.app-category.education",
        "public.app-category.entertainment", "public.app-category.finance", "public.app-category.games",
        "public.app-category.utilities", "public.app-category.video", "public.app-category.weather"
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        iconImg.wantsLayer = true
        iconImg.layer?.cornerRadius = 8.0

        displayName.delegate = self
        version.delegate = self
        bundleID.delegate = self
    }

    override func viewWillAppear() {
        guard plistPath.isEmpty else { return }
        
        plistPath = appPath.appendingPathComponent("Info.plist").path
        guard let plist = NSMutableDictionary(contentsOfFile: plistPath) else {
            DispatchQueue.main.async {
                self.alert(text: "Failed to load Info.plist.")
            }
            return
        }

        ipaPlist = plist
        lastVersion = ipaPlist["CFBundleVersion"] as? String ?? "1.0.0.0"
        version.stringValue = lastVersion
        displayName.stringValue = ipaPlist["CFBundleDisplayName"] as? String
            ?? ipaPlist["CFBundleName"] as? String
            ?? "App Name"
        bundleID.stringValue = ipaPlist["CFBundleIdentifier"] as? String ?? "bundleident.app"

        categoryPicker.removeAllItems()
        categoryPicker.addItems(withTitles: app_categories)
        categoryPicker.selectItem(withTitle: ipaPlist["LSApplicationCategoryType"] as? String ?? "public.app-category.developer-tools")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.loadIcons()
        }
    }

    // MARK: - Icon Loading
    private func loadIcons() {
        if let iconsDict = ipaPlist["CFBundleIcons"] as? [String: Any],
           let primaryIconDict = iconsDict["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIconDict["CFBundleIconFiles"] as? [String] {

            for iconName in iconFiles {
                let matches = (try? FileManager.default.contentsOfDirectory(at: appPath, includingPropertiesForKeys: nil))?
                    .filter { $0.lastPathComponent.contains(iconName) }

                if let matchedIcon = matches?.last, let image = NSImage(contentsOf: matchedIcon) {
                    iconImages.append(matchedIcon)
                    iconImg.image = image
                }
            }

            if iconImages.isEmpty {
                alert(text: "No matching image files found for CFBundleIconFiles.")
            }
        } else {
            // 🪄 Fallback: Pick the largest PNG file inside app bundle
            let fallbackIcons = (try? FileManager.default.contentsOfDirectory(at: appPath, includingPropertiesForKeys: [.fileSizeKey]))?
                .filter { $0.pathExtension.lowercased() == "png" }
                .sorted { (lhs, rhs) -> Bool in
                    let lhsSize = (try? lhs.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) ?? 0
                    let rhsSize = (try? rhs.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) ?? 0
                    return lhsSize > rhsSize
                }

            if let fallback = fallbackIcons?.first, let image = NSImage(contentsOf: fallback) {
                iconImages = [fallback]
                iconImg.image = image
            } else {
                alert(text: "No icon files found in the .app bundle.")
            }
        }
    }
    
    // MARK: - Change Icon
    @IBAction func changeBtnClicked(_ sender: Any) {
        let dialog = NSOpenPanel()
        dialog.title = "Select an image to use as the app icon"
        dialog.allowedFileTypes = ["png"]

        if dialog.runModal() == .OK, let url = dialog.url, let uploadedImg = NSImage(contentsOf: url) {
            for iconURL in iconImages {
                uploadedImg.saveAsPNG(to: iconURL)
            }

            DispatchQueue.main.async {
                self.iconImg.image = uploadedImg
                self.alert(text: "The new app icon has been successfully saved.")
            }
        }
    }

    // MARK: - Save Modified IPA
    @IBAction func saveNewFile(_ sender: Any) {
        let progress = Progress()

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let exportPath = self.appPath
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .appendingPathComponent("\(self.ipaFileName) [ModIPA].ipa")

                if !FileManager.default.fileExists(atPath: exportPath.path) {
                    try FileManager.default.zipItem(
                        at: self.appPath.deletingLastPathComponent(),
                        to: exportPath,
                        progress: progress
                    )
                }

                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Changes Saved"
                    alert.informativeText = "Your modified IPA file has been successfully saved."
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "Return")
                    alert.addButton(withTitle: "OK")

                    let response = alert.runModal()

                    // "Return" is first button -> .alertFirstButtonReturn
                    if response == .alertFirstButtonReturn {
                        self.backButtonClicked(self)
                    }

                    NSWorkspace.shared.selectFile(exportPath.path, inFileViewerRootedAtPath: "")
                }

            } catch {
                DispatchQueue.main.async {
                    self.alert(text: "Failed to generate modified IPA: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Back Button
    @IBAction func backButtonClicked(_ sender: Any) {
        if let viewController = self.storyboard?.instantiateController(withIdentifier: "ViewController") as? ViewController {
            self.view.window?.contentViewController = viewController
        }
    }
    
    // MARK: - Category Picker Change
    @IBAction func categoryValueDidChange(_ sender: NSPopUpButton) {
        let selectedCategory = sender.titleOfSelectedItem ?? ""
        ipaPlist["LSApplicationCategoryType"] = selectedCategory
        ipaPlist.write(toFile: plistPath, atomically: true)
    }

    // MARK: - Text Field Live Update
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }

        if textField == displayName {
            ipaPlist["CFBundleDisplayName"] = textField.stringValue

        } else if textField == version {
            let components = textField.stringValue.components(separatedBy: ".").filter { !$0.isEmpty }
            if components.count != 4 {
                alert(text: "App Version must have 4 valid digits!")
                textField.stringValue = lastVersion
            } else {
                lastVersion = textField.stringValue
                ipaPlist["CFBundleVersion"] = textField.stringValue
                ipaPlist["CFBundleShortVersionString"] = components.dropLast().joined(separator: ".")
            }

        } else if textField == bundleID {
            ipaPlist["CFBundleIdentifier"] = textField.stringValue
        }

        ipaPlist.write(toFile: plistPath, atomically: true)
    }

    // MARK: - Alert
    func alert(text: String) {
        let alert = NSAlert()
        alert.messageText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")

        DispatchQueue.main.async {
            alert.runModal()
        }
    }
}

// MARK: - NSImage Extension for Saving as PNG
extension NSImage {
    func saveAsPNG(to url: URL) {
        guard let tiffData = self.tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: tiffData),
              let pngData = imageRep.representation(using: .png, properties: [:]) else {
            print("⚠️ Failed to save image as PNG.")
            return
        }
        try? pngData.write(to: url)
    }
}
