import AppKit
import Capture
import ShelfUI
import Updates

final class StatusItemController: NSObject, NSMenuDelegate {
    private static let helpURL = url("https://github.com/alekseylopukh/clipsy")
    private static let issueURL = url("https://github.com/alekseylopukh/clipsy/issues/new")

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let iconView = NSImageView()
    private let menu = NSMenu()
    private let pause: CapturePause
    private let settings: MenuBarSettings
    private let updater: AppUpdater
    private let openShelf: () -> Void
    private let newTextCard: () -> Void
    private let startSequence: () -> Void
    private var isShowingPaused: Bool

    init(
        pause: CapturePause,
        settings: MenuBarSettings,
        updater: AppUpdater,
        openShelf: @escaping () -> Void,
        newTextCard: @escaping () -> Void,
        startSequence: @escaping () -> Void
    ) {
        self.pause = pause
        self.settings = settings
        self.updater = updater
        self.openShelf = openShelf
        self.newTextCard = newTextCard
        self.startSequence = startSequence
        isShowingPaused = pause.isPaused
        super.init()
        menu.delegate = self
        guard let button = statusItem.button else {
            fatalError("a status item created by NSStatusBar always has a button")
        }
        button.setAccessibilityLabel(String(localized: "Clipsy", comment: "Accessibility label of the menu bar item"))
        button.target = self
        button.action = #selector(buttonClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        iconView.symbolConfiguration = NSImage.SymbolConfiguration(textStyle: .body, scale: .large)
        iconView.image = Self.icon(isPaused: isShowingPaused)
        iconView.setAccessibilityElement(false)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
    }

    /// applies the pause state and the menu bar settings until the calling task is cancelled
    func run() async {
        let changes = Observations { [pause, settings] in
            (pause.isPaused, settings.isItemShown, settings.clickOpensShelf)
        }
        for await (isPaused, isItemShown, clickOpensShelf) in changes {
            statusItem.isVisible = isItemShown
            statusItem.menu = clickOpensShelf ? nil : menu
            showPaused(isPaused)
        }
    }

    func bounce() {
        guard !reduceMotion else { return }
        iconView.addSymbolEffect(.bounce, options: .nonRepeating)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let openShelfItem = item(String(localized: "Open Shelf"), action: #selector(openShelfChosen))
        openShelfItem.setShortcut(for: .toggleShelf)
        menu.addItem(openShelfItem)
        menu.addItem(item(String(localized: "New Text Card"), action: #selector(newTextCardChosen)))
        let startSequenceItem = item(String(localized: "Start Sequence"), action: #selector(startSequenceChosen))
        startSequenceItem.setShortcut(for: .startSequence)
        menu.addItem(startSequenceItem)
        menu.addItem(.separator())
        if pause.isPaused {
            if let resumeDate = pause.resumeDate {
                let line = NSMenuItem(title: Self.pausedUntil(resumeDate), action: nil, keyEquivalent: "")
                line.isEnabled = false
                menu.addItem(line)
            }
            menu.addItem(item(String(localized: "Resume Capture"), action: #selector(resumeCapture)))
        } else {
            let pauseItem = NSMenuItem(title: String(localized: "Pause Capture"), action: nil, keyEquivalent: "")
            pauseItem.submenu = pauseMenu()
            menu.addItem(pauseItem)
        }
        menu.addItem(.separator())
        menu.addItem(item(String(localized: "Settings…"), action: #selector(openSettings), key: ","))
        menu.addItem(item(String(localized: "Check for Updates…"), action: #selector(checkForUpdates)))
        menu.addItem(item(String(localized: "About Clipsy"), action: #selector(showAbout)))
        menu.addItem(.separator())
        menu.addItem(item(String(localized: "Clipsy Help"), action: #selector(openHelp)))
        menu.addItem(item(String(localized: "Report an Issue"), action: #selector(reportIssue)))
        menu.addItem(.separator())
        menu.addItem(item(String(localized: "Quit Clipsy"), action: #selector(quit), key: "q"))
    }

    private func pauseMenu() -> NSMenu {
        let submenu = NSMenu()
        for duration in PauseDuration.allCases {
            let durationItem = item(Self.title(of: duration), action: #selector(pauseChosen))
            durationItem.representedObject = duration
            submenu.addItem(durationItem)
        }
        return submenu
    }

    private static func title(of duration: PauseDuration) -> String {
        switch duration {
        case .fifteenMinutes: String(localized: "For 15 Minutes")
        case .oneHour: String(localized: "For 1 Hour")
        case .eightHours: String(localized: "For 8 Hours")
        case .untilTomorrow: String(localized: "Until Tomorrow")
        case .untilResumed: String(localized: "Until Resumed")
        }
    }

    private static func pausedUntil(_ date: Date) -> String {
        let time = Calendar.autoupdatingCurrent.isDateInToday(date)
            ? date.formatted(date: .omitted, time: .shortened)
            : date.formatted(.dateTime.weekday(.abbreviated).hour().minute())
        return String(localized: "Paused until \(time)")
    }

    private func item(_ title: String, action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    private func showPaused(_ isPaused: Bool) {
        guard isPaused != isShowingPaused else { return }
        isShowingPaused = isPaused
        let image = Self.icon(isPaused: isPaused)
        if reduceMotion {
            iconView.image = image
        } else {
            iconView.setSymbolImage(image, contentTransition: .replace)
        }
        announce(isPaused
            ? String(localized: "Capture paused", comment: "VoiceOver announcement when capture is paused")
            : String(localized: "Capture resumed", comment: "VoiceOver announcement when capture is resumed"))
    }

    private static func icon(isPaused: Bool) -> NSImage {
        let description = isPaused
            ? String(localized: "Capture Paused", comment: "Accessibility description of the paused menu bar symbol")
            : String(localized: "Clipsy", comment: "Accessibility label of the menu bar item")
        let image = isPaused
            ? NSImage(systemSymbolName: "pause.circle", accessibilityDescription: description)
            : NSImage(named: "clipsy.paperclip")
        guard let image else {
            fatalError("pause.circle ships with SF Symbols and clipsy.paperclip with the app's asset catalog")
        }
        image.accessibilityDescription = description
        return image
    }

    private func announce(_ text: String) {
        NSAccessibility.post(
            element: NSApplication.shared,
            notification: .announcementRequested,
            userInfo: [.announcement: text, .priority: NSAccessibilityPriorityLevel.high.rawValue]
        )
    }

    @objc private func buttonClicked() {
        guard let event = NSApplication.shared.currentEvent else { return }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            openShelf()
        }
    }

    @objc private func openShelfChosen() {
        openShelf()
    }

    @objc private func newTextCardChosen() {
        newTextCard()
    }

    @objc private func startSequenceChosen() {
        startSequence()
    }

    @objc private func pauseChosen(_ sender: NSMenuItem) {
        guard let duration = sender.representedObject as? PauseDuration else {
            fatalError("every Pause Capture item carries its PauseDuration")
        }
        pause.pause(duration)
    }

    @objc private func resumeCapture() {
        pause.resume()
    }

    @objc private func openSettings() {
        SettingsWindow.open()
    }

    @objc private func checkForUpdates() {
        do {
            try updater.checkForUpdates()
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = String(localized: "Clipsy can’t check for updates.")
            alert.informativeText = error.localizedDescription
            NSApplication.shared.activate()
            alert.runModal()
        }
    }

    @objc private func showAbout() {
        NSApplication.shared.activate()
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
    }

    @objc private func openHelp() {
        NSWorkspace.shared.open(Self.helpURL)
    }

    @objc private func reportIssue() {
        NSWorkspace.shared.open(Self.issueURL)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    private static func url(_ string: String) -> URL {
        guard let url = URL(string: string) else {
            fatalError("\(string) is a valid URL literal")
        }
        return url
    }
}
