import AppKit
import CoreImage
import Foundation
import ImageIO
import Store
import UniformTypeIdentifiers

/// invented cards and generated media for the README screenshots; no real clipboard data, people or logos
struct MarketingFixtures {
    static let searchText = "Lisbon"
    static let snippetsBoardID: Int64 = 3

    let directory: URL
    let thumbnails: URL
    let history: [CardSummary]
    let snippets: [CardSummary]
    let searchResults: [SearchResult]
    let sequence: [CardSummary]
    let boards: [Board]
    let representations: @Sendable (Int64) async throws -> [Representation]

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appending(path: "MarketingSnapshots-\(UUID().uuidString)", directoryHint: .isDirectory)
        thumbnails = directory.appending(path: "Thumbnails", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: thumbnails, withIntermediateDirectories: true)

        let now = Date.now
        try Self.png(Self.landscape(width: 1200, height: 630, palette: .dusk))
            .write(to: thumbnails.appending(path: "21.png"))
        try Self.png(Self.styleGuidePreview(width: 1200, height: 630)).write(to: thumbnails.appending(path: "25.png"))
        let photo = try Self.png(Self.landscape(width: 1600, height: 1067, palette: .morning))
        let itinerary = directory.appending(path: "Lisbon Itinerary.pdf")
        try Self.itineraryPDF(at: itinerary)

        history = Self.historyCards(now: now)
        snippets = Self.snippetCards(now: now)
        sequence = Self.sequenceCards(now: now)
        let message = CardSummary(
            id: 31,
            kind: .text,
            preview: "Landing in Lisbon at 10:40. See you at arrivals!",
            sourceApp: SourceApp(bundleID: "com.apple.MobileSMS", name: "Messages"),
            createdAt: now.addingTimeInterval(-259_200),
            lastCopiedAt: now.addingTimeInterval(-259_200)
        )
        let matching = [history[0], history[1], message, history[5]]
        searchResults = matching.map { card in
            SearchResult(
                card: card,
                titleMatches: Self.ranges(of: Self.searchText, in: card.title),
                previewMatches: Self.ranges(of: Self.searchText, in: card.preview)
            )
        }
        boards = [
            Board(id: 1, name: "Work", color: "blue", createdAt: now),
            Board(id: 2, name: "Trip", color: "orange", createdAt: now),
            Board(id: Self.snippetsBoardID, name: "Snippets", color: "green", createdAt: now),
            Board(id: 4, name: "Palette", color: "purple", createdAt: now)
        ]

        let fileURL = Data(itinerary.absoluteString.utf8)
        let byCard: [Int64: [Representation]] = [
            3: [Representation(itemIndex: 0, uti: UTType.png.identifier, data: photo)],
            6: [Representation(itemIndex: 0, uti: "public.file-url", data: fileURL)]
        ]
        representations = { byCard[$0] ?? [] }
    }

    private static func historyCards(now: Date) -> [CardSummary] {
        [
            CardSummary(
                id: 1,
                kind: .text,
                preview: "Lisbon, Friday to Sunday\nArrive 10:40, check in after 3 PM.\n"
                    + "Saturday: tram up to the castle, dinner by the river.",
                metadata: #"{"characterCount":106,"lineCount":3,"wordCount":19}"#,
                sourceApp: SourceApp(bundleID: "com.apple.Notes", name: "Notes"),
                createdAt: now.addingTimeInterval(-60),
                lastCopiedAt: now.addingTimeInterval(-60),
                boardID: 2
            ),
            CardSummary(
                id: 2,
                kind: .link,
                preview: "https://travel.example.com/lisbon/quiet-viewpoints",
                metadata: #"{"pageTitle":"Seven Quiet Viewpoints in the Old Town","pixelWidth":1200,"#
                    + #""pixelHeight":630,"url":"https://travel.example.com/lisbon/quiet-viewpoints"}"#,
                sourceApp: SourceApp(bundleID: "com.apple.Safari", name: "Safari"),
                createdAt: now.addingTimeInterval(-540),
                lastCopiedAt: now.addingTimeInterval(-540),
                contentHash: "21"
            ),
            CardSummary(
                id: 3,
                kind: .image,
                metadata: #"{"pixelWidth":1600,"pixelHeight":1067}"#,
                sourceApp: SourceApp(bundleID: "com.apple.Photos", name: "Photos"),
                createdAt: now.addingTimeInterval(-1500),
                lastCopiedAt: now.addingTimeInterval(-1500),
                contentHash: "22"
            ),
            CardSummary(
                id: 4,
                kind: .color,
                preview: "#5E5CE6",
                metadata: ##"{"color":"#5E5CE6"}"##,
                sourceApp: SourceApp(bundleID: "com.apple.freeform", name: "Freeform"),
                createdAt: now.addingTimeInterval(-3000),
                lastCopiedAt: now.addingTimeInterval(-3000),
                boardID: 4
            ),
            CardSummary(
                id: 5,
                kind: .text,
                preview: "let trip = Trip(nights: 2)\nfor day in trip.days {\n    day.plan(.relaxed)\n}",
                metadata: #"{"characterCount":62,"lineCount":4,"wordCount":10}"#,
                sourceApp: SourceApp(bundleID: "com.apple.dt.Xcode", name: "Xcode"),
                createdAt: now.addingTimeInterval(-7200),
                lastCopiedAt: now.addingTimeInterval(-7200)
            ),
            CardSummary(
                id: 6,
                kind: .file,
                metadata: #"{"fileNames":["Lisbon Itinerary.pdf"]}"#,
                sourceApp: SourceApp(bundleID: "com.apple.finder", name: "Finder"),
                createdAt: now.addingTimeInterval(-86400),
                lastCopiedAt: now.addingTimeInterval(-86400)
            )
        ]
    }

    private static func snippetCards(now: Date) -> [CardSummary] {
        let board = snippetsBoardID
        return [
            CardSummary(
                id: 21,
                kind: .text,
                title: "Reply",
                preview: "Thanks for reaching out! I'll get back to you within one business day.\n\nKind regards",
                metadata: #"{"characterCount":84,"lineCount":3,"wordCount":15}"#,
                sourceApp: SourceApp(bundleID: "com.apple.mail", name: "Mail"),
                createdAt: now.addingTimeInterval(-864_000),
                boardID: board
            ),
            CardSummary(
                id: 22,
                kind: .text,
                title: "Studio Address",
                preview: "Studio North\n12 Harbour Lane, Unit 4\nBayview",
                metadata: #"{"characterCount":43,"lineCount":3,"wordCount":8}"#,
                sourceApp: SourceApp(bundleID: "com.apple.Notes", name: "Notes"),
                createdAt: now.addingTimeInterval(-1_728_000),
                boardID: board
            ),
            CardSummary(
                id: 23,
                kind: .text,
                preview: "$ git switch -c release\n$ git push -u origin HEAD",
                metadata: #"{"characterCount":49,"lineCount":2,"wordCount":10}"#,
                sourceApp: SourceApp(bundleID: "com.apple.Terminal", name: "Terminal"),
                createdAt: now.addingTimeInterval(-2_592_000),
                boardID: board
            ),
            CardSummary(
                id: 24,
                kind: .color,
                title: "Accent",
                preview: "#30B0C7",
                metadata: ##"{"color":"#30B0C7"}"##,
                sourceApp: SourceApp(bundleID: "com.apple.freeform", name: "Freeform"),
                createdAt: now.addingTimeInterval(-3_456_000),
                boardID: board
            ),
            CardSummary(
                id: 25,
                kind: .link,
                preview: "https://docs.example.com/writing-style",
                metadata: #"{"pageTitle":"Writing Style Guide","pixelWidth":1200,"pixelHeight":630,"#
                    + #""url":"https://docs.example.com/writing-style"}"#,
                sourceApp: SourceApp(bundleID: "com.apple.Safari", name: "Safari"),
                createdAt: now.addingTimeInterval(-4_320_000),
                boardID: board,
                contentHash: "25"
            )
        ]
    }

    private static func sequenceCards(now: Date) -> [CardSummary] {
        let lines = ["Casa Azul Guesthouse", "Rua do Sol 12, Lisbon", "Arrival Friday, 3 PM", "Booking 7Q4-28K"]
        return lines.enumerated().map { offset, line in
            CardSummary(
                id: Int64(41 + offset),
                kind: .text,
                preview: line,
                sourceApp: SourceApp(bundleID: "com.apple.mail", name: "Mail"),
                createdAt: now.addingTimeInterval(-Double(offset) * 30)
            )
        }
    }

    private static func ranges(of word: String, in text: String?) -> [Range<String.Index>] {
        guard let text else { return [] }
        var ranges: [Range<String.Index>] = []
        var start = text.startIndex
        while let range = text.range(of: word, options: .caseInsensitive, range: start ..< text.endIndex) {
            ranges.append(range)
            start = range.upperBound
        }
        return ranges
    }
}

extension MarketingFixtures {
    enum Palette {
        case morning
        case dusk

        var sky: [NSColor] {
            switch self {
            case .morning: [rgb(0.36, 0.62, 0.95), rgb(0.98, 0.80, 0.62)]
            case .dusk: [rgb(0.20, 0.20, 0.52), rgb(0.95, 0.52, 0.48)]
            }
        }

        var sun: NSColor {
            self == .morning ? rgb(1.0, 0.94, 0.78) : rgb(1.0, 0.78, 0.55)
        }

        var hills: [NSColor] {
            switch self {
            case .morning: [rgb(0.56, 0.62, 0.86), rgb(0.33, 0.45, 0.72), rgb(0.17, 0.27, 0.50)]
            case .dusk: [rgb(0.55, 0.32, 0.55), rgb(0.35, 0.20, 0.45), rgb(0.16, 0.10, 0.28)]
            }
        }
    }

    static func landscape(width: Int, height: Int, palette: Palette) throws -> CGImage {
        try draw(width: width, height: height) { context, size in
            fill(context, size: size, colors: palette.sky, from: CGPoint(x: 0, y: size.height), to: .zero)
            let sun = CGPoint(x: size.width * 0.68, y: size.height * 0.52)
            let glow = gradient([palette.sun, palette.sun.withAlphaComponent(0)])
            context.drawRadialGradient(
                glow, startCenter: sun, startRadius: size.height * 0.08,
                endCenter: sun, endRadius: size.height * 0.5, options: []
            )
            context.setFillColor(palette.sun.cgColor)
            context.fillEllipse(in: CGRect(x: sun.x, y: sun.y, width: 0, height: 0).insetBy(
                dx: -size.height * 0.08, dy: -size.height * 0.08
            ))
            for (index, color) in palette.hills.enumerated() {
                let base = size.height * (0.42 - CGFloat(index) * 0.13)
                let swing = size.height * (0.10 - CGFloat(index) * 0.02)
                let path = CGMutablePath()
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: 0, y: base))
                path.addCurve(
                    to: CGPoint(x: size.width, y: base + swing * (index.isMultiple(of: 2) ? 0.4 : -0.6)),
                    control1: CGPoint(x: size.width * (0.25 + CGFloat(index) * 0.1), y: base + swing * 2),
                    control2: CGPoint(x: size.width * (0.6 - CGFloat(index) * 0.1), y: base - swing * 1.5)
                )
                path.addLine(to: CGPoint(x: size.width, y: 0))
                path.closeSubpath()
                context.addPath(path)
                context.setFillColor(color.cgColor)
                context.fillPath()
            }
        }
    }

    /// a style guide's link preview: a large "Aa" over the board's teal
    static func styleGuidePreview(width: Int, height: Int) throws -> CGImage {
        try draw(width: width, height: height) { context, size in
            fill(
                context,
                size: size,
                colors: [rgb(0.19, 0.69, 0.78), rgb(0.27, 0.36, 0.86)],
                from: CGPoint(x: 0, y: size.height),
                to: CGPoint(x: size.width, y: 0)
            )
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            NSAttributedString(string: "Aa", attributes: [
                .font: NSFont.systemFont(ofSize: size.height * 0.42, weight: .bold),
                .foregroundColor: NSColor.white
            ]).draw(at: CGPoint(x: size.width * 0.08, y: size.height * 0.30))
            NSAttributedString(string: "Writing Style Guide", attributes: [
                .font: NSFont.systemFont(ofSize: size.height * 0.08, weight: .semibold),
                .foregroundColor: NSColor.white.withAlphaComponent(0.85)
            ]).draw(at: CGPoint(x: size.width * 0.09, y: size.height * 0.16))
            NSGraphicsContext.restoreGraphicsState()
        }
    }

    static func png(_ image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)
        else { throw SnapshotFixtures.FixtureError.drawingFailed }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw SnapshotFixtures.FixtureError.drawingFailed }
        return data as Data
    }

    static func draw(width: Int, height: Int, _ body: (CGContext, CGSize) -> Void) throws -> CGImage {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { throw SnapshotFixtures.FixtureError.drawingFailed }
        body(context, CGSize(width: width, height: height))
        guard let image = context.makeImage() else { throw SnapshotFixtures.FixtureError.drawingFailed }
        return image
    }

    static func blurred(_ image: CGImage, radius: Double, saturation: Double = 1) throws -> CGImage {
        let input = CIImage(cgImage: image)
        let output = input.clampedToExtent()
            .applyingGaussianBlur(sigma: radius)
            .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: saturation])
            .cropped(to: input.extent)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        guard let result = CIContext().createCGImage(output, from: input.extent, format: .RGBA8, colorSpace: colorSpace)
        else { throw SnapshotFixtures.FixtureError.drawingFailed }
        return result
    }

    static func fill(_ context: CGContext, size: CGSize, colors: [NSColor], from start: CGPoint, to end: CGPoint) {
        context.saveGState()
        context.clip(to: CGRect(origin: .zero, size: size))
        context.drawLinearGradient(gradient(colors), start: start, end: end, options: [
            .drawsBeforeStartLocation, .drawsAfterEndLocation
        ])
        context.restoreGState()
    }

    static func gradient(_ colors: [NSColor]) -> CGGradient {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors.map(\.cgColor) as CFArray,
            locations: nil
        )
        else { fatalError("sRGB colors always make a gradient") }
        return gradient
    }

    /// a one-page made-up itinerary, so the file card gets a real Quick Look thumbnail
    private static func itineraryPDF(at url: URL) throws {
        var box = CGRect(x: 0, y: 0, width: 420, height: 595)
        guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else {
            throw SnapshotFixtures.FixtureError.drawingFailed
        }
        context.beginPDFPage(nil)
        context.setFillColor(rgb(0.37, 0.36, 0.90).cgColor)
        context.fill(CGRect(x: 0, y: 470, width: 420, height: 125))
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        NSAttributedString(string: "Lisbon Weekend", attributes: [
            .font: NSFont.systemFont(ofSize: 30, weight: .bold), .foregroundColor: NSColor.white
        ]).draw(at: CGPoint(x: 32, y: 510))
        let days = [
            ("Friday", "Arrive 10:40 · Check in after 3 PM"),
            ("Saturday", "Castle in the morning · River dinner"),
            ("Sunday", "Market · Flight home 18:15")
        ]
        for (index, day) in days.enumerated() {
            let top = 420 - CGFloat(index) * 110
            NSAttributedString(string: day.0, attributes: [
                .font: NSFont.systemFont(ofSize: 20, weight: .semibold), .foregroundColor: NSColor.black
            ]).draw(at: CGPoint(x: 32, y: top))
            NSAttributedString(string: day.1, attributes: [
                .font: NSFont.systemFont(ofSize: 14), .foregroundColor: NSColor.darkGray
            ]).draw(at: CGPoint(x: 32, y: top - 28))
        }
        NSGraphicsContext.restoreGraphicsState()
        context.endPDFPage()
        context.closePDF()
    }
}

private func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> NSColor {
    NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
}
