import AppKit
import Capture
import DesignSystem
import Media
import Pasting
import Store
import SwiftUI
import Testing
@testable import ShelfUI

/// renders the README screenshots over a generated desktop; run with scripts/readme-screenshots.sh
@MainActor
@Suite(
    .enabled(if: snapshotDirectory != nil && ProcessInfo.processInfo.environment["CLIPSY_MARKETING"] != nil),
    .serialized
)
final class MarketingSnapshotTests {
    private static let desktop = CGSize(width: 1440, height: 900)
    private static let strip = CGSize(width: 1200, height: DesignTokens.shelfDefaultHeight + 48)
    private let suiteName = "MarketingSnapshotTests-\(UUID().uuidString)"
    private let fixtures: MarketingFixtures
    private let defaults: UserDefaults

    init() throws {
        fixtures = try MarketingFixtures()
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("a unique suite name always opens a defaults domain")
        }
        self.defaults = defaults
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: fixtures.directory)
    }

    @Test(arguments: SnapshotRenderer.Appearance.allCases)
    func `render the shelf over a desktop`(appearance: SnapshotRenderer.Appearance) async throws {
        let model = makeModel()
        model.receive(fixtures.history)
        model.receiveBoards(fixtures.boards)
        let photo = try MarketingFixtures.landscape(width: 520, height: 400, palette: .morning)
        let root = try MarketingDesktop(size: Self.desktop, appearance: appearance) {
            VStack(spacing: 0) {
                MarketingWindow(title: "Lisbon Weekend") {
                    TripNote(photo: photo)
                }
                .frame(width: 760, height: 330)
                .padding(.top, 72)
                Spacer(minLength: 0)
                shelf(model)
                    .frame(height: DesignTokens.shelfDefaultHeight)
                    .padding(DesignTokens.shelfInset)
            }
        }
        try await render(root, named: "shelf", appearance: appearance, size: Self.desktop)
    }

    @Test(arguments: SnapshotRenderer.Appearance.allCases)
    func `render search with a filter`(appearance: SnapshotRenderer.Appearance) async throws {
        let model = makeModel()
        model.receive(fixtures.history)
        model.receiveBoards(fixtures.boards)
        model.query = MarketingFixtures.searchText
        model.addToken(.date(.last7Days))
        model.receiveResults(fixtures.searchResults)
        try await renderStrip(model, named: "search", appearance: appearance)
    }

    @Test(arguments: SnapshotRenderer.Appearance.allCases)
    func `render a board`(appearance: SnapshotRenderer.Appearance) async throws {
        let model = makeModel()
        model.receiveBoards(fixtures.boards)
        model.showTab(.board(id: MarketingFixtures.snippetsBoardID))
        model.receive(fixtures.snippets)
        try await renderStrip(model, named: "board", appearance: appearance)
    }

    @Test(arguments: SnapshotRenderer.Appearance.allCases)
    func `render a sequence`(appearance: SnapshotRenderer.Appearance) async throws {
        let cards = fixtures.sequence
        let sequence = PasteSequence(defaults: defaults)
        sequence.clear()
        sequence.add(cards.dropFirst().map(\.id))
        let panel = SequencePanelModel(
            sequence: sequence,
            loadCards: { ids in cards.filter { ids.contains($0.id) } },
            onPasteAll: { _ in }
        )
        let size = CGSize(width: 1000, height: 520)
        let root = try MarketingDesktop(size: size, appearance: appearance) {
            ZStack(alignment: .topTrailing) {
                MarketingWindow(title: "Guest Details") {
                    GuestForm(filled: cards.first?.preview ?? "")
                }
                .frame(width: 560, height: 300)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, 80)
                .padding(.top, 110)
                SequencePanelView(model: panel)
                    .frame(width: DesignTokens.sequencePanelWidth)
                    .background(MarketingGlass(cornerRadius: DesignTokens.sequencePanelCornerRadius))
                    .padding(DesignTokens.sequencePanelScreenInset)
                    .padding(.top, 28)
            }
        }
        try await render(root, named: "sequence", appearance: appearance, size: size)
    }

    @Test(arguments: SnapshotRenderer.Appearance.allCases)
    func `render the privacy settings`(appearance: SnapshotRenderer.Appearance) async throws {
        let size = CGSize(width: 900, height: 900)
        let root = try MarketingDesktop(size: size, appearance: appearance) {
            MarketingWindow(title: "Privacy") {
                VStack(spacing: 0) {
                    SettingsToolbar()
                    PrivacySettingsView()
                        .toggleStyle(ActiveSwitchStyle())
                        .environment(PrivacySettings(defaults: defaults))
                        .environment(PasteboardAccess(pasteboard: AllowingPasteboard(), defaults: defaults))
                }
            }
            .frame(width: DesignTokens.settingsWidth)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxHeight: .infinity)
            .padding(.top, 28)
        }
        try await render(root, named: "privacy", appearance: appearance, size: size)
    }

    private func renderStrip(
        _ model: ShelfModel,
        named name: String,
        appearance: SnapshotRenderer.Appearance
    ) async throws {
        let root = try MarketingDesktop(size: Self.strip, appearance: appearance, showsMenuBar: false) {
            shelf(model)
                .padding(.horizontal, DesignTokens.shelfInset)
                .padding(.vertical, (Self.strip.height - DesignTokens.shelfDefaultHeight) / 2)
        }
        try await render(root, named: name, appearance: appearance, size: Self.strip)
    }

    private func render(
        _ root: some View,
        named name: String,
        appearance: SnapshotRenderer.Appearance,
        size: CGSize
    ) async throws {
        try await SnapshotRenderer.render(
            root,
            named: name,
            appearance: appearance,
            size: size,
            settle: .seconds(3)
        )
    }

    private func makeModel() -> ShelfModel {
        ShelfModel(
            defaults: defaults,
            observe: { _ in AsyncThrowingStream { $0.finish() } },
            observeBoards: { AsyncThrowingStream { $0.finish() } }
        )
    }

    private func shelf(_ model: ShelfModel) -> some View {
        let presentation = ShelfPresentation()
        presentation.isVisible = true
        let commands = ShelfCommands()
        commands.newBoard = {}
        let representations = fixtures.representations
        return ShelfContainerView(
            presentation: presentation,
            model: model,
            commands: commands,
            onResize: {},
            onResizeEnded: {}
        )
        .environment(CardActions())
        .environment(BoardEditor(
            model: model,
            create: { _, _ in 0 },
            rename: { _, _ in },
            recolor: { _, _ in },
            move: { _, _ in },
            delete: { _ in },
            addCards: { _, _ in },
            moveCards: { _, _ in }
        ))
        .environment(\.richTextLoader, RichTextLoader(representations: representations))
        .environment(\.cardMediaLoader, CardMediaLoader(
            representations: representations,
            thumbnails: ThumbnailCache(directory: fixtures.thumbnails)
        ))
        .background(MarketingGlass())
    }
}

/// the Settings toolbar with Privacy selected; the real one lives in the window's title bar
private struct SettingsToolbar: View {
    private let panes = [
        ("General", "gearshape"), ("Shortcuts", "command"), ("Privacy", "hand.raised"), ("About", "info.circle")
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(panes, id: \.0) { title, symbol in
                VStack(spacing: 3) {
                    Image(systemName: symbol)
                        .font(.system(size: 18))
                        .frame(height: 22)
                    Text(verbatim: title)
                        .font(.system(size: 11))
                }
                .foregroundStyle(title == "Privacy" ? Color.accentColor : Color.secondary)
                .frame(width: 72, height: 50)
                .background(
                    title == "Privacy" ? Color.secondary.opacity(0.15) : Color.clear,
                    in: .rect(cornerRadius: 8)
                )
            }
        }
        .padding(.bottom, 8)
    }
}

private struct TripNote: View {
    let photo: CGImage

    var body: some View {
        HStack(alignment: .top, spacing: 32) {
            VStack(alignment: .leading, spacing: 14) {
                Text(verbatim: "Lisbon, Friday to Sunday")
                    .font(.system(size: 24, weight: .bold))
                Text(
                    verbatim: "Arrive 10:40, check in after 3 PM.\nSaturday: tram up to the castle, dinner by the river."
                )
                .font(.system(size: 14))
                .lineSpacing(4)
                VStack(alignment: .leading, spacing: 9) {
                    item("Book the river table", done: true)
                    item("Download offline maps", done: true)
                    item("Pack the camera charger", done: false)
                    item("Tram 28 tickets", done: false)
                }
                .padding(.top, 4)
            }
            Image(decorative: photo, scale: 2)
                .resizable()
                .frame(width: 260, height: 200)
                .clipShape(.rect(cornerRadius: 10))
        }
        .padding(.horizontal, 36)
        .padding(.top, 14)
    }

    private func item(_ title: String, done: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? Color.orange : Color.secondary)
            Text(verbatim: title)
                .foregroundStyle(done ? .secondary : .primary)
        }
        .font(.system(size: 14))
    }
}

/// an offscreen app is never active, so system switches draw grey; this draws them as an active window shows them
private struct ActiveSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        LabeledContent {
            Capsule()
                .fill(configuration.isOn ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary))
                .frame(width: 36, height: 16)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
                        .frame(width: 22, height: 13)
                        .padding(.horizontal, 1.5)
                }
        } label: {
            configuration.label
        }
    }
}

private struct GuestForm: View {
    let filled: String

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
            ForEach(["Hotel", "Address", "Arrival", "Reference"], id: \.self) { label in
                GridRow {
                    Text(verbatim: label)
                        .foregroundStyle(.secondary)
                        .gridColumnAlignment(.trailing)
                    Text(verbatim: label == "Hotel" ? filled : "")
                        .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                        .padding(.horizontal, 8)
                        .background(.background, in: .rect(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(
                                    label == "Address" ? Color.accentColor : Color(nsColor: .separatorColor),
                                    lineWidth: label == "Address" ? 2 : 1
                                )
                        }
                }
            }
        }
        .font(.system(size: 14))
        .padding(.horizontal, 40)
        .padding(.top, 24)
    }
}

/// reports that Clipsy may read the clipboard, so the privacy pane shows no warning
private struct AllowingPasteboard: PasteboardAccessReading {
    let accessBehavior = NSPasteboard.AccessBehavior.alwaysAllow
}
