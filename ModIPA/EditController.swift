//
//  EditController.swift
//  ModIPA
//
//  Created by CVPRO on 12/01/24.
//

import Cocoa
import ZIPFoundation

class EditController: NSViewController, NSTextFieldDelegate {
    @IBOutlet weak var displayName: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var version: NSTextField!
    @IBOutlet weak var iconImg: NSImageView!
    @IBOutlet weak var categoryPicker: NSPopUpButton!
    @IBOutlet weak var bundleID: NSTextField!
    
    var appPath = URL(fileURLWithPath: "")
    var plistPath = ""
    var ipaPlist = NSMutableDictionary()
    var iconImages: [URL] = []
    var ipaFileName = ""
    var lastVersion = ""
    
    let app_categories = ["public.app-category.business", "public.app-category.developer-tools", "public.app-category.education", "public.app-category.entertainment", "public.app-category.finance", "public.app-category.games", "public.app-category.action-games", "public.app-category.adventure-games", "public.app-category.arcade-games", "public.app-category.board-games", "public.app-category.card-games", "public.app-category.casino-games", "public.app-category.dice-games", "public.app-category.educational-games", "public.app-category.family-games", "public.app-category.kids-games", "public.app-category.music-games", "public.app-category.puzzle-games", "public.app-category.racing-games", "public.app-category.role-playing-games", "public.app-category.simulation-games", "public.app-category.sports-games", "public.app-category.strategy-games", "public.app-category.trivia-games", "public.app-category.word-games", "public.app-category.graphics-design", "public.app-category.healthcare-fitness", "public.app-category.lifestyle", "public.app-category.medical", "public.app-category.music", "public.app-category.news", "public.app-category.photography", "public.app-category.productivity", "public.app-category.reference", "public.app-category.social-networking", "public.app-category.sports", "public.app-category.travel", "public.app-category.utilities", "public.app-category.video", "public.app-category.weather"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        iconImg.wantsLayer = true
        iconImg.layer?.cornerRadius = 8.0
        
        displayName.delegate = self
        version.delegate = self
        bundleID.delegate = self
    }
    
    func alert(text: String) {
        let alert = NSAlert()
        alert.messageText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func controlTextDidChange(_ obj: Notification) {
        let textField = obj.object as! NSTextField
        
        if textField == displayName {
            ipaPlist["CFBundleDisplayName"] = textField.stringValue
            ipaPlist.write(toFile: plistPath, atomically: true)
        } else if textField == version {
            let components = textField.stringValue.components(separatedBy: ".").filter { !$0.isEmpty }
            if components.count != 4 {
                alert(text: "App Version must have 4 valid digits!")
                textField.stringValue = lastVersion
            } else {
                lastVersion = textField.stringValue
                ipaPlist["CFBundleVersion"] = textField.stringValue
                ipaPlist["CFBundleShortVersionString"] = components.dropLast().joined(separator: ".")
                ipaPlist.write(toFile: plistPath, atomically: true)
            }
        } else if textField == bundleID {
            ipaPlist["CFBundleIdentifier"] = textField.stringValue
            ipaPlist.write(toFile: plistPath, atomically: true)
        }
    }
    
    @IBAction func categoryValueDidChange(_ sender: Any) {
        ipaPlist["LSApplicationCategoryType"] = categoryPicker.selectedItem?.title
        ipaPlist.write(toFile: plistPath, atomically: true)
    }
    
    override func viewWillAppear() {
        plistPath = appPath.appendingPathComponent("Info.plist").path
        guard let plist = NSMutableDictionary(contentsOfFile: plistPath) else {
            alert(text: "Failed to load Info.plist.")
            return
        }
        ipaPlist = plist
        
        ipaPlist["CFBundleDisplayName"] = ipaPlist["CFBundleDisplayName"] ?? "DisplayName"
        ipaPlist["CFBundleVersion"] = ipaPlist["CFBundleVersion"] ?? "1.0.0.0"
        ipaPlist["CFBundleIdentifier"] = ipaPlist["CFBundleIdentifier"] ?? "bundleident.app"
        ipaPlist["CFBundleShortVersionString"] = ipaPlist["CFBundleShortVersionString"] ?? "1.0.0"
        ipaPlist["LSApplicationCategoryType"] = ipaPlist["LSApplicationCategoryType"] ?? "public.app-category.developer-tools"
        ipaPlist.write(toFile: plistPath, atomically: true)
        
        lastVersion = ipaPlist["CFBundleVersion"] as! String
        version.stringValue = lastVersion
        displayName.stringValue = ipaPlist["CFBundleDisplayName"] as! String
        bundleID.stringValue = ipaPlist["CFBundleIdentifier"] as! String
        
        categoryPicker.removeAllItems()
        categoryPicker.addItems(withTitles: app_categories)
        categoryPicker.selectItem(withTitle: ipaPlist["LSApplicationCategoryType"] as! String)
        
        loadIcons()
    }
    
    private func loadIcons() {
        guard let iconsDict = ipaPlist["CFBundleIcons"] as? [String: Any],
              let primaryIconDict = iconsDict["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIconDict["CFBundleIconFiles"] as? [String] else {
            alert(text: "No icon files found.")
            return
        }
        
        for iconName in iconFiles {
            let matches = try? FileManager.default.contentsOfDirectory(at: appPath, includingPropertiesForKeys: nil).filter { $0.lastPathComponent.contains(iconName) }
            if let matchedIcon = matches?.last, let image = NSImage(contentsOf: matchedIcon) {
                iconImages.append(matchedIcon)
                iconImg.image = image // Display the last matching icon
            }
        }
    }

    @IBAction func changeBtnClicked(_ sender: Any) {
        let dialog = NSOpenPanel()
        dialog.title = "Select an image to use as the app icon"
        dialog.allowedFileTypes = ["png"]

        if dialog.runModal() == .OK, let url = dialog.url, let uploadedImg = NSImage(contentsOf: url) {
            for iconURL in iconImages {
                uploadedImg.saveAsPNG(to: iconURL)
            }
            iconImg.image = uploadedImg
        }
    }
    
    @IBAction func generateNewIPA(_ sender: Any) {
        let progress = Progress()
        
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                let exportPath = self.appPath.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("\(self.ipaFileName) [Modified].ipa")
                
                if !FileManager.default.fileExists(atPath: exportPath.path) {
                    try FileManager.default.zipItem(at: self.appPath.deletingLastPathComponent(), to: exportPath, progress: progress)
                }
                
                NSWorkspace.shared.selectFile(exportPath.path, inFileViewerRootedAtPath: "")
            } catch {
                DispatchQueue.main.async {
                    self.alert(text: "Failed to generate modified IPA: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension NSImage {
    func saveAsPNG(to url: URL) {
        guard let tiffData = self.tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: tiffData),
              let pngData = imageRep.representation(using: .png, properties: [:]) else {
            print("Failed to save image as PNG.")
            return
        }
        try? pngData.write(to: url)
    }
}
