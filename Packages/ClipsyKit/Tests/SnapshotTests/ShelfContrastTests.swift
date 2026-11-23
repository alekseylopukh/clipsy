import AppKit
import DesignSystem
import Media
import Store
import SwiftUI
import Testing
@testable import ShelfUI

/// card text must keep label colors on the shelf; glass around the content made it vibrant and invisible
@MainActor
@Suite(.serialized)
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

    /// counts opaque, neutral pixels in the label color: dark in light mode, light in dark mode
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
            settle: .seconds(2)
        )
        var count = 0
        for y in 0 ..< rep.pixelsHigh {
            for x in 0 ..< rep.pixelsWide {
                guard let color = rep.colorAt(x: x, y: y)?.usingColorSpace(.sRGB), color.alphaComponent > 0.95 else {
                    continue
                }
                let channels = [color.redComponent, color.greenComponent, color.blueComponent]
                guard let low = channels.min(), let high = channels.max(), high - low < 0.08 else { continue }
                if appearance == .light ? high < 0.35 : low > 0.65 {
                    count += 1
                }
            }
        }
        return count
    }
}
