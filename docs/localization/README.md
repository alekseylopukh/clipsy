# Localization

Clipsy ships in English (the source language), Russian, Ukrainian, Polish, German and French. Every string lives in [App/Localizable.xcstrings](../../App/Localizable.xcstrings). Strings from `Packages/ClipsyKit` are not extracted by Xcode, so add them to the catalog by hand.

Each language has a glossary: [ru](ru.md), [uk](uk.md), [pl](pl.md), [de](de.md), [fr](fr.md). It fixes the product terms (Shelf, Card, Board, Sequence, History), the macOS terms and the punctuation, so new strings read like the existing ones.

A change that adds or edits a user-facing string translates it into every language in the same PR:
- Follow the glossary. Change a term there first, then everywhere it is used.
- Use the exact macOS names for System Settings panes. They are in the system's `.loctable` files, for example `/System/Library/ExtensionKit/Extensions/SecurityPrivacyExtension.appex`.
- Give strings with a count plural forms for each language, even when the English has none.
- Keep buttons and menu items short. Check new text in the running app with `-AppleLanguages "(de)"`.
