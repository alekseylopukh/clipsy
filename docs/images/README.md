# README images

The screenshots and app icon in the [README](../../README.md). Each image has a `-light` and a `-dark` variant, picked by the reader's appearance.

Regenerate them all after a UI change:

```bash
scripts/readme-screenshots.sh
```

The script needs Xcode 26 or later (for `ictool`) and ImageMagick (`brew install imagemagick`). It runs `MarketingSnapshotTests` in `Packages/ClipsyKit/Tests/SnapshotTests`, which render the real views offscreen over a generated wallpaper, then scales the PNGs and renders the icon from `App/AppIcon.icon`. The suite runs only when `CLIPSY_MARKETING` is set, so `swift test` skips it.

The content comes from `MarketingFixtures.swift` and is made up: no real clipboard data, people or logos. Liquid Glass is composited by the window server and never reaches an offscreen render, so the Shelf and the Sequence panel draw a frosted copy of the generated wallpaper under a lit rim instead. System switches draw grey in an app that is never active, so the Privacy screenshot draws them as an active window shows them.

Keep each PNG under about 400 KB, and check every one by eye before committing.
