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

    var appPath = URL(fileURLWithPath: "")
    var currentlyExtracting = false
    var ipaCopy = ""
    var ipaFileName = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up notification for application termination
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc func applicationWillTerminate(notification: Notification) {
        // Clean up temporary files if extraction is incomplete
        if currentlyExtracting {
            removeTemporaryFiles()
        }
    }

    private func removeTemporaryFiles() {
        do {
            if FileManager.default.fileExists(atPath: ipaCopy + ".zip") {
                try FileManager.default.removeItem(atPath: ipaCopy + ".zip")
            }
            if FileManager.default.fileExists(atPath: ipaCopy) {
                try FileManager.default.removeItem(atPath: ipaCopy)
            }
        } catch {
            print("Error cleaning up temporary files: \(error.localizedDescription)")
        }
    }

    private func openEditController() {
        DispatchQueue.main.async {
            do {
                // Locate the app bundle inside the Payload directory
                let payloadContents = try FileManager.default.contentsOfDirectory(
                    at: URL(fileURLWithPath: self.ipaCopy + "/Payload"),
                    includingPropertiesForKeys: nil,
                    options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
                )
                guard let appBundle = payloadContents.first else {
                    self.showErrorAlert(message: "No app bundle found in the Payload directory.")
                    return
                }

                self.appPath = appBundle
                self.performSegue(withIdentifier: "editsegue", sender: self)
            } catch {
                self.showErrorAlert(message: "Error locating app bundle: \(error.localizedDescription)")
            }
        }
    }

    private func extractPayloadFromIPA(path: URL) {
        ipaCopy = path.deletingPathExtension().lastPathComponent + "_ModIPA"

        // If extracted files already exist, skip re-extraction
        if FileManager.default.fileExists(atPath: ipaCopy),
           !FileManager.default.fileExists(atPath: ipaCopy + ".zip") {
            openEditController()
            return
        }

        let progress = Progress()

        // Remove any old extraction folder
        if FileManager.default.fileExists(atPath: ipaCopy) {
            do {
                try FileManager.default.removeItem(atPath: ipaCopy)
            } catch {
                showErrorAlert(message: "Error removing previous extraction: \(error.localizedDescription)")
                return
            }
        }

        DispatchQueue.global(qos: .userInteractive).async {
            do {
                self.currentlyExtracting = true

                // Copy IPA file and unzip it
                if !FileManager.default.fileExists(atPath: self.ipaCopy + ".zip") {
                    try FileManager.default.copyItem(at: path, to: URL(fileURLWithPath: self.ipaCopy + ".zip"))
                }
                try FileManager.default.unzipItem(
                    at: URL(fileURLWithPath: self.ipaCopy + ".zip"),
                    to: URL(fileURLWithPath: self.ipaCopy),
                    progress: progress
                )
                try FileManager.default.removeItem(atPath: self.ipaCopy + ".zip")

                self.currentlyExtracting = false
                self.openEditController()
            } catch {
                DispatchQueue.main.async {
                    self.showErrorAlert(message: "Error during extraction: \(error.localizedDescription)")
                }
            }
        }

        DispatchQueue.global(qos: .background).async {
            while progress.fractionCompleted < 1.0 {
                DispatchQueue.main.async {
                    self.progressBar.isHidden = false
                    self.progressBar.doubleValue = progress.fractionCompleted * 100
                }
            }
            DispatchQueue.main.async {
                self.progressBar.isHidden = true
            }
        }
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "editsegue" {
            // Pass the app path and file name to the EditController
            if let editController = (segue.destinationController as? NSWindowController)?.contentViewController as? EditController {
                editController.appPath = appPath
                editController.ipaFileName = ipaFileName
            }
            self.view.window?.close()
        }
    }

    @IBAction func uploadFile(_ sender: Any) {
        let dialog = NSOpenPanel()
        dialog.title = "Select an .ipa file"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        dialog.allowedFileTypes = ["ipa"]

        if dialog.runModal() == .OK, let selectedFile = dialog.url {
            ipaName.stringValue = selectedFile.lastPathComponent
            ipaFileName = selectedFile.deletingPathExtension().lastPathComponent
            extractPayloadFromIPA(path: selectedFile)
        }
    }

    // MARK: - Helper Methods

    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
