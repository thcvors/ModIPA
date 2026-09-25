//
//  EditController.swift
//  ModIPA
//
//  Created by CVPRO on 12/01/24.
//

import Cocoa
import UniformTypeIdentifiers
import ZIPFoundation

final class EditController: NSViewController, NSTextFieldDelegate {

    // MARK: - IPA State

    var appPath = URL(fileURLWithPath: "")
    var plistPath = ""
    var ipaPlist = NSMutableDictionary()
    var iconImages: [URL] = []
    var ipaFileName = ""
    var lastVersion = ""

    private let windowSize = NSSize(width: 620, height: 540)

    private let appCategories = [
        "public.app-category.business",
        "public.app-category.developer-tools",
        "public.app-category.education",
        "public.app-category.entertainment",
        "public.app-category.finance",
        "public.app-category.games",
        "public.app-category.utilities",
        "public.app-category.video",
        "public.app-category.weather"
    ]

    // MARK: - Colors

    private let accentColor = NSColor(
        calibratedRed: 0.0,
        green: 0.58,
        blue: 1.0,
        alpha: 1.0
    )

    private let pageColor = NSColor(
        calibratedWhite: 0.985,
        alpha: 1.0
    )

    private let cardColor = NSColor.white

    private let fieldColor = NSColor(
        calibratedWhite: 0.975,
        alpha: 1.0
    )

    private let borderColor = NSColor(
        calibratedWhite: 0.86,
        alpha: 1.0
    )

    private let primaryTextColor = NSColor(
        calibratedWhite: 0.10,
        alpha: 1.0
    )

    private let secondaryTextColor = NSColor(
        calibratedWhite: 0.46,
        alpha: 1.0
    )

    // MARK: - Back

    private lazy var backButton: NSButton = {
        let image = NSImage(
            systemSymbolName: "chevron.left",
            accessibilityDescription: "Back"
        )

        let button = NSButton(
            title: "Back",
            target: self,
            action: #selector(goBack)
        )

        button.image = image
        button.imagePosition = .imageLeading
        button.imageHugsTitle = true

        button.isBordered = false
        button.bezelStyle = .inline

        button.font = .systemFont(
            ofSize: 12,
            weight: .medium
        )

        button.contentTintColor = NSColor(
            calibratedWhite: 0.30,
            alpha: 1.0
        )

        button.toolTip = "Back to Import"
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

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
            ofSize: 27,
            weight: .bold
        )

        label.textColor = .black
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    private let sectionTitleLabel: NSTextField = {
        let label = NSTextField(
            labelWithString: "Customize App"
        )

        label.font = .systemFont(
            ofSize: 15,
            weight: .semibold
        )

        label.textColor = NSColor(
            calibratedWhite: 0.15,
            alpha: 1.0
        )

        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    private let sectionDescriptionLabel: NSTextField = {
        let label = NSTextField(
            labelWithString:
                "Edit the app information before exporting the IPA"
        )

        label.font = .systemFont(
            ofSize: 11,
            weight: .regular
        )

        label.textColor = NSColor(
            calibratedWhite: 0.50,
            alpha: 1.0
        )

        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    // MARK: - Main Card

    private let mainCard: NSView = {
        let card = NSView()

        card.wantsLayer = true
        card.layer?.cornerRadius = 18
        card.layer?.cornerCurve = .continuous
        card.translatesAutoresizingMaskIntoConstraints = false

        return card
    }()

    // MARK: - App Icon

    private let iconImageView: NSImageView = {
        let imageView = NSImageView()

        imageView.imageScaling = .scaleProportionallyUpOrDown

        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 15
        imageView.layer?.cornerCurve = .continuous
        imageView.layer?.masksToBounds = true

        imageView.layer?.backgroundColor = NSColor(
            calibratedWhite: 0.94,
            alpha: 1.0
        ).cgColor

        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
    }()

    private let iconTitleLabel: NSTextField = {
        let label = NSTextField(
            labelWithString: "App Icon"
        )

        label.font = .systemFont(
            ofSize: 13,
            weight: .semibold
        )

        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    private let iconDescriptionLabel: NSTextField = {
        let label = NSTextField(
            labelWithString: "PNG image"
        )

        label.font = .systemFont(
            ofSize: 10,
            weight: .regular
        )

        label.textColor = NSColor(
            calibratedWhite: 0.48,
            alpha: 1.0
        )

        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    private lazy var selectIconButton: NSButton = {
        let button = NSButton(
            title: "Change",
            target: self,
            action: #selector(selectIcon)
        )

        button.isBordered = false
        button.wantsLayer = true

        button.layer?.cornerRadius = 8
        button.layer?.cornerCurve = .continuous

        button.layer?.backgroundColor = NSColor(
            calibratedWhite: 0.94,
            alpha: 1.0
        ).cgColor

        button.font = .systemFont(
            ofSize: 12,
            weight: .medium
        )

        button.contentTintColor = NSColor(
            calibratedWhite: 0.12,
            alpha: 1.0
        )

        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    // MARK: - Fields

    private lazy var displayNameField: NSTextField = {
        let field = makeTextField()
        field.delegate = self
        return field
    }()

    private lazy var bundleIDField: NSTextField = {
        let field = makeTextField()
        field.delegate = self
        return field
    }()

    private lazy var versionField: NSTextField = {
        let field = makeTextField()
        field.delegate = self
        return field
    }()

    private let categoryPicker: NSPopUpButton = {
        let picker = NSPopUpButton()

        picker.controlSize = .regular

        picker.font = .systemFont(
            ofSize: 11,
            weight: .regular
        )

        picker.translatesAutoresizingMaskIntoConstraints = false

        return picker
    }()

    // MARK: - Export

    private lazy var exportButton: NSButton = {
        let button = NSButton(
            title: "Export IPA",
            target: self,
            action: #selector(saveNewFile)
        )

        button.isBordered = false
        button.wantsLayer = true

        button.layer?.cornerRadius = 10
        button.layer?.cornerCurve = .continuous
        button.layer?.backgroundColor = accentColor.cgColor

        button.font = .systemFont(
            ofSize: 13,
            weight: .semibold
        )

        button.contentTintColor = .white
        button.keyEquivalent = "\r"
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    // MARK: - Export Spinner

    private let exportLoadingContainer: NSView = {
        let view = NSView()

        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private let exportIndicator: NSProgressIndicator = {
        let indicator = NSProgressIndicator()

        indicator.style = .spinning
        indicator.controlSize = .small
        indicator.isIndeterminate = true
        indicator.isDisplayedWhenStopped = false

        indicator.translatesAutoresizingMaskIntoConstraints = false

        return indicator
    }()

    private let exportLoadingLabel: NSTextField = {
        let label = NSTextField(
            labelWithString: "Exporting IPA"
        )

        label.font = .systemFont(
            ofSize: 11,
            weight: .medium
        )

        label.textColor = NSColor(
            calibratedWhite: 0.48,
            alpha: 1.0
        )

        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    // MARK: - Lifecycle

    override func loadView() {
        let rootView = NSView()

        rootView.wantsLayer = true
        rootView.layer?.backgroundColor = pageColor.cgColor

        view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupInterface()

        mainCard.layer?.backgroundColor = cardColor.cgColor
        mainCard.layer?.borderWidth = 1
        mainCard.layer?.borderColor = borderColor.cgColor

        categoryPicker.target = self
        categoryPicker.action = #selector(categoryValueDidChange)
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        guard plistPath.isEmpty else {
            return
        }

        loadAppInformation()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        configureWindow()
    }

    // MARK: - Window

    private func configureWindow() {
        guard let window = view.window else {
            return
        }

        window.title = "ModIPA"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        window.styleMask.insert(
            .fullSizeContentView
        )

        window.isMovableByWindowBackground = true

        window.setContentSize(windowSize)
        window.minSize = windowSize
        window.maxSize = windowSize

        window.backgroundColor = pageColor

        // Keep this screen light even when macOS is using Dark Mode
        window.appearance = NSAppearance(
            named: .aqua
        )
    }

    // MARK: - Interface

    private func setupInterface() {

        view.addSubview(backButton)
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(sectionTitleLabel)
        view.addSubview(sectionDescriptionLabel)
        view.addSubview(mainCard)

        mainCard.addSubview(iconImageView)
        mainCard.addSubview(iconTitleLabel)
        mainCard.addSubview(iconDescriptionLabel)
        mainCard.addSubview(selectIconButton)

        let displayNameGroup = makeFieldGroup(
            title: "App Display Name",
            control: displayNameField
        )

        let bundleIDGroup = makeFieldGroup(
            title: "Bundle ID",
            control: bundleIDField
        )

        let versionGroup = makeFieldGroup(
            title: "Version",
            control: versionField
        )

        let categoryGroup = makeFieldGroup(
            title: "Category",
            control: categoryPicker
        )

        mainCard.addSubview(displayNameGroup)
        mainCard.addSubview(bundleIDGroup)
        mainCard.addSubview(versionGroup)
        mainCard.addSubview(categoryGroup)

        view.addSubview(exportButton)
        view.addSubview(exportLoadingContainer)

        exportLoadingContainer.addSubview(
            exportIndicator
        )

        exportLoadingContainer.addSubview(
            exportLoadingLabel
        )

        NSLayoutConstraint.activate([

            // MARK: Back

            backButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 22
            ),

            backButton.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: 24
            ),

            backButton.widthAnchor.constraint(
                equalToConstant: 70
            ),

            backButton.heightAnchor.constraint(
                equalToConstant: 28
            ),

            // MARK: Logo

            logoImageView.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            logoImageView.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: 32
            ),

            logoImageView.widthAnchor.constraint(
                equalToConstant: 28
            ),

            logoImageView.heightAnchor.constraint(
                equalToConstant: 28
            ),

            // MARK: ModIPA

            titleLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            titleLabel.topAnchor.constraint(
                equalTo: logoImageView.bottomAnchor,
                constant: 5
            ),

            // MARK: Customize App

            sectionTitleLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            sectionTitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 5
            ),

            sectionDescriptionLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            sectionDescriptionLabel.topAnchor.constraint(
                equalTo: sectionTitleLabel.bottomAnchor,
                constant: 3
            ),

            // MARK: Main Card

            mainCard.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 45
            ),

            mainCard.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -45
            ),

            mainCard.topAnchor.constraint(
                equalTo: sectionDescriptionLabel.bottomAnchor,
                constant: 17
            ),

            mainCard.heightAnchor.constraint(
                equalToConstant: 270
            ),

            // MARK: App Icon

            iconImageView.leadingAnchor.constraint(
                equalTo: mainCard.leadingAnchor,
                constant: 16
            ),

            iconImageView.topAnchor.constraint(
                equalTo: mainCard.topAnchor,
                constant: 16
            ),

            iconImageView.widthAnchor.constraint(
                equalToConstant: 68
            ),

            iconImageView.heightAnchor.constraint(
                equalToConstant: 68
            ),

            iconTitleLabel.leadingAnchor.constraint(
                equalTo: iconImageView.trailingAnchor,
                constant: 13
            ),

            iconTitleLabel.topAnchor.constraint(
                equalTo: iconImageView.topAnchor,
                constant: 12
            ),

            iconDescriptionLabel.leadingAnchor.constraint(
                equalTo: iconTitleLabel.leadingAnchor
            ),

            iconDescriptionLabel.topAnchor.constraint(
                equalTo: iconTitleLabel.bottomAnchor,
                constant: 4
            ),

            selectIconButton.trailingAnchor.constraint(
                equalTo: mainCard.trailingAnchor,
                constant: -16
            ),

            selectIconButton.centerYAnchor.constraint(
                equalTo: iconImageView.centerYAnchor
            ),

            selectIconButton.widthAnchor.constraint(
                equalToConstant: 86
            ),

            selectIconButton.heightAnchor.constraint(
                equalToConstant: 30
            ),

            // MARK: Display Name

            displayNameGroup.leadingAnchor.constraint(
                equalTo: mainCard.leadingAnchor,
                constant: 16
            ),

            displayNameGroup.trailingAnchor.constraint(
                equalTo: mainCard.trailingAnchor,
                constant: -16
            ),

            displayNameGroup.topAnchor.constraint(
                equalTo: iconImageView.bottomAnchor,
                constant: 13
            ),

            displayNameGroup.heightAnchor.constraint(
                equalToConstant: 48
            ),

            // MARK: Bundle ID

            bundleIDGroup.leadingAnchor.constraint(
                equalTo: displayNameGroup.leadingAnchor
            ),

            bundleIDGroup.trailingAnchor.constraint(
                equalTo: displayNameGroup.trailingAnchor
            ),

            bundleIDGroup.topAnchor.constraint(
                equalTo: displayNameGroup.bottomAnchor,
                constant: 7
            ),

            bundleIDGroup.heightAnchor.constraint(
                equalToConstant: 48
            ),

            // MARK: Version

            versionGroup.leadingAnchor.constraint(
                equalTo: displayNameGroup.leadingAnchor
            ),

            versionGroup.topAnchor.constraint(
                equalTo: bundleIDGroup.bottomAnchor,
                constant: 7
            ),

            versionGroup.widthAnchor.constraint(
                equalToConstant: 232
            ),

            versionGroup.heightAnchor.constraint(
                equalToConstant: 48
            ),

            // MARK: Category

            categoryGroup.trailingAnchor.constraint(
                equalTo: displayNameGroup.trailingAnchor
            ),

            categoryGroup.topAnchor.constraint(
                equalTo: versionGroup.topAnchor
            ),

            categoryGroup.widthAnchor.constraint(
                equalToConstant: 232
            ),

            categoryGroup.heightAnchor.constraint(
                equalToConstant: 48
            ),

            // MARK: Export

            exportButton.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            exportButton.topAnchor.constraint(
                equalTo: mainCard.bottomAnchor,
                constant: 15
            ),

            exportButton.widthAnchor.constraint(
                equalToConstant: 215
            ),

            exportButton.heightAnchor.constraint(
                equalToConstant: 38
            ),

            // MARK: Export Spinner

            exportLoadingContainer.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            exportLoadingContainer.topAnchor.constraint(
                equalTo: exportButton.bottomAnchor,
                constant: 7
            ),

            exportLoadingContainer.widthAnchor.constraint(
                equalToConstant: 120
            ),

            exportLoadingContainer.heightAnchor.constraint(
                equalToConstant: 18
            ),

            exportIndicator.leadingAnchor.constraint(
                equalTo: exportLoadingContainer.leadingAnchor
            ),

            exportIndicator.centerYAnchor.constraint(
                equalTo: exportLoadingContainer.centerYAnchor
            ),

            exportIndicator.widthAnchor.constraint(
                equalToConstant: 15
            ),

            exportIndicator.heightAnchor.constraint(
                equalToConstant: 15
            ),

            exportLoadingLabel.leadingAnchor.constraint(
                equalTo: exportIndicator.trailingAnchor,
                constant: 7
            ),

            exportLoadingLabel.centerYAnchor.constraint(
                equalTo: exportLoadingContainer.centerYAnchor
            )
        ])
    }

    // MARK: - Text Field UI

    private func makeTextField() -> NSTextField {
        let field = NSTextField()

        field.font = .systemFont(
            ofSize: 12,
            weight: .regular
        )

        field.textColor = primaryTextColor
        field.backgroundColor = fieldColor

        field.isBezeled = true
        field.bezelStyle = .roundedBezel
        field.isBordered = true
        field.drawsBackground = true
        field.focusRingType = .default

        field.translatesAutoresizingMaskIntoConstraints = false

        return field
    }

    private func makeFieldGroup(
        title: String,
        control: NSView
    ) -> NSView {

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = NSTextField(
            labelWithString: title
        )

        label.font = .systemFont(
            ofSize: 10,
            weight: .medium
        )

        label.textColor = secondaryTextColor
        label.translatesAutoresizingMaskIntoConstraints = false

        control.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)
        container.addSubview(control)

        NSLayoutConstraint.activate([

            label.leadingAnchor.constraint(
                equalTo: container.leadingAnchor
            ),

            label.topAnchor.constraint(
                equalTo: container.topAnchor
            ),

            control.leadingAnchor.constraint(
                equalTo: container.leadingAnchor
            ),

            control.trailingAnchor.constraint(
                equalTo: container.trailingAnchor
            ),

            control.topAnchor.constraint(
                equalTo: label.bottomAnchor,
                constant: 4
            ),

            control.heightAnchor.constraint(
                equalToConstant: 30
            )
        ])

        return container
    }

    // MARK: - Load Info.plist

    private func loadAppInformation() {

        plistPath = appPath
            .appendingPathComponent(
                "Info.plist"
            )
            .path

        guard let plist =
                NSMutableDictionary(
                    contentsOfFile: plistPath
                )
        else {
            alert(
                text: "Failed to load Info.plist"
            )
            return
        }

        ipaPlist = plist

        lastVersion =
            ipaPlist["CFBundleVersion"]
            as? String
            ?? "1.0"

        versionField.stringValue =
            lastVersion

        displayNameField.stringValue =
            ipaPlist["CFBundleDisplayName"]
            as? String
            ?? ipaPlist["CFBundleName"]
            as? String
            ?? "App Name"

        bundleIDField.stringValue =
            ipaPlist["CFBundleIdentifier"]
            as? String
            ?? "bundleident.app"

        categoryPicker.removeAllItems()

        categoryPicker.addItems(
            withTitles: appCategories
        )

        if let currentCategory =
            ipaPlist[
                "LSApplicationCategoryType"
            ] as? String,
           appCategories.contains(
                currentCategory
           ) {

            categoryPicker.selectItem(
                withTitle: currentCategory
            )

        } else {

            categoryPicker.selectItem(
                withTitle:
                    "public.app-category.developer-tools"
            )
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.2
        ) {
            self.loadIcons()
        }
    }

    // MARK: - Load Icons

    private func loadIcons() {

        iconImages.removeAll()

        if
            let iconsDictionary =
                ipaPlist["CFBundleIcons"]
                as? [String: Any],

            let primaryIcon =
                iconsDictionary[
                    "CFBundlePrimaryIcon"
                ] as? [String: Any],

            let iconFiles =
                primaryIcon[
                    "CFBundleIconFiles"
                ] as? [String] {

            let contents =
                try? FileManager.default
                    .contentsOfDirectory(
                        at: appPath,
                        includingPropertiesForKeys: nil
                    )

            for iconName in iconFiles {

                let matches =
                    contents?.filter {
                        $0.lastPathComponent
                            .contains(iconName)
                    }

                if let matchedIcon =
                    matches?.last,
                   let image =
                    NSImage(
                        contentsOf: matchedIcon
                    ) {

                    iconImages.append(
                        matchedIcon
                    )

                    iconImageView.image =
                        image
                }
            }
        }

        if !iconImages.isEmpty {
            return
        }

        let fallbackIcons =
            (
                try? FileManager.default
                    .contentsOfDirectory(
                        at: appPath,
                        includingPropertiesForKeys: [
                            .fileSizeKey
                        ]
                    )
            )?
            .filter {
                $0.pathExtension
                    .lowercased() == "png"
            }
            .sorted {

                let leftSize =
                    (
                        try? $0.resourceValues(
                            forKeys: [.fileSizeKey]
                        ).fileSize
                    ) ?? 0

                let rightSize =
                    (
                        try? $1.resourceValues(
                            forKeys: [.fileSizeKey]
                        ).fileSize
                    ) ?? 0

                return leftSize > rightSize
            }

        if let fallback =
            fallbackIcons?.first,
           let image =
            NSImage(
                contentsOf: fallback
            ) {

            iconImages = [
                fallback
            ]

            iconImageView.image =
                image

        } else {

            iconImageView.image =
                NSImage(
                    systemSymbolName:
                        "app.dashed",
                    accessibilityDescription:
                        "App Icon"
                )

            iconImageView.contentTintColor =
                secondaryTextColor
        }
    }

    // MARK: - Change Icon

    @objc private func selectIcon() {

        let dialog = NSOpenPanel()

        dialog.title =
            "Select an image to use as the app icon"

        dialog.prompt =
            "Select"

        dialog.allowedContentTypes = [.png]

        dialog.allowsMultipleSelection =
            false

        dialog.canChooseDirectories =
            false

        dialog.canChooseFiles =
            true

        guard
            dialog.runModal() == .OK,
            let url = dialog.url,
            let uploadedImage =
                NSImage(contentsOf: url)
        else {
            return
        }

        guard !iconImages.isEmpty else {

            alert(
                text:
                    "No replaceable app icon files were found"
            )

            return
        }

        for iconURL in iconImages {

            guard uploadedImage.saveAsPNG(
                to: iconURL
            ) else {

                alert(
                    text:
                        "Failed to save the new app icon"
                )

                return
            }
        }

        iconImageView.image =
            uploadedImage
    }

    // MARK: - Category

    @objc private func categoryValueDidChange(
        _ sender: NSPopUpButton
    ) {

        guard !plistPath.isEmpty else {
            return
        }

        ipaPlist[
            "LSApplicationCategoryType"
        ] =
            sender.titleOfSelectedItem
            ?? ""

        writePlist()
    }

    // MARK: - Text Editing

    func controlTextDidEndEditing(
        _ notification: Notification
    ) {

        guard
            let textField =
                notification.object
                as? NSTextField
        else {
            return
        }

        if textField === displayNameField {

            ipaPlist[
                "CFBundleDisplayName"
            ] =
                textField.stringValue

        } else if textField === versionField {

            saveVersion(
                textField.stringValue
            )

        } else if textField === bundleIDField {

            ipaPlist[
                "CFBundleIdentifier"
            ] =
                textField.stringValue
        }

        writePlist()
    }

    private func saveVersion(
        _ newVersion: String
    ) {

        let cleanedVersion =
            newVersion.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanedVersion.isEmpty else {

            versionField.stringValue =
                lastVersion

            return
        }

        lastVersion =
            cleanedVersion

        ipaPlist[
            "CFBundleVersion"
        ] =
            cleanedVersion

        ipaPlist[
            "CFBundleShortVersionString"
        ] =
            cleanedVersion
    }

    // MARK: - Write Plist

    private func writePlist() {

        guard !plistPath.isEmpty else {
            return
        }

        let success =
            ipaPlist.write(
                toFile: plistPath,
                atomically: true
            )

        if !success {

            alert(
                text:
                    "Failed to save Info.plist"
            )
        }
    }

    // MARK: - Export State

    private func setExporting(
        _ exporting: Bool
    ) {

        exportButton.isEnabled =
            !exporting

        backButton.isEnabled =
            !exporting

        selectIconButton.isEnabled =
            !exporting

        displayNameField.isEnabled =
            !exporting

        bundleIDField.isEnabled =
            !exporting

        versionField.isEnabled =
            !exporting

        categoryPicker.isEnabled =
            !exporting

        if exporting {

            exportButton.alphaValue =
                0.50

            exportLoadingContainer.isHidden =
                false

            exportIndicator.startAnimation(
                nil
            )

        } else {

            exportButton.alphaValue =
                1.0

            exportIndicator.stopAnimation(
                nil
            )

            exportLoadingContainer.isHidden =
                true
        }
    }

    // MARK: - Export IPA

    @objc private func saveNewFile() {

        view.window?.makeFirstResponder(
            nil
        )

        writePlist()

        setExporting(
            true
        )

        let payloadDirectory =
            appPath
                .deletingLastPathComponent()

        let workingDirectory =
            payloadDirectory
                .deletingLastPathComponent()

        let exportPath =
            workingDirectory
                .appendingPathComponent(
                    "\(ipaFileName) [ModIPA].ipa"
                )

        DispatchQueue.global(
            qos: .userInitiated
        ).async {

            do {

                if FileManager.default
                    .fileExists(
                        atPath:
                            exportPath.path
                    ) {

                    try FileManager.default
                        .removeItem(
                            at: exportPath
                        )
                }

                try FileManager.default
                    .zipItem(
                        at: payloadDirectory,
                        to: exportPath
                    )

                DispatchQueue.main.async {

                    self.setExporting(
                        false
                    )

                    self.alert(
                        text:
                            "Modified IPA saved successfully"
                    )

                    NSWorkspace.shared
                        .selectFile(
                            exportPath.path,
                            inFileViewerRootedAtPath:
                                ""
                        )
                }

            } catch {

                DispatchQueue.main.async {

                    self.setExporting(
                        false
                    )

                    self.alert(
                        text:
                            "Failed to generate modified IPA\n\(error.localizedDescription)"
                    )
                }
            }
        }
    }

    // MARK: - Back to Import

    @objc private func goBack() {

        view.window?.makeFirstResponder(
            nil
        )

        guard
            let controller =
                storyboard?
                    .instantiateController(
                        withIdentifier:
                            "ViewController"
                    )
                as? ViewController
        else {

            alert(
                text:
                    "Unable to return to the import screen"
            )

            return
        }

        view.window?
            .contentViewController =
            controller
    }

    // MARK: - Alert

    private func alert(
        text: String
    ) {

        DispatchQueue.main.async {

            let alert =
                NSAlert()

            alert.messageText =
                text

            alert.alertStyle =
                .warning

            alert.addButton(
                withTitle: "OK"
            )

            alert.runModal()
        }
    }
}

// MARK: - NSImage

extension NSImage {

    @discardableResult
    func saveAsPNG(
        to url: URL
    ) -> Bool {

        guard
            let tiffData =
                tiffRepresentation,

            let imageRepresentation =
                NSBitmapImageRep(
                    data: tiffData
                ),

            let pngData =
                imageRepresentation
                    .representation(
                        using: .png,
                        properties: [:]
                    )
        else {
            return false
        }

        do {

            try pngData.write(
                to: url,
                options: .atomic
            )

            return true

        } catch {

            print(
                "Failed to save PNG:",
                error.localizedDescription
            )

            return false
        }
    }
}
