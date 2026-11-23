// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ClipsyKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(
            name: "ClipsyKit",
            targets: ["Store", "Capture", "Media", "Pasting", "DesignSystem", "ShelfUI", "Updates", "Integrations"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.12.0"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.4.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.10.1")
    ],
    targets: [
        .target(name: "Store", dependencies: [.product(name: "GRDB", package: "GRDB.swift")]),
        .target(name: "Capture", dependencies: ["Store"]),
        .target(name: "Media", dependencies: ["Store"]),
        .target(name: "Pasting", dependencies: ["Store"]),
        .target(name: "DesignSystem"),
        .target(
            name: "ShelfUI",
            dependencies: [
                "DesignSystem", "Pasting", "Media", "Store",
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ]
        ),
        .target(name: "Updates", dependencies: [.product(name: "Sparkle", package: "Sparkle")]),
        .target(name: "Integrations", dependencies: ["Capture", "DesignSystem", "Store"]),
        .testTarget(name: "StoreTests", dependencies: ["Store"]),
        .testTarget(name: "CaptureTests", dependencies: ["Capture"]),
        .testTarget(name: "MediaTests", dependencies: ["Media"]),
        .testTarget(name: "PastingTests", dependencies: ["Pasting"]),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"]),
        .testTarget(name: "ShelfUITests", dependencies: ["ShelfUI"]),
        .testTarget(
            name: "SnapshotTests",
            dependencies: ["Capture", "DesignSystem", "Media", "Pasting", "ShelfUI", "Store", "Updates"],
            // `App` is a symlink to the app target's folder; a new file there belongs in `sources` or `exclude`
            exclude: [
                "App/AppDelegate.swift", "App/AppIcon.icon", "App/ClipsyApp.swift", "App/ClipsyApp+URLScheme.swift",
                "App/PasteboardAccessAlert.swift", "App/SettingsWindow.swift", "App/StatusItemController.swift",
                "App/Intents", "App/Sounds", "App/Credits.rtf", "App/Localizable.xcstrings"
            ],
            sources: [
                "AppSnapshotTests.swift", "ComponentGallerySnapshotTests.swift", "PopoverSnapshotTests.swift",
                "SearchSuggestionLayerTests.swift", "ShelfContrastTests.swift", "ShelfSnapshotTests.swift",
                "SnapshotFixtures.swift", "SnapshotRenderer.swift",
                "App/SettingsView.swift", "App/GeneralSettingsView.swift", "App/ShortcutsSettingsView.swift",
                "App/PrivacySettingsView.swift", "App/AboutSettingsView.swift", "App/AcknowledgementsView.swift",
                "App/OnboardingView.swift", "App/PermissionStatusLabel.swift", "App/MenuBarSettings.swift",
                "App/RetentionPeriod+Title.swift"
            ]
        ),
        .testTarget(name: "UpdatesTests", dependencies: ["Updates"]),
        .testTarget(name: "IntegrationsTests", dependencies: ["Integrations"])
    ]
)
