import Foundation

public extension AppUpdater {
    private static let releaseBundleIdentifier = "app.gonar.clipsy"

    convenience init(bundle: Bundle) {
        self.init(driver: Self.driver(for: bundle))
    }

    internal static func driver(for bundle: Bundle) -> any UpdaterDriver {
        guard bundle.bundleIdentifier == releaseBundleIdentifier else {
            return DisabledUpdaterDriver()
        }
        return SparkleUpdaterDriver(bundle: bundle)
    }
}
