#!/bin/bash
# usage: scripts/perf.sh   seeds 100k synthetic cards and prints the store timings (compare with architecture §6.2)
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
CLIPSY_PERF=1 swift test --package-path Packages/ClipsyKit --quiet --filter PerformanceTests
