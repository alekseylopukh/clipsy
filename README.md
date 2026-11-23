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
- Privacy controls: ignored apps, password managers, concealed content and text that looks like a secret are skipped
- Everything stays on your Mac. No account, no telemetry, no sync.

The full behavior is described in [docs/product.md](docs/product.md).

## Requirements

macOS 26 or later.

## Install

1. Download `Clipsy-<version>.dmg` from the [latest release](https://github.com/alekseylopukh/clipsy/releases/latest).
2. Open the disk image and drag Clipsy to Applications.
3. Open Clipsy from Applications. It runs in the menu bar and has no Dock icon.

Releases are signed with a Developer ID and notarized by Apple, so macOS opens them without a warning.

### Permissions

- **Accessibility** lets Clipsy paste straight into the app you were using. Without it, Clipsy puts the item on the clipboard and you press ⌘V yourself. Grant it in System Settings › Privacy & Security › Accessibility.
- **Clipboard access:** if macOS asks whether Clipsy may read the clipboard, allow it always. Otherwise Clipsy cannot see what you copy.

The first-launch window walks through both and can be skipped.

### Updates

Clipsy never checks for updates on its own unless you turn on automatic checks in Settings › About. "Check for Updates…" in that pane or in the menu bar menu checks once. Updates are signed and verified before they install.

### Uninstall

Quit Clipsy from its menu bar menu, then move it from Applications to the Trash. Your history and boards stay in `~/Library/Application Support/Clipsy/`; delete that folder to remove them too.

## Building from source

Requires macOS 26 and Xcode 27.2 or later. Swift packages (GRDB, KeyboardShortcuts, Sparkle) are fetched on the first build.

```bash
git clone https://github.com/alekseylopukh/clipsy.git
cd clipsy
scripts/build.sh        # build the app (Debug) into .build/DerivedData, signed with your Apple Development identity if you have one
scripts/build.sh test   # run the tests
open .build/DerivedData/Build/Products/Debug/Clipsy.app
```

A Debug build is signed ad hoc and needs no Apple developer account.

Release builds are made by `scripts/release/release.sh`, which needs the maintainer's signing and notarization secrets. `scripts/release/release.sh --dry-run <version> <build-number>` runs the whole pipeline without them. See [architecture §6.4](docs/architecture.md#64-release-pipeline).

To contribute, start with [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[GPL-3.0](LICENSE). Third-party code and its licenses are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). To report a security issue, see [SECURITY.md](SECURITY.md).

Clipsy is an independent project. It is not affiliated with or endorsed by Paste Team ApS, the makers of Paste.
