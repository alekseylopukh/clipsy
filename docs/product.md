# Clipsy product spec

This is the source of truth for what Clipsy does: scope, features, behavior and the keyboard map. Visual design is in [design.md](design.md). Architecture, stack, data model and permissions are in [architecture.md](architecture.md). Project-level decisions (platform, license, distribution, privacy) are in [CLAUDE.md](../CLAUDE.md#decisions) and are not repeated here.

Conventions:
- **MVP**: without it there is no product. **v1**: feature parity. **later**: expensive or niche, after v1.
- `> TODO:` marks behavior we have not settled. `> Decision needed:` marks a choice the maintainer has to make; the text gives a proposal and the tradeoff.

## 1. Scope

Clipsy is a clipboard manager for macOS 26 and later. It keeps a history of everything the user copies, shows it in a panel at the bottom of the screen, lets the user organize items into boards, search them, edit them and paste them into any app.

### Non-goals

| Out of scope | Note |
|---|---|
| Sync of any kind (iCloud, CloudKit, other devices) | The data layer is local-only. Device attribution and device filters are dropped with it. |
| Shared boards, collaboration, roles | Depends on sync. |
| AI features: suggestions ranked by the target window, on-device language models, MCP server, Writing Tools | May be revisited after v1; not planned. |
| iOS, iPadOS, visionOS apps, keyboard extension, widgets | Mac only. |
| Licensing, trials, subscriptions, paywall, upsell banners | Free and GPL-3.0. |
| Telemetry, analytics, crash-reporting services, remote in-app messages | See the privacy decision in CLAUDE.md. |
| Importing data from other clipboard managers | Not planned. |

## 2. Glossary

| Term | Meaning |
|---|---|
| **Shelf** | The floating panel at the bottom of the screen that shows cards. Opened with the global shortcut or the menu bar item. |
| **Card** | One stored clipboard item: all its pasteboard representations plus metadata (type, title, source app, times). |
| **History** | The default stream of cards, newest first, subject to retention. |
| **Board** | A named, colored, manually ordered collection of cards. Cards on a board are exempt from retention. |
| **Sequence** | A temporary ordered queue of cards that are pasted one after another with ⌘V in the target app. |
| **Target app** | The app that was frontmost when the shelf opened; direct paste goes there. |
| **Representation** | One pasteboard type and its data (plain text, RTF, HTML, PNG, file URL, …). A card keeps all of them. |
| **Own write** | A pasteboard change made by Clipsy itself (paste, copy, Sequence). Never captured as a new card. |
| **Quick Paste** | Pasting one of the first nine visible cards with modifier + digit. |

## 3. Features

### 3.1 Capture and history

| Feature | Behavior | Priority |
|---|---|---|
| Continuous capture | Detects every pasteboard change and stores it as a card (§4.1). | MVP |
| Full fidelity | Every representation of every pasteboard item is stored and written back on paste, so rich text, HTML and images survive. | MVP |
| Type detection | Text, Link, Image, File / Multiple files, Color, Unknown (§4.2). | MVP |
| Size cap | Oversized representations are dropped one by one (§4.1). | MVP |
| Source app | Each card records the app it was copied from. | MVP |
| Dedupe, re-copy to top | Copying content that already exists moves that card to the top instead of creating a duplicate (§4.3). | MVP |
| Privacy filters | Skip concealed, transient and auto-generated content and ignored apps (§4.1). | MVP |
| Secret detection | Skip text that looks like a password, token or key (§4.1). | v1 |
| Pasteboard access | On macOS versions with pasteboard privacy, detect when access is not granted and explain how to grant it. | MVP |
| Retention | Age-based limit from 1 day to forever (§4.4). | MVP |
| Erase History | Delete all History cards; board cards stay. | MVP |
| Storage summary | Show item count and disk size next to the retention control. | v1 |
| Pause | Stop capturing until resumed. | MVP |
| Pause for a duration | Pause until a chosen time, then resume automatically. | v1 |
| Recover from a damaged store | Move the unreadable store aside to a backup folder and start with an empty one. | v1 |

### 3.2 Shelf and cards

| Feature | Behavior | Priority |
|---|---|---|
| Shelf | Bottom-of-screen panel with one horizontal row of cards, newest on the left, one card always selected. Height is resizable and remembered. | MVP |
| Compact size | Below a height threshold the cards switch to a condensed layout that shows only content. | v1 |
| Cards by type | Each type has its own preview and footer metadata (details in design.md). | MVP |
| Toolbar | Search field, tabs for History and each board, button to add a board, filter control. | MVP |
| Empty states | Distinct states for empty History, empty board, no search results. | MVP |
| Multi-select | Select several cards and act on all of them (§4.12). | MVP |
| Context menu | All card actions in a native menu. | MVP |
| Preview | Space or Quick Look in the card's context menu opens a larger preview anchored to the card (Quick Look for files, our own view for images, text, links and colors). | v1 |
| Open | Open a link in the default browser or a file in its default app; also "Open With" and "Show in Finder". | MVP (Open), v1 (rest) |
| Show in list | From a search result, jump to the card's place in History or its board with surrounding cards visible. Single selection only. | v1 |
| Rename | Give a card a custom title. | v1 |
| Edit | Edit text, link and color cards in place (§4.10). | v1 |
| Image editing | Rotate, remove background. | later |
| New text card | Create a text or link card from scratch. | v1 |
| Duplicate | Make a copy of a card. | later |
| Delete with undo | Delete cards; ⌘Z restores them. | MVP |
| Share | System share sheet. | v1 |
| Drag out | Dragging a card into another app inserts it like a paste; images can be dropped as files. | v1 |
| Link previews | Fetch the page title and image for links. Opt-in, off by default; offered on the onboarding Finish step and in Settings › Privacy, both bound to the same setting. One of the two network uses listed in [CLAUDE.md](../CLAUDE.md#decisions). | v1 |
| File thumbnails | Quick Look thumbnails for file cards. | v1 |
| Text in images | Recognize text in image cards on device so search finds it. | v1 |
| Sounds | Optional sounds on capture and paste, our own assets. | v1 |
| Hidden from screen sharing | The shelf is excluded from screen capture unless the user allows it. | MVP |
| Menu bar item | Template symbol (`clipsy.paperclip`, `pause.circle` while capture is paused) with a menu (§6, Menu bar menu). Can be hidden. | MVP |
| Open at login | Register as a login item. | MVP |
| Permission onboarding | First-run explanation for Accessibility and pasteboard access, with links to System Settings. The last step offers Open at login, history retention and link previews (off by default). | MVP |

### 3.3 Pasting

| Feature | Behavior | Priority |
|---|---|---|
| Direct paste | Return or double-click pastes the card into the target app (§4.5). | MVP |
| Copy-only mode | Put the card on the clipboard without pasting, by setting or when Accessibility is not granted. | MVP |
| Paste as plain text | Per paste via modifier, or by default via setting. | MVP |
| Quick Paste | Modifier + 1…9 pastes the Nth visible card (§4.6). | MVP |
| Paste several | Paste a multi-selection in one go (§4.12). | v1 |

### 3.4 Sequence

| Feature | Behavior | Priority |
|---|---|---|
| Start a Sequence | From any app with a global shortcut, or from selected cards (§4.7). | v1 |
| Collect | While open, every new copy joins the Sequence. | v1 |
| Paste next | ⌘V in the target app pastes the next card and removes it from the Sequence. | v1 |
| Paste all | One shortcut pastes all remaining cards at once. | v1 |
| Manage | Reorder by drag, remove, undo the last paste or removal, reverse order, plain-text toggle, close and clear. | v1 |

### 3.5 Boards

| Feature | Behavior | Priority |
|---|---|---|
| Create, rename, recolor, reorder, delete boards | §4.8. | MVP |
| Add to Board / Remove from Board | Context menu, drag onto a tab, or for a multi-selection. | MVP |
| Manual order inside a board | Drag to reorder. | MVP |
| Board navigation | Shortcuts for next and previous board. | MVP |

### 3.6 Search

| Feature | Behavior | Priority |
|---|---|---|
| Type to search | Typing in the open shelf searches immediately (§4.9). | MVP |
| Search text in images | Includes recognized text. | v1 |
| Filters | Type, App, Date, Board as tokens in the search field, suggested while typing; a filter browser lists all of them. | v1 |

### 3.7 Integrations

| Feature | Behavior | Priority |
|---|---|---|
| App Intents | Create card, create board, get card at index, get latest card of a type. Details: [WD-50](roadmap.md#working-defaults-for-open-todos). | v1 |
| URL scheme | Our own scheme to open the shelf, search, create a text card, open settings. | v1 |
| System Spotlight | Index board cards in Spotlight, opt-in. | later |

Decided (2026-11-17): the scheme is `clipsy`. Grammar (designed in T12.2):

| URL | Action |
|---|---|
| `clipsy://open` | Opens the Shelf on its current tab. |
| `clipsy://search?q=<text>` | Opens the Shelf and searches for `<text>`, replacing any search and filters. Without `q`, it focuses the empty search field. |
| `clipsy://new?text=<text>` | Opens the Shelf and the New Text Card editor for the current tab, filled with `<text>`. The card is saved only when the user saves it, so a link cannot add cards on its own. If the editor is already open, it is left as it is. |
| `clipsy://settings` | Opens Settings. |

The scheme and the route are case-insensitive. Values are percent-encoded; `+` is not read as a space. Unknown query items are ignored. Any other route, or a URL with a path, is ignored and logged without its contents. A Debug build answers to `clipsy-dev` with the same grammar ([architecture §6.1](architecture.md#61-layout)).

## 4. Behavior rules

### 4.1 Capture

1. A timer polls the general pasteboard's change count; macOS has no change notification. Proposed interval 0.5 s with timer tolerance, then a short coalescing delay so apps that write in several steps produce one card.
   Working default [WD-1](roadmap.md#working-defaults-for-open-todos): 0.5 s with 0.1 s tolerance; a change is processed one tick after it is first seen, which is the coalescing delay.
2. On a change, the capture is dropped if any of these hold, checked in this order:
   1. Capture is paused.
   2. It is an own write: the change count equals the one recorded after our last write, or the pasteboard carries our private marker type.
   3. No frontmost app can be determined.
   4. The frontmost app is in Ignored Apps.
   5. "Ignore passwords and other concealed content" is on and the pasteboard has a concealed type (`org.nspasteboard.ConcealedType`) or a password manager's private type, or the source is a known password manager app.
   6. "Ignore temporary content from other apps" is on and the pasteboard has `org.nspasteboard.TransientType` or `org.nspasteboard.AutoGeneratedType` (plus the older equivalents some apps still write).
   7. (v1) "Ignore passwords and other concealed content" is on and the text matches the secret patterns below.

   Setting labels are owned by [design.md §8](design.md#8-settings-window).
3. Read every pasteboard item, every type, and its data. Drop:
   - volatile or junk types that carry no content (source markers, Microsoft OLE link types, our own marker);
   - any single representation larger than the size cap. If nothing usable is left, drop the capture.
4. Files are stored by reference (file URL), not by content. The app is not sandboxed, so no security-scoped bookmark is needed.
   Working default [WD-4](roadmap.md#working-defaults-for-open-todos): no bookmark or alias; a moved file is not resolved.
5. Detect the type (§4.2), compute the checksum (§4.3), insert or re-copy, record source app and times, then queue thumbnails, text recognition and (if enabled) link preview in the background.
6. Persist the last seen change count so a change made while Clipsy was not running is captured once at launch and not twice.

**Source app.** The frontmost app at capture time. A copy made through another app's menu bar extra is attributed to the frontmost app.
Working default [WD-2](roadmap.md#working-defaults-for-open-todos): `org.nspasteboard.source` is ignored; the frontmost app is always the source.

**Ignored Apps.** A user-editable list, preset with Apple Passwords (`com.apple.Passwords`, verified in the app's Info.plist on macOS 26). Checked only at capture time; adding an app does not remove its existing cards. Password managers with verified bundle IDs (1Password, Bitwarden and Apple's Keychain Access) are treated as confidential sources under rule 5 rather than listed; the others wait on the TODO below.

**Recognized types and sources.** From [nspasteboard.org](http://nspasteboard.org): concealed types are `org.nspasteboard.ConcealedType` and 1Password's legacy `com.agilebits.onepassword`; temporary types are `org.nspasteboard.TransientType`, `org.nspasteboard.AutoGeneratedType` and the legacy `de.petermaurer.TransientPasteboardType`, `com.typeit4me.clipping` and `Pasteboard generator type`. Password-manager bundle IDs, each verified: Keychain Access `com.apple.keychainaccess` and Bitwarden `com.bitwarden.desktop` (app Info.plist), 1Password `com.1password.1password` ([1Password MDM docs](https://support.1password.com/mobile-device-management/), preference domain).
> TODO: bundle IDs for Dashlane, LastPass, Keeper, Enpass, RoboForm and NordPass, each from the app's Info.plist or vendor docs; until then they are left out of rule 5.

**Known limit.** Browser extensions of password managers may not mark their copies as concealed. Users can add the browser to Ignored Apps; say so in the settings help text.

**Secret patterns (v1).** Text is treated as confidential when it contains: an assignment whose key is a password, passcode, secret, token, API key, private key or client secret; a JWT; a well-known token prefix (GitHub, Slack, AWS access key, `sk-` style API keys); an HTTP Bearer or Basic credential.
- Only the plain-text representations are checked. A match skips the capture ([WD-3](roadmap.md#working-defaults-for-open-todos)).
- To keep ordinary code, an assignment counts only when the key ends in one of the words and the value is a literal: a quoted string of at least 6 characters with no spaces and at least one character that is not a letter, an unquoted value of at least 8 characters with a letter and a digit, or an upper-case `NAME=value` line whose value does not start with `$`. `password: String`, `password = field.stringValue` and `case password = "password"` are kept.
- A Bearer or Basic credential needs at least 8 characters with a digit, `+`, `/`, `=` or an inner capital, so prose such as "Basic authentication" is kept.
> TODO: confirm false-positive rate on real code snippets.

**Size cap.**
Decided (2026-11-17): the per-representation cap is 50 MB.

**Universal Clipboard.**
Working default [WD-2](roadmap.md#working-defaults-for-open-todos): content from another device (`com.apple.is-remote-clipboard`) is captured like a local copy and attributed to the frontmost app.

**Pasteboard access.** At launch and after wake, read the app's pasteboard access behavior. If it is "ask" or "deny", show a one-time explanation with an "Open System Settings…" button: at most once per launch, with a "Don't ask again" checkbox, and not at the launch that shows onboarding. Use pattern detection, not data reads, where only the type is needed.
> TODO: whether polling the change count alone triggers the system prompt on macOS 26.
> TODO: the pasteboard-access button opens `x-apple.systempreferences:com.apple.preference.security?Privacy_Pasteboard` and the text names the pane ([design.md §9](design.md#9-onboarding-and-permissions)); verify the anchor on macOS 26.

### 4.2 Type detection

Applied in order; the first match wins.

| Order | Type | Rule |
|---|---|---|
| 1 | File / Multiple files | Pasteboard has one or more file URLs. One URL → File, several → Multiple files. |
| 2 | Image | Pasteboard has an image representation (PNG, TIFF, JPEG, HEIC, PDF image) and no file URL. |
| 3 | Link | The trimmed plain text is a single URL with no whitespace. |
| 4 | Color | The trimmed plain text matches the hex or rgb rule below. |
| 5 | Text | Any plain or rich text. |
| 6 | Unknown | None of the above. Stored and pasteable, shown with a generic preview. |

**Hex color rule.** The whole trimmed string is exactly six hex digits, and either starts with `#` or contains at least one letter A–F (either case).

**RGB color rule.** The whole trimmed string is `rgb(` (either case), three whole numbers from 0 to 255 separated by commas (spaces around them allowed), and `)`. These are the two formats the color editor writes (§4.10, [WD-51](roadmap.md#working-defaults-for-open-todos)).

| Input | Result |
|---|---|
| `#1A2B3C`, `1a2b3c`, `#235442` | Color |
| `235442` (no `#`, digits only, e.g. a one-time code) | Text |
| `rgb(26, 43, 60)`, `RGB(0,255,7)` | Color |
| `#FFF`, `rgba(…)`, `rgb(256, 0, 0)`, `red`, hex inside a sentence | Text |
| `#1A2B3C4D` (8 digits, with alpha) | Text |

**Link schemes.** http, https and ftp with a host, mailto, and any other scheme followed by `//` (for example `custom://x`). Working default [WD-5](roadmap.md#working-defaults-for-open-todos).

### 4.3 Dedupe and re-copy

- Checksum: a hash over the card's (type, data) pairs, sorted, after dropping volatile types. The same text copied from two apps dedupes; a rich and a plain version of the same text do not.
- If the checksum exists, the existing card moves to the top of History (its "last copied" time is set to now; its creation time stays) and its source app is updated. No new card.
- If the existing card is only on a board, it returns to History and stays on the board.
- Editing a card recomputes its checksum.
- Pasting a card from the shelf does not move it to the top of History (working default [WD-6](roadmap.md#working-defaults-for-open-todos)).
- An edit that makes a card identical to another one is refused (§4.10, working default [WD-7](roadmap.md#working-defaults-for-open-todos)).

### 4.4 Retention

- Options: 1 Day, 1 Week, 1 Month (default), 1 Year, Forever. Age only; no count limit.
- Age counts from the card's last copied time.
- Purge runs at launch and then hourly; it deletes History cards older than the limit that are not on a board. Board cards that leave History stay on their board.
- Lowering the limit when older cards exist asks for confirmation, states that board cards are kept and that the action cannot be undone. Cancel keeps the old limit.
- Erase History asks for confirmation; it removes all History cards not on a board and takes board cards out of History. Not undoable.
- Payload files no longer referenced by any card are garbage-collected.

### 4.5 Paste mechanics

1. The target app is the app that was frontmost when the shelf opened. Its name appears in "Paste to <App>" menu items.
2. Write the card to the general pasteboard: clear it, write every stored representation (for plain text: only the plain string), add our private marker type, record the resulting change count.
3. Hide the shelf. The shelf never activates Clipsy, so the target app stays frontmost. When a single card is pasted into the target app, a snapshot of it flies to the text insertion point while the paste goes ahead; the paste never waits for it, and Reduce Motion turns it off ([design.md §2 Motion](design.md#motion)).
4. If the paste setting is "Paste into the active app" and Accessibility is granted, post a synthesized ⌘V key down/up. Resolve the key code for "V" from the current keyboard layout, and handle layouts that switch to QWERTY while ⌘ is held.
5. If Accessibility is not granted, the first direct paste asks whether to grant it or just copy, with a "don't ask again" option. After declining, Return copies only.
6. If the paste setting is "Copy to the clipboard only", Return copies only and the shelf closes.
7. Play the paste sound if sounds are on.

The pasteboard keeps the pasted content afterwards; the previous clipboard is not restored.

**Plain text.** The plain-text modifier (default ⇧) turns any paste or copy into plain text: ⇧Return, ⇧-double-click, Quick Paste with ⇧. "Paste without formatting by default" makes it the default; there is no inverse modifier.
Working default [WD-8](roadmap.md#working-defaults-for-open-todos): holding the modifier while "Paste without formatting by default" is on has no effect.

### 4.6 Quick Paste

- While the shelf is open, holding the Quick Paste modifier (default ⌘) shows number badges 1–9 on the first nine visible cards of the current list or search result.
- Modifier + digit pastes that card; adding the plain-text modifier pastes it as plain text.
- Numbers follow what is visible after scrolling, not the absolute start of the list.
Working default [WD-28](roadmap.md#working-defaults-for-open-todos): badges appear only while the modifier is held; VoiceOver reads them as part of the card label ([design §10](design.md#10-accessibility-and-appearance)).

### 4.7 Sequence

- **Start from another app.** The Sequence shortcut opens the Sequence panel and synthesizes ⌘C in the frontmost app; the resulting copy becomes the first card. Needs Accessibility.
- **Start from the shelf.** With cards selected, the same shortcut or "Add to Sequence" in the context menu seeds the Sequence with them in shelf order.
- **Collect.** While the panel is open, every captured copy is added. Cards can also be dragged in from other apps or from the shelf.
- **Order.** Each new card goes either to the end of the queue or to its head, depending on "Reverse Order". The head is pasted next.
  Decided (2026-11-17): the default order is copy order (first copied, first pasted).
- **Paste next.** The head card is kept on the pasteboard. When the user presses ⌘V in any app, that card is pasted, removed from the Sequence and the next one is put on the pasteboard. Dragging a card out also removes it. Pasting a card out of order (double-click, context menu) also removes it. When the last card is pasted, the panel closes.
  Detection: the head is promised lazily, and the target app reading its data counts as the paste, so no extra permission is needed and Edit > Paste works too ([architecture §4.4](architecture.md#44-sequence)).
- **Paste all.** Pastes all remaining cards at once; text cards are joined with a newline. Clears the Sequence and closes the panel.
- **Plain text.** A toggle in the panel; it persists across Sequences.
- **Undo** restores the last pasted or removed card to its previous position. Close clears the Sequence.
- Sequence cards stay in History; the Sequence itself is not persisted across app restarts.

### 4.8 Boards

- A board has a name, a color and a position among the tabs. Default name "Untitled" if left empty, also when renamed to an empty name.
- Colors come from the system palette (red, orange, yellow, green, blue, purple, gray).
  Working default [WD-9](roadmap.md#working-defaults-for-open-todos): the palette and its order are in [design §4](design.md#board-colors); there is no "no color".
- A card belongs to at most one board. Adding it to another board moves it.
- Add to Board keeps the card in History. A board card survives retention and Erase History; after that it exists only on the board.
- Remove from Board takes the card off the board. If it is no longer in History, it is deleted.
- Deleting a board asks for confirmation. Its cards that are still in History stay in History; the rest are deleted.
- Order inside a board is manual (drag). Newly added cards go to the front (working default [WD-9](roadmap.md#working-defaults-for-open-todos)).
- The shelf reopens on the last selected tab.
  Working default [WD-9](roadmap.md#working-defaults-for-open-todos).

### 4.9 Search and filters

- Typing while the shelf is focused starts a search; ⌘F focuses the search field. Results update live; one result is always selected; Return pastes it.
- Scope: History and all boards together, regardless of the current tab. Results show which board a card is on. Choosing a tab clears the search (working default WD-44 in [roadmap.md](roadmap.md)).
  Working default [WD-10](roadmap.md#working-defaults-for-open-todos).
- Matched fields: title, text content, URL and page title, file names, source app name, recognized image text (v1).
- Case- and diacritic-insensitive, word-prefix matching. Ordered newest first. Matches are highlighted.
- Filters (v1): Type, App, Date (today, yesterday, last 7 days, last 30 days, custom range), Board. Typing a word that matches a type, app, date range or board name offers it as a filter token. Filters combine with AND. Pressing ⌘F again while the field is focused opens a browser of all filters (working default WD-46 in [roadmap.md](roadmap.md)).
- While filter suggestions are showing, ↓ highlights the first suggestion and then the next one, ↑ the previous one (above the first it returns to no highlight), and Return adds the highlighted suggestion as a token. With nothing highlighted, Return pastes as usual. ← / → keep moving the caret.
- Tab moves focus between the search field and the results.
- Esc hides the filter suggestions first, then clears the search, then closes the shelf on the next press.

### 4.10 Editing (v1)

- **Rename:** ⌘R or click on the card title. An empty title removes the custom title; the card shows its type label again.
- **Edit:** ⌘E opens an editor for the card type.
  - Text: rich editing with bold, italic, underline, strikethrough; live character, word and line counts.
  - Link: edit the URL and the card's title; re-detect type on save.
  - Color: system color panel, a Hex / RGB format picker and the value as text ([WD-51](roadmap.md#working-defaults-for-open-todos)).
  - Image and file cards: rename only (image editing later).
- Save replaces the card's content in place and keeps its title, position, board and times (no separate modified time is stored, [WD-48](roadmap.md#working-defaults-for-open-todos)). Discard leaves it unchanged. Edits never touch the system clipboard.
- Saved text is classified and hashed like a copy (§4.2), so text that is only a link or a color becomes that card type. A save that would make the card identical to another card is refused with an inline error ([WD-7](roadmap.md#working-defaults-for-open-todos)).
- **New text card:** ⌘N opens an empty text editor; on save the card is added to the top of History, or to the front of the current board (and not to History) when a board tab is active. Like an edit, it is refused when another card has the same content.

### 4.11 Deleting

- Delete (⌫) removes the selected cards. One card is deleted immediately; several ask for confirmation with the count.
- ⌘Z undoes the last delete while the shelf is open.
  Working default [WD-11](roadmap.md#working-defaults-for-open-todos): undo covers delete only.
- Deleting in History removes the card from History; deleting on a board removes it from the board. A card is removed from the store when it is in neither.
  > TODO: confirm that Delete on a board should not also remove the card from History.

### 4.12 Multi-select

- ⌘-click toggles, ⇧-click extends, ⇧← / ⇧→ extend from the keyboard, ⌘A selects all in the current list. The toolbar shows the selected count and a way to deselect.
- Actions on a selection: paste, paste as plain text, copy, add to board (or move to another board), delete, add to Sequence, share, drag out. Rename, edit, preview and show-in-list need a single card.
- Paste several:
  - all text: joined with a newline into one paste;
  - all files: one pasteboard write with all file URLs;
  - mixed: one pasteboard write with one item per card.
  Decided (2026-11-17): a multi-paste goes oldest first, in the order the user copied the cards.

### 4.13 Shelf window behavior

- Opens on the display that contains the mouse pointer; it is not tied to a display.
- Joins the active Space and appears above full-screen apps without switching Spaces.
- Never activates Clipsy or steals frontmost status from the target app, but takes keyboard focus so the shortcuts work.
- Closes on: Esc (when search is empty), a second press of the global shortcut, a successful paste or copy from the shelf, and focus loss.
- **Focus loss:** clicking another app or window, or switching apps, closes the shelf. The shelf stays open while one of our own sheets (such as the editor) is attached, or while the shelf or one of its child windows (a popover, the preview) has keyboard focus; it closes when focus leaves both ([WD-49](roadmap.md#working-defaults-for-open-todos)). A window that is neither, such as the system color panel, must become a child window of the shelf to keep it open.
  Working default [WD-13](roadmap.md#working-defaults-for-open-todos): there is no option to keep the shelf open after paste.
- Height is resizable by dragging the top edge and is remembered: one height for all displays ([WD-13](roadmap.md#working-defaults-for-open-todos)).
- Excluded from screen sharing and screenshots unless "Show the Shelf in screenshots and screen sharing" is on.
- The Sequence panel is a separate small floating panel that the user can move; its position is remembered. It follows the same Space and full-screen rules.

## 5. Keyboard map

### Global (customizable)

| Action | Default | Priority |
|---|---|---|
| Show / hide the shelf | ⇧⌘V | MVP |
| Start Sequence (copies the current selection in the frontmost app) | ⇧⌘C | v1 |
| Paste next Sequence card | ⌘V (the system shortcut; not registered by us) | v1 |
| Paste all Sequence cards | ⌃⌥⌘V | v1 |

These are the released app's defaults; the dev build uses [its own](architecture.md#61-layout) so both can run at once.

Decided (2026-11-17): the default shelf shortcut is ⇧⌘V. It takes "Paste and Match Style" away from apps that use it, and users can rebind it in Settings.

Decided (2026-11-17): the default Sequence shortcut is ⇧⌘C (rebindable). It shadows ⇧⌘C in Finder, in browser dev tools and in some editors.

### In the shelf

| Action | Keys | Priority |
|---|---|---|
| Close / clear search | Esc | MVP |
| Previous / next card | ← / → | MVP |
| First / last card | ⌘↑ / ⌘↓ | MVP |
| Extend selection | ⇧← / ⇧→, ⇧-click, ⌘-click | MVP |
| Select all | ⌘A | MVP |
| Paste (or copy in copy-only mode) | Return, double-click | MVP |
| Paste as plain text | ⇧Return, ⇧-double-click | MVP |
| Quick Paste Nth card | ⌘1…⌘9 | MVP |
| Quick Paste Nth card as plain text | ⇧⌘1…⇧⌘9 | MVP |
| Copy to clipboard | ⌘C | MVP |
| Copy as plain text | The plain-text modifier with ⌘C (⇧⌘C by default); none while Start Sequence uses that combination ([WD-41](roadmap.md#working-defaults-for-open-todos)) | MVP |
| Open link / file | ⌘O | MVP |
| Open With (opens the app menu at the card) | ⇧⌘O | v1 |
| Show in Finder | ⇧⌘R | v1 |
| Share | ⇧⌘S | v1 |
| Delete | ⌫ | MVP |
| Undo | ⌘Z | MVP |
| Search | type, or ⌘F | MVP |
| Filter browser | ⌘F while the search field is focused | v1 |
| Move focus between search and cards | Tab; ↓ from the search field | MVP |
| Previous / next tab (History, boards) | ⌘← / ⌘→ (customizable) | MVP |
| New board | ⇧⌘N | MVP |
| Edit current board | ⇧⌘E | MVP |
| Delete current board | ⇧⌘⌫ | MVP |
| Add selected cards to a board (opens the board menu) | ⌘B | MVP |
| Move selected cards left / right on a board | ⌥⌘← / ⌥⌘→ | MVP |
| Pause / resume capture | ⌘T | MVP |
| Preview | Space | v1 |
| Rename | ⌘R | v1 |
| Edit | ⌘E | v1 |
| New text card | ⌘N | v1 |
| Show in list | ⌘G | v1 |
| Settings | ⌘, | MVP |
| Quit | ⌘Q | MVP |

Note: first / last card use ⌘↑ / ⌘↓ because ⌘← / ⌘→ switch tabs. Space types a space while the search field has focus; it previews only when the cards have focus.

### In the Sequence panel

| Action | Keys |
|---|---|
| Remove selected card | ⌫ |
| Undo last paste or removal | ⌘Z |
| Close and clear | Esc |

### Shortcut recorder rules

- Reject a combination already used by another Clipsy shortcut, by a menu item, or by a system shortcut, and say which.
- Warn that shortcuts using only ⌥ as a modifier may not work reliably.
- A cleared shortcut stays cleared across restarts. If both the shelf shortcut and the menu bar item are off, the shelf can still be opened with `clipsy://open`; launching the app again opens Settings, where either can be turned back on.
- "Restore Defaults" asks for confirmation.

## 6. Settings

Content and defaults only; layout and exact label wording are in [design.md §8](design.md#8-settings-window).

### General

| Setting | Options | Default |
|---|---|---|
| Open at login | on / off | off; offered during onboarding |
| Show in menu bar | on / off | on |
| Clicking the menu bar item | Show menu / Open shelf | Show menu |
| Sound effects | on / off | off |
| Keep history | 1 Day, 1 Week, 1 Month, 1 Year, Forever | 1 Month |
| Storage summary | item count and size (read-only, v1) | — |
| Erase History | button with confirmation | — |
| Paste behavior | Paste into the active app / Copy to the clipboard only | Paste into the active app |
| Paste without formatting by default | on / off | off |
| Accessibility status | granted / not granted, button to open System Settings | — |

### Shortcuts

| Setting | Default |
|---|---|
| Show / hide the shelf | ⇧⌘V |
| Start Sequence | ⇧⌘C |
| Paste all Sequence cards | ⌃⌥⌘V |
| Next board / Previous board | ⌘→ / ⌘← |
| Quick Paste modifier | ⌘ (one of ⌘ ⌃ ⌥) |
| Plain text modifier | ⇧ (one of ⇧ ⌘ ⌃ ⌥, must differ from the Quick Paste modifier) |
| Restore Defaults | button with confirmation |

### Privacy

| Setting | Options | Default |
|---|---|---|
| Ignored apps | list with add / remove | Apple Passwords |
| Ignore passwords and other concealed content | on / off | on |
| Ignore temporary content from other apps | on / off | on |
| Show link previews | on / off, with a note that fetching may trigger one-time or tracking links | off; offered during onboarding |
| Show the Shelf in screenshots and screen sharing | on / off | off |
| Recognize text in images | on / off (on device) | on |
| Clipboard access status | allowed / asks / not allowed, button to open System Settings; hidden until macOS has asked about Clipsy | — |

> TODO: whether file thumbnails need a toggle (they read file contents through Quick Look). Working default: no toggle ([WD-49](roadmap.md#working-defaults-for-open-todos)).

### Menu bar menu

This is the item list; grouping and wording are in [design.md §7](design.md#7-menu-bar-extra).

- Open Shelf · New Text Card · Start Sequence
- Pause Capture for 15 minutes, 1 hour, 8 hours, until tomorrow, or until resumed / Resume Capture; while paused, the time capture resumes. "Until tomorrow" ends at the next midnight. A pause survives relaunch; ⌘T pauses until resumed.
- Settings… · Check for Updates… (always manual, see [CLAUDE.md](../CLAUDE.md#decisions); not in the dev build, [architecture §6.1](architecture.md#61-layout)) · About Clipsy
- Clipsy Help · Report an Issue
- Quit Clipsy

## 7. Open questions

These still need a test on real hardware, data from vendors, or the task that settles them. Everything else in this document is settled or follows a working default in [roadmap.md](roadmap.md#working-defaults-for-open-todos).

- > TODO: bundle IDs of the remaining password managers (§4.1).
- > TODO: false-positive rate of the secret patterns on real code (§4.1).
- > TODO: pasteboard privacy on macOS 26: whether polling the change count triggers the system prompt, and whether the `Privacy_Pasteboard` link opens the right list (§4.1).
- > TODO: Delete on a board vs History (§4.11).
- > TODO: whether file thumbnails need a toggle (§6).
- > TODO: drag-out formats for several cards and for images (file vs image data) ([WD-14](roadmap.md#working-defaults-for-open-todos)).
