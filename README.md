# Clipsy

A free, open-source clipboard manager for macOS that feels like part of the system.

Clipsy keeps everything you copy on a shelf at the bottom of the screen: text, links, images, files and colors. Search it, organize it into boards and paste anything back with a keystroke.

> **Status:** no release yet. The first build will be published on [GitHub Releases](https://github.com/alekseylopukh/clipsy/releases).

## Features

- Clipboard history with retention from one day to forever
- A shelf of cards with previews for each content type
- Boards for keeping snippets you reuse
- Search across History and boards
- Paste directly into the frontmost app, or as plain text
- Quick paste with numbered shortcuts
- Sequential pasting of several items
- Editing of text, link and color cards, and custom card titles
- Search inside images through on-device text recognition
- Optional link previews
- Privacy controls: ignored apps, password managers, concealed and transient content and text that looks like a secret are skipped; capture can be paused from the menu bar
- Shortcuts actions and a `clipsy://` URL scheme
- No account, no telemetry, no sync. Your history stays on your Mac; the only network requests are link previews and update checks, and both are off until you turn them on.

The full behavior is described in [docs/product.md](docs/product.md).

## Requirements

macOS 26 or later.

## Install

1. Download `Clipsy-<version>.dmg` from the [latest release](https://github.com/alekseylopukh/clipsy/releases/latest).
2. Open the disk image and drag Clipsy to Applications.
3. Open Clipsy from Applications. It runs in the menu bar and has no Dock icon.

Releases are signed with a Developer ID and notarized by Apple. On first launch macOS shows its usual "downloaded from the Internet" confirmation and no "unidentified developer" block.

### Using Clipsy

Press ⇧⌘V to show or hide the shelf. This takes over "Paste and Match Style" in apps that use that shortcut; change it in Settings › Shortcuts. ⇧⌘C starts a Sequence and ⌃⌥⌘V pastes every card in it. All shortcuts are listed in the [keyboard map](docs/product.md#5-keyboard-map).

### Permissions

- **Accessibility** lets Clipsy paste straight into the app you were using. A Sequence started from another app also needs it to copy your selection. Without it, Clipsy puts the item on the clipboard and you press ⌘V yourself. Grant it in System Settings › Privacy & Security › Accessibility. If you skip it, Clipsy asks again on the first paste; choose "Don't ask again" to stay in copy-only mode.
- **Paste from Other Apps:** macOS may ask before Clipsy reads what you copy, or block it. Set Clipsy to Allow in System Settings › Privacy & Security › Paste from Other Apps, or your history will miss items.

On first launch a short setup window lets you set the shelf shortcut, asks for Accessibility, asks for clipboard access if macOS restricts it, and offers Open at login, history length and link previews. Every step can be skipped.

If pasting stops working after an update or a reinstall, remove Clipsy from the Accessibility list and add it again. macOS ties the permission to the app's signature.

### Updates

Clipsy never checks for updates on its own unless you turn on automatic checks in Settings › About. "Check for Updates…" in that pane or in the menu bar menu checks once. Updates are signed and verified before they install.

### Uninstall

1. If Clipsy opens at login, turn that off in Settings › General.
2. Quit Clipsy from its menu bar menu, then move it from Applications to the Trash.
3. To remove your data too, delete `~/Library/Application Support/Clipsy/` (history, boards, images and backups) and run `defaults delete app.gonar.clipsy` (settings and shortcuts).
4. To clear its permissions, run `tccutil reset Accessibility app.gonar.clipsy` and remove Clipsy from Paste from Other Apps in System Settings.

## Building from source

Requires macOS 26 and Xcode 26 or later. Swift packages (GRDB, KeyboardShortcuts, Sparkle) are fetched on the first build.

```bash
git clone https://github.com/alekseylopukh/clipsy.git
cd clipsy
scripts/build.sh        # build the app (Debug) into .build/DerivedData, signed with your Apple Development identity if you have one
scripts/build.sh test   # run the tests
open .build/DerivedData/Build/Products/Debug/Clipsy.app
```

A Debug build needs no Apple developer account. Without an Apple Development identity it stays signed ad hoc, and macOS asks for Accessibility again after each rebuild. Set `CLIPSY_SIGN_IDENTITY=-` to force an ad-hoc signature.

Release builds are made by `scripts/release/release.sh`, which needs the maintainer's signing and notarization secrets. `scripts/release/release.sh --dry-run <version> <build-number>` runs the whole pipeline without them. See [architecture §6.4](docs/architecture.md#64-release-pipeline).

To contribute, start with [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[GPL-3.0](LICENSE). Third-party code and its licenses are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). To report a security issue, see [SECURITY.md](SECURITY.md).

Clipsy is an independent project. It is not affiliated with or endorsed by Paste Team ApS, the makers of Paste.
