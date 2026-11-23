#!/bin/bash
# usage: scripts/readme-screenshots.sh   renders the README screenshots and app icon into docs/images (needs ImageMagick)
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
command -v magick >/dev/null || { echo "readme-screenshots: ImageMagick is not installed (brew install imagemagick)" >&2; exit 1; }
ictool="$(xcode-select -p)/../Applications/Icon Composer.app/Contents/Executables/ictool"
[ -x "$ictool" ] || { echo "readme-screenshots: ictool not found; install Xcode 26 or later" >&2; exit 1; }

raw=$(mktemp -d)
trap 'rm -rf "$raw"' EXIT
CLIPSY_SNAPSHOTS="$raw" CLIPSY_MARKETING=1 swift test --package-path Packages/ClipsyKit --disable-xctest --quiet \
  --filter MarketingSnapshotTests

out=docs/images
mkdir -p "$out"
for png in "$raw"/*.png; do
  name=$(basename "$png")
  case "$name" in
    shelf-*) width=1280 ;;
    search-* | board-*) width=1200 ;;
    sequence-*) width=1000 ;;
    *) width=900 ;;
  esac
  magick "$png" -resize "${width}x" -strip -define png:compression-level=9 "$out/$name"
done
for pair in Default:light Dark:dark; do
  "$ictool" App/AppIcon.icon --export-image --output-file "$raw/icon.png" --platform macOS \
    --rendition "${pair%:*}" --width 128 --height 128 --scale 2 >/dev/null
  magick "$raw/icon.png" -strip -define png:compression-level=9 "$out/icon-${pair#*:}.png"
done
ls -l "$out"/*.png
