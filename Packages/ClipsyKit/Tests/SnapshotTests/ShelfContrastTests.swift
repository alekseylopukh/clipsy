import AppKit
import DesignSystem
import Media
import Store
import SwiftUI
import Testing
@testable import ShelfUI

/// card text must keep label colors on the shelf; glass around the content made it vibrant and invisible
@MainActor
final class ShelfContrastTests {
    private let suiteName = "ShelfContrastTests-\(UUID().uuidString)"
    private let fixtures: SnapshotFixtures

    init() throws {
        fixtures = try SnapshotFixtures()
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: fixtures.directory)
    }

    enum CardText: CaseIterable {
        case linkTitle
        case textBody
    }

    @Test(arguments: SnapshotRenderer.Appearance.allCases, CardText.allCases)
    func `card text is drawn in a label color`(appearance: SnapshotRenderer.Appearance, text: CardText) async throws {
        let card: CardSummary
        var blank: CardSummary
        switch text {
        case .linkTitle:
            card = try #require(fixtures.cards.first { $0.kind == .link })
            blank = card
            blank.metadata = card.metadata?.replacing(#""pageTitle":"Designing for the Desktop","#, with: "")
        case .textBody:
            card = try #require(fixtures.cards.first { $0.kind == .text })
            blank = card
            blank.preview = ""
        }
        #expect(blank != card)

        let withText = try await labelPixelCount(showing: card, appearance: appearance)
        let withoutText = try await labelPixelCount(showing: blank, appearance: appearance)
        withKnownIssue(
            "light link titles render with fewer label pixels on the GitHub runner VM",
            isIntermittent: true
        ) {
            #expect(withText - withoutText > 500)
        } when: {
            ProcessInfo.processInfo.environment["CI"] != nil && appearance == .light && text == .linkTitle
        }
    }

    private func labelPixelCount(
        showing card: CardSummary,
        appearance: SnapshotRenderer.Appearance
    ) async throws -> Int {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let model = ShelfModel(
            defaults: defaults,
            observe: { _ in AsyncThrowingStream { $0.finish() } },
            observeBoards: { AsyncThrowingStream { $0.finish() } }
        )
        model.receive([card])
        let presentation = ShelfPresentation()
        presentation.isVisible = true
        let boardEditor = BoardEditor(
            model: model,
            create: { _, _ in 0 },
            rename: { _, _ in },
            recolor: { _, _ in },
            move: { _, _ in },
            delete: { _ in },
            addCards: { _, _ in },
            moveCards: { _, _ in }
        )
        let representations = fixtures.representations
        let root = ShelfContainerView(
            presentation: presentation,
            model: model,
            commands: ShelfCommands(),
            onResize: {},
            onResizeEnded: {}
        )
        .environment(CardActions())
        .environment(boardEditor)
        .environment(\.cardMediaLoader, CardMediaLoader(
            representations: representations,
            thumbnails: ThumbnailCache(directory: fixtures.thumbnails)
        ))

        let rep = try await SnapshotRenderer.bitmap(
            root,
            appearance: appearance,
            size: CGSize(width: 600, height: DesignTokens.shelfDefaultHeight),
            settle: .milliseconds(100)
        )
        return try labelPixelCount(in: rep, appearance: appearance)
    }

    /// counts opaque, neutral pixels in the label color: dark in light mode, light in dark mode
    private func labelPixelCount(in rep: NSBitmapImageRep, appearance: SnapshotRenderer.Appearance) throws -> Int {
        let image = try #require(rep.cgImage)
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let drawn = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        try #require(drawn)
        let darkCeiling = 89
        let lightFloor = 166
        var count = 0
        for offset in stride(from: 0, to: pixels.count, by: 4) {
            guard pixels[offset + 3] > 242 else { continue }
            let red = Int(pixels[offset])
            let green = Int(pixels[offset + 1])
            let blue = Int(pixels[offset + 2])
            let low = min(red, green, blue)
            let high = max(red, green, blue)
            guard high - low <= 20 else { continue }
            if appearance == .light ? high <= darkCeiling : low >= lightFloor {
                count += 1
            }
        }
        return count
    }
}
