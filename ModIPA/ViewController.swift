//
//  ViewController.swift
//  ModIPA
//
//  Created by CVPRO on 12/01/24.
//

import Cocoa
import UniformTypeIdentifiers
import ZIPFoundation

final class ViewController: NSViewController {

    // MARK: - IPA State

    var appPath = URL(fileURLWithPath: "")
    var currentlyExtracting = false
    var ipaCopy = ""
    var ipaFileName = ""

    // MARK: - Constants

    private let windowSize = NSSize(width: 620, height: 540)

    private let accentColor = NSColor(
        calibratedRed: 0.0,
        green: 0.58,
        blue: 1.0,
        alpha: 1.0
    )

    // MARK: - Header

    private let logoImageView: NSImageView = {
        let imageView = NSImageView()

        imageView.image = NSImage(named: "CVO15")
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
    }()

    private let titleLabel: NSTextField = {
        let label = NSTextField(
            labelWithString: "ModIPA"
        )

        label.font = .systemFont(
            ofSize: 32,
            weight: .bold
        )

        label.textColor = .labelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    private let descriptionLabel: NSTextField = {
        let label = NSTextField(
            labelWithString:
                "Import an IPA file to customize its app information and icon"
        )

        label.font = .systemFont(
            ofSize: 13,
            weight: .regular
        )

        label.textColor = .secondaryLabelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    private lazy var infoButton: NSButton = {
        let image = NSImage(
            systemSymbolName: "info.circle",
            accessibilityDescription: "ModIPA Info"
        ) ?? NSImage()

        let button = NSButton(
            image: image,
            target: self,
            action: #selector(openGitHubLink)
        )

        button.bezelStyle = .inline
        button.isBordered = false
        button.contentTintColor = accentColor
        button.toolTip = "ModIPA on GitHub"
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    // MARK: - Import Card

    private let importCard: NSView = {
        let card = NSView()

        card.wantsLayer = true
        card.layer?.cornerRadius = 18
        card.layer?.cornerCurve = .continuous

        card.layer?.backgroundColor =
            NSColor.controlBackgroundColor.cgColor

        card.layer?.borderWidth = 1
        card.layer?.borderColor =
            NSColor.separatorColor.cgColor

        card.translatesAutoresizingMaskIntoConstraints = false

        return card
    }()

    private let importIcon: NSImageView = {
        let imageView = NSImageView()

        let configuration = NSImage.SymbolConfiguration(
            pointSize: 39,
            weight: .regular
        )

        imageView.image = NSImage(
            systemSymbolName: "plus.circle",
            accessibilityDescription: "Import IPA"
        )?.withSymbolConfiguration(configuration)

        imageView.contentTintColor = .labelColor
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
    }()

    private let importTitleLabel: NSTextField = {
        let label = NSTextField(
            labelWithString:
                "Drag & Drop or Tap to Browse"
        )

        label.font = .systemFont(
            ofSize: 15,
            weight: .semibold
        )

        label.textColor = .labelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    private let importSubtitleLabel: NSTextField = {
        let label = NSTextField(
            labelWithString:
                "Only IPA files are allowed for upload"
        )

        label.font = .systemFont(
            ofSize: 11,
            weight: .regular
        )

        label.textColor = .secondaryLabelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    private lazy var uploadButton: NSButton = {
        let button = NSButton(
            title: "",
            target: self,
            action: #selector(uploadFile)
        )

        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    // MARK: - Selected File

    private let ipaNameLabel: NSTextField = {
        let label = NSTextField(
            labelWithString:
                "No files uploaded yet"
        )

        label.font = .systemFont(
            ofSize: 11,
            weight: .regular
        )

        label.textColor = .tertiaryLabelColor
        label.alignment = .center
        label.lineBreakMode = .byTruncatingMiddle
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    // MARK: - Loading

    private let loadingContainer: NSView = {
        let container = NSView()

        container.isHidden = true
        container.translatesAutoresizingMaskIntoConstraints = false

        return container
    }()

    private let loadingIndicator: NSProgressIndicator = {
        let indicator = NSProgressIndicator()

        indicator.style = .spinning
        indicator.controlSize = .small
        indicator.isIndeterminate = true
        indicator.isDisplayedWhenStopped = false
        indicator.translatesAutoresizingMaskIntoConstraints = false

        return indicator
    }()

    private let loadingLabel: NSTextField = {
        let label = NSTextField(
            labelWithString:
                "Processing IPA"
        )

        label.font = .systemFont(
            ofSize: 11,
            weight: .medium
        )

        label.textColor = .secondaryLabelColor
        label.alignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    // MARK: - Footer

    private let footerLabel: NSTextField = {
        let label = NSTextField(
            labelWithString:
                "Made by @cvors"
        )

        label.font = .systemFont(
            ofSize: 10,
            weight: .regular
        )

        label.textColor = .tertiaryLabelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    // MARK: - Lifecycle

    override func loadView() {
        let rootView = NSView()

        rootView.wantsLayer = true

        rootView.layer?.backgroundColor =
            NSColor.windowBackgroundColor.cgColor

        view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupInterface()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        configureWindow()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Window

    private func configureWindow() {
        guard let window = view.window else {
            return
        }

        // App name remains ModIPA
        window.title = "ModIPA"

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        window.styleMask.insert(
            .fullSizeContentView
        )

        window.isMovableByWindowBackground = true

        // ViewController and EditController use the exact same size
        window.setContentSize(windowSize)
        window.minSize = windowSize
        window.maxSize = windowSize

        window.backgroundColor =
            .windowBackgroundColor

        window.center()
    }

    // MARK: - Interface

    private func setupInterface() {
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(infoButton)

        view.addSubview(importCard)

        importCard.addSubview(importIcon)
        importCard.addSubview(importTitleLabel)
        importCard.addSubview(importSubtitleLabel)
        importCard.addSubview(uploadButton)

        view.addSubview(ipaNameLabel)

        view.addSubview(loadingContainer)

        loadingContainer.addSubview(
            loadingIndicator
        )

        loadingContainer.addSubview(
            loadingLabel
        )

        view.addSubview(footerLabel)

        NSLayoutConstraint.activate([

            // MARK: CVO15

            logoImageView.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            logoImageView.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: 58
            ),

            logoImageView.widthAnchor.constraint(
                equalToConstant: 40
            ),

            logoImageView.heightAnchor.constraint(
                equalToConstant: 40
            ),

            // MARK: ModIPA

            titleLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            titleLabel.topAnchor.constraint(
                equalTo: logoImageView.bottomAnchor,
                constant: 10
            ),

            // MARK: Description

            descriptionLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            descriptionLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 9
            ),

            descriptionLabel.widthAnchor.constraint(
                lessThanOrEqualToConstant: 440
            ),

            // MARK: Info

            infoButton.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            infoButton.topAnchor.constraint(
                equalTo: descriptionLabel.bottomAnchor,
                constant: 11
            ),

            infoButton.widthAnchor.constraint(
                equalToConstant: 22
            ),

            infoButton.heightAnchor.constraint(
                equalToConstant: 22
            ),

            // MARK: Import Card

            importCard.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            importCard.topAnchor.constraint(
                equalTo: infoButton.bottomAnchor,
                constant: 22
            ),

            importCard.widthAnchor.constraint(
                equalToConstant: 450
            ),

            importCard.heightAnchor.constraint(
                equalToConstant: 155
            ),

            // MARK: Import Icon

            importIcon.centerXAnchor.constraint(
                equalTo: importCard.centerXAnchor
            ),

            importIcon.topAnchor.constraint(
                equalTo: importCard.topAnchor,
                constant: 22
            ),

            importIcon.widthAnchor.constraint(
                equalToConstant: 42
            ),

            importIcon.heightAnchor.constraint(
                equalToConstant: 42
            ),

            // MARK: Import Title

            importTitleLabel.centerXAnchor.constraint(
                equalTo: importCard.centerXAnchor
            ),

            importTitleLabel.topAnchor.constraint(
                equalTo: importIcon.bottomAnchor,
                constant: 12
            ),

            // MARK: Import Subtitle

            importSubtitleLabel.centerXAnchor.constraint(
                equalTo: importCard.centerXAnchor
            ),

            importSubtitleLabel.topAnchor.constraint(
                equalTo: importTitleLabel.bottomAnchor,
                constant: 6
            ),

            // MARK: Click Area

            uploadButton.leadingAnchor.constraint(
                equalTo: importCard.leadingAnchor
            ),

            uploadButton.trailingAnchor.constraint(
                equalTo: importCard.trailingAnchor
            ),

            uploadButton.topAnchor.constraint(
                equalTo: importCard.topAnchor
            ),

            uploadButton.bottomAnchor.constraint(
                equalTo: importCard.bottomAnchor
            ),

            // MARK: Filename

            ipaNameLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            ipaNameLabel.topAnchor.constraint(
                equalTo: importCard.bottomAnchor,
                constant: 14
            ),

            ipaNameLabel.widthAnchor.constraint(
                lessThanOrEqualToConstant: 420
            ),

            // MARK: Loading Container

            loadingContainer.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            loadingContainer.topAnchor.constraint(
                equalTo: ipaNameLabel.bottomAnchor,
                constant: 10
            ),

            loadingContainer.widthAnchor.constraint(
                equalToConstant: 125
            ),

            loadingContainer.heightAnchor.constraint(
                equalToConstant: 20
            ),

            // Spinner

            loadingIndicator.leadingAnchor.constraint(
                equalTo: loadingContainer.leadingAnchor
            ),

            loadingIndicator.centerYAnchor.constraint(
                equalTo: loadingContainer.centerYAnchor
            ),

            loadingIndicator.widthAnchor.constraint(
                equalToConstant: 16
            ),

            loadingIndicator.heightAnchor.constraint(
                equalToConstant: 16
            ),

            // Processing IPA

            loadingLabel.leadingAnchor.constraint(
                equalTo: loadingIndicator.trailingAnchor,
                constant: 7
            ),

            loadingLabel.centerYAnchor.constraint(
                equalTo: loadingContainer.centerYAnchor
            ),

            loadingLabel.trailingAnchor.constraint(
                lessThanOrEqualTo:
                    loadingContainer.trailingAnchor
            ),

            // MARK: Footer

            footerLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            footerLabel.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -18
            )
        ])
    }

    // MARK: - Loading State

    private func setProcessing(
        _ processing: Bool
    ) {
        if processing {
            uploadButton.isEnabled = false

            importIcon.alphaValue = 0.35
            importTitleLabel.alphaValue = 0.35
            importSubtitleLabel.alphaValue = 0.35

            loadingContainer.isHidden = false
            loadingIndicator.startAnimation(nil)

        } else {
            uploadButton.isEnabled = true

            importIcon.alphaValue = 1
            importTitleLabel.alphaValue = 1
            importSubtitleLabel.alphaValue = 1

            loadingIndicator.stopAnimation(nil)
            loadingContainer.isHidden = true
        }
    }

    // MARK: - Select IPA

    @objc private func uploadFile() {
        let dialog = NSOpenPanel()

        dialog.title = "Select an IPA file"
        dialog.prompt = "Open"

        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        dialog.canChooseFiles = true
        if let ipaType = UTType(filenameExtension: "ipa") {
            dialog.allowedContentTypes = [ipaType]
        }

        dialog.level = .modalPanel

        if let documentsURL =
            FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first {

            dialog.directoryURL =
                documentsURL
        }

        guard
            dialog.runModal() == .OK,
            let selectedFile = dialog.url
        else {
            return
        }

        ipaNameLabel.stringValue =
            selectedFile.lastPathComponent

        ipaFileName =
            selectedFile
                .deletingPathExtension()
                .lastPathComponent

        extractPayloadFromIPA(
            path: selectedFile
        )
    }

    // MARK: - Extract IPA

    private func extractPayloadFromIPA(
        path: URL
    ) {
        let workingDirectory =
            FileManager.default
                .temporaryDirectory
                .appendingPathComponent(
                    "ModIPA-\(UUID().uuidString)",
                    isDirectory: true
                )

        let zipURL =
            workingDirectory
                .appendingPathExtension(
                    "zip"
                )

        ipaCopy =
            workingDirectory.path

        try? FileManager.default.removeItem(
            at: workingDirectory
        )

        try? FileManager.default.removeItem(
            at: zipURL
        )

        setProcessing(true)

        DispatchQueue.global(
            qos: .userInitiated
        ).async {

            do {
                self.currentlyExtracting = true

                try FileManager.default.copyItem(
                    at: path,
                    to: zipURL
                )

                try FileManager.default.unzipItem(
                    at: zipURL,
                    to: workingDirectory
                )

                if FileManager.default.fileExists(
                    atPath: zipURL.path
                ) {
                    try FileManager.default.removeItem(
                        at: zipURL
                    )
                }

                let payloadPath =
                    workingDirectory
                        .appendingPathComponent(
                            "Payload"
                        )

                let payloadContents =
                    try FileManager.default
                        .contentsOfDirectory(
                            at: payloadPath,
                            includingPropertiesForKeys: nil,
                            options: [
                                .skipsSubdirectoryDescendants,
                                .skipsHiddenFiles
                            ]
                        )

                guard
                    let appBundle =
                        payloadContents.first(
                            where: {
                                $0.pathExtension
                                    .lowercased()
                                    == "app"
                            }
                        )
                else {
                    throw NSError(
                        domain: "ModIPA",
                        code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "No app bundle found in Payload"
                        ]
                    )
                }

                let infoPlistPath =
                    appBundle
                        .appendingPathComponent(
                            "Info.plist"
                        )

                guard
                    FileManager.default.fileExists(
                        atPath:
                            infoPlistPath.path
                    ),
                    NSDictionary(
                        contentsOfFile:
                            infoPlistPath.path
                    ) != nil
                else {
                    throw NSError(
                        domain: "ModIPA",
                        code: 2,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Failed to load Info.plist"
                        ]
                    )
                }

                self.appPath =
                    appBundle

                self.currentlyExtracting =
                    false

                DispatchQueue.main.async {
                    self.setProcessing(false)
                    self.openEditController()
                }

            } catch {
                self.currentlyExtracting =
                    false

                DispatchQueue.main.async {
                    self.setProcessing(false)

                    self.showErrorAlert(
                        message:
                            error.localizedDescription
                    )
                }
            }
        }
    }

    // MARK: - Edit Controller

    private func openEditController() {
        guard
            let editController =
                storyboard?
                    .instantiateController(
                        withIdentifier:
                            "EditController"
                    ) as? EditController
        else {
            showErrorAlert(
                message:
                    "EditController could not be loaded"
            )

            return
        }

        editController.appPath =
            appPath

        editController.ipaFileName =
            ipaFileName

        view.window?.contentViewController =
            editController
    }

    // MARK: - GitHub

    @objc private func openGitHubLink() {
        guard
            let url = URL(
                string:
                    "https://github.com/thcvors/ModIPA"
            )
        else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    // MARK: - Cleanup

    @objc private func applicationWillTerminate(
        notification: Notification
    ) {
        if currentlyExtracting {
            removeTemporaryFiles()
        }
    }

    private func removeTemporaryFiles() {
        guard !ipaCopy.isEmpty else {
            return
        }

        let workingDirectory =
            URL(
                fileURLWithPath:
                    ipaCopy
            )

        let zipURL =
            workingDirectory
                .appendingPathExtension(
                    "zip"
                )

        do {
            if FileManager.default.fileExists(
                atPath:
                    zipURL.path
            ) {
                try FileManager.default.removeItem(
                    at: zipURL
                )
            }

            if FileManager.default.fileExists(
                atPath:
                    workingDirectory.path
            ) {
                try FileManager.default.removeItem(
                    at: workingDirectory
                )
            }

        } catch {
            print(
                "Temporary file cleanup failed:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Error

    private func showErrorAlert(
        message: String
    ) {
        let alert = NSAlert()

        alert.messageText =
            "Error"

        alert.informativeText =
            message

        alert.alertStyle =
            .critical

        alert.addButton(
            withTitle: "OK"
        )

        alert.runModal()
    }
}
