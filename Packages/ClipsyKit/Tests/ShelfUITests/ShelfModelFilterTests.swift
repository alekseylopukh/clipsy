import Foundation
import Store
import SwiftUI
import Synchronization
import Testing
@testable import ShelfUI

/// 64 is the deprecated .function bit that a real arrow press still carries
private let arrowPress: EventModifiers = [.numericPad, EventModifiers(rawValue: 64)]

@MainActor
final class ShelfModelFilterTests {
    private let suiteName = "ShelfModelFilterTests-\(UUID().uuidString)"
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    private static let safari = SourceApp(bundleID: "com.example.safari", name: "Safari")
    private static let notes = SourceApp(bundleID: "com.example.notes", name: "Sticky Notes")

    private func makeModel(
        observeSearch: @escaping ShelfModel.SearchObservation = { _, _ in AsyncThrowingStream { $0.finish() } }
    ) -> ShelfModel {
        let model = ShelfModel(
            defaults: defaults,
            observe: { _ in AsyncThrowingStream { $0.finish() } },
            observeBoards: { AsyncThrowingStream { $0.finish() } },
            observeSearch: observeSearch,
            searchDelay: .zero
        )
        model.receiveApps([Self.safari, Self.notes])
        model.receiveBoards([Board(id: 1, name: "Work", color: "blue", createdAt: .now)])
        return model
    }

    @Test func `typing app name suggests token`() {
        let model = makeModel()

        model.query = "invoice saf"
        #expect(model.suggestions == [.app(Self.safari)])

        model.query = "invoice not"
        #expect(model.suggestions == [.app(Self.notes)])

        model.acceptSuggestion(.app(Self.notes))
        #expect(model.query == "invoice ")
        #expect(model.tokens == [.app(Self.notes)])
        #expect(model.suggestions.isEmpty)
    }

    @Test(arguments: [
        ("tex", [SearchToken.kind(.text)]),
        ("TOD", [.date(.today)]),
        ("last", [.date(.last7Days), .date(.last30Days)]),
        ("wor", [.board(id: 1)]),
        ("s", []),
        ("saf ", [])
    ])
    func `suggestions match word prefixes of names`(query: String, expected: [SearchToken]) {
        let model = makeModel()

        model.query = query

        #expect(model.suggestions == expected)
    }

    @Test func `one token per filter`() {
        let model = makeModel()

        model.addToken(.kind(.text))
        model.addToken(.date(.today))
        model.addToken(.kind(.link))

        #expect(model.tokens == [.date(.today), .kind(.link)])
        model.query = "lin"
        #expect(model.suggestions.contains(.kind(.link)) == false)
    }

    @Test func `filter only search observes the filter`() async {
        let requested = Mutex<[ShelfModel.SearchKey]>([])
        let model = makeModel { text, filter in
            requested.withLock { $0.append(ShelfModel.SearchKey(text: text, filter: filter)) }
            return AsyncThrowingStream { continuation in
                continuation.yield([SearchResult(
                    card: CardSummary(id: 7, kind: .link, createdAt: .now),
                    titleMatches: [],
                    previewMatches: []
                )])
                continuation.finish()
            }
        }

        model.addToken(.kind(.link))
        #expect(model.isSearching)
        await model.observeSearch()

        #expect(requested.withLock { $0 } == [ShelfModel.SearchKey(text: "", filter: CardFilter(kind: .link))])
        #expect(model.cards.map(\.id) == [7])
        #expect(model.clearSearch())
        #expect(model.tokens.isEmpty)
        #expect(model.isSearching == false)
    }

    @Test func `backspace in an empty field removes the last token`() {
        let model = makeModel()
        model.addToken(.kind(.text))
        model.addToken(.app(Self.safari))

        model.query = "a"
        #expect(model.removeLastToken() == false)
        model.query = ""
        #expect(model.removeLastToken())
        #expect(model.tokens == [.kind(.text)])
    }

    @Test func `arrows move the suggestion highlight and return accepts it`() {
        let model = makeModel()
        model.query = "last"

        #expect(model.acceptHighlightedSuggestion() == false)
        #expect(model.moveSuggestionHighlight(.next))
        #expect(model.moveSuggestionHighlight(.next))
        #expect(model.moveSuggestionHighlight(.next))
        #expect(model.highlightedSuggestion == .date(.last30Days))
        #expect(model.moveSuggestionHighlight(.previous))
        #expect(model.acceptHighlightedSuggestion())
        #expect(model.tokens == [.date(.last7Days)])
        #expect(model.query.isEmpty)
        #expect(model.highlightedSuggestion == nil)
        #expect(model.moveSuggestionHighlight(.next) == false)
    }

    @Test(arguments: [EventModifiers(), arrowPress])
    func `arrow keys move the suggestion highlight`(modifiers: EventModifiers) {
        let model = makeModel()
        model.isSearchFieldFocused = true
        model.query = "last"

        #expect(model.handleSearchFieldArrow(.next, modifiers: modifiers))
        #expect(model.highlightedSuggestion == model.suggestions.first)
        #expect(model.handleSearchFieldArrow(.next, modifiers: modifiers))
        #expect(model.highlightedSuggestion == model.suggestions.dropFirst().first)
        #expect(model.handleSearchFieldArrow(.previous, modifiers: modifiers))
        #expect(model.handleSearchFieldArrow(.previous, modifiers: modifiers))
        #expect(model.highlightedSuggestion == nil)
        #expect(model.isSearchFieldFocused)
    }

    @Test(arguments: [EventModifiers.shift, .command, .option, .control])
    func `modified arrow keys leave the suggestions to the field`(modifier: EventModifiers) {
        let model = makeModel()
        model.query = "last"

        #expect(model.handleSearchFieldArrow(.next, modifiers: arrowPress.union(modifier)) == false)
        #expect(model.highlightedSuggestion == nil)
    }

    @Test func `down arrow without suggestions moves focus to the cards`() {
        let model = makeModel()
        model.isSearchFieldFocused = true
        model.query = "x"

        #expect(model.handleSearchFieldArrow(.previous, modifiers: arrowPress) == false)
        #expect(model.handleSearchFieldArrow(.next, modifiers: arrowPress))
        #expect(model.isSearchFieldFocused == false)
    }

    @Test func `escape hides the suggestions before it clears the search`() {
        let model = makeModel()
        model.query = "last"
        _ = model.moveSuggestionHighlight(.next)

        #expect(model.cancelSearchField())
        #expect(model.suggestions.isEmpty)
        #expect(model.highlightedSuggestion == nil)
        #expect(model.query == "last")
        #expect(model.cancelSearchField())
        #expect(model.query.isEmpty)
        #expect(model.cancelSearchField() == false)
    }

    @Test func `a deleted board drops its token`() {
        let model = makeModel()
        model.addToken(.board(id: 1))

        model.receiveBoards([])

        #expect(model.tokens.isEmpty)
    }

    @Test func `opening the shelf clears tokens and the browser`() {
        let model = makeModel()
        model.addToken(.kind(.image))
        model.isFilterBrowserPresented = true

        model.didOpen()

        #expect(model.tokens.isEmpty)
        #expect(model.isFilterBrowserPresented == false)
    }
}
