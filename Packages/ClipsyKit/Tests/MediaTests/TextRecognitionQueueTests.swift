import CoreGraphics
import CoreText
import Foundation
import GRDB
import ImageIO
import Synchronization
import Testing
import UniformTypeIdentifiers
@testable import Media
@testable import Store

struct TextRecognitionQueueTests {
    let directory = FileManager.default.temporaryDirectory.appending(
        path: "Clipsy-\(UUID().uuidString)",
        directoryHint: .isDirectory
    )
    let repository: CardRepository

    init() throws {
        repository = try CardRepository(database: AppDatabase(directory: directory))
    }

    @Test(.disabled(
        if: ProcessInfo.processInfo.environment["CI"] != nil,
        "Vision finds no text on the GitHub runner VM"
    ))
    func `ocr text is searchable`() async throws {
        let id = try await recordImage(Self.renderedText("Quarterly invoice"))
        let queue = TextRecognitionQueue(repository: repository)
        await queue.setEnabled(true)

        try await queue.recognizePendingCards()

        #expect(try await state(of: id) == .done)
        #expect(try await repository.search("quarterly").map(\.id) == [id])
        #expect(try await repository.search("invoice").map(\.id) == [id])
    }

    @Test func `toggle off skips queue`() async throws {
        let id = try await recordImage(Self.renderedText("A"))
        let recognizer = FakeRecognizer(result: .success("hello"))
        let queue = TextRecognitionQueue(repository: repository, recognizer: recognizer)

        await queue.setEnabled(false)
        try await queue.recognizePendingCards()

        #expect(recognizer.callCount == 0)
        #expect(try await state(of: id) == .pending)

        await queue.setEnabled(true)
        try await queue.recognizePendingCards()

        #expect(recognizer.callCount == 1)
        #expect(try await state(of: id) == .done)
    }

    @Test(arguments: [true, false])
    func `failed ocr is marked`(imageDecodes: Bool) async throws {
        let data = imageDecodes ? try Self.renderedText("A") : Data(repeating: 7, count: 64)
        let failed = try await recordImage(data, hash: 1)
        let recognizer = FakeRecognizer(result: .failure(.recognitionFailed))
        let queue = TextRecognitionQueue(repository: repository, recognizer: recognizer)
        await queue.setEnabled(true)

        try await queue.recognizePendingCards()

        #expect(try await state(of: failed) == .failed)
        #expect(recognizer.callCount == (imageDecodes ? 1 : 0))
        #expect(try await repository.nextCardAwaitingTextRecognition() == nil)
    }

    @Test func `pending work resumes after relaunch`() async throws {
        let older = try await recordImage(Self.renderedText("A"), hash: 1)
        let newer = try await recordImage(Self.renderedText("B"), hash: 2)
        let relaunched = try CardRepository(database: AppDatabase(directory: directory))
        let recognizer = FakeRecognizer(result: .success("hello"))
        let queue = TextRecognitionQueue(repository: relaunched, recognizer: recognizer)

        try await withThrowingTaskGroup { group in
            group.addTask { try await queue.run() }
            await queue.setEnabled(true)
            for try await pending in relaunched.observeTextRecognitionBacklog() where pending == nil {
                break
            }
            group.cancelAll()
        }

        #expect(try await state(of: older) == .done)
        #expect(try await state(of: newer) == .done)
        #expect(recognizer.callCount == 2)
    }

    private func recordImage(_ data: Data, hash: UInt8 = 1) async throws -> Int64 {
        try await repository.record(NewCard(
            kind: .image,
            representations: [Representation(itemIndex: 0, uti: UTType.png.identifier, data: data)],
            contentHash: Data(repeating: hash, count: 32),
            previewText: nil,
            metadata: nil,
            sourceApp: SourceApp(bundleID: "com.example.preview", name: "Preview")
        ))
    }

    private func state(of id: Int64) async throws -> TextRecognitionState? {
        try await repository.database.pool.read { connection in
            try Int.fetchOne(connection, sql: "SELECT ocr_state FROM card WHERE id = ?", arguments: [id])
                .flatMap(TextRecognitionState.init(rawValue:))
        }
    }

    private static func renderedText(_ text: String) throws -> Data {
        let width = 900
        let height = 200
        let context = try #require(CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let font = CTFontCreateWithName("Helvetica" as CFString, 72, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0, alpha: 1)
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
        context.textPosition = CGPoint(x: 40, y: 70)
        CTLineDraw(line, context)
        let image = try #require(context.makeImage())
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }
}

private final class FakeRecognizer: TextRecognizing {
    enum Failure: Error {
        case recognitionFailed
    }

    private let result: Result<String, Failure>
    private let calls = Mutex(0)

    init(result: Result<String, Failure>) {
        self.result = result
    }

    var callCount: Int {
        calls.withLock { $0 }
    }

    func recognizeText(in _: CGImage) async throws -> String {
        calls.withLock { $0 += 1 }
        return try result.get()
    }
}
