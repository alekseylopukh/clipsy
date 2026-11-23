#!/bin/bash
# usage: scripts/build.sh [build|test]   build the app, or run the ClipsyKit tests
# CLIPSY_SIGN_IDENTITY: identity to re-sign the Debug app with ("-" keeps the ad-hoc signature).
# Unset: the first "Apple Development" identity in the keychain, if any, so macOS keeps
# Accessibility permission across rebuilds; an ad-hoc signature changes on every build.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

sign_app() {
  local app=.build/DerivedData/Build/Products/Debug/Clipsy.app
  local identity=${CLIPSY_SIGN_IDENTITY-}
  if [[ -z $identity ]]; then
    identity=$(security find-identity -v -p codesigning 2>/dev/null \
      | awk -F'"' '/Apple Development/ { print $2; exit }')
  fi
  [[ -z $identity || $identity == "-" ]] && return 0
  local entitlements
  entitlements=$(mktemp)
  # shellcheck disable=SC2064 # expand now: the EXIT trap runs after the local is gone
  trap "rm -f '$entitlements'" RETURN EXIT
  codesign -d --entitlements - --xml "$app" >"$entitlements" 2>/dev/null || true
  local args=(--force --deep --options runtime --sign "$identity")
  [[ -s $entitlements ]] && args+=(--entitlements "$entitlements")
  codesign "${args[@]}" "$app"
  echo "signed with $identity"
}

case "${1:-build}" in
  build)
    xcodebuild -project Clipsy.xcodeproj -scheme Clipsy -destination "platform=macOS,arch=$(uname -m)" \
      -derivedDataPath .build/DerivedData -quiet build
    sign_app ;;
  test)
    swift test --package-path Packages/ClipsyKit --disable-xctest --quiet ;;
  *)
    echo "usage: scripts/build.sh [build|test]" >&2; exit 64 ;;
esac
