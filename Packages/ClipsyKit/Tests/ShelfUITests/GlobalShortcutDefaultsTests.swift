import KeyboardShortcuts
import Testing
@testable import ShelfUI

struct GlobalShortcutDefaultsTests {
    @Test func `the release build keeps the documented defaults`() {
        let defaults = GlobalShortcutDefaults(bundleIdentifier: "app.gonar.clipsy")

        #expect(defaults.toggleShelf == .init(.v, modifiers: [.command, .shift]))
        #expect(defaults.startSequence == .init(.c, modifiers: [.command, .shift]))
        #expect(defaults.pasteAllSequence == .init(.v, modifiers: [.command, .option, .control]))
    }

    @Test(arguments: ["app.gonar.clipsy.dev", nil])
    func `any other build adds control and leaves paste all unset`(bundleIdentifier: String?) {
        let defaults = GlobalShortcutDefaults(bundleIdentifier: bundleIdentifier)

        #expect(defaults.toggleShelf == .init(.v, modifiers: [.command, .shift, .control]))
        #expect(defaults.startSequence == .init(.c, modifiers: [.command, .shift, .control]))
        #expect(defaults.pasteAllSequence == nil)
    }
}
