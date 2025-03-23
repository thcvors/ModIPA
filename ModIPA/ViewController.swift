//
//  ViewController.swift
//  ModIPA
//
//  Created by CVPRO on 12/01/24.
//

import Cocoa
import ZIPFoundation

class ViewController: NSViewController {
    @IBOutlet weak var ipaName: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var githubButton: NSButton!

    var appPath = URL(fileURLWithPath: "")
    var currentlyExtracting = false
    var ipaCopy = ""
    var ipaFileName = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        progressBar.isHidden = true
        progressBar.minValue = 0
        progressBar.maxValue = 100
        progressBar.doubleValue = 0

        githubButton.target = self
        githubButton.action = #selector(openGitHubLink)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc func openGitHubLink() {
        if let url = URL(string: "https://github.com/thcvors/ModIPA") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func applicationWillTerminate(notification: Notification) {
        if currentlyExtracting {
            removeTemporaryFiles()
        }
    }

    private func removeTemporaryFiles() {
        do {
            let zipPath = ipaCopy + ".zip"
            if FileManager.default.fileExists(atPath: zipPath) {
                try FileManager.default.removeItem(atPath: zipPath)
            }
            if FileManager.default.fileExists(atPath: ipaCopy) {
                try FileManager.default.removeItem(atPath: ipaCopy)
            }
        } catch {
            showErrorAlert(message: "Error cleaning up temporary files: \(error.localizedDescription)")
        }
    }

    private func extractPayloadFromIPA(path: URL) {
        ipaCopy = path.deletingPathExtension().lastPathComponent + "_ModIPA"
        let progress = Progress(totalUnitCount: 100)
        let zipPath = ipaCopy + ".zip"

        if FileManager.default.fileExists(atPath: ipaCopy) {
            try? FileManager.default.removeItem(atPath: ipaCopy)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                self.currentlyExtracting = true

                if !FileManager.default.fileExists(atPath: zipPath) {
                    try FileManager.default.copyItem(at: path, to: URL(fileURLWithPath: zipPath))
                }

                try FileManager.default.unzipItem(
                    at: URL(fileURLWithPath: zipPath),
                    to: URL(fileURLWithPath: self.ipaCopy),
                    progress: progress
                )

                try FileManager.default.removeItem(atPath: zipPath)
                self.currentlyExtracting = false

                // ✅ Validate .app bundle & Info.plist before continuing
                let payloadPath = URL(fileURLWithPath: self.ipaCopy).appendingPathComponent("Payload")
                let payloadContents = try FileManager.default.contentsOfDirectory(
                    at: payloadPath,
                    includingPropertiesForKeys: nil,
                    options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
                )

                guard let appBundle = payloadContents.first(where: { $0.pathExtension == "app" }) else {
                    throw NSError(domain: "ModIPA", code: 1, userInfo: [NSLocalizedDescriptionKey: "No .app bundle found in Payload."])
                }

                let infoPlistPath = appBundle.appendingPathComponent("Info.plist")
                guard FileManager.default.fileExists(atPath: infoPlistPath.path),
                      NSDictionary(contentsOfFile: infoPlistPath.path) != nil else {
                    throw NSError(domain: "ModIPA", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to load Info.plist."])
                }

                self.appPath = appBundle

                DispatchQueue.main.async {
                    self.progressBar.doubleValue = 100
                    self.progressBar.isHidden = true
                    self.openEditController()
                }

            } catch {
                DispatchQueue.main.async {
                    self.progressBar.isHidden = true
                    self.showErrorAlert(message: error.localizedDescription)
                }
            }
        }

        DispatchQueue.global(qos: .background).async {
            while progress.fractionCompleted < 1.0 {
                DispatchQueue.main.async {
                    self.progressBar.isHidden = false
                    self.progressBar.doubleValue = progress.fractionCompleted * 100
                }
                usleep(100_000)
            }
        }
    }

    private func openEditController() {
        let editController = self.storyboard?.instantiateController(withIdentifier: "EditController") as! EditController
        editController.appPath = self.appPath
        editController.ipaFileName = self.ipaFileName
        self.view.window?.contentViewController = editController
    }

    @IBAction func githubButtonClicked(_ sender: NSButton) {
        openGitHubLink()
    }

    @IBAction func uploadFile(_ sender: Any) {
        let dialog = NSOpenPanel()
        dialog.title = "Select an IPA file"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        dialog.allowedFileTypes = ["ipa"]
        dialog.level = .modalPanel

        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            dialog.directoryURL = documentsURL
        }

        guard dialog.runModal() == .OK, let selectedFile = dialog.url else {
            self.showErrorAlert(message: "No file selected.")
            return
        }

        print("📂 Selected IPA: \(selectedFile.lastPathComponent)")
        self.ipaName.stringValue = selectedFile.lastPathComponent
        self.ipaFileName = selectedFile.deletingPathExtension().lastPathComponent
        self.extractPayloadFromIPA(path: selectedFile)
    }

    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
