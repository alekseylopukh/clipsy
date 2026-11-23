import Foundation
@_exported import KeyboardShortcuts

public extension KeyboardShortcuts.Name {
    static let toggleShelf = Self("toggleShelf", default: GlobalShortcutDefaults.current.toggleShelf)
    static let previousBoard = Self("previousBoard", default: .init(.leftArrow, modifiers: .command))
    static let nextBoard = Self("nextBoard", default: .init(.rightArrow, modifiers: .command))
    static let startSequence = Self("startSequence", default: GlobalShortcutDefaults.current.startSequence)
    static let pasteAllSequence = Self("pasteAllSequence", default: GlobalShortcutDefaults.current.pasteAllSequence)

    static let global: [Self] = [.toggleShelf, .startSequence, .pasteAllSequence]

    /// handled inside the shelf; they must never stay registered as global hotkeys
    static let shelfOnly: [Self] = [.previousBoard, .nextBoard]
}

struct GlobalShortcutDefaults: Equatable {
    static let current = Self(bundleIdentifier: Bundle.main.bundleIdentifier)

    let toggleShelf: KeyboardShortcuts.Shortcut
    let startSequence: KeyboardShortcuts.Shortcut
    let pasteAllSequence: KeyboardShortcuts.Shortcut?

    init(bundleIdentifier: String?) {
        if bundleIdentifier == "app.gonar.clipsy" {
            toggleShelf = .init(.v, modifiers: [.command, .shift])
            startSequence = .init(.c, modifiers: [.command, .shift])
            pasteAllSequence = .init(.v, modifiers: [.command, .option, .control])
        } else {
            toggleShelf = .init(.v, modifiers: [.command, .shift, .control])
            startSequence = .init(.c, modifiers: [.command, .shift, .control])
            pasteAllSequence = nil
        }
    }
}
