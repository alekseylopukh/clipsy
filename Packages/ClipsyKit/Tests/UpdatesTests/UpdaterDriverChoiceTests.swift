import Foundation
import Testing
@testable import Updates

@MainActor
struct UpdaterDriverChoiceTests {
    @Test func `the release bundle gets Sparkle`() throws {
        let bundle = try temporaryBundle(identifier: "app.gonar.clipsy")

        let updater = AppUpdater(bundle: bundle)

        #expect(AppUpdater.driver(for: bundle) is SparkleUpdaterDriver)
        #expect(updater.isAvailable)
    }

    @Test(arguments: ["app.gonar.clipsy.dev", nil])
    func `any other bundle gets no updater`(identifier: String?) throws {
        let bundle = try temporaryBundle(identifier: identifier)

        let updater = AppUpdater(bundle: bundle)

        #expect(AppUpdater.driver(for: bundle) is DisabledUpdaterDriver)
        #expect(updater.isAvailable == false)
        #expect(updater.automaticallyChecksForUpdates == false)
    }

    private func temporaryBundle(identifier: String?) throws -> Bundle {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "UpdaterDriverChoiceTests-\(UUID().uuidString).app")
        let contents = url.appending(path: "Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        var info = ["CFBundlePackageType": "APPL"]
        info["CFBundleIdentifier"] = identifier
        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: contents.appending(path: "Info.plist"))
        return try #require(Bundle(url: url))
    }
}
