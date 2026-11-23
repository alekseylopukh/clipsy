import Capture
import DesignSystem
import ShelfUI
import Store
import SwiftUI
import Updates

struct SettingsView: View {
    @AppStorage("SettingsPane") private var pane = SettingsPane.general

    var body: some View {
        TabView(selection: $pane) {
            Tab("General", systemImage: "gearshape", value: SettingsPane.general) {
                GeneralSettingsView()
            }
            Tab("Shortcuts", systemImage: "command", value: SettingsPane.shortcuts) {
                ShortcutsSettingsView()
            }
            Tab("Privacy", systemImage: "hand.raised", value: SettingsPane.privacy) {
                PrivacySettingsView()
            }
            Tab("About", systemImage: "info.circle", value: SettingsPane.about) {
                AboutSettingsView()
            }
        }
        .frame(width: DesignTokens.settingsWidth)
    }
}

enum SettingsPane: String {
    case general
    case shortcuts
    case privacy
    case about
}

#Preview {
    if let database = try? AppDatabase.temporary() {
        SettingsView()
            .environment(RetentionSettings(repository: CardRepository(database: database)))
            .environment(PrivacySettings())
            .environment(PasteboardAccess(pasteboard: NSPasteboard.withUniqueName()))
            .environment(MenuBarSettings())
            .environment(ShortcutSettings(store: KeyboardShortcutsStore()))
            .environment(AppUpdater(bundle: .main))
    }
}
