import Foundation

public enum URLRoute: Equatable, Sendable {
    case openShelf
    case search(String)
    case newTextCard(String)
    case openSettings

    public init?(_ url: URL, scheme: String) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == scheme.lowercased(),
              components.path.isEmpty || components.path == "/",
              let host = components.host?.lowercased()
        else { return nil }
        let items = components.queryItems ?? []
        let value = { (name: String) in items.first { $0.name == name }?.value ?? "" }
        switch host {
        case "open": self = .openShelf
        case "search": self = .search(value("q"))
        case "new": self = .newTextCard(value("text"))
        case "settings": self = .openSettings
        default: return nil
        }
    }
}
