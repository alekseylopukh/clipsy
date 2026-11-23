import Foundation
import GRDB
import Testing
@testable import Store

struct AppDatabaseTests {
    let database: AppDatabase

    init() throws {
        database = try AppDatabase.temporary()
    }

    @Test(arguments: [
        (bundleIdentifier: "app.gonar.clipsy", folder: "Clipsy"),
        (bundleIdentifier: "app.gonar.clipsy.dev", folder: "app.gonar.clipsy.dev")
    ])
    func `default directory derives from the bundle id`(bundleIdentifier: String, folder: String) {
        let expected = URL.applicationSupportDirectory.appending(path: folder, directoryHint: .isDirectory)
        #expect(AppDatabase.defaultDirectory(bundleIdentifier: bundleIdentifier) == expected)
    }

    @Test func `migration creates all tables`() throws {
        let names = try database.pool.read { connection in
            try String.fetchSet(connection, sql: "SELECT name FROM sqlite_master WHERE type IN ('table', 'index')")
        }
        let expected: Set = [
            "card", "representation", "board", "source_app", "card_search",
            "card_history", "card_board", "representation_payload"
        ]
        #expect(expected.isSubset(of: names))
    }

    @Test(arguments: [
        (lastCopiedAt: 1.0 as Double?, boardID: nil as Int64?, isAccepted: true),
        (lastCopiedAt: nil, boardID: 1, isAccepted: true),
        (lastCopiedAt: 1.0, boardID: 1, isAccepted: true),
        (lastCopiedAt: nil, boardID: nil, isAccepted: false)
    ])
    func `card requires history or board`(lastCopiedAt: Double?, boardID: Int64?, isAccepted: Bool) throws {
        try database.pool.write { connection in
            try connection.execute(sql: """
            INSERT INTO board (id, name, color, position, created_at) VALUES (1, 'B', 'blue', 1, 0)
            """)
            let insert = {
                try connection.execute(
                    sql: """
                    INSERT INTO card (kind, content_hash, byte_size, created_at, last_copied_at, board_id)
                    VALUES (?, ?, 1, 0, ?, ?)
                    """,
                    arguments: [CardKind.text.rawValue, Data([1]), lastCopiedAt, boardID]
                )
            }
            if isAccepted {
                try insert()
            } else {
                let error = #expect(throws: DatabaseError.self) { try insert() }
                #expect(error?.extendedResultCode == .SQLITE_CONSTRAINT_CHECK)
            }
        }
    }

    @Test(arguments: [
        (inlineData: Data([1]) as Data?, payloadHash: nil as String?, isAccepted: true),
        (inlineData: nil, payloadHash: "ab", isAccepted: true),
        (inlineData: Data([1]), payloadHash: "ab", isAccepted: false),
        (inlineData: nil, payloadHash: nil, isAccepted: false)
    ])
    func `representation requires exactly one payload`(
        inlineData: Data?,
        payloadHash: String?,
        isAccepted: Bool
    ) throws {
        try database.pool.write { connection in
            try connection.execute(
                sql: """
                INSERT INTO card (id, kind, content_hash, byte_size, created_at, last_copied_at)
                VALUES (1, ?, ?, 1, 0, 0)
                """,
                arguments: [CardKind.text.rawValue, Data([1])]
            )
            let insert = {
                try connection.execute(
                    sql: """
                    INSERT INTO representation (card_id, item_index, type_index, uti, inline_data, payload_hash, byte_size)
                    VALUES (1, 0, 0, 'public.utf8-plain-text', ?, ?, 1)
                    """,
                    arguments: [inlineData, payloadHash]
                )
            }
            if isAccepted {
                try insert()
            } else {
                let error = #expect(throws: DatabaseError.self) { try insert() }
                #expect(error?.extendedResultCode == .SQLITE_CONSTRAINT_CHECK)
            }
        }
    }

    @Test(arguments: ["cafe", "CAFÉ", "creme", "crè*"])
    func `search tokenizer folds diacritics`(query: String) throws {
        let matches = try database.pool.write { connection in
            try connection.execute(sql: "INSERT INTO card_search (rowid, body) VALUES (7, 'Café crème brûlée')")
            return try Int64.fetchAll(
                connection,
                sql: "SELECT rowid FROM card_search WHERE card_search MATCH ?",
                arguments: [query]
            )
        }
        #expect(matches == [7])
    }

    @Test func `directory is owner only`() throws {
        let path = database.directory.path(percentEncoded: false)
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        let permissions = try #require(attributes[.posixPermissions] as? Int)
        #expect(permissions == 0o700)
    }
}
