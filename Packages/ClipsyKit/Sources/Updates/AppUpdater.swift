import Observation

@MainActor
@Observable
public final class AppUpdater {
    @ObservationIgnored private let driver: any UpdaterDriver
    @ObservationIgnored private(set) var isStarted = false

    public init(driver: any UpdaterDriver) {
        self.driver = driver
    }

    public var isAvailable: Bool {
        driver.isAvailable
    }

    /// sparkle owns this setting in the app's user defaults
    public var automaticallyChecksForUpdates: Bool {
        access(keyPath: \.automaticallyChecksForUpdates)
        return driver.automaticallyChecksForUpdates
    }

    public func setAutomaticallyChecksForUpdates(_ isOn: Bool) throws {
        if isOn {
            try startIfNeeded()
        }
        withMutation(keyPath: \.automaticallyChecksForUpdates) {
            driver.automaticallyChecksForUpdates = isOn
        }
    }

    public func startIfAutomatic() throws {
        if driver.automaticallyChecksForUpdates {
            try startIfNeeded()
        }
    }

    public func checkForUpdates() throws {
        try startIfNeeded()
        driver.checkForUpdates()
    }

    private func startIfNeeded() throws {
        guard !isStarted else { return }
        try driver.start()
        isStarted = true
    }
}
