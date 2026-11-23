import Foundation
import GRDB
import Testing
@testable import Store

struct AppDatabaseRecoveryTests {
    let directory = FileManager.default.temporaryDirectory.appending(
        path: "Clipsy-\(UUID().uuidString)",
        directoryHint: .isDirectory
    )

    var storeFile: URL {
        directory.appending(path: "clipsy.sqlite")
    }

    @Test func `corrupt file is moved aside`() throws {
        let garbage = Data(repeating: 0x5A, count: 4096)
        let payload = Data(repeating: 0x01, count: 16)
        let payloadFile = directory.appending(path: "Payloads/ab/abcd")
        try FileManager.default.createDirectory(
            at: payloadFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try garbage.write(to: storeFile)
        try payload.write(to: payloadFile)

        let opened = try AppDatabase.openRecoveringDamagedStore(
            directory: directory,
            now: Date(timeIntervalSince1970: 0)
        )

        let backup = try #require(opened.backupDirectory)
        #expect(backup.deletingLastPathComponent().lastPathComponent == "Backups")
        #expect(try Data(contentsOf: backup.appending(path: "clipsy.sqlite")) == garbage)
        #expect(try Data(contentsOf: backup.appending(path: "Payloads/ab/abcd")) == payload)
        #expect(FileManager.default.fileExists(atPath: payloadFile.path(percentEncoded: false)) == false)
        let cardCount = try opened.database.pool.read { try Int.fetchOne($0, sql: "SELECT COUNT(*) FROM card") }
        #expect(cardCount == 0)
    }

    @Test func `failed migration does not touch file`() throws {
        let original = try storeContents(of: AppDatabase(directory: directory))
        var migrator = AppDatabase.migrator
        migrator.registerMigration("v2_failing") { connection in
            try connection.execute(sql: "CREATE TABLE added (id INTEGER PRIMARY KEY)")
            try connection.execute(sql: "ALTER TABLE missing_table ADD COLUMN value INTEGER")
        }

        #expect(throws: DatabaseError.self) {
            try AppDatabase.openRecoveringDamagedStore(directory: directory, migrator: migrator, now: .now)
        }

        let backups = directory.appending(path: "Backups").path(percentEncoded: false)
        #expect(FileManager.default.fileExists(atPath: backups) == false)
        #expect(try storeContents(of: AppDatabase(directory: directory)) == original)
    }

    @Test func `newer store is refused without touching files`() throws {
        var newer = AppDatabase.migrator
        newer.registerMigration("v99_future") { connection in
            try connection.execute(sql: "CREATE TABLE future (id INTEGER PRIMARY KEY)")
        }
        _ = try AppDatabase(directory: directory, migrator: newer)
        let original = try fileContents()

        #expect(throws: AppDatabase.SupersededError.self) {
            try AppDatabase.openRecoveringDamagedStore(directory: directory)
        }

        #expect(try fileContents() == original)
    }

    private func fileContents() throws -> [String: Data] {
        // -shm is sqlite's shared-memory index, which every reader rewrites
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false))
            .filter { $0 != "clipsy.sqlite-shm" }
        return try Dictionary(uniqueKeysWithValues: names.map { name in
            try (name, Data(contentsOf: directory.appending(path: name)))
        })
    }

    private func storeContents(of database: AppDatabase) throws -> [String] {
        try database.pool.read { connection in
            try String.fetchAll(connection, sql: "SELECT sql FROM sqlite_master WHERE sql IS NOT NULL ORDER BY name")
                + String.fetchAll(connection, sql: "SELECT identifier FROM grdb_migrations ORDER BY identifier")
        }
    }

    @Test func `healthy store opens without backup`() throws {
        _ = try AppDatabase(directory: directory)

        let opened = try AppDatabase.openRecoveringDamagedStore(directory: directory)

        #expect(opened.backupDirectory == nil)
    }
}
