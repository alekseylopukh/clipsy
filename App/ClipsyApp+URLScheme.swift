import Foundation
import os
import ShelfUI

extension ClipsyApp {
    private static let urlSchemeLogger = Logger(subsystem: "app.gonar.clipsy", category: "URLScheme")

    private static let urlScheme: String = {
        guard let types = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]],
              let scheme = (types.first?["CFBundleURLSchemes"] as? [String])?.first
        else { fatalError("Config/Info.plist declares the URL scheme from CLIPSY_URL_SCHEME") }
        return scheme
    }()

    static func open(_ urls: [URL], shelf: ShelfController) {
        for url in urls {
            switch URLRoute(url, scheme: urlScheme) {
            case .openShelf: shelf.show()
            case let .search(text): shelf.showSearch(for: text)
            case let .newTextCard(text): shelf.showNewTextCard(text: text)
            case .openSettings: SettingsWindow.open()
            case nil: urlSchemeLogger.error("ignored a URL with an unknown route")
            }
        }
    }
}
