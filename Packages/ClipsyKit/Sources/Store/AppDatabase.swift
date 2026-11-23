import Foundation
import GRDB

public struct AppDatabase: Sendable {
    public struct SupersededError: Error {}

    public static func defaultDirectory(bundleIdentifier: String) -> URL {
        URL.applicationSupportDirectory.appending(
            path: bundleIdentifier == "app.gonar.clipsy" ? "Clipsy" : bundleIdentifier,
            directoryHint: .isDirectory
        )
    }

    public let directory: URL
    let pool: DatabasePool

    public init(directory: URL) throws {
        try self.init(directory: directory, migrator: Self.migrator)
    }

    init(directory: URL, migrator: DatabaseMigrator) throws {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        self.directory = directory
        let path = directory.appending(path: "clipsy.sqlite").path(percentEncoded: false)
        if FileManager.default.fileExists(atPath: path) {
            // grdb's migrate() silently accepts unknown applied migrations
            let superseded = try DatabaseQueue(path: path).read(migrator.hasBeenSuperseded)
            guard !superseded else { throw SupersededError() }
        }
        pool = try DatabasePool(path: path)
        try migrator.migrate(pool)
    }

    public static func temporary() throws -> AppDatabase {
        try AppDatabase(
            directory: FileManager.default.temporaryDirectory.appending(
                path: "Clipsy-\(UUID().uuidString)",
                directoryHint: .isDirectory
            )
        )
    }

    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1_initial") { connection in
            try connection.execute(sql: """
            CREATE TABLE source_app (
                id INTEGER PRIMARY KEY,
                bundle_id TEXT NOT NULL UNIQUE,
                name TEXT NOT NULL
            );

            CREATE TABLE board (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                color TEXT NOT NULL,
                position REAL NOT NULL,
                created_at REAL NOT NULL
            );

            CREATE TABLE card (
                id INTEGER PRIMARY KEY,
                kind INTEGER NOT NULL,
                content_hash BLOB NOT NULL UNIQUE,
                title TEXT,
                preview_text TEXT,
                metadata TEXT,
                source_app_id INTEGER REFERENCES source_app(id) ON DELETE SET NULL,
                byte_size INTEGER NOT NULL,
                created_at REAL NOT NULL,
                last_copied_at REAL,
                board_id INTEGER REFERENCES board(id) ON DELETE SET NULL,
                board_position REAL,
                ocr_state INTEGER NOT NULL DEFAULT 0,
                CHECK (last_copied_at IS NOT NULL OR board_id IS NOT NULL)
            );
            CREATE INDEX card_history ON card(last_copied_at DESC) WHERE last_copied_at IS NOT NULL;
            CREATE INDEX card_board ON card(board_id, board_position) WHERE board_id IS NOT NULL;

            CREATE TABLE representation (
                card_id INTEGER NOT NULL REFERENCES card(id) ON DELETE CASCADE,
                item_index INTEGER NOT NULL,
                type_index INTEGER NOT NULL,
                uti TEXT NOT NULL,
                inline_data BLOB,
                payload_hash TEXT,
                byte_size INTEGER NOT NULL,
                PRIMARY KEY (card_id, item_index, type_index),
                CHECK ((inline_data IS NULL) <> (payload_hash IS NULL))
            );
            CREATE INDEX representation_payload ON representation(payload_hash) WHERE payload_hash IS NOT NULL;
            CREATE INDEX card_ocr_pending ON card(id) WHERE ocr_state = 1;

            CREATE VIRTUAL TABLE card_search USING fts5(
                title, body, url, file_names, ocr_text, app_name,
                tokenize = 'unicode61 remove_diacritics 2',
                prefix = '2 3'
            );
            """)
        }
        return migrator
    }
}
