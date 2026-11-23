import Foundation
import Testing
@testable import ShelfUI

struct URLRouteTests {
    @Test(arguments: ["clipsy", "clipsy-dev"], [
        ("://open", URLRoute.openShelf),
        ("://Open/", .openShelf),
        ("://search?q=invoice%20march", .search("invoice march")),
        ("://search", .search("")),
        ("://new?text=Hello%2C%20world", .newTextCard("Hello, world")),
        ("://new", .newTextCard("")),
        ("://settings", .openSettings)
    ])
    func `parses each route`(scheme: String, route: (suffix: String, expected: URLRoute)) throws {
        let url = try #require(URL(string: scheme + route.suffix))
        #expect(URLRoute(url, scheme: scheme) == route.expected)
    }

    @Test(arguments: ["clipsy", "clipsy-dev"])
    func `matches the scheme case-insensitively`(scheme: String) throws {
        let url = try #require(URL(string: scheme.uppercased() + "://open"))
        #expect(URLRoute(url, scheme: scheme) == .openShelf)
    }

    @Test(arguments: [
        ("clipsy://delete", "clipsy"),
        ("clipsy://", "clipsy"),
        ("clipsy:open", "clipsy"),
        ("clipsy://open/extra", "clipsy"),
        ("https://open", "clipsy"),
        ("otherapp://search?q=a", "clipsy"),
        ("clipsy-dev://open", "clipsy"),
        ("clipsy://open", "clipsy-dev")
    ])
    func `rejects unknown route`(string: String, scheme: String) throws {
        let url = try #require(URL(string: string))
        #expect(URLRoute(url, scheme: scheme) == nil)
    }
}
