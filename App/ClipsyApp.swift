import AppIntents
import AppKit
import Capture
import DesignSystem
import Integrations
import Media
import os
import Pasting
import ShelfUI
import Store
import SwiftUI
import Updates

@main
struct ClipsyApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var shelf: ShelfController
    @State private var retention: RetentionSettings
    @State private var privacy: PrivacySettings
    @State private var menuBarSettings: MenuBarSettings
    @State private var statusItem: StatusItemController
    @State private var updater: AppUpdater
    @State private var shortcuts = ShortcutSettings(store: KeyboardShortcutsStore())
    @State private var onboarding = Self.startOnboarding()

    init() {
        let repository = CardRepository(database: Self.openDatabase())
        AppDependencyManager.shared.add(dependency: CardIntentHandler(repository: repository))
        let writer = PasteboardWriter()
        let privacy = PrivacySettings()
        _privacy = State(initialValue: privacy)
        let pause = CapturePause()
        let monitor = PasteboardMonitor(
            isOwnWrite: { writer.isOwnWrite($0) },
            policy: { Self.capturePolicy(privacy: privacy, pause: pause) },
            repository: repository
        )
        _ = Task {
            try await monitor.run()
        }
        let retention = RetentionSettings(repository: repository)
        _ = Task {
            try await retention.runPurgeSchedule()
        }
        _retention = State(initialValue: retention)

        let linkPreviews = Self.startLinkPreviews(repository: repository, privacy: privacy)

        let paster = PasteCoordinator(writer: writer) { try await repository.representations(of: $0) }
        let sequence = Self.runSequence(writer: writer, paster: paster, repository: repository)
        let shelf = Self.makeShelf(repository: repository, paster: paster, sequence: sequence)
        shelf.commands.isCapturePaused = { pause.isPaused }
        shelf.commands.setCapturePaused = { $0 ? pause.pause(.untilResumed) : pause.resume() }
        shelf.commands.openSettings = { SettingsWindow.open() }
        shelf.commands.startSequence = { sequence.start(shelfSelection: shelf.selectedCardIDs) }
        _shelf = State(initialValue: shelf)
        Self.apply(privacy, to: shelf, textRecognition: TextRecognitionQueue(repository: repository))
        Self.runSequencePanel(
            sequence: sequence,
            repository: repository,
            monitor: monitor,
            privacy: privacy,
            shelf: shelf
        )
        KeyboardShortcuts.onKeyUp(for: .toggleShelf) {
            shelf.toggle()
        }

        let updater = Self.startUpdater()
        _updater = State(initialValue: updater)
        let menuBarSettings = MenuBarSettings()
        _menuBarSettings = State(initialValue: menuBarSettings)
        let statusItem = StatusItemController(
            pause: pause,
            settings: menuBarSettings,
            updater: updater,
            openShelf: { shelf.show() },
            newTextCard: { shelf.showNewTextCard(text: "") },
            startSequence: { sequence.start(shelfSelection: shelf.selectedCardIDs) }
        )
        _statusItem = State(initialValue: statusItem)
        _ = Task {
            await statusItem.run()
        }
        Self.startCaptureEffects(of: monitor, statusItem: statusItem, linkPreviews: linkPreviews, sequence: sequence)
        Self.handleEvents(of: appDelegate, shelf: shelf, menuBarSettings: menuBarSettings)
    }

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(retention)
                .environment(privacy)
                .environment(menuBarSettings)
                .environment(shortcuts)
                .environment(onboarding.access)
                .environment(updater)
        }
        Window("Welcome to Clipsy", id: OnboardingView.windowID) {
            OnboardingView()
                .environment(onboarding)
                .environment(onboarding.access)
                .environment(retention)
                .environment(privacy)
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .defaultLaunchBehavior(onboarding.presentsAtLaunch ? .presented : .suppressed)
    }

    private static func startOnboarding() -> OnboardingFlow {
        let access = PasteboardAccess()
        let onboarding = OnboardingFlow(access: access)
        if !onboarding.presentsAtLaunch {
            _ = Task {
                PasteboardAccessAlert.presentIfNeeded(access: access)
            }
        }
        _ = Task {
            for await _ in NSWorkspace.shared.notificationCenter.notifications(named: NSWorkspace.didWakeNotification) {
                PasteboardAccessAlert.presentIfNeeded(access: access)
            }
        }
        return onboarding
    }

    private static func startUpdater() -> AppUpdater {
        let updater = AppUpdater(driver: SparkleUpdaterDriver())
        do {
            try updater.startIfAutomatic()
        } catch {
            Logger(subsystem: "app.gonar.clipsy", category: "Updates")
                .error("the updater failed to start: \(String(describing: type(of: error)), privacy: .public)")
        }
        return updater
    }

    private static func handleEvents(
        of appDelegate: AppDelegate,
        shelf: ShelfController,
        menuBarSettings: MenuBarSettings
    ) {
        appDelegate.onReopen = {
            if !menuBarSettings.isItemShown {
                SettingsWindow.open()
            }
        }
        appDelegate.onOpenURLs = { open($0, shelf: shelf) }
    }

    private static func apply(
        _ privacy: PrivacySettings,
        to shelf: ShelfController,
        textRecognition: TextRecognitionQueue
    ) {
        _ = Task {
            for await isShown in Observations({ privacy.showsShelfInScreenCapture }) {
                shelf.isShownInScreenCapture = isShown
            }
        }
        _ = Task {
            try await textRecognition.run()
        }
        _ = Task {
            for await isEnabled in Observations({ privacy.recognizesTextInImages }) {
                await textRecognition.setEnabled(isEnabled)
            }
        }
    }

    private static func makeShelf(
        repository: CardRepository,
        paster: PasteCoordinator,
        sequence: SequenceCoordinator
    ) -> ShelfController {
        let model = ShelfModel(
            observe: { repository.observeCards(in: $0) },
            observeBoards: { repository.observeBoards() },
            observeSearch: { repository.observeSearch($0, filter: $1) },
            observeApps: { repository.observeSourceApps() }
        )
        return ShelfController(
            model: model,
            paster: paster,
            deletion: CardDeletion(
                delete: { try await repository.delete(cards: $0, in: $1) },
                restore: { try await repository.restore($0) }
            ),
            boardEditor: BoardEditor(
                model: model,
                create: { try await repository.createBoard(named: $0, color: $1) },
                rename: { try await repository.renameBoard($0, to: $1) },
                recolor: { try await repository.recolorBoard($0, to: $1) },
                move: { try await repository.moveBoard($0, after: $1) },
                delete: { try await repository.deleteBoard($0) },
                addCards: { try await repository.addCards($0, toBoard: $1) },
                moveCards: { try await repository.moveCards($0, after: $1) }
            ),
            representations: { try await repository.representations(of: $0) },
            rename: { try await repository.rename(card: $0, to: $1) },
            addToSequence: { sequence.add($0) },
            thumbnails: ThumbnailCache(directory: repository.thumbnailsDirectory),
            replaceText: { try await repository.replaceContent(of: $0, with: NewCard.editedText($1)) },
            addText: { try await repository.add(NewCard.editedText($0), to: $1) }
        )
    }

    private static func startLinkPreviews(repository: CardRepository, privacy: PrivacySettings) -> LinkPreviewFetcher {
        let linkPreviews = LinkPreviewFetcher(
            repository: repository,
            thumbnails: ThumbnailCache(directory: repository.thumbnailsDirectory),
            maxPixelSize: DesignTokens.thumbnailMaxPixelSize
        ) { privacy.fetchesLinkPreviews }
        _ = Task {
            try await linkPreviews.run()
        }
        return linkPreviews
    }

    private static func startCaptureEffects(
        of monitor: PasteboardMonitor,
        statusItem: StatusItemController,
        linkPreviews: LinkPreviewFetcher,
        sequence: SequenceCoordinator
    ) {
        let sounds = SoundEffects()
        _ = Task {
            for await id in monitor.capturedCardIDs {
                sounds.play(.capture)
                statusItem.bounce()
                linkPreviews.submit(id)
                sequence.didCapture(id)
            }
        }
    }

    private static func runSequencePanel(
        sequence: SequenceCoordinator,
        repository: CardRepository,
        monitor: PasteboardMonitor,
        privacy: PrivacySettings,
        shelf: ShelfController
    ) {
        let model = SequencePanelModel(
            sequence: sequence.sequence,
            loadCards: { try await repository.cards(withIDs: $0) },
            onPasteAll: { cardIDs in
                Task {
                    await sequence.pasteAll(cardIDs) { shelf.hideImmediately() }
                }
            }
        )
        let panel = SequencePanelController(model: model) {
            try await monitor.recordDrop(from: $0)
        }
        _ = Task {
            await panel.run()
        }
        _ = Task {
            for await isShown in Observations({ privacy.showsShelfInScreenCapture }) {
                panel.isShownInScreenCapture = isShown
            }
        }
        KeyboardShortcuts.onKeyUp(for: .startSequence) {
            sequence.start(shelfSelection: shelf.selectedCardIDs)
        }
        KeyboardShortcuts.onKeyUp(for: .pasteAllSequence) {
            model.pasteAll()
        }
    }

    private static func runSequence(
        writer: PasteboardWriter,
        paster: PasteCoordinator,
        repository: CardRepository
    ) -> SequenceCoordinator {
        let sequence = SequenceCoordinator(
            detector: SequencePasteDetector(mechanism: .dataProvider, writer: writer),
            paster: paster,
            representations: { try await repository.representations(of: $0) },
            loadCards: { try await repository.cards(withIDs: $0) }
        )
        _ = Task {
            try await sequence.run()
        }
        return sequence
    }

    private static func capturePolicy(privacy: PrivacySettings, pause: CapturePause) -> CapturePolicy {
        var policy = privacy.capturePolicy
        policy.isPaused = pause.isPaused
        return policy
    }

    /// migrations must finish before any UI shows (architecture §3.4), so this runs synchronously at launch
    private static func openDatabase() -> AppDatabase {
        let logger = Logger(subsystem: "app.gonar.clipsy", category: "Startup")
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { fatalError("the app has a bundle id") }
        do {
            let directory = AppDatabase.defaultDirectory(bundleIdentifier: bundleIdentifier)
            let opened = try AppDatabase.openRecoveringDamagedStore(directory: directory)
            if let backup = opened.backupDirectory {
                logger.error("the database was damaged and was moved aside")
                showRecoveryAlert(backup: backup)
            }
            return opened.database
        } catch {
            logger.fault("opening the database failed: \(String(describing: type(of: error)), privacy: .public)")
            let alert = NSAlert(error: error)
            alert.messageText = String(localized: "Clipsy can’t open its clipboard history.")
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: String(localized: "Quit Clipsy"))
            NSApplication.shared.activate()
            alert.runModal()
            exit(EXIT_FAILURE)
        }
    }

    private static func showRecoveryAlert(backup: URL) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = String(localized: "Clipsy’s clipboard history was damaged.")
        alert.informativeText = String(
            localized: "Clipsy moved it to “\(backup.path(percentEncoded: false))” and started a new, empty history."
        )
        alert.addButton(withTitle: String(localized: "OK"))
        alert.addButton(withTitle: String(localized: "Show in Finder"))
        NSApplication.shared.activate()
        if alert.runModal() == .alertSecondButtonReturn {
            NSWorkspace.shared.activateFileViewerSelecting([backup])
        }
    }
}
