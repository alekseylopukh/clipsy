# Clipsy UI and visual design

This is the source of truth for how Clipsy looks. Behavior, features and the keyboard map live in [product.md](product.md); window plumbing, permissions and data live in [architecture.md](architecture.md). Product decisions (macOS 26+, no sync, no brand chrome) are in [CLAUDE.md](../CLAUDE.md#decisions).

Terms used here:

| Term | Meaning |
|---|---|
| Shelf | The floating panel that shows clipboard items |
| Card | One item on the Shelf |
| History | The default, time-ordered stream of everything copied |
| Board | A named, colored collection of Cards |
| Sequence | A queue of Cards pasted one after another |

Values marked "proposed" are starting points to tune on real hardware, not measured facts.

---

## 1. Design principles

1. **Looks like Apple shipped it.** System controls, SF Symbols, system text styles (one exception: the Card header band title, see [Header band](#header-band)), semantic colors, the user's accent color. If AppKit or SwiftUI has a control for it, we use that control. No custom fonts, no brand colors, no illustrations.
2. **Liquid Glass is for controls, not content.** The Shelf container, the top bar's controls, floating badges and the Sequence header are glass. Cards are content: opaque, readable, and they never sit in glass of their own.
3. **Content first.** A Card spends its area on the preview. Metadata is small; the one exception to neutral metadata is the header band, which shows the source app's color so the app reads at a glance.
4. **Color means something or it isn't there.** The only colors in the UI are the accent color (selection, primary action), Board colors (identity of a Board), the source app's color on the Card header band, from a fixed band palette (identity of the app) and the content itself (images, color swatches, link thumbnails).
5. **Keyboard is a first-class input.** Every action reachable by pointer is reachable by keyboard, and focus is always visible.
6. **Respect system settings.** Light/Dark, accent color, Reduce Motion, Reduce Transparency, Increase Contrast, Liquid Glass appearance, Dynamic Type where macOS supports it.

### Visual choices we made

| Rejected option | Clipsy | Why |
|---|---|---|
| Neutral header with a small app icon | Solid header band in the source app's system color, with the app icon nested in its corner | The source app reads at a glance by color as well as by icon. The band uses a fixed palette that is the same in light and dark (system colors resolved in their light variant, plus our amber and graphite), so white text holds on it in both modes; the Card body stays neutral, so content keeps its contrast. |
| Glass on Cards at every size | Glass only on the Shelf container and controls | HIG: no Liquid Glass in the content layer. Opaque Cards keep text contrast stable over any wallpaper. |
| Colored Board tabs | Board name with a small colored dot in a neutral tab track | Same information, less chroma; reads like Finder tags. The accent color stays reserved for the selection ring. |
| Custom animated menu bar icon | Template SF Symbol with a system symbol effect | Matches every other menu bar extra; adapts to the menu bar appearance. |
| In-app promotional banners | None. Only system alerts where a permission is actually missing | No nudges, no upsell. |
| Brand-tinted Sequence window | Plain glass panel with system rows | First-party look. |

### App icon

`App/AppIcon.icon`, an Icon Composer document that Xcode compiles into the app (the `AppIcon` build setting). It shows a paperclip of three glass pieces in a fixed blue, indigo and pink close to the system colors, each with a subtle vertical gradient; the indigo piece lies on top, and where it crosses the other two the overlap takes a mixed color, so the clip reads as layered glass. The artwork is SVG with no baked-in shadows or highlights; the material, light and dark backgrounds, and the clear and tinted renditions come from Icon Composer. Edit it in Icon Composer and check every rendition and the 32 and 16 pt sizes.

---

## 2. Shelf

### Placement and size

| Aspect | Design |
|---|---|
| Edge | Bottom of the screen, centered horizontally. Bottom only in v1. |
| Inset | Floats like the Dock: inset 8 pt from the bottom and side edges of the visible frame, with a soft system shadow. Never covers the menu bar. Respects the Dock: placed above it when the Dock is at the bottom and visible. |
| Corners | ≈37.31 pt, concentric with the Cards at the 16 pt inner padding. Inner elements use concentric radii; see [Metrics](#metrics). |
| Width | Full width of the visible frame minus the insets. |
| Height | User-resizable by dragging the top edge; one remembered height for all displays ([WD-13](roadmap.md#working-defaults-for-open-todos)). Range: from one compact row (160 pt) to 40% of the visible height; default 324 pt ([WD-22](roadmap.md#working-defaults-for-open-todos)). |
| Compact mode | When a regular Card would be under 150 pt tall ([WD-15](roadmap.md#working-defaults-for-open-todos)), Cards switch to a condensed layout: the header band shrinks to 32 pt with a 24 pt app icon and the time, the footer is hidden and the body fills the rest. Compact Cards are 4:3 instead of square so the time fits next to the icon. |
| Display | Opens on the display that holds the pointer. Moves with the user to the active Space and appears over full-screen apps. |

### Metrics

One radius system and an 8 pt grid (12 pt is the one half step, inside Cards). Every value lives in `DesignTokens`.

| Metric | Value | Rule |
|---|---|---|
| Screen inset | 8 pt | `shelfInset` |
| Shadow margin | 32 pt | `shelfShadowMargin`: the Shelf window extends this far past the glass on every side and the margin stays transparent, so the glass shadow fades out instead of being clipped to the window rectangle |
| Shelf padding | 16 pt | `shelfPadding`: top, sides and bottom; the gap between the top bar and the Cards is the same 16 pt |
| Card gap | 16 pt | `cardSpacing` = `shelfPadding`, so gaps between Cards equal the outer insets |
| Card radius | ≈21.31 pt | `cardCornerRadius` = header icon squircle radius (25.7% of its 44 pt visible size) + its 10 pt inset, so the icon nests concentrically in the top-trailing corner. Exact concentricity wins over the 8-pt grid here |
| Shelf radius | ≈37.31 pt | `shelfCornerRadius` = Card radius + Shelf padding (concentric) |
| Card content inset | 12 pt | `cardContentInset`, on all four sides |
| Card inner radius | ≈9.31 pt | `cardInnerCornerRadius` = Card radius − content inset. Body previews (link image, color swatch, image) clip to `ConcentricRectangle` against the Card's `containerShape`, with this as the minimum |
| Selection ring | 3 pt (4 pt with Increase Contrast), 2 pt gap | Radius = Card radius + gap + width, so the ring is concentric outside the Card |
| Quick-paste badge | 22 pt, bottom-trailing, inset ≈10.31 pt | `badgeSize`; inset = Card radius − badge radius, so the badge circle is concentric with the corner |
| Top bar controls | 28 pt tall | Large control size; icon-only buttons are 28 pt circles (16 pt glyph box), the search field is a 28 pt capsule |
| Tab track | 28 pt tall, 2 pt padding, 24 pt segments | `tabTrackPadding`, `tabSegmentHeight`; segments have 10 pt horizontal padding, sit 2 pt apart and truncate their label at 160 pt |
| Header band | 64 pt regular, 32 pt compact | Icon squircle + 2 × its inset |
| Header icon | 44 pt regular, 24 pt compact, measured on the visible squircle | Icon images carry transparent padding (the squircle is 824 of 1024 px), so the image is requested at squircle ÷ 0.8047. Inset 10 pt (4 pt compact) above, below and to the trailing edge. The squircle's corner is 25.7% of its size (measured against SwiftUI's continuous corner), so the regular icon nests concentrically in the Card corner; the compact one does not, which would need a ~54 pt band |
| Band-to-body gap | 12 pt regular, 8 pt compact for text, file and placeholder bodies; 0 for media | `cardBodyTopInset` / `cardCompactBodyTopInset`; link images, images and color swatches run edge to edge right under the band |
| Body-to-footer gap | 8 pt | `spacingMedium` |
| Text fade | 16 pt | `cardFadeHeight` |

Liquid Glass on the Shelf is a background layer, not a wrapper: wrapping the Cards in `.glassEffect` gave their text the glass's adaptive (vibrant) foreground, which turned Card text dark on dark Cards. Content outside the panel shape is clipped to it, so a Card scrolled under a rounded corner does not poke out.

### Snapshot harness

`scripts/snapshots.sh [dir]` renders offscreen to `.build/snapshots` (or `dir`), each in light and dark (`<name>-{light,dark}.png`, at the backing scale). The suites are skipped unless `CLIPSY_SNAPSHOTS` names the output folder, so `scripts/build.sh test` never renders.

All suites live in the `SnapshotTests` target:

| Suite | Renders |
|---|---|
| `ShelfSnapshotTests` | `shelf-{regular,short,compact,more}`: the Shelf, 1920 pt wide. `regular` (324 pt), `short` (240 pt, the lowest regular layout) and `compact` (160 pt) show the first eight Cards; `more` shows the other fixture Cards at 324 pt |
| `PopoverSnapshotTests` | `sequence`, `sequence-empty`, `rename`, `preview-<card id>`, `preview-<card id>-small` (clamped to 1438 × 524 pt, a 13" MacBook Air above a 300 pt Shelf), `edit-{text,link,color,board}`, `filters` |
| `AppSnapshotTests` | `settings-{general,shortcuts,privacy,about}`, `onboarding-{welcome,paste-directly,clipboard-access,finish}` |
| `ComponentGallerySnapshotTests` | `components`: every [DesignSystem component](#components) in its states; glass shows shape and layout only |

- Fixture: fifteen made-up Cards (`SnapshotFixtures`: text, rich text, link with preview image, color, code, image, file, three files, then wide, tall and transparent images, a link without an image, a short text, a dark color and an unknown item) and three Boards. Images and files are generated into a temporary folder; app icons come from system apps. No clipboard data is read. Settings and onboarding use a private defaults suite, a temporary database, a fake updater and a fake pasteboard access status (`.ask`, so the clipboard step shows).
- `SnapshotRenderer` hosts each view in a borderless `NSWindow` that is never ordered in, so nothing appears on screen, and captures it with `cacheDisplay`. Views without a fixed size render at their fitting size.
- Animations are disabled while rendering (a root `transaction` with `disablesAnimations`): a window that is never ordered in does not advance animations on the wall clock, so a capture could otherwise land mid-animation.
- The Settings panes and onboarding live in the app target, which `swift test` cannot build. `Tests/SnapshotTests/App` is a symlink to `App/`, and `Package.swift` lists the view files the target compiles and excludes the rest, so a new file in `App/` goes into one of the two lists; the menu bar menu (`StatusItemController`) is not rendered because it creates a real status item.
- Liquid Glass is composited by the window server and does not render offscreen. The harness draws a material stand-in for the Shelf and the Sequence panel, and glass buttons show only their labels. Popovers and sheets get a window background instead of their system chrome. Windows are never key, so default and prominent buttons render gray. Check glass, chrome and button tint in the running app.

Left, right and top edges (vertical layout) are not part of v1; they are listed under Later in [roadmap.md](roadmap.md#later-not-scheduled).
Placement uses the display's visible frame, so an auto-hidden Dock is not avoided ([WD-22](roadmap.md#working-defaults-for-open-todos)).

### Behavior as the user sees it

- Opens with the global shortcut (see [product.md](product.md)) or from the menu bar extra. The frontmost app keeps its focus and text cursor; the Shelf takes keyboard input without activating Clipsy's menu bar.
- Closes on Esc, on the shortcut again, after a paste, or when the user clicks outside it. It stays open while one of its sheets (such as an editor) is attached, or while it or one of its child windows (a popover, the Quick Look preview) has keyboard focus, and closes when focus leaves both (see [product.md §4.13](product.md#413-shelf-window-behavior)).
- Hidden from screenshots and screen sharing by default (setting in Privacy).
- One Card is always selected while the Shelf has items; on open, the newest Card in the current view is selected.
- Scrolls sideways with a trackpad, a horizontal wheel or Shift-wheel, and also with a plain vertical mouse wheel: over a scroll view that only scrolls horizontally (the Card strip, the Board tabs), the Shelf panel turns a vertical wheel turn into a horizontal one (`WheelRedirect`). Trackpad gestures pass through unchanged.

### Motion

Every animation uses one of five curves in `DesignTokens.Motion` (`DesignTokens+Motion.swift`); no view uses `.default` or a curve of its own. The one exception is the Shelf's own open and close slide, which Core Animation runs with its own timing (see Open and Close below). Distances, scales and delays live with their area: `DesignTokens+Strip.swift`, `+Card`, `+TopBar` and `+Flight`. Change them there.

| Curve | Value | Used for |
|---|---|---|
| `quick` | `.spring(duration: 0.2, bounce: 0)` | Scroll to the cursor, everything that leaves |
| `standard` | `.spring(duration: 0.3, bounce: 0.1)` | Layout: neighbors, the tab lens, the search field width |
| `present` | `.spring(duration: 0.35, bounce: 0.14)` | Everything that arrives: the cascade, suggestions, empty states |
| `pop` | `.spring(duration: 0.34, bounce: 0.28)` | Small single confirmations: a new Card, badges, filter tokens |
| `reduced` | `.easeOut(duration: 0.15)` | Reduce Motion: opacity only (the Shelf's window fade uses the same ease-out and 0.15 s) |

| Moment | Default | Reduce Motion |
|---|---|---|
| Open | The whole Shelf slides up from below its window's bottom edge, like the Dock, on a spring with no bounce (`shelfOpenSlideDuration` 0.3 s). It is one layer translation that runs in the render server (`ShelfSlide`), so it stays smooth while the app builds Cards; nothing fades, materializes or scales. Reopening during a close continues from where the panel is | The window fades in over 0.15 s (`shelfReducedFadeDuration`) |
| Cascade | While the Shelf arrives, each Card visible at open rises 24 pt (`cardEntranceOffset`) and fades in on `present`, starting 60 ms after the open (`cardEntranceDelay`) and 25 ms (`cardEntranceStagger`) after its left neighbor, capped at the 8th Card (`cardEntranceMaximumIndex` 7). Cards do not scale. After 350 ms (`cardEntranceWindow`) Cards that scroll into view appear at once | None |
| Close | The whole Shelf slides down below its window's bottom edge in 0.22 s, ease-in (`shelfCloseSlideDuration`), the same layer translation as the open; the glass does not fade, and the window is ordered out once the panel is gone. Copy closes the Shelf this way | The window fades out over 0.15 s |
| Paste | See [Paste](#paste) | No flight; the paste happens alone |
| Hover, selection | None: the selection ring appears and leaves at once, and a Card never moves ([States](#states)) | None |
| Scroll to the cursor | `quick`; revealing a Card in the center uses `standard` | Not animated |
| Strip edges | Cards less than half visible (`cardVisibilityThreshold`) dim to 50% (`stripEdgeOpacity`); opacity only, no scale | Same |
| Board switch | The tab lens slides on `standard`; the old strip fades out on `quick`; the new Cards slide in 16 pt (`cardTabSlideOffset`) from the side of the new tab and fade in on `standard`. The new strip starts at its beginning | Fade |
| New Card | Neighbors move on `standard`; the Card scales from 0.94 (`cardInsertScale`) and fades in on `pop` after 60 ms (`cardInsertDelay`) | Fade |
| Card deleted | The Card scales to 0.9 (`cardRemoveScale`) and fades on `quick`; neighbors close the gap on `standard` | Fade |
| Search results | Crossfade on `quick` | Fade |
| Compact ↔ regular | The first measurement is applied without animation, so a compact Shelf opens compact; later changes animate on `standard` | Instant |
| Search suggestions | The list materializes and scales from 0.96 (`searchSuggestionEntranceScale`) at its top edge, starting 8 pt higher (`searchSuggestionEntranceOffset`), on `present`; it leaves on `quick` | Fade |
| Filter tokens | Scale from 0.8 (`searchTokenEntranceScale`) at the leading edge and fade in on `pop`; the field width follows on `standard` | Fade |
| Selection count | The capsule scales from 0.8 (`searchTokenEntranceScale`) at its trailing edge and fades on `pop`, in and out; the number changes with a numeric content transition | Fade |
| Quick-paste badges | After 120 ms (`badgeAppearDelay`) each scales from 0.4 to 1 (`badgeEntranceScale`) on `pop`, 15 ms (`badgeStagger`) after the previous number; they leave on `quick` | Fade, no delays |
| Empty state | Fades in and scales from 0.96 (`emptyStateEntranceScale`) on `present` | Fade |
| Quick Look, next Card | Crossfade on `quick` | Same |
| Onboarding step | Blur-replace on `standard` | Fade |

#### Paste

The Shelf leaves at once, without its close animation, and the Card flies alone: it lifts, scaling to 1.04 (`pasteLiftScale`) in 80 ms (`pasteLiftDuration`) while its shadow grows from radius 12 to 24 (`pasteFlightLiftedShadowRadius`) and from 25% to 35% opacity, then flies along a gentle arc to the text insertion point of the target app and lands at scale 0.12 (`pasteFlightLandingScale`), fading out over the last 30% of the flight (`pasteFlightFadeStart` 0.7). The flight lasts `min(0.44, max(0.28, 0.26 + distance / 5000))` seconds for a distance in points (`pasteFlightMinimumDuration`, `pasteFlightMaximumDuration`, `pasteFlightBaseDuration`, `pasteFlightPointsPerSecond`). The arc's control point is 85% of the way up and 15% of the way across (`pasteFlightArcFraction`), so the Card rises first and then turns toward the caret.

The paste is posted right away, so the text appears while the Card is in flight. Single-Card pastes into the target app only (Return, double-click, Quick Paste, Paste in the menu); copies and multi-Card pastes have no flight.

**Paste afterimage (off).** The Shelf can also leave a Liquid Glass ghost of itself (`NSGlassEffectView`) and an afterimage of the strip, with a hole where the pasted Card was, which fade out and drop 12 pt (`pasteAfterimageDrop`) in 0.16 s (`pasteAfterimageDuration`) under the flying Card. Both are built but off: `pasteAfterimageIsEnabled` is `false`, because the strip snapshot runs before the paste keystroke is posted and took 65–69 ms offscreen at 1920 pt, over its 8 ms budget. Turn it on only after a measurement in the running app; with Reduce Transparency both stay off.

**Paste landing.** The landing point comes from Accessibility in the target app: the bounds of the focused element's selected text range (the caret), else the focused element's frame, else the focused window's frame; Accessibility's top-left coordinates are converted to AppKit's. With none of these, or when the landing point is on a different display than the Shelf, the Card fades out and shrinks to 0.92 (`pasteFadeEndScale`) where it was, on a 0.2 s spring (`pasteFadeSpringDuration`). The Card (and the ghost, when it is on) lives in a borderless, non-activating, click-through overlay panel above the Shelf that never takes focus, and it follows the "Show the Shelf in screenshots and screen sharing" setting. There is no setting to turn the flight off: it never delays the paste, and Reduce Motion removes it.

---

## 3. Cards

### Anatomy

A Card is a rounded rectangle with an opaque fill, an edge and a two-layer shadow; it never sits in glass of its own. Square in regular mode, 4:3 in compact mode. Metrics are in [§2 Metrics](#metrics).

- **Fill.** `cardFill`: `controlBackgroundColor` (white) in light, #2A2A2C in dark, lighter than the window background so a Card reads as raised in both modes.
- **Edge.** Light: a black 6% hairline (`cardEdgeOpacity`, one pixel wide). Dark: a 1 pt gradient from white 22% at the top to white 6% at the bottom (`cardEdgeTopOpacityDark`, `cardEdgeBottomOpacityDark`, `cardEdgeWidthDark`). No blend modes, because they render differently offscreen. Increase Contrast: a 1 pt `separatorColor` line.
- **Shadow.** Two layers on the fill only: a contact shadow, black 12% (dark 40%), radius 1, y 1, and an ambient shadow, black 14% (dark 36%), radius 14, y 6 (`cardContactShadow*`, `cardAmbientShadow*`).

| Part | Contents | Style |
|---|---|---|
| Header | A solid band flush with the Card's top edge, in the source app's color; the app icon nested in the top-trailing corner ([Metrics](#metrics)); title if the user renamed the Card, else the type label; relative time ("2 minutes ago") below it | See [Header band](#header-band) |
| Body | Type-specific preview (table below) | Text bodies start 12 pt below the band (8 pt compact); media run edge to edge |
| Footer | Type-specific metadata | `.subheadline`, secondary label color (tertiary was too faint for 4.5:1), single line, truncated. Image and color Cards and compact Cards have none |
| Board marker | When showing search results from all of History and Boards: the Board's colored dot next to the time on the header band | Board color, 8 pt dot with a 1 pt white ring, so a dot keeps its edge on a band of the same color |

Type sizes on a Card are 14 pt (band title), 13 pt (body) and 11 pt (time and footer).

### Header band

- **Palette.** A flat fill from eleven fixed colors, the same in light and dark: red, orange, amber, green, teal, blue, indigo, purple, pink and gray, plus graphite. All but amber and graphite are system colors resolved in their light variant in both schemes, because the dark variants are lighter and hold white text worse. Amber is #FAB700 (`cardBandAmber`); graphite is #1D1D1F in light and #48484A in dark (`cardBandGraphite`, `cardBandGraphiteDark`). Cards without a source app are gray. When the app is unknown or no longer installed, the Card's type symbol takes the icon's place, white at 85%, sized to the 44 pt squircle.
- **Icon → color.** The icon is drawn into a 32 × 32 px sRGB sample. Each opaque pixel (alpha > 0.5) whose chroma (max − min) is at least 0.25 votes, weighted by its chroma, for the color whose hue window holds it. Windows in degrees, lower bound inclusive: red 354–10, orange 10–39, amber 39–65, green 65–160, teal 160–190, blue 190–235, indigo 235–270, purple 270–318, pink 318–354. Other pixels count as dark (WCAG luminance < 0.06) or light (> 0.4). The color with the most votes wins when its share of the opaque pixels is at least 0.04 + 0.15 × the dark share; otherwise the band is graphite when dark pixels outnumber light ones, else gray. There are no per-app exceptions.
- **Text.** Always white. Title 14 pt semibold. Time `.subheadline` medium with monospaced digits, wide units in regular ("2 minutes ago") and narrow units in compact. On light bands, where white has less than 3:1 contrast (`cardBandLightContrast`: amber, orange, green and teal), the time is 100% white and both lines carry a subtle shadow (black 22%, radius 1, y 0.5) that keeps the letter edges; on the other bands the time is 85% white and there is no shadow.
- **Contrast.** The band is a flat fill in its palette color and is never darkened, except with Increase Contrast: then every band under 4.5:1 for white text darkens just enough to reach it, and the time is fully opaque.
- **First frame.** The icons and band colors of the first 12 Cards (`appIconPrewarmCount`) are loaded in the background as soon as the Cards load, also while the Shelf is hidden, and a Card reads its cached color in its first frame, so an open does not show a band changing color. A Card whose color is not cached yet starts gray and changes on `quick`.
- **Quick-paste badges** sit at the bottom-trailing corner, concentric with it, so they never cover the icon.

### Per-type layouts

| Type | Body | Footer |
|---|---|---|
| Plain text | Text from top-left, `.body`, as many lines as fit, tail-truncated with a fade. Compact: 2 lines (`cardCompactTextLineLimit`), no fade | Character count |
| Rich text | Rendered with its own fonts and colors, scaled to the system body size; colors that fail contrast on the Card fill fall back to label color. Compact: 2 lines in plain `.body` | Character count |
| Code-like text | Plain text heuristically detected as code gets SF Mono (`.monospaced()`); no syntax colors. Not a separate type | Line count |
| Link | With a preview image: the image runs edge to edge right under the band and takes the rest of the body, at least 44 pt (`cardLinkImageMinimumHeight`), filled; the page title below it in `.callout` semibold, up to 2 lines. When the body is too short for both, only the image remains. Compact: the image fills the body. Without a preview image: the `link` symbol, centered, with the page title (else the host) under it in `.callout` semibold, up to 2 lines | Host name without `www.` |
| Image | Edge to edge from the band to the bottom corners. Fills the body when the image's aspect ratio is within 0.5–2× of the body's (`cardMediaFillAspectRange`), else fits on a neutral fill; checkerboard behind transparency. Pixel dimensions, without grouping separators ("1600 × 1000"), in a `MediaCaption` at the bottom-leading corner, 8 pt in (`mediaCaptionInset`). Same in compact | None |
| File | Quick Look thumbnail or file icon, centered; shrinks to fit in compact | File name, middle-truncated |
| Multiple files | Up to three stacked thumbnails, slightly fanned | "N files" and total size |
| Color | Swatch edge to edge from the band to the bottom corners, the value in a `SwatchValueLabel` at the bottom-leading corner, 12 pt in (`swatchValueInset`), in black or white, whichever reads on the swatch. Same in compact | None |
| Unknown | Generic `questionmark.square.dashed` symbol, short note that the item can still be pasted | Type identifier, if useful |

Media bodies clip their bottom corners to the Card radius. Details such as rich text scaling, the contrast threshold and the link body without a preview follow [WD-32](roadmap.md#working-defaults-for-open-todos); link previews follow [WD-40](roadmap.md#working-defaults-for-open-todos).

### States

| State | Look |
|---|---|
| Rest | Fill, edge, contact and ambient shadow ([Anatomy](#anatomy)) |
| Hover | No change, as in Finder: a Card does not move, scale or change its shadow under the pointer |
| Selected | Accent-colored 3 pt ring, 2 pt outside the Card at a concentric radius. The ring appears and leaves at once, with no animation, and the Card itself does not change, so holding an arrow key never shows more than one ring |
| Multi-selected | Each selected Card gets the ring; a count ("3 selected") appears in the top bar |
| Keyboard focus without selection change | Same as Selected; there is only one focus indicator |
| Being dragged | An AppKit drag image taken from the Card; the source Card stays as it is |
| Pasted (Sequence) | Not shown on the Shelf; see §6 |

### Quick-paste badges

- While the quick-paste modifier is held (see [product.md](product.md)), the first nine visible Cards show a 22 pt glass capsule with the number (1–9) in `.subheadline` semibold at the bottom-trailing corner, clear of the header icon.
- Badges appear after 120 ms, one after another; see [Motion](#motion). With Reduce Motion they fade in without delays.
- Numbers count from the first visible Card, not the first Card in History. A Card counts as visible when at least half of it is, the same threshold that dims the strip edges.

---

## 4. Top bar

A single row at the top of the Shelf. Its glass controls (search field, Filters, New Board, the selection count, More) sit in one `GlassEffectContainer`; the Board tabs are a fill, not glass, so glass never sits on glass.

```
[Search          ] (Filters)       [ History | ● Work | ● Design ] (+)       (3 selected) (More)
```

Leading to trailing:

1. **Search field.** Capsule search field with a magnifying-glass symbol and placeholder "Search". Typing anywhere on the Shelf starts a search. Active filters show as tokens inside the field.
2. **Filters button** (`line.3.horizontal.decrease`). Opens a popover with sections Type, App, Date, Board. Choosing a value adds a token. Pressing the search shortcut a second time also opens it. While any filter is active the button uses the prominent glass style.
3. **Board tabs**, centered on the Shelf together with the New Board button: a `TabTrack`, a capsule track in a tertiary fill with one segment per tab, "History" first (symbol `clock`), then each Board (colored dot + name). A neutral lens in a secondary fill slides under the selected tab; the accent color stays reserved for the selection ring. The track stays centered while the tabs fit and scrolls when they do not. Boards reorder by drag; dropping a Card on a tab adds it to that Board, and the tab shows a 25% accent fill while it is the drop target.
4. **New Board button** (`plus`), right after the track and outside its scrolling, so it is always visible.
5. **Selection count.** With two or more Cards selected, a glass capsule "3 selected"; the number changes with a numeric content transition.
6. **More menu** (`ellipsis`): New Text Card, Start Sequence, Pause/Resume capture, Settings…

The trailing group is at least as wide as the leading one, so the track and the New Board button stay centered on the Shelf.

While search is active, the Board switcher stays visible. Selecting a Board clears the search and shows that Board ([product.md §4.9](product.md#49-search-and-filters)). Matches in a Card's title and text are highlighted with the system find-highlight color.

### Board colors

System colors only, so they adapt to light/dark and Increase Contrast: red, orange, yellow, green, blue, purple, gray (the Finder tag set). Pink is left out because it is hard to tell apart from red. The color picker in the New/Edit Board sheet is a row of these swatches, not a free color well.

Working default [WD-9](roadmap.md#working-defaults-for-open-todos): every Board has a color; there is no "no color".

### Empty states

Use `ContentUnavailableView` centered in the Card area. Our own wording (proposed):

| Situation | Symbol | Title | Description |
|---|---|---|---|
| History empty | `clipboard` | No Clipboard History | Copy something and it shows up here. |
| Board empty | `square.stack` | This Board Is Empty | Drag Cards here or use "Add to Board". |
| No search results | `magnifyingglass` | No Results | Try a different search or remove a filter. |
| Capture paused | `pause.circle` | Capture Paused | A Resume button. |

---

## 5. Context menu, Quick Look, editing

### Card context menu

Native `NSMenu` with SF Symbols on items and section separators. Items that do not apply to the selection are hidden, not disabled. Order:

| Section | Items |
|---|---|
| Paste | Paste to *App* (`arrow.down.doc`), Paste as Plain Text (`textformat`) |
| Copy | Copy (`doc.on.doc`), Copy as Plain Text (`doc.plaintext`) |
| Open | Open (`arrow.up.forward.app`; links, files), Open With ▸ (files), Show in Finder (`folder`; files) |
| Item | Quick Look (`eye`), Show in List (`list.bullet.rectangle`; search results only), Edit… (`pencil`; text, links, colors), Rename… (`character.cursor.ibeam`), Duplicate (not built yet, see [roadmap](roadmap.md#needs-the-maintainer)) |
| Organize | Add to Board ▸ (list of Boards + New Board…), Add to Sequence (`list.number`) |
| Share | Share… (`square.and.arrow.up`), opens the system share picker at the Card, like Share… in Finder |
| Destructive | Delete (`trash`, destructive role), or Remove from Board (`minus.circle`) inside a Board |

With several Cards selected, the menu shows only actions that work on many: Paste, Paste as Plain Text, Copy, Add to Board, Add to Sequence, Share, Delete (Remove from Board inside a Board).

Inside a Board, Delete is hidden and Remove from Board takes its place in the last section, because Delete on a Board only removes the Card from it ([WD-12](roadmap.md#working-defaults-for-open-todos)).

### Quick Look

- Space toggles a preview anchored to the Card under the keyboard cursor, as an `NSPopover` with the system's glass background. Esc closes the preview before it clears the search or closes the Shelf.
- Files use `QLPreviewView`; a file that was moved or deleted shows "File Not Found" with its name. Several files show a list of their names with Quick Look thumbnails.
- Images use our own image view (decoded at up to 2048 px, checkerboard behind transparency): `QLPreviewView` needs a file, and image Cards keep their data in the store, so a temporary copy would put clipboard data outside it.
- Text, rich text, links and colors use our own read-only SwiftUI views: selectable text (rich text keeps the Card's styling rules), the link's title or host with the full URL, and a large swatch with Hex, RGB and HSL values. Details follow [WD-49](roadmap.md#working-defaults-for-open-todos).
- The popover is sized to its content, never larger than 880 × 680 pt:

  | Content | Size |
  |---|---|
  | Text | 640 pt wide (760 pt for code-like text), as tall as the text and at least 96 pt; `.title3` with 4 pt line spacing, code in monospaced `.body` |
  | Link | 480 pt wide; the preview image 480 × 270 pt edge to edge, then the title, host and URL |
  | Color | 360 pt wide; a 180 pt swatch edge to edge, then Hex, RGB and HSL |
  | Several files | 420 pt wide, 44 pt rows, up to 10 before it scrolls |
  | Unknown | 320 × 220 pt |
  | Image | Fitted to the image's aspect ratio inside the box above the Shelf, at least 240 pt on each side ([Window and popover metrics](#window-and-popover-metrics)) |
  | One file, File Not Found | The whole box above the Shelf |

- A 36 pt source bar along the bottom shows the source app's icon (16 pt), its name and the time in secondary `.callout`, then the Card's metadata in `.metadataStyle()`.
- An image shows its thumbnail first and crossfades to the full image; a spinner appears only after 300 ms.
- Arrow keys move the selection and the preview follows, crossfading on `quick`.

Prototype result (T8.1): the popover uses `.applicationDefined` behavior, is anchored to an invisible view behind the cursor Card, and hands key status back to the Shelf after it opens and after it closes while key, so Space, arrows and Esc keep reaching the Shelf. When a click in the preview (selecting text, scrolling a PDF) makes the popover key, it forwards every key without ⌘ to the Shelf, Esc included, and keeps ⌘ shortcuts so ⌘C copies the selected text. The Shelf stays open while the popover or another child window is key and closes when focus leaves both; the popover's own loss of key status runs the same check as the panel's. This builds and the previews render offscreen in light and dark, but the live behavior inside the non-activating panel was not run by the agent; it is a human check of T8.1.

> TODO: compare against `QLPreviewPanel` (the Finder-style floating panel) in practice; the popover is chosen because it works inside a non-activating panel, but the system panel may feel more native.

### Edit sheet

- Opens as a sheet attached to the Shelf. Working default ([WD-48](roadmap.md#working-defaults-for-open-todos)): no standalone window; the sheet is never taller than the Shelf, and the text area shrinks to fit.
- Toolbar per type, using system controls:
  - Text: Bold, Italic, Underline, Strikethrough as a segmented control (⌘B, ⌘I, ⌘U); character/word/line counts in the bottom bar; an inline error next to the buttons.
  - Link: URL field and optional title field.
  - Color: `ColorPicker` / system color panel plus a format picker (Hex, RGB) and a value field.
  - Link and color editors are grouped forms with Cancel (Esc) and Save (Return); the form scrolls when the Shelf is shorter than the sheet.
  - Image (later): rotate left/right.
- Buttons: Cancel (Esc) and Save (Return with ⌘ in text editors), standard placement.
- Rename uses a small popover with a single text field; empty name clears the title.

---

## 6. Sequence

A separate floating panel, independent of the Shelf, so the user can keep working in the target app.

| Aspect | Design |
|---|---|
| Window | Small non-activating utility panel, glass background; proposed width ~280 pt, height grows with rows up to a limit, then scrolls. Draggable; position remembered. |
| Header | Title "Sequence" with `list.number` symbol; trailing buttons: Undo (`arrow.uturn.backward`), More (`ellipsis`), Close (`xmark`). |
| More menu | Reverse Order, Paste All, Paste as Plain Text (checkmark toggle), Clear |
| Rows | Opaque content rows, one per item: one or two lines of preview, trailing app icon or type symbol. The next row to paste carries a small accent-colored marker. |
| Reorder / remove | Drag to reorder; hover shows a remove button; Delete key removes the selected row. |
| Paste feedback | The pasted row slides out; the next row gets the marker. With Reduce Motion, it disappears instantly. |
| Empty state | Short line in secondary color telling the user to copy items or drag Cards here (own wording). |
| End | After the last item is pasted, the panel fades out. |

---

## 7. Menu bar extra

- Symbol: `clipsy.paperclip` normally, a custom symbol in `App/Assets.xcassets` whose outline is the paperclip of the [app icon](#app-icon) in one color (its three pieces merged), and the `pause.circle` SF Symbol while paused. Both are template symbols, so the menu bar tints them. A brief `.bounce` symbol effect on each capture; none with Reduce Motion.
- Shown by default; hidden with a Settings toggle. If hidden, the global shortcut still works and launching the app again opens Settings.
- Click shows a menu (per HIG). An opt-in setting makes a left click open the Shelf instead, with the menu on right-click / Control-click.

Menu contents: the items and pause durations are set in [product.md §6](product.md#menu-bar-menu); this table sets grouping and wording.

| Group | Items |
|---|---|
| Main | Open Shelf (shows the shortcut), New Text Card, Start Sequence |
| Capture | Pause Capture ▸ (For 15 Minutes, For 1 Hour, For 8 Hours, Until Tomorrow, Until Resumed) / Resume Capture; when paused, a disabled line with the resume time in the user's locale time format |
| App | Settings… (⌘,), Check for Updates…, About Clipsy |
| Help | Clipsy Help (opens the project docs), Report an Issue |
| Quit | Quit Clipsy (⌘Q) |

Decided (T6.4, symbol changed with the app icon): `clipsy.paperclip` normally and `pause.circle` while paused, swapped with the `.replace` content transition. The custom symbol has no pause variant.

Decided (T7.3): the disabled line reads "Paused until 15:45", in the locale's short time format, with the abbreviated weekday when the resume time is not today. Until Resumed shows no line.

---

## 8. Settings window

SwiftUI `Settings` scene with a toolbar `TabView`. Each pane is a `Form` with `.formStyle(.grouped)`. Window title equals the pane name; the last pane is restored; minimize and zoom disabled. Opens with ⌘, from the Shelf or the menu bar menu. No Sync pane.

### General

| Control | Type |
|---|---|
| Open at login | Toggle (`SMAppService`) |
| Show in menu bar | Toggle |
| Click on menu bar icon opens the Shelf | Toggle (disabled when the icon is hidden) |
| Sound effects | Toggle |
| Paste behavior | Radio group: "Paste into the active app" / "Copy to the clipboard only" |
| Paste without formatting by default | Toggle |
| Accessibility status | Status row (granted / not granted) with "Open System Settings…" button when missing |
| Keep history for | Slider with tick marks: 1 Day, 1 Week, 1 Month, 1 Year, Forever |
| Storage | Row with secondary value text: card count and disk size, for example "1,234 cards, 56.7 MB" |
| Erase History… | Button, destructive confirmation alert; Board contents are kept |

### Shortcuts

| Control | Type |
|---|---|
| Open Shelf | Shortcut recorder |
| Start Sequence | Shortcut recorder |
| Paste All Sequence Cards | Shortcut recorder |
| Next Board / Previous Board | Shortcut recorders |
| Quick paste modifier | Pop-up: ⌘ / ⌥ / ⌃ |
| Plain text modifier | Pop-up: ⇧ / ⌥ / ⌃ / ⌘ |
| Restore Defaults | Button with confirmation |

The recorder rejects combinations already used by the app, by a menu item or by the system. A conflict with another Clipsy shortcut is shown inline below the field; a menu item or system conflict is shown in the recorder's own sheet (WD-36 in the roadmap).

### Privacy

| Control | Type |
|---|---|
| Ignore passwords and other concealed content | Toggle, on by default |
| Ignore temporary content from other apps | Toggle, on by default |
| Ignored apps | `List` with +/− buttons below (system app picker); Passwords is pre-added |
| Show link previews | Toggle with a footnote that it makes a network request per link and may trigger one-time links; off by default (network use: [CLAUDE.md](../CLAUDE.md#decisions)) |
| Recognize text in images | Toggle (on-device; makes images searchable) |
| Show the Shelf in screenshots and screen sharing | Toggle, off by default |
| Clipboard access status | Status row for the system pasteboard permission (see §9) |

### About

App icon, name, version and build, "Free and open-source under GPL-3.0", links: Source Code, Report an Issue, Acknowledgements (third-party licenses, shown in a sheet from `App/Credits.rtf`). An Updates section with an "Automatically check for updates" toggle (off by default) and a Check for Updates… button.

Decided (T13.1, WD-19): update settings live in About.
There is no Advanced pane; capture polling and the size limit are fixed ([WD-1](roadmap.md#working-defaults-for-open-todos), [product §4.1](product.md#41-capture)).

---

## 9. Onboarding and permissions

A single window shown on first launch (SwiftUI, standard window chrome, glass toolbar), 480 × 480 pt on every step so it never jumps. Each step has a 96 pt hero (the app icon on Welcome, a hierarchical SF Symbol on the others), a bold `.largeTitle` title and a secondary `.title3` message up to 400 pt wide; the primary button is large and prominent. Steps change with a blur-replace transition on `standard`, a fade with Reduce Motion. Three short steps, all skippable. Text below is our own and still a draft.

| Step | Content | Controls |
|---|---|---|
| 1. Welcome | App icon; one line: "Everything you copy, one shortcut away." Shows the current Open Shelf shortcut with a recorder to change it. | Continue |
| 2. Paste directly | Explains that pasting into other apps needs Accessibility permission, and that without it Clipsy copies the item and the user presses ⌘V. Live status row that turns green when granted (polled while the step is visible). | Open System Settings…, Not Now |
| 3. Clipboard access | On systems where macOS asks before an app reads the clipboard, explains why Clipsy needs ongoing access and how to allow it. Live status row. Skipped when the system does not gate access. | Open System Settings…, Not Now |
| Finish | Open at login (toggle), Keep history for (pop-up), Show link previews (toggle, off by default, with a one-line note that loading a link can use up a one-time link or let the site track the visit; same setting as Settings › Privacy). Hint: press the shortcut to try it. | Done |

Rules:
- Never block the app on a missing permission. The Shelf works in copy-only mode without Accessibility.
- When a paste fails for lack of permission, show one standard alert offering "Open System Settings…" and "Copy Only", with a "Don't ask again" checkbox (suppression button).
- Permission status is re-checked when the app becomes active; Settings rows update live.
- No seeded Boards or sample Cards.

Step 3 and the Privacy pane row read `NSPasteboard.general.accessBehavior` (checked against the macOS 26 SDK). The step and the row appear only once macOS has asked about Clipsy (`.ask`, `.alwaysAllow` or `.alwaysDeny`); `.default` means the system never asked, so there is nothing to set. The pane is System Settings › Privacy & Security › Paste from Other Apps, and its button opens `x-apple.systempreferences:com.apple.preference.security?Privacy_Pasteboard` (the anchor is in the macOS 27.2 System Settings; the copy names the pane in case the anchor does not resolve). The Accessibility button calls the system prompt instead of a URL (WD-27).

> TODO: whether reading `changeCount` alone triggers the pasteboard prompt on macOS 26 (see [product.md §4.1](product.md#41-capture)).
> TODO: verify on macOS 26 that the `Privacy_Pasteboard` anchor opens the Paste from Other Apps list.

---

## 10. Accessibility and appearance

| Area | Requirement |
|---|---|
| VoiceOver: Card | Label "*Type* from *App*, *relative time*", e.g. "Image from Preview, 2 minutes ago"; value = first line of text, link title, file name or color value; custom actions for Paste, Paste as Plain Text, Copy, Quick Look, Add to Board, Delete. |
| VoiceOver: Shelf | The Card strip is a list with item count; the Board tabs are a group labeled "Boards" whose selected tab carries the selected trait; quick-paste badges are exposed as part of the Card label ("number 3") only while visible. |
| Announcements | Announce capture paused/resumed, item deleted (with undo hint), Sequence item pasted. |
| Keyboard only | Every action has a key or is in a menu reachable from the keyboard; Tab moves between search field, Board switcher and Card strip; focus ring always visible. Key map in [product.md](product.md). |
| Reduce Motion | Fades on `reduced` replace springs, offsets, scales and slides; no Card cascade and no paste flight; scrolling and layout changes are instant (see [§2 Motion](#motion)). |
| Reduce Transparency | Glass and the media caption's material turn opaque automatically; we add no custom blur that would ignore the setting. The paste ghost and afterimage stay off even when `pasteAfterimageIsEnabled` is on. The strip edge dimming stays. |
| Increase Contrast | Card edges become a 1 pt `separatorColor` line; the selection ring thickens to 4 pt; the tab lens gets a `separatorColor` outline; Board dots do not change (on the Card header band they always have a white ring); header bands darken to 4.5:1 for their white text and the time turns opaque (see [Header band](#header-band)). |
| Liquid Glass appearance | Test with the system Clear and Tinted glass options. |
| Color independence | Board identity never relies on color alone: the name is always shown next to the dot. Selection uses a ring, not only a fill. |
| Text size | System text styles, so the macOS text size setting (where honored) applies. Exception: the Card header band title is a fixed 14 pt semibold, chosen by the maintainer to sit between `.headline` and `.title3`; the time below it uses `.subheadline`. |
| Light / Dark | Semantic colors only, with these exceptions, all in `DesignTokens`: the Card header band palette (system colors resolved in light for both modes, amber #FAB700, graphite #1D1D1F / #48484A), its white text and Board dot ring and the faint black text shadow on light bands (see [Header band](#header-band)); the dark Card fill #2A2A2C; the black or white value on a color swatch. Image and color Cards show content as-is in both modes. |

---

## 11. Component mapping

| Element | Component |
|---|---|
| Shelf window | `NSPanel` subclass, non-activating, full-size content view, resizable from the top edge, floating level, joins the active Space and full-screen Spaces; `sharingType = .none` unless the privacy toggle is on. Details in [architecture.md](architecture.md). |
| Shelf background | `GlassPanelBackground` (`.glassEffect(.regular, in: .rect(cornerRadius:))` on a background layer of the root view, see [§2 Metrics](#metrics)), concentric corner radius |
| Shelf content | SwiftUI hosted in `NSHostingView` |
| Card strip | Horizontal `ScrollView` + `LazyHStack` (or `NSCollectionView` if performance needs it) |
| Card | `.cardSurface(isSelected:)`: opaque `cardFill`, edge and two-layer shadow; no glass |
| Selection ring | Part of `.cardSurface`: stroke in `Color.accentColor`, concentric outside the Card |
| Quick-paste badge | `GlassBadge(count:)` |
| Top bar | `GlassEffectContainer` holding the glass controls; the Board tabs are a `TabTrack` in a horizontal `ScrollView` |
| Search field | `GlassSearchField` with removable chips for tokens and a plain `TextField` (see [Components](#components)) |
| Filters | Button with `.buttonStyle(.glassIcon(isProminent:))` opening a `.popover`; prominent while filters are active |
| Board tabs | `TabTrack` with `.tabTrackSegment(id:in:isSelected:isTargeted:)` on each tab; the lens follows the selection with `matchedGeometryEffect` |
| Board color dot | `BoardDot` (`BoardColor.menuSwatch` inside menus) |
| Empty states | `EmptyStateView`, a `ContentUnavailableView` |
| Context menu | `NSMenu` / SwiftUI `.contextMenu` with `Label` items (SF Symbols), `Divider` between sections, destructive role on Delete |
| Quick Look | `NSPopover` containing `QLPreviewView` (files) or SwiftUI previews (images, text, links, colors), with the source bar in `safeAreaBar(edge: .bottom)` |
| Edit sheet | `.sheet` with `Form`, `ColorPicker`, standard toolbar; the text editor is an `NSTextView` in `NSViewRepresentable`, because RTF in and out needs AppKit font attributes that SwiftUI's `TextEditor` does not keep |
| New/Edit Board | Sheet with `TextField` and a swatch row |
| Sequence panel | Separate `NSPanel` (utility, non-activating) hosting SwiftUI; header in `GlassEffectContainer`; rows in `List` with `.onMove` and `.onDelete` |
| Menu bar extra | `NSStatusItem` with an `NSMenu` ([WD-35](roadmap.md#working-defaults-for-open-todos)) |
| Symbol effects | `.symbolEffect(.bounce)` on capture |
| Settings | `Settings` scene, `TabView` with `Tab(_:systemImage:value:)`, `Form` + `.formStyle(.grouped)` |
| Shortcut recorder | `KeyboardShortcuts.Recorder` from KeyboardShortcuts ([architecture §2](architecture.md#2-stack)) |
| Ignored apps list | `List` + `.fileImporter` limited to applications |
| Onboarding | SwiftUI `Window` scene with a step container and standard buttons |
| Alerts | `.alert` / `NSAlert` with `showsSuppressionButton` |
| Toast/HUD | None. The menu bar symbol shows the paused state ([§7](#7-menu-bar-extra)) and sounds confirm capture and paste ([WD-34](roadmap.md#working-defaults-for-open-todos)) |

Checked against the macOS 26 SDK: SwiftUI has `.glass`, `.glassProminent`, `glassEffectID(_:in:)` and `glassEffectUnion(id:namespace:)`; `NSGlassEffectView` has `contentView`, `cornerRadius`, `tintColor` and `style`.

### Components

Every recurring UI role has one component, listed below, and screens use it instead of assembling the same look from modifiers ([code rule R5.6](../.claude/rules/code-rules.md#r5-native-look)). The components live in the `DesignSystem` module, except `PermissionStatusLabel`, which lives in the app target with its strings. The gallery renders each one in light and dark: `ComponentGallerySnapshotTests` → `components-{light,dark}.png` (see [Snapshot harness](#snapshot-harness)).

| Role | Component | Where used | Rules |
|---|---|---|---|
| Glass icon button | `.buttonStyle(.glassIcon)`, `.glassIcon(isProminent:)` (`GlassIconButtonStyle`) | Top bar: New Board, Filters, More | 28 pt circle at `.large` size, 16 pt glyph box (`.labelStyle(.glassIcon)`); `isProminent` uses `.glassProminent` (Filters while filters are active). Write `Button("Title", systemImage:)` so it has a label |
| Glass icon menu | A glass icon button with `.popUpMenuAnchor(_:)` (`PopUpMenuAnchor`) that pops up an `NSMenu` of `ActionMenuItem`s under itself | Top bar: More | Same control as the glass icon button, so the whole 28 pt circle is the hit target and focus ring, and Space or Return opens the menu. Not a SwiftUI `Menu`: macOS draws a menu's button through AppKit and ignores `.buttonStyle(.glass)` (it renders the plain bezel, with or without `.menuStyle(.button)`), and a borderless menu over a glass circle only takes clicks on its 16 pt glyph, whatever frame its label gets. Build the menu when the button is pressed, so state such as Pause/Resume is current |
| Tab track | `TabTrack(selection:label:content:)` | Top bar: History and Board tabs | 28 pt capsule track in `.fill.tertiary` with 2 pt padding; a neutral lens in `.fill.secondary` slides to the selected segment on `standard` (`matchedGeometryEffect`), outlined in `separatorColor` with Increase Contrast; an accessibility group with a label. Not glass |
| Tab track segment | `.tabTrackSegment(id:in:isSelected:isTargeted:)` | Each tab inside a `TabTrack` | 24 pt tall, 10 pt horizontal padding, one line up to 160 pt; primary when selected, else secondary; `.fill.quaternary` on hover; 25% accent while a drop targets it, with an alignment haptic on entry; the selected trait. The weight never changes, so widths stay put |
| Search field | `GlassSearchField { … }` | Top bar | Leading magnifying glass, 220 pt minimum, 28 pt capsule of glass (not interactive: a text field does not flex when pressed). Content: tokens, a plain `TextField`, the clear button |
| Removable chip | `.buttonStyle(.removableChip)` (`RemovableChipButtonStyle`) | Search tokens in the search field | Callout label, trailing small `xmark`, `.fill.secondary` capsule; the whole chip removes it |
| Accessory icon | `.buttonStyle(.accessoryIcon)` (`AccessoryIconButtonStyle`) | Clear Search; Remove on Sequence rows | Borderless, icon only, secondary |
| Borderless icon | `.buttonStyle(.borderlessIcon)`, `.menuStyle(.borderlessIcon)` | Sequence header (Undo, More, Close); Privacy Ignored Apps +/− | Borderless, icon only, label color |
| Card surface | `.cardSurface(isSelected:)` (`CardSurface`) | `CardView` | Opaque `cardFill`; edge (light hairline, dark gradient, `separatorColor` with Increase Contrast); contact and ambient shadow; accent selection ring 2 pt outside at a concentric radius that appears and leaves at once; sets the `containerShape` for `.cardInner` clips. Never glass, never scaled |
| Glass badge | `GlassBadge(count:)` | Quick-paste numbers | `.subheadline` semibold, monospaced digits, 22 pt minimum, on a regular glass capsule |
| Media caption | `MediaCaption(_:)` | Image Card dimensions | `.caption` medium, monospaced digits, on an `.ultraThinMaterial` capsule: a material, not Liquid Glass |
| Swatch value label | `SwatchValueLabel(_:on:)` | Color Card value | Monospaced `.callout` semibold, black when the swatch's WCAG luminance is above 0.179 (`swatchLabelLuminanceThreshold`), else white, both at 100%; no background |
| Board color dot | `BoardDot(_:isOutlined:)`; `BoardColor.menuSwatch` in menus | Top bar Board tabs, search token labels, Card header (outlined); Board context menu and Add to Board | 8 pt dot in the Board color; outlined in white on the colored header band. Menus draw SwiftUI symbols as templates, so they use the palette image |
| Empty state | `EmptyStateView(_:systemImage:description:actions:)` | Shelf empty states, preview No Preview and File Not Found | A `ContentUnavailableView` with a symbol, an optional description and optional actions |
| Placeholder symbol | `PlaceholderSymbol(_:)` | Card bodies without a preview, image and link previews | `.largeTitle`, secondary |
| Metadata text | `.metadataStyle()` | Card footer, text editor counts | `.subheadline`, secondary, monospaced digits |
| Row with note | `LabelWithNote(_:note:)` | General, Privacy, onboarding Finish: rows and toggles that explain themselves | Goes in the label of a `LabeledContent` or `Toggle` in a grouped `Form`, which draws the note as a secondary subtitle |
| Section footnote | `FormFootnote(_:)` | Privacy and About section footers | Secondary text under a grouped section |
| Sheet header | `SheetHeader(_:)` | Board sheet, link and color edit sheets | `.headline` section header |
| Sheet button bar | `SheetButtonBar(errorMessage:) { … }` | Board, link, color and text edit sheets; Acknowledgements; onboarding steps | Optional `InlineErrorLabel` leading, buttons trailing; the caller pads it |
| Inline error | `InlineErrorLabel(_:)` | Inside `SheetButtonBar` | `exclamationmark.triangle.fill`, red |
| Glass panel background | `GlassPanelBackground(cornerRadius:)` | Shelf, Sequence panel | Regular glass on a background layer, so content keeps label colors |
| Permission status | `PermissionStatusLabel` (app target, its strings live there) | Privacy, General Accessibility row, onboarding | Green check "Allowed" / secondary cross "Not Allowed" |

Single-use looks stay in their screen: the search suggestion list (glass rect, selected-row highlight), the Board swatch picker, the Sequence row marker, the Sequence empty state (one secondary callout line), the Card header band and the text editor border.

### Window and popover metrics

Metrics of everything other than the Shelf. Every value lives in `DesignTokens`.

| Surface | Metric |
|---|---|
| Settings | 500 pt wide (`settingsWidth`); each pane is as tall as its grouped `Form`. Ignored Apps list 120 pt tall, rows with 16 pt app icons, flush inside its section like System Settings lists |
| About | 64 pt app icon; Acknowledgements sheet 460 × 420 pt |
| Onboarding | 480 × 480 pt on every step, 20 pt padding, 96 pt hero, message up to 400 pt wide |
| Sequence panel | 280 pt wide, 18 pt radius, glass as a background layer (like the Shelf, so rows keep label colors); 44 pt rows, up to 6 before it scrolls, 8 pt list inset with a 10 pt concentric radius |
| Quick Look popover | Sized to the content ([§5 Quick Look](#quick-look)): text 640 pt (code 760) wide, link 480, color 360, several files 420, unknown 320 × 220. At most 880 × 680 pt (`previewWidth` × `previewHeight`), scaled down with its aspect ratio kept to fit the space above the Shelf on the Shelf's screen (visible frame above the Shelf's glass, minus a 16 pt margin, `previewScreenMargin`) and the screen width minus 16 pt on each side. Image Cards fit the popover to the image's aspect ratio inside that box, at least 240 pt on each side (`previewMinimumSide`) but never larger than the box. Computed by `PreviewSizeCalculator` |
| Rename popover | 220 pt text field, system padding |
| Filters popover | 260 × 380 pt |
| Edit sheets | 20 pt padding (`sheetPadding`) on every sheet. Link and color sheets are 420 pt and the Board sheet 400 pt wide grouped forms; text editor 480 × 320 pt, never taller than the Shelf, 6 pt text-area radius |

---

## 12. Open questions

These still need a test on real hardware or the task that settles them. Choices that follow a working default are in [roadmap.md](roadmap.md#working-defaults-for-open-todos); features left for later are in [roadmap.md](roadmap.md#later-not-scheduled).

> TODO: Quick Look as popover vs system `QLPreviewPanel` (§5).
> TODO: whether reading `changeCount` alone triggers the pasteboard prompt on macOS 26, and whether the `Privacy_Pasteboard` anchor opens the Paste from Other Apps list (§9).
> TODO: compact-mode threshold and Card sizes: tune on 13" and 27"+ displays ([WD-15](roadmap.md#working-defaults-for-open-todos) until then).
> TODO: maximum Board count in the switcher before it scrolls or collapses into a menu.
> TODO: behavior and visuals on macOS releases after 26 (Liquid Glass changes not yet reviewed).
> TODO: the dark Card fill #2A2A2C and the Card shadows over live Liquid Glass: whether Cards read as raised in both modes (offscreen renders draw a material stand-in).
> TODO: the paste ghost (`NSGlassEffectView`) on real glass, and the strip snapshot time in the running app, before `pasteAfterimageIsEnabled` is turned on (§2 Paste).
> TODO: whether macOS 27 hides menu item images (Board dots and app icons in Add to Board, a Board's context menu and Open With).
> TODO: frame rate of the open cascade on real hardware, at 1920 pt and on a 13" display.
