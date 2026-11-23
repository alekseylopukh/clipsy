import Foundation
import GRDB
import Testing
@testable import Store

@Suite(.enabled(if: ProcessInfo.processInfo.environment["CLIPSY_PERF"] == "1"))
struct PerformanceTests {
    static let cardCount = 100_000
    static let words = (0 ..< 400).map { "w\(String($0, radix: 36))tok" }

    @Test(.timeLimit(.minutes(2)))
    func `search and history load with 100k cards`() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "Clipsy-perf-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        defer { try? FileManager.default.removeItem(at: directory) }
        let clock = ContinuousClock()

        let seedTime = try await clock.measure {
            try await Self.seed(AppDatabase(directory: directory))
        }

        var database: AppDatabase?
        let openTime = try clock.measure { database = try AppDatabase(directory: directory) }
        let repository = try CardRepository(database: #require(database))

        var history: [CardSummary] = []
        let historyTime = try await clock.measure { history = try await repository.cards(in: .history) }
        #expect(history.count == Self.cardCount)

        let queries = [
            TimedQuery(label: "2-char prefix", text: "w1", filter: CardFilter()),
            TimedQuery(label: "common word", text: Self.words[7], filter: CardFilter()),
            TimedQuery(label: "two words", text: "\(Self.words[3]) \(Self.words[11])", filter: CardFilter()),
            TimedQuery(label: "unique token", text: "n99999", filter: CardFilter()),
            TimedQuery(label: "kind filter only", text: "", filter: CardFilter(kind: .link)),
            TimedQuery(label: "word + kind", text: Self.words[5], filter: CardFilter(kind: .link))
        ]
        var lines = [
            "performance: \(Self.cardCount) cards",
            "  seed           \(Self.format(seedTime))",
            "  open database  \(Self.format(openTime))",
            "  history load   \(Self.format(historyTime))"
        ]
        for query in queries {
            var results: [SearchResult] = []
            var times: [Duration] = []
            for _ in 0 ..< 5 {
                try await times.append(clock.measure {
                    results = try await repository.search(query.text, filter: query.filter)
                })
            }
            times.sort()
            #expect(results.isEmpty == false, "\(query.label)")
            lines.append("  search \(query.label.padding(toLength: 18, withPad: " ", startingAt: 0))"
                + "median \(Self.format(times[2])), max \(Self.format(times[4])), \(results.count) results")
        }
        FileHandle.standardError.write(Data((lines.joined(separator: "\n") + "\n").utf8))
    }

    private static func seed(_ database: AppDatabase) async throws {
        try await database.pool.write { connection in
            let apps = (0 ..< 20).map { "com.example.app\($0)" }
            for (index, bundleID) in apps.enumerated() {
                try connection.execute(
                    sql: "INSERT INTO source_app (id, bundle_id, name) VALUES (?, ?, ?)",
                    arguments: [index + 1, bundleID, "App \(index)"]
                )
            }
            let card = try connection.makeStatement(sql: """
            INSERT INTO card (id, kind, content_hash, preview_text, source_app_id, byte_size, created_at, last_copied_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """)
            let representation = try connection.makeStatement(sql: """
            INSERT INTO representation (card_id, item_index, type_index, uti, inline_data, byte_size)
            VALUES (?, 0, 0, 'public.utf8-plain-text', ?, ?)
            """)
            let search = try connection.makeStatement(
                sql: "INSERT INTO card_search (rowid, body, app_name) VALUES (?, ?, ?)"
            )
            var generator = SyntheticGenerator(seed: 42)
            for id in 1 ... cardCount {
                let body = (0 ..< 12).map { _ in words[generator.next(below: words.count)] }.joined(separator: " ")
                    + " n\(id)"
                let data = Data(body.utf8)
                let kind: CardKind = id.isMultiple(of: 10) ? .link : .text
                let app = generator.next(below: apps.count) + 1
                let time = Double(1_700_000_000 + id * 60)
                try card.execute(arguments: [id, kind.rawValue, Data("\(id)".utf8), body, app, data.count, time, time])
                try representation.execute(arguments: [id, data, data.count])
                try search.execute(arguments: [id, body, "App \(app - 1)"])
            }
        }
    }

    private static func format(_ duration: Duration) -> String {
        duration.formatted(.units(allowed: [.seconds, .milliseconds], width: .narrow, fractionalPart: .show(length: 1)))
    }
}

private struct TimedQuery {
    var label: String
    var text: String
    var filter: CardFilter
}

private struct SyntheticGenerator {
    var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next(below upperBound: Int) -> Int {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int((state >> 33) % UInt64(upperBound))
    }
}
