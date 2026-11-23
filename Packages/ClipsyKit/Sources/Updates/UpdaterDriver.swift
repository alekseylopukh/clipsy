@MainActor
public protocol UpdaterDriver: AnyObject {
    var isAvailable: Bool { get }
    var automaticallyChecksForUpdates: Bool { get set }
    func start() throws
    func checkForUpdates()
}

public extension UpdaterDriver {
    var isAvailable: Bool {
        true
    }
}
