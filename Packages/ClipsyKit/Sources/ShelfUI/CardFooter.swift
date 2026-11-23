import DesignSystem
import Store
import SwiftUI

struct CardFooter: View {
    let kind: CardKind
    let content: CardContent

    var body: some View {
        Group {
            switch kind {
            case .text:
                if content.isCodeLike, let lines = content.metadata.lineCount {
                    Text("\(lines) lines", comment: "Card footer: number of lines in a code-like text card")
                } else if let characters = content.metadata.characterCount {
                    Text("\(characters) characters", comment: "Card footer: number of characters in a text card")
                }
            case .link:
                if let label = content.host.map(Self.displayHost) ?? content.metadata.url {
                    Text(verbatim: label)
                }
            case .file:
                if let names = content.metadata.fileNames, names.count > 1 {
                    if let size = content.metadata.totalFileSize {
                        Text(
                            "\(names.count) files, \(Int64(size), format: .byteCount(style: .file))",
                            comment: "Card footer: number of files and their total size"
                        )
                    } else {
                        Text("\(names.count) files", comment: "Card footer: number of files in a card")
                    }
                } else if let name = content.metadata.fileNames?.first {
                    Text(verbatim: name)
                        .truncationMode(.middle)
                }
            case .unknown:
                if let type = content.metadata.typeIdentifier {
                    Text(verbatim: type)
                        .truncationMode(.middle)
                }
            case .image, .color:
                EmptyView()
            }
        }
        .metadataStyle()
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    static func isShown(for kind: CardKind, layout: CardLayout) -> Bool {
        switch kind {
        case .text, .link, .file, .unknown:
            layout == .regular
        case .image, .color:
            false
        }
    }

    nonisolated static func displayHost(_ host: String) -> String {
        host.hasPrefix("www.") ? String(host.dropFirst("www.".count)) : host
    }
}
