# Contributing to Clipsy

Thanks for helping. This file covers how work moves from an idea to a release.

## Before you start

- Bugs and feature ideas start as an [issue](https://github.com/alekseylopukh/clipsy/issues/new/choose). For anything bigger than a small fix, wait for a maintainer to agree on the approach before writing code.
- Clipsy is an independent project. Do not contribute code, images, sounds or text copied from Paste or any other proprietary app. See the IP rules in [CLAUDE.md](CLAUDE.md#ip-rules).
- Contributions are licensed under [GPL-3.0](LICENSE). Code taken from other projects must come from GPL-3.0-compatible licenses (MIT, BSD, Apache-2.0, GPL-3.0) and keep its copyright notice.

## AI-assisted contributions

AI tools are welcome. You stay responsible for what you submit.

- Say in the pull request description which AI tools you used and for what, for example "Claude Code wrote the first draft of the search parser". Pull requests that hide AI use may be closed.
- You must understand every line you submit and be able to explain it in review. You must have built and tested it yourself.
- Do not submit large generated changes nobody asked for. Open an issue first.
- Instructions for AI coding agents live in [CLAUDE.md](CLAUDE.md).

## Setup

```bash
brew install swiftformat swiftlint
git config core.hooksPath .githooks
```

The git pre-commit hook lints staged Swift files. CI runs the same checks on every pull request. CI pins the tool versions in [.github/workflows/lint.yml](.github/workflows/lint.yml); if your local result differs, CI is the reference.

## Code quality

- The rules and the review checklist are in [.claude/rules/code-rules.md](.claude/rules/code-rules.md). Reviews cite rule IDs such as `R2.3`.
- Before opening a pull request, run `scripts/lint.sh`, build the app and run the tests.
- Claude Code users get the same rules automatically through [CLAUDE.md](CLAUDE.md). Claude Code sessions also run a hook ([.claude/settings.json](.claude/settings.json)) that blocks commits until the `pre-commit-review` skill approves the staged tree. The plain git hook only lints.

## Workflow: GitHub Flow

`main` is always releasable. All work happens on short-lived branches and lands through a pull request.

1. Branch off `main` and name the branch `<type>/<short-description>`, for example `feat/search-filters` or `fix/paste-into-terminal`.
2. Keep each pull request focused on one change.
3. Title the pull request as a [Conventional Commit](https://www.conventionalcommits.org/en/v1.0.0/), for example `feat: add type filters to search`. Pull requests are squash-merged and the title becomes the commit message on `main`.
4. Once the pull request is merged, its branch is deleted automatically.

Commit types: `feat`, `fix`, `perf`, `refactor`, `docs`, `test`, `build`, `ci`, `chore`. Mark breaking changes with `!`, for example `feat!: ...`.

## Releases

- Versions follow [Semantic Versioning](https://semver.org). Releases are tagged `vMAJOR.MINOR.PATCH` on `main`, for example `v0.1.0`.
- Only maintainers create tags. Each tag gets a GitHub Release with a signed and notarized build attached.
- Release notes are generated from merged pull requests and grouped by label (see [.github/release.yml](.github/release.yml)): `enhancement` goes under New features, `bug` under Bug fixes, `breaking` under Breaking changes, and everything else under Other changes. `skip-changelog` leaves a pull request out. Label your pull request so it lands in the right section.
- A hotfix for an old version gets a `release/vX.Y` branch cut from that tag. This is needed only when `main` has moved on.
- Pushing the tag runs [.github/workflows/release.yml](.github/workflows/release.yml). It imports the certificate into a temporary keychain, runs `scripts/release/release.sh` with the tag's version and the run number as the build number, and creates the GitHub Release with the DMG, the zip and `appcast.xml`. The steps are in [architecture §6.4](docs/architecture.md#64-release-pipeline).

### Release checklist

A maintainer works through this list for every release. For the first release, skip the key match in step 1 and the update test in step 8: there is no earlier release, and `appcast.sh` starts a new feed.

1. All [release secrets](#release-secrets) are set, and `SPARKLE_PUBLIC_ED_KEY` matches the private key that signed earlier releases. A new key pair breaks updates for everyone on an older version.
2. `main` is green in CI, and the merged pull requests since the last tag carry release-note labels. CI on pull requests only lints, so also run the **Build** workflow (Actions › Build › Run workflow) on the release commit: it builds and tests with the same Xcode as the release.
3. `scripts/release/release.sh --dry-run <version> 1` passes locally.
4. The manual checklist in [architecture §6.2](docs/architecture.md#62-testing) passes on a Debug build of the release commit (an ad-hoc signed Release build does not launch, see [architecture §6.4](docs/architecture.md#64-release-pipeline)).
5. Docs match the release: the README feature list, [product.md](docs/product.md) and the open questions in each doc under `docs/`.
6. Tag `vX.Y.Z` on `main` and push the tag. Wait for the release workflow to finish.
7. Check the published release: the DMG opens and Clipsy launches from Applications with only the usual "downloaded from the Internet" confirmation, no "unidentified developer" block (`spctl --assess --type execute -v /Applications/Clipsy.app` says "Notarized Developer ID"), and the release lists the DMG, the zip and `appcast.xml`.
8. Update test: an older installed version finds the new one with "Check for Updates…" in Settings › About, installs it and relaunches.
9. Edit the generated release notes if needed.

### Release secrets

The workflow stops before building and names every repository secret that is missing. Add them under Settings › Secrets and variables › Actions.

| Secret | Value |
|---|---|
| `DEVELOPER_ID_CERTIFICATE` | Developer ID Application certificate with its private key, exported as `.p12` and base64-encoded (`base64 -i cert.p12`). The signing identity and team ID are read from it. |
| `DEVELOPER_ID_CERTIFICATE_PASSWORD` | Password of that `.p12` |
| `NOTARY_KEY` | Contents of the App Store Connect API key file `AuthKey_XXXXXXXXXX.p8` (Developer role or higher) |
| `NOTARY_KEY_ID` | Key ID of that API key |
| `NOTARY_ISSUER_ID` | Issuer ID of the App Store Connect team |
| `SPARKLE_PUBLIC_ED_KEY` | Sparkle EdDSA public key printed by Sparkle's `generate_keys` |
| `SPARKLE_PRIVATE_ED_KEY` | Sparkle EdDSA private key exported with `generate_keys -x` |
