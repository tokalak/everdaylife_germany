#!/usr/bin/env bash
#
# Local CI pipeline (P0-02). Run on demand instead of GitHub Actions:
#
#   ios/scripts/ci.sh
#
# Mirrors what a CI runner would do: regenerate the Xcode project, pick an
# available iPhone simulator, then build + run the test suite. No code signing,
# no Apple Developer account, no cloud runner required.
#
# Requirements: Xcode, xcodegen. Optional: xcbeautify (prettier output).
#   brew install xcodegen xcbeautify

set -euo pipefail

# Resolve repo's ios/ dir regardless of where the script is invoked from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$IOS_DIR"

PROJECT="Alltag.xcodeproj"
SCHEME="Alltag"

echo "==> Toolchain"
xcodebuild -version
swift --version

echo "==> Generate Xcode project"
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "error: xcodegen not found. Install with: brew install xcodegen" >&2
  exit 1
fi
xcodegen generate

echo "==> Pick an iOS Simulator"
# Choose the newest available iPhone simulator so we don't hard-code a device
# name that may differ across machines / Xcode versions.
UDID=$(xcrun simctl list devices available --json \
  | python3 -c "import json,sys; ds=json.load(sys.stdin)['devices']; \
    cands=[d for rt in ds for d in ds[rt] if d['isAvailable'] and 'iPhone' in d['name']]; \
    print(cands[-1]['udid'] if cands else '')")
if [ -z "$UDID" ]; then
  echo "error: no iPhone simulator available" >&2
  exit 1
fi
echo "Selected simulator $UDID"

echo "==> Build & test"
if command -v xcbeautify >/dev/null 2>&1; then
  set -o pipefail
  NSUnbufferedIO=YES xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$UDID" \
    CODE_SIGNING_ALLOWED=NO \
    | xcbeautify
else
  echo "(xcbeautify not found — raw xcodebuild output; brew install xcbeautify for cleaner logs)"
  xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$UDID" \
    CODE_SIGNING_ALLOWED=NO
fi

echo "==> CI passed"
