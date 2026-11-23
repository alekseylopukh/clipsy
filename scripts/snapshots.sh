#!/bin/bash
# usage: scripts/snapshots.sh [dir]   renders the Shelf, Settings and other windows offscreen to PNGs (default .build/snapshots)
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
mkdir -p "${1:-.build/snapshots}"
out=$(cd "${1:-.build/snapshots}" && pwd)
CLIPSY_SNAPSHOTS="$out" swift test --package-path Packages/ClipsyKit --disable-xctest --quiet --filter SnapshotTests
ls "$out"/*.png
