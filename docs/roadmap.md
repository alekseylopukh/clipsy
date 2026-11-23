# Roadmap

The ordered task list for building Clipsy. The `build-clipsy` workflow (`.claude/workflows/build-clipsy.js`) builds it in dependency order, running independent tasks in parallel (see the CLAUDE.md Commands entry); each task ends in one reviewed commit (Conventional Commit title, through the `pre-commit-review` gate), plus a reviewed `fix: integrate T…` commit when combining it with earlier work needs a fix. Behavior lives in [product.md](product.md), UI in [design.md](design.md), structure in [architecture.md](architecture.md), code rules in [.claude/rules/code-rules.md](../.claude/rules/code-rules.md). This file only orders the work; when it disagrees with those docs, the docs win.

## Settled decisions

Settled decisions live in [CLAUDE.md Decisions](../CLAUDE.md#decisions) and in the "Decided" lines of product.md and architecture.md. Read them there; this file does not repeat them.

## Working defaults for open TODOs

Not maintainer decisions. They are the doc's current text or the simplest choice, so tasks can proceed. Each is easy to change later; a task that implements one names it (`WD-n`).

| ID | Open TODO | Working default |
|---|---|---|
| WD-1 | Poll interval, coalescing ([product §4.1](product.md#41-capture)) | 0.5 s poll, 0.1 s tolerance; a change is processed one tick after it is first seen, so multi-step writes coalesce |
| WD-2 | `org.nspasteboard.source`, Universal Clipboard | Ignore both; source is always the frontmost app, remote copies are captured like local ones |
| WD-3 | Secret pattern match | Skip the capture (rule 7) |
| WD-4 | Bookmark for moved files | None; file URL only |
| WD-5 | Link schemes, 8-digit hex | http, https, mailto, ftp, and any scheme followed by `//`; 8-digit hex is Text |
| WD-6 | Paste from shelf moves card to top | No |
| WD-7 | Edit makes a card identical to another | Save is refused with an inline error; the editor stays open |
| WD-8 | Plain-text modifier when plain is the default | No effect (no inverse modifier) |
| WD-9 | Boards | Palette from [design §4](design.md#board-colors), no "no color"; new cards go to the front; the shelf reopens on the last tab; opening the shelf or switching tabs selects the tab's first card; ⇧-arrows and ⇧-click select the range from the anchor card |
| WD-10 | Search scope | Global (History and all boards) |
| WD-11 | Undo scope | Delete only |
| WD-12 | Delete on a board | Removes from the board only |
| WD-13 | Keep shelf open after paste; height per display | No option; one height for all displays |
| WD-14 | Drag-out formats | Same representations as a paste, one pasteboard item per representation item (a multi-file card gives one item per file), each carrying the card's `CardReference`; images also offer a PNG file |
| WD-15 | Compact threshold | Regular card height below 150 pt |
| WD-16 | System Settings deep links | Use a pane URL only if verified on macOS 26; otherwise open System Settings and say where to go |
| WD-17 | Own-write marker type | `app.gonar.clipsy.own-write`, declared in `Store` so `Capture` and `Pasting` share it |
| WD-18 | App Support folder | `~/Library/Application Support/Clipsy/` for `app.gonar.clipsy`; `~/Library/Application Support/<bundle id>/` for any other id ([architecture §3.1](architecture.md#31-files)) |
| WD-19 | Update settings location | About pane |
| WD-20 | Linking new modules into the app | One library product `ClipsyKit` lists every package target; the app links only it. A third-party module reaches the app through a ClipsyKit module that re-exports it with `@_exported import` (KeyboardShortcuts through `ShelfUI`). If the app must link a third-party product directly, stop and ask the maintainer to link it in Xcode. |
| WD-21 | Clipboard previous contents after paste | Not restored; no `currentHostOnly` |
| WD-22 | Shelf size and Dock auto-hide ([design §2](design.md#placement-and-size)) | Minimum height 160 pt (one compact row), default 324 pt, maximum 40% of the visible height; placement uses the display's visible frame, so an auto-hidden Dock is not avoided |
| WD-23 | Frontmost app without a bundle ID ([product §4.1](product.md#41-capture) rule 3) | Counts as no frontmost app, so the capture is skipped |
| WD-24 | Database fails to open at launch ([architecture §3.4](architecture.md#34-migrations)) | An alert shows the error with one "Quit Clipsy" button, then the app quits; no files are moved or deleted. A damaged store is recovered instead (T7.4) |
| WD-25 | Plain-text paste of a Card without a plain string ([architecture §4.2](architecture.md#42-paste)) | Writes every representation, as a normal paste would |
| WD-26 | Sequence details ([product §4.7](product.md#47-sequence)) | Paste All with any non-text Card writes one item per Card, as a multi-paste does; Reverse Order lasts for the app session and affects only Cards added later; the same Card copied twice is queued twice; Clear empties the panel and keeps it open; removing the last Card keeps the panel open, pasting it closes the panel |
| WD-27 | Accessibility alert on paste ([product §4.5](product.md#45-paste-mechanics) step 5, [design §9](design.md#9-onboarding-and-permissions)) | Shown at most once per launch; "Don't ask again" makes that permanent; either way later pastes copy only until Accessibility is granted. "Open System Settings…" calls `AXIsProcessTrustedWithOptions` with the prompt, which lists Clipsy in Privacy & Security and offers the system's own "Open System Settings"; "Copy Only" reactivates the target app so ⌘V works. Since T11.1, Return and ⌘C with several cards selected paste or copy them all |
| WD-28 | Quick Paste details ([product §4.6](product.md#46-quick-paste)) | Badges show only while the modifier is held; a card counts as visible when at least half of it is in view; digits are matched by key position (number row and keypad), so they work on any layout; a stored modifier that is not allowed, or a plain-text modifier equal to the Quick Paste one, falls back to the default; Return, double-click and ⌘C read the plain-text modifier setting (T6.2) |
| WD-29 | Sequence panel ([design §6](design.md#6-sequence)) | First shown at the top-right of the display under the pointer, then wherever the user moved it (AppKit frame autosave); hidden from screen sharing like the Shelf, following the Privacy pane's screenshot setting (`SequencePanelController.isShownInScreenCapture`); rows are a fixed two-line height, up to 6 visible before scrolling; the next marker is an accent dot; the trailing symbol shows the card type; ⌘Z, ⌫ and Esc work while the panel is key, which happens only when the user clicks into it |
| WD-30 | General pane details ([product §6 General](product.md#general), [§4.4](product.md#44-retention)) | The retention slider commits when the drag ends (keyboard steps commit at once); confirmation is asked only when lowering the limit and some History card, on a board or not, is older than the new limit; raising it never purges; the hourly purge uses `ContinuousClock`, so time asleep counts; the Accessibility row's "Open System Settings…" calls the same prompt as WD-27; a login item waiting for approval shows as on, with a button that opens Login Items; Show in menu bar and the click toggle come with T6.4, the storage summary with T7.2 |
| WD-31 | Rename details ([product §4.10](product.md#410-editing-v1)) | Rename trims whitespace; Return saves, Esc or clicking outside discards |
| WD-32 | Card details ([design §3](design.md#3-cards)) | Cards are square and as tall as the strip; the header shows the time of the last copy; a link without a preview shows the `link` symbol with the host name under it, and the footer shows the host without `www.`; rich text is scaled so its most common font size becomes the body size, keeps underline and strikethrough, drops background colors, and a text color under 4.5:1 contrast on the card fill falls back to the label color; rich text wins over the code-like font; code-like text is decided by a line heuristic (`CodeLikeText`); right-clicking an unselected card acts on that card without changing the selection, as in Finder; ⌃-click does not select; image and file cards show their type symbol while the thumbnail or icons load; thumbnails are made when an image Card is first shown (not at capture), at most 800 px on the long side, and the checkerboard is drawn only for images with an alpha channel; a file Card shows the workspace icon of each of its first three files |
| WD-33 | Privacy pane details ([product §6 Privacy](product.md#privacy), [design §8 Privacy](design.md#privacy)) | Ignored Apps keep the order they were added in, adding an app twice does nothing, and removing the Passwords preset is remembered; ⌫ removes the selected apps; the picker opens in /Applications and allows several apps; an app without a bundle ID is refused with an alert, because rule 3 skips it anyway (WD-23); an app that is no longer installed shows its bundle ID and a generic icon; the screenshot toggle sets the Shelf's and the Sequence panel's `sharingType` to `.readOnly` or `.none` at once; Show link previews, Recognize text in images and the clipboard access row come with T9.2, T9.1 and T6.5 |
| WD-34 | Sounds ([product §3.2](product.md#32-shelf-and-cards), [§4.5](product.md#45-paste-mechanics)) | Our own synthesized sounds in `App/Sounds` (regenerate with `scripts/generate-sounds.py`): a short high tick when a card is captured, a soft falling pop after a paste or copy from the shelf; played at system output volume through `NSSound`; a sound already playing is not restarted; the toggle takes effect at once; the capture sound plays from the app's single consumer of `PasteboardMonitor.capturedCardIDs`, which T6.4's bounce shares |
| WD-35 | Menu bar extra details ([design §7](design.md#7-menu-bar-extra)) | An `NSStatusItem`, because SwiftUI's `MenuBarExtra` cannot open the Shelf on a left click; with that setting on, right-click or Control-click shows the menu; Pause Capture is a single item until T7.3 adds the durations, and the pause lasts until resumed or the app quits (T7.3 makes it survive relaunch); Clipsy Help opens the project README and Report an Issue opens a new GitHub issue; AppKit opens Settings through the app menu item the `Settings` scene installs; launching the app again opens Settings only while the item is hidden; the bounce shares the capture sound's single consumer of `capturedCardIDs` (WD-34), so T11.5 has to fan the stream out; VoiceOver announces pause and resume |
| WD-36 | Shortcuts pane details ([product §6 Shortcuts](product.md#shortcuts), [recorder rules](product.md#shortcut-recorder-rules)) | Conflicts with menu items and system shortcuts are rejected by the KeyboardShortcuts recorder's own sheet, which names the menu item; conflicts with another Clipsy shortcut (the other recorders, the fixed shelf keys of product §5 including ⌘, and ⌘Q, and the Quick Paste digits) are rejected inline below the recorder, which keeps its previous value; the ⌥-only warning covers ⌥ and ⌥⇧ and is shown inline but does not reject; each modifier pop-up disables the choice the other one uses; Restore Defaults resets the recorders and both modifiers; Next/Previous Board are stored as KeyboardShortcuts names but unregistered as global hotkeys after every write, because the library registers every stored shortcut |
| WD-37 | Onboarding and clipboard access ([design §9](design.md#9-onboarding-and-permissions), [product §4.1](product.md#41-capture)) | The window opens at the first launch only, marked as shown when it appears, so closing it early also counts; it is a SwiftUI `Window` scene with `defaultLaunchBehavior`; `.default` access counts as not gated (macOS never asked), so step 3 and the Privacy row are skipped; the clipboard step is decided when leaving step 2; permission rows poll every second while their step is visible, the Privacy row refreshes when Settings becomes active; the launch and wake explanation is an alert shown at most once per launch with "Don't ask again", skipped at the launch that shows onboarding; Finish uses a pop-up for Keep history for and asks before a shorter limit removes cards, as the General pane does; `OnboardingFlow` lives in `Capture` so it can be tested |
| WD-38 | Text recognition details ([product §3.2](product.md#32-shelf-and-cards), [§6 Privacy](product.md#privacy)) | Every image Card (PDF included) is marked pending at capture, whatever the toggle says; the queue in `Media` works only while "Recognize text in images" is on, newest Card first, so turning it on later also covers earlier images; turning it off stops after the Card in progress and keeps text already recognized; `.accurate` with automatic language detection; a Card whose image cannot be decoded or whose recognition throws is marked failed and not retried; pending Cards survive relaunch because the state is in the database; recognized text is searchable but not highlighted, since it is not shown on the Card |
| WD-39 | Top bar details ([design §4](design.md#4-top-bar), [empty states](design.md#empty-states)) | ⌘← and ⌘→ stop at the first and last tab, as the arrows stop at the first and last card; while the search field has focus they move the caret instead; the customized shortcuts are read by `TabShortcuts` from the storage of the `.previousBoard` and `.nextBoard` names that the Shortcuts pane records (WD-36), which stay unregistered as global hotkeys; Esc clears a non-empty search, otherwise closes the shelf; New Board, New Text Card and Start Sequence stay disabled until T5.2, T8.4 and T11.5 set their handlers on `ShelfController.commands`; Pause/Resume Capture and the Capture Paused empty state read and set the app's `CapturePause`, the same one the menu bar extra and ⌘T toggle; the Capture Paused empty state replaces the History one while capture is paused, and empty states wait for the tab's first load; until T5.4 the query does not filter the cards, so No Results shows only when the tab is empty too; the selected tab is marked by the `TabTrack` lens, which slides to it on `standard` ([design §4](design.md#4-top-bar)); the filters button comes with its filters |
| WD-40 | Link preview details ([product §3.2](product.md#32-shelf-and-cards), [design per-type layouts](design.md#per-type-layouts)) | `LinkPreviewFetcher` (Media) fetches in the background after a capture or a re-copy, fed by the app's single consumer of `capturedCardIDs` (WD-34), one link at a time, only for http and https links and only while the setting is on, checked when each fetch starts; a card that has a preview is not fetched again, and a failed fetch is retried only when the link is copied again, so links copied while the setting was off get a preview on their next copy; turning the setting off keeps previews already fetched; the trimmed page title goes into `metadata.pageTitle` and replaces the card's search body (the URL stays searchable through the `url` column); the page image is downsampled into `Thumbnails/` under the card's content hash (so retention GC keeps it with the card), and its stored pixel size goes into the link card's `pixelWidth` and `pixelHeight`, which mark that the image exists; no favicon is fetched; a card with a title but no image shows the title under the `link` symbol instead of the host name; VoiceOver reads the page title as the card's value |
| WD-41 | Starting and collecting a Sequence ([product §4.7](product.md#47-sequence), [§5](product.md#global-customizable)) | While the shelf is open, the Start Sequence shortcut and the menu bar item seed the Sequence with the selected cards in shelf order (an empty Sequence with nothing selected), never synthesize ⌘C, and leave the shelf open; otherwise they open the panel and, with Accessibility, post ⌘C to the frontmost app; without it the panel opens empty and nothing asks for the permission (the paste flow asks, WD-27); pressing the shortcut again while a Sequence is open copies the next selection into it; a capture while capture is paused or skipped by the ignore rules does not join; when a capture joins, the head is written back to the pasteboard, which the copy replaced (a copy that is not captured leaves it replaced); Start Sequence may use Copy as Plain Text's combination (⇧⌘C by default), and the shelf then shows Copy as Plain Text without a shortcut; content dropped on the panel from another app is recorded with the frontmost app as its source and joins through the capture stream (sound and bounce included), even while capture is paused, because a drop is explicit; ⌃⌥⌘V does nothing while no Sequence is open |
| WD-42 | Board management ([product §4.8](product.md#48-boards)) | A new board starts with the first palette color no board uses, else cycles the palette; the New/Edit Board sheet has a name field (prompt "Untitled") and the swatch row, which is one Tab stop that ← and → move through; a Board tab's context menu has Edit Board…, a Color submenu and Delete Board…; in the shelf ⇧⌘E edits and ⇧⌘⌫ deletes the current board; dropping a Board tab on another puts it before that one when moved left and after it when moved right; the delete confirmation names the board and says what happens to its cards |
| WD-43 | Updater details ([design §8 About](design.md#about)) | Sparkle lives in the `Updates` module, whose `AppUpdater` starts `SPUUpdater` at launch only when automatic checks are on, otherwise at the first manual check or when the toggle is turned on; the toggle is Sparkle's own `automaticallyChecksForUpdates` default; a check that cannot start (for example while the public key is a placeholder) shows an alert; Check for Updates… is never disabled, since Sparkle brings an update already on screen to the front; Sparkle's standard update window is used, without gentle reminders; Acknowledgements opens a sheet with `App/Credits.rtf` |
| WD-44 | Search in the shelf ([product §4.9](product.md#49-search-and-filters)) | Search covers History and all boards whatever the tab; choosing a tab and reopening the shelf clear the search; a printable key without ⌘, ⌃ or ⌥ while the cards have focus starts a search with that character and leaves the caret after it, while Space alone does not (it is reserved for preview); ⌘F focuses the field and selects its text; the query is debounced by 150 ms and results follow the database live; each new query selects the first result, and a live update keeps the selected result if it is still there, else selects the first; Return in the field pastes the selection and honors the plain-text modifier like double-click; ↓ and Tab in the field move focus to the cards, so Tab from the field skips the Board switcher that [design §10](design.md#10-accessibility-and-appearance) puts between them, and Tab from the cards follows the window's key view loop; Delete and Remove from Board act on the list each result is in: the current tab if the card is in it, else History if the card is there, else its board, so one action can remove cards from several lists and one ⌘Z restores them all; the menu and the confirmation say Delete when a selection spans several lists; matches in the title and preview text are drawn on the system find-highlight color, and a highlighted text card shows its plain preview instead of rich text; the board dot sits after the time and names the board in its tooltip and in VoiceOver custom content |
| WD-45 | Show in List ([product §3.2](product.md#32-shelf-and-cards)) | ⌘G and the context menu item "Show in List" (Item section, before Rename…) appear only for a single search result; the target is the list the result's Delete acts on (WD-44): the current tab if the card is in it, else History, else its board; the search clears, focus moves to the cards, the card is selected and scrolled to the middle of the strip so cards on both sides show; if the card is gone by the time the list loads, the first card is selected; ⌘G with several cards selected or outside a search does nothing |
| WD-46 | Filter tokens and browser ([product §4.9](product.md#49-search-and-filters), [design §4](design.md#4-top-bar)) | Typed suggestions cover type, date range (presets only), app and board names, matched case- and diacritic-insensitively against the start of any word of the name once the last typed word has at least 2 characters, at most 6, types first, then dates, apps and boards; they show in a list under the search field while it has focus; ↓ and ↑ move the highlight (↓ moves focus to the cards only while no suggestion is shown, Tab always does), Return or a click turns the highlighted suggestion into a token and removes the typed word, Return without a highlight pastes as before; one token per filter, so a new one replaces the old one of its kind; a token shows its symbol (an app icon, a board dot) and name, a click on it removes it, and ⌫ in an empty field removes the last one; Esc clears the text and the tokens together; a deleted board drops its token; the App section and suggestions list only apps that still have cards, by name; the Filters button sits right of the search field and opens a popover with a list of Type, App, Date and Board; Return or a click toggles the row's filter (checkmark) and keeps the popover open so filters can be combined, Esc closes it; Custom Range… shows From and Through date pickers and an Apply Range button that takes Return while they are shown; the search field grows to fit its tokens; opening the shelf and choosing a tab clear the tokens |
| WD-47 | Pause for a duration ([product §6 Menu bar menu](product.md#menu-bar-menu), [design §7](design.md#7-menu-bar-extra)) | "Until Tomorrow" ends at the next midnight in the user's calendar; 15 minutes, 1 hour and 8 hours are wall-clock time; every pause, including Until Resumed, is stored in UserDefaults and survives relaunch, and one that ended while the app was quit is cleared at launch; ⌘T pauses until resumed; the disabled line reads "Paused until <time>", with the abbreviated weekday when the time is not today |
| WD-48 | Text editor details ([product §4.10](product.md#410-editing-v1), [design edit sheet](design.md#edit-sheet)) | No modified time is stored, since nothing shows it; an edit keeps created and copied times. The sheet is capped at the Shelf's height instead of opening a standalone window. Rich text is saved as RTF (RTFD with attachments) plus the plain string when the card had rich text or any B/I/U/S is applied; otherwise as the plain string only. ⌘E opens the editor for text cards; link and color cards follow in T8.5. Closing the Shelf discards an open editor |
| WD-49 | Quick Look and file thumbnails ([design §5](design.md#quick-look), [product §6 Privacy](product.md#privacy)) | Space previews the Card under the keyboard cursor, so with several Cards selected the last one clicked or reached by arrow; Space again or Esc closes the preview, and Esc clears the search or closes the Shelf only when no preview is open; images use our own view instead of `QLPreviewView` so their data never leaves the store; several files show a list; text previews show at most 20,000 characters; colors show Hex, RGB and HSL; file thumbnails have no toggle, use Quick Look's icon mode (as Finder does), fall back to the workspace icon when the file is missing or Quick Look fails, and are cached in memory only |
| WD-50 | App Intents details ([product §3.7](product.md#37-integrations)) | The intents are declared in the app target and call `CardIntentHandler` (Integrations), registered with `AppDependencyManager` at launch, and run in the background without showing the Shelf. Create Card takes text only, classified like a copy (so a link or color becomes that kind) with Clipsy as the source app, and goes to the front of the chosen board, else to History, as ⌘N does; empty text and text that is already a card are refused with an error. Create Board takes a name; its color follows WD-42. Get Card at Index counts from 1 in the Shelf's order, History newest first when no board is chosen. Get Latest Card of Type is the newest History card of that type. Create Card and both Get intents return a Card with Title, Type, Text (the plain text, else the preview), Source App, Created and Last Copied; a missing card is an error, not an empty result |
| WD-51 | Link and color editing ([product §4.2](product.md#42-type-detection), [§4.10](product.md#410-editing-v1), [design edit sheet](design.md#edit-sheet)) | The link editor's title field is the card's custom title (prompt: the fetched page title); saving with an unchanged URL only renames, so the link preview is kept; a changed URL replaces the content with the trimmed plain string and is classified like a copy. Color formats are Hex (`#1A2B3C`) and RGB (`rgb(26, 43, 60)`), both exact for 8-bit sRGB; to keep an RGB value a color card, type detection accepts the rgb form too, also on capture. Colors picked in another space (Display P3) are converted and clamped to sRGB; opacity is not offered. The editor opens in the card's format; typing a valid value switches the picker to its format; saving an unchanged value writes nothing, otherwise the value is written canonically in the chosen format. While the editor is open the color panel stays visible although the app is inactive behind the non-activating Shelf, and it closes with the editor |

## Rules for every task

- Acceptance always also includes: `scripts/build.sh` builds with no new warnings, `scripts/build.sh test` passes, and `scripts/lint.sh` is clean.
- Tests use Swift Testing, fakes at IO boundaries, private named pasteboards and synthetic fixtures ([code-rules R8](../.claude/rules/code-rules.md#r8-tests)).
- A task that settles a TODO or deviates from a doc updates that doc in the same commit.
- A finished task adds `- Status: done` as the last field of its section, in the same commit.
- `- Human check:` marks steps an agent cannot verify (TCC prompts, real paste into other apps, visual review). The workflow records them in the PR description and the maintainer signs off; the task still commits.
- UI tasks load the `macos-native-ui` skill first and run its Verify steps.

## M0. Project skeleton — done

What exists:
- `Clipsy.xcodeproj`, with `App/` as a synchronized group: a menu bar shell and a Settings scene placeholder.
- `Packages/ClipsyKit`, with one module, `Capture` (`HexColor` and its tests), exposed through the umbrella product `ClipsyKit`.
- `scripts/build.sh` and the commands in CLAUDE.md.
- The decisions recorded in CLAUDE.md, product.md and architecture.md.

## M1. Foundations and Store

### T1.1 Record settled decisions in the docs
- Module(s): docs only
- Depends on: none
- Spec: this file, "Settled decisions"
- Deliverable: the dependency line in [architecture §6.1](architecture.md#61-layout) gains `Pasting` → `Store` and `Capture` → `Store`. The recorder row in [design §11](design.md#11-component-mapping) names KeyboardShortcuts.
- Acceptance: both lines read as described.
- Size: S
- Status: done

### T1.2 Build and test in CI, umbrella product
- Module(s): package manifest, CI, CLAUDE.md
- Depends on: T1.1
- Spec: [architecture §6.3](architecture.md#63-ci-github-actions), WD-20
- Deliverable: `Package.swift` adds the targets `Store`, `Media`, `Pasting`, `DesignSystem` and `ShelfUI`, each with a test target and the dependency directions of §6.1, all in the umbrella product `ClipsyKit`. `.github/workflows/build.yml` runs `scripts/build.sh` and `scripts/build.sh test` on a macOS runner, with ad-hoc signing and an SPM cache.
- Acceptance: both commands pass locally; workflow YAML passes `actionlint` if installed; the runner label is the one GitHub documents for an Xcode with the macOS 26 SDK, or a `> TODO:` if it cannot be confirmed
- Size: S
- Status: done

### T1.3 Database bootstrap and initial schema
- Module(s): Store
- Depends on: T1.2
- Spec: [architecture §3.1](architecture.md#31-files), [§3.2](architecture.md#32-schema), [§3.4](architecture.md#34-migrations), WD-18
- Deliverable: GRDB dependency (notice row added); `AppDatabase` opening a `DatabasePool` at a given URL (directory created 0700) or in a temp directory for tests; `DatabaseMigrator` with `v1_initial` creating `card`, `representation`, `board`, `source_app`, `card_search` exactly as §3.2; `CardKind` enum
- Acceptance: tests `migrationCreatesAllTables`, `cardRequiresHistoryOrBoard` (CHECK rejects a row with neither), `representationRequiresExactlyOnePayload`, `searchTokenizerFoldsDiacritics`, `directoryIsOwnerOnly`
- Size: M
- Status: done

### T1.4 Payload file store
- Module(s): Store
- Depends on: T1.3
- Spec: [architecture §3.3](architecture.md#33-payload-storage)
- Deliverable: `PayloadStore`: inline below 4 KB, otherwise SHA-256-named file in `Payloads/<aa>/`, written to temp then renamed; read back; delete unreferenced files and thumbnails (`collectGarbage(referenced:)`)
- Acceptance: tests `smallPayloadStaysInline`, `largePayloadIsContentAddressed`, `identicalPayloadsShareOneFile`, `garbageCollectionKeepsReferencedFiles`, `crashBeforeInsertLeavesOnlyOrphan`
- Size: S
- Status: done

### T1.5 Insert and re-copy cards
- Module(s): Store
- Depends on: T1.4
- Spec: [product §4.3](product.md#43-dedupe-and-re-copy), [architecture §4.1](architecture.md#41-capture) steps 5–6
- Deliverable: `NewCard` input (kind, ordered representations, content hash, preview text, metadata JSON, source app, search body/URL/file names for `card_search`); `CardRepository.record(_:)` that upserts `source_app`, inserts card + representations + search row in one transaction, or on an existing hash sets `last_copied_at` and source app; `representations(of:)` reading payloads back in original order
- Acceptance: tests `newCardIsInsertedWithSearchRow`, `sameHashMovesCardToTop` (created_at unchanged), `boardOnlyCardReturnsToHistory`, `representationsRoundTripInOrder`
- Size: M
- Status: done

### T1.6 History and board queries with observation
- Module(s): Store
- Depends on: T1.5
- Spec: [architecture §3.2](architecture.md#32-schema), [product §3.2](product.md#32-shelf-and-cards)
- Deliverable: `CardSummary` value (id, kind, title, preview, metadata, source app, times, board id); queries for History (newest first) and a board (by position); `AsyncSequence` observation of each via `ValueObservation`
- Acceptance: tests `historyIsNewestFirst`, `boardIsByPosition`, `observationEmitsOnInsert`, `historyExcludesBoardOnlyCards`
- Size: M
- Status: done

### T1.7 Boards in the store
- Module(s): Store
- Depends on: T1.6
- Spec: [product §4.8](product.md#48-boards), [architecture §4.5](architecture.md#45-retention-cleanup) last paragraph, WD-9
- Deliverable: create (empty name → "Untitled"), rename, recolor, reorder, delete; add card (moves from another board, goes to front), remove card (deletes it if not in History), reorder inside a board with fractional positions
- Acceptance: tests `addToSecondBoardMoves`, `removeFromBoardDeletesCardOutsideHistory`, `deleteBoardKeepsHistoryCards`, `deleteBoardDeletesBoardOnlyCards`, `reorderBetweenNeighbors`, `emptyNameBecomesUntitled`
- Size: M
- Status: done

### T1.8 Retention, Erase History, delete and restore
- Module(s): Store
- Depends on: T1.7
- Spec: [product §4.4](product.md#44-retention), [§4.11](product.md#411-deleting), [architecture §4.5](architecture.md#45-retention-cleanup), WD-11, WD-12
- Deliverable: `RetentionPeriod` enum (default 1 Month); `purge(olderThan:)`, `eraseHistory()`, both followed by garbage collection; `delete(cards:in:)` with History/board semantics returning a snapshot that `restore(_:)` puts back (for undo)
- Acceptance: tests `purgeKeepsBoardCardsAndClearsTheirHistory`, `purgeDeletesExpiredHistoryCards`, `eraseHistoryKeepsBoards`, `deleteOnBoardKeepsHistory`, `restoreUndoesDelete`, `purgeCollectsOrphanPayloads`
- Size: M
- Working default: `RetentionPeriod.cutoff` subtracts one calendar day, week, month or year; a card copied exactly at the cutoff is kept. `delete` does not collect garbage, so `restore` can reuse the payload files; a card whose payload file was collected since is not restored. When a card with the same content exists again at restore time (copied again), restore puts the deleted membership back on that card instead of inserting a second one; a card whose id was reused meanwhile comes back under a new id
- Status: done

### T1.9 Full-text search query
- Module(s): Store
- Depends on: T1.6
- Spec: [product §4.9](product.md#49-search-and-filters), [architecture §3.2](architecture.md#32-schema), WD-10
- Deliverable: `search(_ text:)` over History and boards, word-prefix, case- and diacritic-insensitive, newest first, returning `CardSummary` plus board id and match ranges for highlighting; query text escaped for FTS5 syntax
- Acceptance: tests `prefixMatches`, `diacriticsAreFolded`, `matchesAppName`, `fts5OperatorsInInputAreLiteral`, `resultsIncludeBoardOnlyCards`
- Size: M
- Working default: "newest" is `last_copied_at`, or `created_at` for a board-only card; every run of letters and digits in the query is a quoted prefix term, terms combine with AND; match ranges cover the matched prefix in the title and preview text
- Status: done

## M2. Capture

### T2.1 Pasteboard reading and size cap
- Module(s): Capture, Store
- Depends on: T1.5
- Spec: [product §4.1](product.md#41-capture) rule 3, [architecture §4.1](architecture.md#41-capture) step 3, WD-17
- Deliverable: `PasteboardReading` protocol (change count, items, types, data); `NSPasteboard` conformance; `PasteboardSnapshot` reader that drops junk types (source markers, OLE link types, own marker) and any representation over 50 MB, returning nil when nothing is left; marker type constant in Store
- Acceptance: tests on a private named pasteboard: `readsAllItemsAndTypesInOrder`, `dropsJunkTypes`, `dropsOversizedRepresentation`, `emptyAfterFilteringIsNil`
- Size: M
- Status: done

### T2.2 Type classifier
- Module(s): Capture
- Depends on: T2.1
- Spec: [product §4.2](product.md#42-type-detection), WD-5
- Deliverable: `classify(_ snapshot:) -> CardKind` in the §4.2 order, reusing `HexColor`; File vs Multiple files kept in metadata
- Acceptance: parameterized test `classification` covering every row of the §4.2 tables plus `mailto:`, `ftp://`, `custom://x`, a URL with spaces, and 8-digit hex
- Size: S
- Status: done

### T2.3 Content hash, preview and metadata
- Module(s): Capture
- Depends on: T2.2
- Spec: [product §4.3](product.md#43-dedupe-and-re-copy), [architecture §3.2](architecture.md#32-schema) rules
- Deliverable: SHA-256 over sorted `(uti, data)` pairs (CryptoKit); preview text (first ~1000 chars); per-kind metadata (URL, pixel size, file count and names, color value, char/word/line counts); builds `NewCard`
- Acceptance: tests `sameTextFromTwoAppsSameHash`, `richAndPlainDiffer`, `typeOrderDoesNotChangeHash`, `imageMetadataHasPixelSize`, `fileMetadataHasNames`
- Size: S
- Status: done

### T2.4 Skip rules
- Module(s): Capture
- Depends on: T2.1
- Spec: [product §4.1](product.md#41-capture) rule 2, Ignored Apps paragraph, [architecture §5](architecture.md#5-permissions-and-privacy), WD-23
- Deliverable: `CapturePolicy` value (paused, ignored bundle IDs, ignore concealed, ignore transient); `SkipReason` enum; evaluation in the documented order; concealed, transient, auto-generated and legacy types; password-manager bundle IDs each verified from the vendor app's Info.plist or official docs, otherwise left out with a `> TODO:` in product.md
- Acceptance: parameterized test `eachRuleSkips`, test `rulesApplyInDocumentedOrder`, test `togglesOffLetContentThrough`
- Size: M
- Status: done

### T2.5 Pasteboard monitor and pipeline
- Module(s): Capture
- Depends on: T2.3, T2.4, T1.5
- Spec: [architecture §4.1](architecture.md#41-capture), [product §4.1](product.md#41-capture) rules 1, 5, 6, WD-1, WD-2
- Deliverable: `@MainActor` monitor polling change count via an injected clock and `FrontmostAppProviding`; own-write check through an injected closure; reading on main, hashing and DB write off main; last handled change count persisted through an injected store; emits captured card ids as an `AsyncStream` (for the menu bar effect and the Sequence)
- Acceptance: tests with fakes: `changeProducesOneCard`, `multiStepWriteCoalesces`, `ownWriteIsIgnored`, `relaunchDoesNotRecapture`, `pausedProducesNothing`
- Size: M
- Status: done

### T2.6 Start capture in the app
- Module(s): App
- Depends on: T2.5
- Spec: [architecture §3.4](architecture.md#34-migrations), [§4.1](architecture.md#41-capture)
- Deliverable: app startup opens the database (migrations before any UI; on failure an alert and no file changes, WD-24), starts the monitor with default policy, wires own-write closure placeholder
- Acceptance: launching the built app creates the store in App Support with mode 0700
- Human check: copy text, a URL, an image and a Finder file; `sqlite3 <store> "select kind, count(*) from card group by kind"` shows four kinds (never print contents); the store folder is mode 0700 (`stat -f %Lp`); with the store folder at `chmod 000`, launching shows the WD-24 alert and quits, and the folder is unchanged (restore with `chmod 700`)
- Size: S
- Status: done

## M3. Shelf UI

### T3.1 Design tokens and board colors
- Module(s): DesignSystem
- Depends on: T1.2
- Spec: [design §2](design.md#placement-and-size), [§3](design.md#states), [§4](design.md#board-colors)
- Deliverable: spacing, insets, radii, card size, ring width (+1 pt with Increase Contrast), badge size; `BoardColor` enum mapped to system colors
- Acceptance: test `boardColorRoundTripsStoredName` for all seven colors
- Size: S
- Status: done

### T3.2 Shelf panel
- Module(s): ShelfUI
- Depends on: T3.1
- Spec: [product §4.13](product.md#413-shelf-window-behavior), [design §2](design.md#2-shelf), [design §11](design.md#11-component-mapping)
- Deliverable: non-activating `NSPanel` subclass with glass container hosting SwiftUI; placement on the pointer's display, inset above a bottom Dock; joins active Space and full-screen Spaces; `sharingType = .none` by default; show/hide records the target app; closes on Esc, focus loss (except own sheets/menus); open/close motion with Reduce Motion fallback; top-edge resize between one row and 40% of the visible height, persisted (WD-13, WD-22)
- Acceptance: tests `frameIsInsetAboveDock`, `heightIsClampedToRange` for a pure frame calculator
- Human check: opens over a full-screen app without switching Spaces; TextEdit keeps its caret and stays frontmost; clicking elsewhere closes it; a screen recording does not show it; height survives relaunch
- Size: M
- Status: done

### T3.3 Global shelf shortcut
- Module(s): App
- Depends on: T3.2
- Spec: [product §5](product.md#global-customizable)
- Deliverable: KeyboardShortcuts dependency (notice row); `.toggleShelf` name, default ⇧⌘V; second press closes
- Acceptance: build passes with the dependency resolved through the umbrella product (WD-20)
- Human check: ⇧⌘V toggles the shelf from Finder, Safari and a full-screen app
- Size: S
- Status: done

### T3.4 Shelf model: list, selection, navigation
- Module(s): ShelfUI
- Depends on: T1.6, T3.2
- Spec: [product §4.12](product.md#412-multi-select), [§5 In the shelf](product.md#in-the-shelf), WD-9
- Deliverable: `@Observable ShelfModel` fed by store observation: current tab, cards, single and multi selection (← → ⌘↑ ⌘↓ ⇧← ⇧→ ⌘-click ⇧-click ⌘A), newest selected on open, last tab remembered
- Acceptance: tests `arrowsMoveSelection`, `shiftArrowExtends`, `commandClickToggles`, `selectAllSelectsCurrentList`, `selectionSurvivesInsertAtFront`, `openSelectsNewest`
- Size: M
- Status: done

### T3.5 Card view: chrome, text, link, color, unknown
- Module(s): ShelfUI, DesignSystem
- Depends on: T3.4
- Spec: [design §3](design.md#3-cards), [§10](design.md#10-accessibility-and-appearance)
- Deliverable: card strip (`ScrollView` + `LazyHStack`), header (app icon, title or type label, relative time), footer, selection ring; bodies for plain and rich text, code-like text, link without preview, color, unknown; VoiceOver label, value and custom actions
- Acceptance: `#Preview`s with mock data for each type; test for the code-like heuristic
- Human check: light and dark, Increase Contrast, VoiceOver reads "Text from TextEdit, 2 minutes ago"
- Human check: ← → ⇧← ⇧→ ⌘↑ ⌘↓ ⌘A move and extend the selection and the strip scrolls to follow it; click, ⌘-click, ⇧-click and double-click behave as in product §5
- Human check: a rich text card copied from TextEdit or Pages shows its fonts and colors; dark text stays readable in dark mode
- Size: M
- Working default: WD-32. The shelf's arrow keys and ⌘A were not wired to `ShelfModel` yet, so this task adds them to `ShelfController`; the strip also wires the Quick Paste badges (T4.4), the context menu (T5.1, with WD-32's right-click rule instead of selecting first) and drag into the Sequence panel (`CardReference`, T11.4)
- Status: done

### T3.6 Card view: image and file
- Module(s): Media, ShelfUI
- Depends on: T3.5
- Spec: [design §3 Per-type layouts](design.md#per-type-layouts), [architecture §1](architecture.md#1-overview) thumbnails row
- Deliverable: ImageIO downsampled thumbnail off the main actor, cached in `Thumbnails/`; image body with checkerboard; file and multiple-files bodies with workspace icons (Quick Look thumbnails come in T8.1)
- Acceptance: tests `thumbnailFitsRequestedSize`, `thumbnailIsCachedByHash`
- Human check: a 20 MB screenshot card scrolls without stutter
- Size: M
- Status: done

### T3.7 Top bar, tabs, empty states
- Module(s): ShelfUI
- Depends on: T3.5
- Spec: [design §4](design.md#4-top-bar), [empty states](design.md#empty-states), [product §4.9](product.md#49-search-and-filters)
- Deliverable: glass top bar with search field, History and board capsules, New Board button, More menu; `ShelfModel` falls back to History when its remembered board no longer exists; ⌘← ⌘→ switch tabs (customizable shortcuts read locally, not registered globally); Esc clears search then closes; empty states for History, board, no results, paused
- Acceptance: tests `escClearsSearchFirst`, `tabShortcutsSwitchTabs` on the model
- Human check: keyboard-only pass: Tab cycles the search field and the tab capsules with visible focus (cards join the cycle with T5.4); on open the search field is not focused, so ← → still move the card selection
- Human check: the top bar is glass, the selected tab uses prominent glass, board dots keep their color; Esc in the search field clears it, a second Esc closes the shelf; ⌘← ⌘→ switch tabs and ⌘← does not reach other apps while the shelf is closed; Settings… in the More menu opens Settings
- Size: M
- Working default: WD-39
- Status: done

## M4. Pasting

### T4.1 Pasteboard writer and own-write ledger
- Module(s): Pasting
- Depends on: T1.5, T2.5
- Spec: [product §4.5](product.md#45-paste-mechanics) step 2, [architecture §4.2](architecture.md#42-paste), WD-17, WD-21, WD-25
- Deliverable: `PasteboardWriter` that clears the pasteboard, writes all representations in item and type order (or plain text only), adds the marker, records the change count and answers `isOwnWrite(_:)`; the app wiring moved to T4.3, the first task that writes from the app (the monitor is started by T2.6)
- Acceptance: tests on a private pasteboard: `writesAllRepresentationsInOrder`, `plainWritesOnlyString`, `markerIsPresent`, `ledgerMatchesChangeCount`
- Size: S
- Status: done

### T4.2 Synthesized ⌘V and Accessibility
- Module(s): Pasting
- Depends on: T4.1
- Spec: [product §4.5](product.md#45-paste-mechanics) step 4, [architecture §4.2](architecture.md#42-paste) step 5, [§5](architecture.md#5-permissions-and-privacy)
- Deliverable: key code for "V" from the ASCII-capable layout (`UCKeyTranslate`); `CGEvent` ⌘V with left-Cmd flag; `AccessibilityTrust` protocol (check, prompt); notice for any code adapted from Maccy, Clipy or Flycut
- Acceptance: test `keyCodeForVOnUSLayoutIs9` against the US layout input source
- Human check: paste works into TextEdit, Safari, Terminal and an Electron app; with Dvorak–QWERTY ⌘ layout
- Size: M
- Status: done

### T4.3 Paste flow from the shelf
- Module(s): ShelfUI, Pasting, App
- Depends on: T4.2, T3.4, T2.6
- Spec: [product §4.5](product.md#45-paste-mechanics), [design §9 Rules](design.md#9-onboarding-and-permissions), WD-6, WD-8
- Deliverable: the app creates one `PasteboardWriter` and passes its `isOwnWrite` to the capture monitor in place of T2.6's placeholder; `PasteCoordinator`: Return and double-click paste, ⇧ for plain, ⌘C copies, copy-only setting, plain-by-default setting; hide shelf, reactivate target if needed, then post ⌘V; first paste without Accessibility shows the alert with "Don't ask again"
- Acceptance: tests with fakes: `copyOnlyNeverPostsKeystroke`, `missingTrustAsksOnce`, `shiftForcesPlain`, `pasteHidesShelfBeforeKeystroke`
- Human check: the alert appears once with Accessibility revoked; afterwards Return copies only
- Human check: with Accessibility granted, Return pastes the newest card into TextEdit, ⇧Return pastes it as plain text and ⌘C only copies (the card strip arrives with T3.5, so check after both land)
- Note: the card view (T3.5) wires double-click and ⇧-double-click to `ShelfController.perform(_:cardID:plainModifier:)`; WD-27 covers the alert details
- Size: M
- Status: done

### T4.4 Quick Paste
- Module(s): ShelfUI
- Depends on: T4.3
- Spec: [product §4.6](product.md#46-quick-paste), [design quick-paste badges](design.md#quick-paste-badges)
- Deliverable: badges 1–9 on the first visible cards while the modifier is held; modifier + digit pastes, with ⇧ as plain text; modifiers from settings
- Acceptance: tests `badgesCountFromFirstVisibleCard`, `digitBeyondVisibleCountDoesNothing`
- Human check: badges follow scrolling; ⇧⌘3 pastes the third visible card as plain text
- Human check: badge digits are legible on glass in light and dark (offscreen rendering cannot draw Liquid Glass)
- Note: settings keys `QuickPasteModifier` and `PlainTextModifier` (`QuickPasteModifiers`), WD-28. The card strip (T3.5) wires the badges: it reports `onScrollTargetVisibilityChange(idType: Int64.self, threshold: 0.5)` to `ShelfModel.setVisibleCards(_:)` and applies `.quickPasteBadge(model.quickPasteNumber(for: card.id))` to each card; whichever of T3.5 and T4.4 lands second adds those two lines, so the human checks need both
- Size: S
- Status: done

## M5. Organize

### T5.1 Context menu, open, delete and undo
- Module(s): ShelfUI
- Depends on: T4.3, T1.8
- Spec: [design card context menu](design.md#card-context-menu), [product §4.11](product.md#411-deleting), WD-11, WD-12
- Deliverable: context menu with MVP items (Paste to App, Paste as Plain Text, Copy, Copy as Plain Text, Open, Add to Board, Remove from Board, Delete), hidden when not applicable; ⌘O opens links and files; ⌫ deletes (confirmation with count for several); ⌘Z restores while the shelf is open
- Acceptance: tests `deleteSeveralNeedsConfirmation`, `undoRestoresDeletedCards`, `multiSelectionMenuHasOnlyBatchItems`
- Human check: menu matches design.md order and symbols
- Human check: with three cards selected, ⌫ shows the count in a sheet on the shelf; Delete removes them, ⌘Z brings them back, and after closing and reopening the shelf ⌘Z does nothing
- Human check: ⌘O on a link card opens the browser; on a file card it opens the file in its default app
- Size: M
- Working default: Add to Board moves to T5.3, which already delivers the submenu and needs the board list that arrives with T3.7. Inside a board, Delete is hidden and Remove from Board takes its place, because under WD-12 they do the same thing; ⌫ there removes from the board with the same confirmation and undo. Paste as Plain Text and Copy as Plain Text are hidden for image and file cards. Several selected cards offer Paste, Paste as Plain Text, Copy and Delete or Remove from Board, which act on all of them. ⌘Z undoes deletes one at a time, newest first, and the undo history is dropped when the shelf closes. After a delete the next card is selected, else the previous one
- Note: the card view (T3.5) attaches `CardContextMenu(cards:list:)` with `.contextMenu`, passing the selected cards when the clicked card is selected and otherwise selecting the clicked card first; `CardActions` reaches it through the environment set by `ShelfController`
- Status: done

### T5.2 Board management UI
- Module(s): ShelfUI
- Depends on: T1.7, T3.7
- Spec: [product §4.8](product.md#48-boards), [design §4](design.md#board-colors), WD-9
- Deliverable: New/Edit Board sheet (name, swatch row) via ⇧⌘N and the plus button; rename, recolor, delete (confirmation) from the capsule's context menu; reorder capsules by drag
- Acceptance: test `newBoardBecomesCurrentTab` on the model
- Human check: create, rename, recolor, reorder and delete a board using only the keyboard plus one drag
- Size: M
- Status: done

### T5.3 Cards on boards
- Module(s): ShelfUI
- Depends on: T5.2
- Spec: [product §3.5](product.md#35-boards), [§4.8](product.md#48-boards)
- Deliverable: Add to Board submenu (with New Board…) and Remove from Board for single and multi selection; drop cards on a capsule; drag to reorder inside a board
- Acceptance: tests `addSelectionToBoard`, `dropOnCapsuleAdds`
- Human check: reordered board survives relaunch
- Human check: select one card, then several, and press ⌘B; the board menu opens at the selected card, arrows and Return add the cards, Esc closes it, and New Board… opens the sheet
- Human check: drag a card and a multi-selection onto a board capsule (the capsule highlights while targeted), then drag cards inside the board to reorder them; light and dark
- Size: M
- Working default: Add to Board sits in the Organize section before Add to Sequence and lists every board except one that already holds all the selected cards, then New Board…, which opens the New Board sheet and adds the cards on save while the shelf stays on the current tab. Dragging a card that is part of the selection carries the whole selection in shelf order, as in Finder, both onto a capsule and inside a board. A capsule ignores dropped cards that are already on its board. Inside a board a drop puts the cards before the target card when moving left and after it when moving right, like capsules (WD-42). ⌥⌘← / ⌥⌘→ move the selected cards one place on a board, gathered in shelf order; key repeats are ignored. VoiceOver gets one "Add to *Board*" action per board plus "Add to New Board…", because a submenu cannot be a custom action. ⌘B opens the same board list as a menu at the selected card, so Add to Board works from the keyboard; the context menu does not show the shortcut
- Status: done

### T5.4 Search in the shelf
- Module(s): ShelfUI
- Depends on: T1.9, T3.7
- Spec: [product §4.9](product.md#49-search-and-filters), [design §3 Anatomy](design.md#anatomy) board marker
- Deliverable: typing anywhere starts a search; ⌘F focuses the field; live results with one selected; Return pastes; matches highlighted; board dot on results; Tab and ↓ move focus to cards
- Acceptance: tests `typingStartsSearch`, `resultsKeepOneSelected`, `queryDebounceCancelsStale`
- Human check: search for an app name and a word prefix with accents
- Human check: with the shelf open and no field focused, typing "inv" fills the search field with "inv" (no character lost); ↓ or Tab moves focus back to the cards, where ← → move the selection; on a Board tab, ⌫ on a result that is only in History deletes it and ⌘Z brings it back; ⌘F selects the query; Return pastes the selected result; results on a board show its dot in light and dark mode
- Size: M
- Working default: WD-44
- Status: done

## M6. Settings, permissions, menu bar — MVP complete

### T6.1 General settings pane
- Module(s): App, Store, Pasting
- Depends on: T5.1
- Spec: [product §6 General](product.md#general), [design §8 General](design.md#general), [product §4.4](product.md#44-retention)
- Deliverable: Settings scene with toolbar tabs; General pane: open at login (`SMAppService.mainApp`), sound toggle (stored, used in T8.8), retention slider with confirmation when lowering, Erase History with confirmation, paste behavior, plain by default, Accessibility status re-checked on activation; hourly retention purge
- Acceptance: test `loweringRetentionNeedsConfirmation` on the settings model; test `purgeScheduleRunsAtLaunch` with a fake clock
- Human check: login item appears in System Settings › General › Login Items
- Size: M
- Status: done

### T6.2 Shortcuts pane
- Module(s): App, ShelfUI
- Depends on: T6.1, T3.3
- Spec: [product §6 Shortcuts](product.md#shortcuts), [shortcut recorder rules](product.md#shortcut-recorder-rules)
- Deliverable: recorders for Open Shelf and Next/Previous Board (Sequence recorders added in T11.5); Quick Paste and plain-text modifier pop-ups that must differ, writing the `QuickPasteModifiers` keys; Return and double-click honor the plain-text modifier (WD-28); Restore Defaults with confirmation; ⌥-only warning
- Acceptance: tests `modifiersMustDiffer`, `restoreDefaultsResetsAll`
- Human check: a recorder rejects ⌘Q and says that Quit Clipsy uses it; setting Next Board to ⇧⌘V is rejected inline and the recorder keeps ⌘→, and ⇧⌘V still opens the shelf afterwards
- Human check: with the plain-text modifier set to ⌥, ⌥Return in the shelf pastes plain text and the context menu shows ⌥↩ for Paste as Plain Text
- Human check: ⌘→ still moves to the end of a line in TextEdit after changing Next Board and pressing Restore Defaults
- Size: S
- Working default: WD-36. Double-click reaches the controller through `CardActions.pasteOnDoubleClick`, which the card view's double-click gesture (T3.5) calls. Previous Board and Next Board are only recorded here; the shelf's tab switching (T3.7) reads `.previousBoard` and `.nextBoard`
- Status: done

### T6.3 Privacy pane and ignored apps
- Module(s): App, Capture, ShelfUI
- Depends on: T6.1, T2.4
- Spec: [product §6 Privacy](product.md#privacy), [design §8 Privacy](design.md#privacy)
- Deliverable: concealed and temporary toggles, ignored apps list (app picker via `NSOpenPanel`, Apple Passwords preset with a verified bundle ID), help text about browser extensions, screen sharing toggle applied live to the panel; changes flow into `CapturePolicy`
- Acceptance: test `settingsMapToCapturePolicy`
- Human check: adding TextEdit to Ignored Apps stops its copies being captured
- Human check: with "Show the Shelf in screenshots and screen sharing" off, a ⇧⌘5 screenshot of the open Shelf does not show it; turning it on shows it without relaunching
- Size: M
- Working default: WD-33
- Status: done

### T6.4 Menu bar extra and pause
- Module(s): App, Capture
- Depends on: T6.1
- Spec: [product §6 Menu bar menu](product.md#menu-bar-menu), [design §7](design.md#7-menu-bar-extra)
- Deliverable: template symbol (paused variant, bounce on capture unless Reduce Motion); menu: Open Shelf with shortcut, Pause/Resume Capture (durations in T7.3), Settings…, About Clipsy (standard panel with acknowledgements), Help and Report an Issue (https://github.com/alekseylopukh/clipsy), Quit; ⌘T in the shelf; Show in menu bar and click-opens-shelf settings
- Acceptance: test `pauseStopsCaptureAndResumeRestarts`
- Human check: hiding the item and relaunching the app opens Settings
- Human check: the menu bar symbol bounces on each capture (not with Reduce Motion) and switches to the paused symbol from the menu and from ⌘T in the shelf; the menu shows the shelf shortcut next to Open Shelf
- Human check: with "Click on menu bar icon opens the Shelf" on, a left click opens the Shelf and a right-click or Control-click shows the menu
- Human check: Settings… and About Clipsy come to the front; the About panel lists the acknowledgements and stays readable in dark mode
- Size: M
- Status: done

### T6.5 Onboarding and permission explanations
- Module(s): App, Capture
- Depends on: T6.3, T6.4
- Spec: [design §9](design.md#9-onboarding-and-permissions), [product §4.1](product.md#41-capture) "Pasteboard access", [architecture §5](architecture.md#5-permissions-and-privacy), WD-16
- Deliverable: `PasteboardAccessStatus` from `NSPasteboard.accessBehavior` behind a protocol (API names checked against the macOS 26 SDK), re-read on wake; status row in the Privacy pane; first-launch window with Welcome (shortcut recorder), Paste directly (live Accessibility status), Clipboard access (skipped when not gated), Finish (open at login, retention); one-time pasteboard-access explanation at launch and on wake
- Acceptance: tests `askAndDenyNeedExplanation`, `clipboardStepSkippedWhenNotGated`, `onboardingShownOnlyOnce`
- Human check: full onboarding with Accessibility off then on; status rows turn green without reopening; on a clean user account, record whether polling `changeCount` alone triggers the system prompt and update the TODO in product.md
- Human check: on a first launch the onboarding window opens in front, and it does not open again on the next launch
- Human check: with clipboard access set to Ask or Deny, the explanation alert appears at launch and after wake, and its button opens Privacy & Security › Paste from Other Apps on macOS 26
- Size: M
- Working default: WD-37
- Status: done

### T6.6 MVP acceptance pass
- Module(s): Store, tests
- Depends on: T6.5
- Spec: [architecture §6.2](architecture.md#62-testing)
- Deliverable: performance test seeding 100k synthetic cards measuring search latency and history load; baseline recorded in architecture §6.2
- Acceptance: performance test passes and prints timings; no UI change
- Human check: architecture §6.2 manual checklist on a signed build; MVP is usable end to end
- Size: S
- Status: done

## M7. Capture and storage (v1)

### T7.1 Secret detection
- Module(s): Capture
- Depends on: T2.4
- Spec: [product §4.1](product.md#41-capture) "Secret patterns", WD-3
- Deliverable: rule 7 matcher for the listed patterns, gated by the concealed-content setting
- Acceptance: parameterized tests `secretsAreSkipped` and `ordinaryCodeIsKept` (synthetic snippets only)
- Size: S
- Status: done

### T7.2 Storage summary
- Module(s): Store, App
- Depends on: T6.1
- Spec: [product §3.1](product.md#31-capture-and-history), [design §8 General](design.md#general)
- Deliverable: item count and on-disk size (database plus payloads), formatted with `FormatStyle`, refreshed after purge and erase
- Acceptance: test `summaryCountsPayloadBytes`
- Working default: the count covers every stored card (History and boards); the size is the allocated size of `clipsy.sqlite` with its `-wal` and `-shm` files, `Payloads/` and `Thumbnails/`, not `Backups/`. The row also refreshes whenever the Settings window becomes active.
- Size: S
- Status: done

### T7.3 Pause for a duration
- Module(s): Capture, App
- Depends on: T6.4
- Spec: [product §6 Menu bar menu](product.md#menu-bar-menu), [design §7](design.md#7-menu-bar-extra)
- Deliverable: 15 minutes, 1 hour, 8 hours, until tomorrow, until resumed; resume time shown; survives relaunch
- Acceptance: tests `pauseResumesAtDeadline`, `untilTomorrowUsesCalendar` with a fake clock
- Human check: Pause Capture ▸ For 15 Minutes shows "Paused until <time>" above Resume Capture, capture resumes on its own at that time, and quitting and relaunching Clipsy while paused keeps the pause
- Size: S
- Status: done

### T7.4 Recover from a damaged store
- Module(s): Store, App
- Depends on: T2.6
- Spec: [product §3.1](product.md#31-capture-and-history), [architecture §3.4](architecture.md#34-migrations)
- Deliverable: an unreadable database (not a failed migration) is moved to a timestamped backup folder and a new store is created; the user is told where the backup is
- Acceptance: tests `corruptFileIsMovedAside`, `failedMigrationDoesNotTouchFile`
- Human check: quit Clipsy, write junk over `clipsy.sqlite` in the store folder, launch; the damaged-history alert names the backup folder, "Show in Finder" reveals it, and the shelf starts empty
- Size: S
- Status: done

## M8. Cards (v1)

### T8.1 Quick Look preview and file thumbnails
- Module(s): Media, ShelfUI
- Depends on: T3.6
- Spec: [design Quick Look](design.md#quick-look), [design per-type layouts](design.md#per-type-layouts), [architecture §8](architecture.md#8-open-questions)
- Deliverable: Space toggles a popover anchored to the card; `QLPreviewView` for files, own views for images, text, links and colors; arrows move the preview; the shelf stays open; `QLThumbnailGenerator` thumbnails for file cards, cached, fanned stack for multiple files
- Acceptance: test `missingFileFallsBackToIcon`; prototype result (popover inside a non-activating panel) noted in design.md
- Human check: preview of a PDF, an image, rich text and a color
- Size: M
- Human check: in the running app, Space opens the preview above the selected card while the Shelf stays open and keeps keyboard focus; ← → move it to the next card; Space and Esc close it; clicking another app closes both the preview and the Shelf
- Human check: open the preview of a text card, select some of its text, press ⌘C (the selection is copied), then ← (the preview follows) and Esc (only the preview closes); open it again, click into it, then click another app: both the preview and the Shelf close
- Human check: a file card shows its Quick Look thumbnail (a PDF's first page), three files fan out, and a deleted file shows its type icon
- Human check: with "Show the Shelf in screenshots and screen sharing" off, open the preview of a text card and take a screenshot (⇧⌘3): neither the Shelf nor the preview is captured; with it on, both are
- Human check: right-click a card that is not selected and choose Quick Look (`eye`, shown with Space): the card is selected and its preview opens; VoiceOver's actions rotor on a card lists Quick Look
- Human check: open the preview, scroll the strip with the trackpad until the selected card is far off screen, then press Space once; note whether the preview reopens on the first press or needs two (the lazy strip unloads the anchor and leaves the preview requested)
- Human check: on a large display the preview is 880 × 680 pt; on a 13" MacBook Air with a 300 pt Shelf it shrinks to fit above the Shelf with the same proportions and never reaches the menu bar; a tall screenshot gets a narrow popover and a wide image a short one, with no gray bars beside the image
- Working default: WD-49. The Shelf now closes on focus loss unless the panel or one of its child windows (a popover) is key, checked on the next run loop pass; before, any open child window kept it open
- Status: done

### T8.2 Open With, Show in Finder, Share, drag out
- Module(s): ShelfUI
- Depends on: T5.3
- Spec: [product §3.2](product.md#32-shelf-and-cards), [design card context menu](design.md#card-context-menu), WD-14
- Deliverable: Open With submenu for files, Show in Finder, Share submenu for single and multi selection; drag one or several cards into other apps, images also as PNG files; each dragged card also carries a `CardReference` (T11.4) so the Sequence panel accepts it
- Acceptance: tests `openWithHiddenForText`, `dragItemsMatchPasteRepresentations`
- Human check: share a link to Notes; drag an image card to Finder and a text card to TextEdit
- Human check: drag a text card and a multi-selection into the Sequence panel, onto a board capsule and inside a board; the drag image follows the pointer and each target still accepts the cards; light and dark
- Human check: ⇧⌘O opens the Open With menu at a selected file card, ⇧⌘R shows its files in Finder, ⇧⌘S opens the share picker at the card
- Size: M
- Working default: Share is a "Share…" item that opens the system share picker at the card, as in Finder, instead of a submenu, because a SwiftUI context menu cannot build its submenu from content that is read asynchronously. It shares the text of text and color cards, the URL of links, the image of image cards and the files of file cards; cards of unknown type offer no Share. Open With lists the apps that open every file of the card, the default app first as "*App* (default)", then the rest by name, and is hidden when no app qualifies. Keys: ⇧⌘O opens the Open With menu at the card, ⇧⌘R is Show in Finder (⌘R is Rename), ⇧⌘S is Share. Show in Finder and Open With act on single file cards; a file that no longer exists shows an error. Dragging uses an AppKit drag session, because a `Transferable` has a fixed list of types and a card has its own: the cards are read when the pointer crosses the drag threshold and the drag starts once they are loaded, if the button is still down. Each pasteboard item of each dragged card carries the card's paste representations and a `CardReference`; drop targets drop repeated references. An image card's item also promises a PNG file named after the card title, or "Image"
- Status: done

### T8.3 Rename
- Module(s): Store, ShelfUI
- Depends on: T5.1
- Spec: [product §4.10](product.md#410-editing-v1), [design edit sheet](design.md#edit-sheet)
- Deliverable: ⌘R or click on the title opens a rename popover; empty title clears it; search row updated. Duplicate is not in v1 (see "Needs the maintainer"). WD-31
- Acceptance: tests `emptyTitleClears`, `renameUpdatesSearchRow`
- Note: the card view (T3.5) was not on this branch yet, so the popover ships as the `cardRenamePopover(for:)` modifier; T8.4 applies it to the card and makes the header title a button that sends `CardCommand.rename`
- Size: S
- Status: done

### T8.4 Text editor and New Text Card
- Module(s): Store, ShelfUI
- Depends on: T8.3
- Spec: [product §4.10](product.md#410-editing-v1), [design edit sheet](design.md#edit-sheet), WD-7
- Deliverable: apply T8.3's `cardRenamePopover(for:)` to each card and make the header title a button that sends `CardCommand.rename`, if T3.5 did not; ⌘E sheet with rich text editing (B/I/U/S), live counts; save replaces content in place and recomputes hash and search row; ⌘N creates a card in History or the current board
- Acceptance: tests `editKeepsPositionAndBoard`, `editRecomputesHash`, `editToExistingHashIsRefused`, `newCardGoesToCurrentBoard`
- Human check: in the running app, ⌘R and a click on the title open T8.3's rename popover, its field takes typing while the Shelf stays open, Return saves and the Shelf keeps keyboard focus afterwards; light and dark
- Human check: edits never change the system clipboard
- Human check: in the running app, ⌘E on a text card and ⌘N open the editor sheet over the Shelf; it takes typing, ⌘B/⌘I/⌘U and the segmented control style the selection, ⌘X/⌘C/⌘V/⌘Z work inside it, ⌘Return saves, Esc cancels; a 160 pt Shelf still shows the buttons; light and dark
- Size: M
- Status: done

### T8.5 Link and color editing
- Module(s): ShelfUI, Capture, Store
- Depends on: T8.4
- Spec: [product §4.10](product.md#410-editing-v1), [design edit sheet](design.md#edit-sheet)
- Deliverable: link editor (URL and title, type re-detected on save); color editor with system color panel and format picker
- Acceptance: tests `linkEditedToTextBecomesText`, `colorFormatsRoundTrip`
- Human check: in the running app, ⌘E on a link card opens Edit Link over the Shelf; changing the URL to plain words and saving turns the card into a text card; changing only the title keeps the link preview; light and dark
- Human check: ⌘E on a color card opens Edit Color; the color well opens the system color panel in front of the Shelf while the Shelf stays open, a pick updates the value in the chosen format, Hex/RGB rewrites it, Save updates the swatch, and the color panel closes with the sheet
- Size: S
- Working default: WD-51
- Status: done

### T8.6 Show in List
- Module(s): ShelfUI
- Depends on: T5.4
- Spec: [product §3.2](product.md#32-shelf-and-cards), [§5](product.md#in-the-shelf)
- Deliverable: ⌘G from a single search result clears the search, switches to its board or History and selects it with neighbors visible
- Acceptance: test `showInListSelectsCardInItsTab`
- Human check: search for a card that sits far down History or on another board, press ⌘G: the search clears, the right tab is shown and the card is selected in the middle of the strip with cards on both sides; the context menu of a single search result shows Show in List
- Size: S
- Working default: WD-45
- Status: done

### T8.7 Compact size
- Module(s): ShelfUI, DesignSystem
- Depends on: T3.5
- Spec: [design §2](design.md#placement-and-size), WD-15
- Deliverable: condensed card layout below the threshold, animated switch (instant with Reduce Motion)
- Acceptance: test `compactBelowThreshold`
- Human check: drag height across the threshold in light and dark
- Size: S
- Status: done

### T8.8 Sounds
- Module(s): App, Pasting
- Depends on: T6.1
- Spec: [product §3.2](product.md#32-shelf-and-cards), [§4.5](product.md#45-paste-mechanics) step 7
- Deliverable: capture and paste sounds when enabled; our own assets or system sounds, with origin recorded in THIRD_PARTY_NOTICES.md if third-party
- Acceptance: test `soundsOffPlaysNothing` with a fake player
- Human check: maintainer approves the sounds
- Size: S
- Status: done

## M9. Media (v1)

### T9.1 Text recognition in images
- Module(s): Media, Store, App
- Depends on: T1.9, T6.3
- Spec: [product §3.2](product.md#32-shelf-and-cards), [§3.6](product.md#36-search), [architecture §2](architecture.md#2-stack)
- Deliverable: Vision `RecognizeTextRequest` queue for image cards with `ocr_state`; text written to `card_search.ocr_text`; Privacy toggle (on by default); pending work resumes after relaunch
- Acceptance: tests `ocrTextIsSearchable` (synthetic rendered image), `toggleOffSkipsQueue`, `failedOcrIsMarked`
- Size: M
- Working default: WD-38
- Human check: with "Recognize text in images" on, copying a screenshot of some text and then searching the Shelf for one of its words finds the image Card
- Human check: the "Recognize text in images" toggle and its note in Settings → Privacy look right in light and dark appearance
- Status: done

### T9.2 Link previews (opt-in)
- Module(s): Media, Store, ShelfUI
- Depends on: T3.5, T6.3
- Spec: [product §3.2](product.md#32-shelf-and-cards), [design per-type layouts](design.md#per-type-layouts), [architecture §5](architecture.md#5-permissions-and-privacy)
- Deliverable: `LPMetadataProvider` fetch only when "Show link previews" is on; page title into metadata and search; image cached in Thumbnails
- Acceptance: tests `noFetchWhenOff` (fake provider), `titleIsIndexed`
- Human check: with the toggle off, Little Snitch or `nettop` shows no request on copying a link
- Size: M
- Working default: WD-40
- Status: done

## M10. Search filters (v1)

### T10.1 Filter query
- Module(s): Store
- Depends on: T1.9
- Spec: [product §4.9](product.md#49-search-and-filters)
- Deliverable: filters Type, App, Date (today, yesterday, 7 days, 30 days, custom), Board, combined with AND and with text
- Acceptance: parameterized test `filtersCombineWithAnd`; test `dateRangesUseCalendar`
- Size: S
- Working default: at most one value per filter (Type, App, Date, Board); a card's date is `last_copied_at`, or `created_at` for a board-only card; date ranges are whole days in the user's calendar and time zone, "last 7/30 days" include today, a custom range includes both end days; a blank query with a filter lists every matching card, newest first
- Status: done

### T10.2 Filter tokens and browser
- Module(s): ShelfUI
- Depends on: T10.1, T5.4
- Spec: [product §4.9](product.md#49-search-and-filters), [design §4](design.md#4-top-bar)
- Deliverable: tokens in the search field, suggestions while typing a type or app name, Filters popover, ⌘F twice opens it
- Acceptance: test `typingAppNameSuggestsToken`
- Human check: keyboard-only filtering by type and date
- Human check: in the shelf, type "ima", press ↓ and Return: an Image token appears in the field and only image cards show; type "tod", ↓, Return: a Today token joins it; ⌫ in the empty field removes Today; Esc clears everything
- Human check: press ⌘F twice: the Filters popover opens above the button with the list focused; ↓ and Return toggle a filter and its checkmark, Esc closes the popover and the shelf stays open; Custom Range… with From and Through filters by those days; check the suggestion list, tokens and popover in light and dark mode and with Increase Contrast
- Size: M
- Working default: WD-46
- Status: done

## M11. Paste several and Sequence (v1)

### T11.1 Paste several
- Module(s): Pasting, ShelfUI
- Depends on: T4.3
- Spec: [product §4.12](product.md#412-multi-select), [architecture §4.2](architecture.md#42-paste)
- Deliverable: multi-selection paste: text joined with newline, files as one write, mixed as one item per card; oldest first
- Acceptance: tests `textsJoinOldestFirst`, `filesBecomeOneWrite`, `mixedIsOneItemPerCard`
- Size: S
- Status: done

### T11.2 Sequence state machine
- Module(s): Pasting
- Depends on: T4.1
- Spec: [product §4.7](product.md#47-sequence), [architecture §4.4](architecture.md#44-sequence)
- Deliverable: in-memory queue of card ids: add (end, or head with Reverse Order), seed from selection in shelf order, advance, remove, reorder, undo last paste or removal, paste all joined text, plain-text flag persisted
- Acceptance: tests `copyOrderPastesFirstCopiedFirst`, `reverseOrderInsertsAtHead`, `undoRestoresPosition`, `lastPasteCloses`, `pasteAllJoinsText`
- Size: M
- Status: done

### T11.3 Sequence paste detection
- Module(s): Pasting
- Depends on: T11.2
- Spec: [architecture §4.4](architecture.md#44-sequence) "Paste detection"
- Deliverable: lazy `NSPasteboardItemDataProvider` for the head card that advances on read; fallback global ⌘V key monitor; chosen mechanism and findings recorded in architecture.md
- Acceptance: test `providerReadAdvancesOnce` on a private pasteboard
- Human check: in Safari, Notes, Terminal and an Electron app, focusing or opening the Edit menu does not advance; ⌘V does
- Size: M
- Status: done

### T11.4 Sequence panel
- Module(s): ShelfUI
- Depends on: T11.3
- Spec: [design §6](design.md#6-sequence), [product §5](product.md#in-the-sequence-panel)
- Deliverable: non-activating utility panel, remembered position, header with Undo, More (Reverse Order, Paste All, Plain Text, Clear), Close; rows with next marker, drag reorder, ⌫ removes, Esc clears; empty state; drop cards from the shelf
- Acceptance: test `panelModelReflectsQueue`
- Human check: works over a full-screen app; hidden from screen recording by default
- Size: M
- Status: done

### T11.5 Sequence shortcuts and collection
- Module(s): App, Pasting, ShelfUI
- Depends on: T11.4, T6.2
- Spec: [product §4.7](product.md#47-sequence), [§5](product.md#global-customizable)
- Deliverable: ⇧⌘C starts a Sequence (synthesized ⌘C in the frontmost app, needs Accessibility) or seeds from shelf selection; ⌃⌥⌘V pastes all; captures stream into the open Sequence; content dropped on the Sequence panel from other apps is captured as a card and joins it; the app runs `SequencePanelController` (screen capture follows `PrivacySettings.showsShelfInScreenCapture`, as the Shelf does; cards from `CardRepository.cards(withIDs:)`, Paste All through the multi-paste) and `SequencePasteDetector` (data provider), publishes each new head and advances on its reports; Add to Sequence in the context menu and menu bar; recorders in the Shortcuts pane
- Acceptance: test `capturesJoinOpenSequence`
- Human check: collect three lines in TextEdit, paste them in order in Notes with ⌘V
- Human check: ⇧⌘C in TextEdit with Accessibility granted opens the Sequence panel with the selection as its first card; with cards selected in the shelf, ⇧⌘C and Add to Sequence seed the panel with them in shelf order
- Human check: dragging text from TextEdit and a file from Finder onto the Sequence panel, over the rows and over the empty state, adds a card to History and to the Sequence
- Human check: ⌃⌥⌘V in Notes pastes the remaining cards joined by newlines and closes the panel; the menu bar menu shows Start Sequence with its shortcut
- Size: M
- Working default: WD-41. The app runs `Pasting.SequenceCoordinator` (publishes heads, advances on the detector, Paste All in queue order through `PasteCoordinator.perform(keepsOrder:)`); the single consumer of `capturedCardIDs` (WD-34, WD-35) also hands each id to it
- Status: done

## M12. Integrations (v1)

### T12.1 App Intents
- Module(s): App, Store
- Depends on: T8.4, T5.2
- Spec: [product §3.7](product.md#37-integrations)
- Deliverable: intents Create Card, Create Board, Get Card at Index, Get Latest Card of Type
- Acceptance: tests on the intent handlers' store calls
- Human check: each intent runs in the Shortcuts app
- Size: M
- Status: done

### T12.2 URL scheme
- Module(s): App, ShelfUI
- Depends on: T6.4, T8.4
- Spec: [product §3.7](product.md#37-integrations)
- Deliverable: scheme to open the shelf, search, create a text card, open settings
- Acceptance: tests `parsesEachRoute`, `rejectsUnknownRoute`
- Human check: with Clipsy running, `open clipsy://open`, `open "clipsy://search?q=test"`, `open "clipsy://new?text=Hello"` and `open clipsy://settings` each do what [product §3.7](product.md#37-integrations) says, and none of them shows the Welcome window; repeat `clipsy://open` with Clipsy quit to check a cold launch
- Size: S
- Status: done

## M13. Release readiness

### T13.1 Sparkle, About pane, signing configuration
- Module(s): App, Xcode build settings
- Depends on: T6.4
- Spec: [architecture §1](architecture.md#1-overview) process model, [§2](architecture.md#2-stack), [§7.1](architecture.md#71-third-party-dependencies), [design §8 About](design.md#about), WD-19
- Deliverable: Sparkle 2 dependency after reading its LICENSE (notice row); automatic checks off until opted in; About pane with version, license, links, acknowledgements, Check for Updates and the opt-in toggle; menu item Check for Updates…; feed URL and EdDSA public key as build settings left `> TODO:`; `LSUIElement`, Hardened Runtime, no sandbox, only the entitlements Sparkle and Apple Events need, set through Info.plist or xcconfig files, following CLAUDE.md's project rule for `project.pbxproj`
- Acceptance: test that the updater is not started with checks off; `codesign -d --entitlements -` on a Release build lists only the expected keys
- Human check: maintainer supplies the appcast URL (`SPARKLE_FEED_URL`) and generates the Sparkle EdDSA key pair (`SPARKLE_PUBLIC_ED_KEY`); checks the About pane in light and dark mode
- Size: M
- Status: done

### T13.2 Release scripts
- Module(s): scripts/release
- Depends on: T13.1
- Spec: [architecture §6.4](architecture.md#64-release-pipeline)
- Deliverable: scripts for archive and export, notarize and staple, zip and DMG, Sparkle signing and appcast; all secrets from environment variables
- Acceptance: `shellcheck` clean; dry-run mode runs the archive and packaging steps with ad-hoc signing
- Human check: maintainer supplies `DEVELOPER_ID_APPLICATION` and `APPLE_TEAM_ID` (Developer ID Application certificate), `NOTARY_KEY_PATH`, `NOTARY_KEY_ID` and `NOTARY_ISSUER_ID` (App Store Connect API key), and `SPARKLE_PUBLIC_ED_KEY` and `SPARKLE_PRIVATE_ED_KEY` (Sparkle `generate_keys`), then runs `scripts/release/release.sh` once with them to confirm export, notarization, stapling and a signed appcast
- Size: M
- Status: done

### T13.3 Release workflow
- Module(s): CI
- Depends on: T13.2
- Spec: [architecture §6.4](architecture.md#64-release-pipeline), [CONTRIBUTING releases](../CONTRIBUTING.md#releases)
- Deliverable: workflow on `vX.Y.Z` tags that imports the certificate into a temporary keychain, runs the scripts and creates the GitHub Release with DMG and zip
- Acceptance: workflow lints clean; names every required secret in CONTRIBUTING.md
- Human check: maintainer adds the Developer ID certificate, App Store Connect API key and Sparkle private key as secrets and runs the first tagged release
- Size: M
- Status: done

### T13.4 Docs for a public release
- Module(s): docs
- Depends on: T13.3
- Spec: [README](../README.md), [CLAUDE.md](../CLAUDE.md)
- Deliverable: README build-from-source and install sections; release checklist in CONTRIBUTING.md; remaining TODOs in docs/ reviewed and either resolved or listed in an Open questions section
- Acceptance: every link in README and docs/ resolves
- Size: S
- Status: done

## M14. Developer speed and a separate dev build (0.2.0)

Found by the 2026-11-23 audits. These come first because every later task gets faster and safer with them. Measured baseline: local `swift test` 46 s, CI Build 6m37s (app 2m18s, then tests 3m52s, ClipsyKit compiled twice).

### T14.1 Faster ShelfContrastTests
- Module(s): SnapshotTests
- Depends on: none
- Spec: `ShelfContrastTests` renders 4 cases twice each with a 2 s settle (16 s of sleep, about 27 s in all) and reads pixels with `NSColor.colorAt`
- Deliverable: the shortest settle that still makes the test fail when the glass-contrast fix is reverted (prove it by reverting locally, never commit the revert); pixels read through `CGImage` bitmap data; drop `.serialized` only if `SnapshotRenderer` holds no shared state
- Acceptance: the suite runs in under 6 s locally; reverting the fix still fails it
- Size: S
- Status: done

### T14.2 Performance tests run on demand
- Module(s): StoreTests, scripts, CONTRIBUTING
- Depends on: none
- Spec: `PerformanceTests` seeds 100k cards once and times 6 queries × 5 runs in every `swift test` (10 s locally, about 30 s in CI), asserting only result counts; [architecture §6.2](architecture.md#62-testing)
- Deliverable: the suite runs only when `CLIPSY_PERF=1`; `scripts/perf.sh` runs it alone and prints the timings; architecture §6.2 and the CONTRIBUTING release checklist call `scripts/perf.sh` and compare with the baseline
- Acceptance: `scripts/build.sh test` no longer runs it; `scripts/perf.sh` does
- Size: S
- Status: done

### T14.3 No empty XCTest phase
- Module(s): scripts
- Depends on: none
- Spec: no test target uses XCTest, yet `swift test` spends about 5 s in an empty XCTest run
- Deliverable: `--disable-xctest` in `scripts/build.sh` test and `scripts/snapshots.sh`
- Acceptance: both scripts pass; `scripts/test-commit-gate.sh` stays green
- Size: S
- Status: done

### T14.4 GitHub Actions on Node 24
- Module(s): CI
- Depends on: none
- Spec: `actions/checkout@v4` and `actions/cache@v4` run on the deprecated Node 20 (annotation in every run)
- Deliverable: `actions/checkout@v7` and `actions/cache@v6` in lint.yml, build.yml and release.yml; release.yml keeps `persist-credentials: false`; verify the newest major versions with `gh api repos/actions/<name>/releases/latest` first
- Acceptance: workflows lint clean (`actionlint` if available); no Node 20 annotation on the next run
- Size: S
- Status: done

### T14.5 SwiftLint with SourceKit in CI
- Module(s): CI
- Depends on: T14.4
- Spec: lint.yml installs `swiftlint-static`, which skips `custom_rules` (the `no_print` privacy rule) and `statement_position` ("Skipping enabled rule … requires SourceKit")
- Deliverable: the dynamic `swiftlint` binary with SourceKit available on the runner (from the same release zip, or `swift-actions/setup-swift`); the smoke test fails the job when a file with `print(` passes or when the output contains "Skipping enabled rule"
- Acceptance: the Lint job runs every rule; the smoke test catches `print(`
- Size: S
- Status: done

### T14.6 Parallel CI Build
- Module(s): CI, docs
- Depends on: T14.3, T14.4
- Spec: build.yml compiles ClipsyKit twice in a row (xcodebuild, then `swift test`) and `--quiet` hides test timings; a transient SwiftPM clone failure needed a full rerun
- Deliverable: two parallel jobs, `app` (scripts/build.sh) and `test` (`swift package resolve` retried up to 3 times, then `swift test --disable-xctest` without `--quiet`), each with its own cache; architecture §6.3 matches
- Acceptance: the Build workflow passes on the branch; wall time noted in the PR
- Size: S
- Status: done

### T14.7 Data directory from the bundle id
- Module(s): Store, App
- Depends on: none
- Spec: `AppDatabase.defaultDirectory` hardcodes `Application Support/Clipsy` (`AppDatabase.swift:5-8`), so the Debug build and the installed release share one database
- Deliverable: the directory derives from the bundle id: `app.gonar.clipsy` keeps `Clipsy` (released data stays where it is), any other id uses a folder named after the id; architecture §3.1 and WD-18 updated
- Acceptance: unit tests for both ids; the release path is unchanged
- Size: S
- Status: done

### T14.8 Debug runs as Clipsy Dev
- Module(s): App, ShelfUI, build settings
- Depends on: T14.7
- Spec: Debug and Release share `app.gonar.clipsy`, so UserDefaults, the `clipsy://` scheme, TCC grants and LaunchServices collide
- Deliverable: build settings in project.pbxproj (only build settings are edited there): in Debug `PRODUCT_BUNDLE_IDENTIFIER = app.gonar.clipsy.dev` and `INFOPLIST_KEY_CFBundleDisplayName = Clipsy Dev`; a new `CLIPSY_URL_SCHEME` setting, `clipsy` in Release and `clipsy-dev` in Debug. Config/Info.plist uses `$(CLIPSY_URL_SCHEME)` and `CFBundleURLName = $(PRODUCT_BUNDLE_IDENTIFIER)`; the scheme is passed to `URLRoute` (ShelfUI/URLRoute.swift) and the app reads it from `Bundle.main`; the menu bar accessibility label and tooltip (App/StatusItemController.swift) say "Clipsy Dev" in dev. `PRODUCT_NAME` stays `Clipsy`. docs/architecture.md describes it; CLAUDE.md Identity only links there
- Acceptance: `URLRouteTests` cover both schemes; a Debug build's Info.plist shows the dev id and scheme; a Release build's shows the released ones (check with `plutil` on both products, without launching)
- Human check: with the installed release running, launch the Debug build: two menu bar icons, a separate Accessibility prompt for Clipsy Dev, `clipsy-dev://open` opens Dev and `clipsy://open` opens the release
- Size: S
- Status: done

### T14.9 Refuse a database from a newer version
- Module(s): Store, App
- Depends on: T14.7
- Spec: GRDB's migrator silently accepts applied migrations it does not know, so an older app can run on a newer schema; [architecture §3.4](architecture.md#34-migrations)
- Deliverable: `AppDatabase` checks `migrator.hasBeenSuperseded` before migrating and throws without touching the files; the app shows an alert and quits
- Acceptance: test with a database that has an extra `v99` migration: the open throws and the files are unchanged
- Size: S
- Status: done

### T14.10 No Sparkle in the dev build
- Module(s): Updates, App
- Depends on: T14.8
- Spec: Debug uses the release feed and a placeholder key; opting in from Debug would change the shared defaults
- Deliverable: one factory picks the driver and both call sites use it (`SparkleUpdaterDriver()` is created in App/ClipsyApp.swift and App/SettingsView.swift today); when the bundle id is not `app.gonar.clipsy` it returns a no-op `UpdaterDriver`, and "Check for Updates…" and the About updates section are hidden
- Acceptance: unit test for the driver choice
- Size: S

### T14.11 Dev default hotkeys
- Module(s): ShelfUI
- Depends on: T14.8
- Spec: both builds register ⇧⌘V, ⇧⌘C and ⌃⌥⌘V
- Deliverable: in the dev build the defaults are ⌃⇧⌘V (Shelf) and ⌃⇧⌘C (Sequence) and paste-all has none; check they collide with no system shortcut
- Acceptance: unit test for both builds' defaults
- Size: S

### T14.12 Test target warnings
- Module(s): Package.swift, DesignSystem, ShelfUI tests
- Depends on: none
- Spec: test builds warn about 5 unhandled files from the `App/AppIcon.icon` symlink, 3 `#ActorIsolatedCall` and deprecated `EventModifiers.function`
- Deliverable: exclude `App/AppIcon.icon` in the SnapshotTests target; `nonisolated static` for the pure helpers in `SwatchValueLabel.swift` and `CardFooter.swift`; the filter tests keep the function-key bit a real arrow press carries (see the comment in ShelfModel+Filters.swift) without calling the deprecated `.function` symbol, for example through `EventModifiers(rawValue:)` with a one-line comment
- Acceptance: `swift build --build-tests` prints no warnings
- Size: S
- Status: done

## Needs the maintainer

Found while writing this roadmap. Tasks that hit one stop and ask.

Decided:
- **URL scheme** (T12.2): the maintainer approved the `clipsy` scheme and the grammar in [product §3.7](product.md#37-integrations) on 2026-11-17.
- **Appcast URL, Sparkle keys, signing and notarization secrets** (T13.1, T13.3): the appcast URL is in [architecture §6.4](architecture.md#64-release-pipeline); the release secrets were set on 2026-11-23 ([CONTRIBUTING](../CONTRIBUTING.md#release-secrets)).
- **Duplicate** ([product §3.2](product.md#32-shelf-and-cards)): dropped from v1 on 2026-11-23. `card.content_hash` is `UNIQUE` ([architecture §3.2](architecture.md#32-schema)), so a copy needs its own rule, for example a salted hash that capture dedupe ignores.

- **Linking package products into the app** without editing `project.pbxproj` (WD-20): if a third-party module must be imported by the app target directly, the link is a one-time Xcode action.

## Later (not scheduled)

- Image editing: rotate, remove background ([product §3.2](product.md#32-shelf-and-cards))
- Duplicate a card, with its own dedupe rule ([Needs the maintainer](#needs-the-maintainer))
- System Spotlight indexing of board cards ([product §3.7](product.md#37-integrations))
- Other shelf edges and a vertical list layout ([design §2](design.md#placement-and-size))
- Homebrew cask ([architecture §6.4](architecture.md#64-release-pipeline))
