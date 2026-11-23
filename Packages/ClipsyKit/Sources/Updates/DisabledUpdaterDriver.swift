@MainActor
final class DisabledUpdaterDriver: UpdaterDriver {
    var automaticallyChecksForUpdates = false

    var isAvailable: Bool {
        false
    }

    func start() throws {}

    func checkForUpdates() {}
}
