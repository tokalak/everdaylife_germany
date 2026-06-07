#!/usr/bin/env bash
#
# Build, install, and launch Alltag on a physically connected iPhone (USB).
#
#   ios/scripts/deploy-device.sh                 # auto-pick the connected device
#   ios/scripts/deploy-device.sh <device-udid>   # target a specific device
#   DEVICE_ID=<udid> ios/scripts/deploy-device.sh # same, via env
#
# Unlike scripts/ci.sh (which targets the Simulator and needs no signing), a
# physical device REQUIRES a code signature: iOS refuses to launch any unsigned
# app on real hardware. This script supplies the signing settings as xcodebuild
# command-line overrides, so project.yml stays simulator/CI-friendly (signing
# off, empty team) and nothing in the repo needs to change.
#
# Prerequisites (one-time):
#   - Apple ID signed into Xcode (Settings ▸ Accounts) that owns the team below.
#   - On the device, after the first install: Settings ▸ General ▸ VPN & Device
#     Management ▸ trust the "Apple Development: <your-account>" profile.
#   - Device unlocked, connected via USB, and "Trust This Computer" accepted.
#
# A free Apple ID signature expires after ~7 days; just re-run this to refresh.
#
# Requirements: Xcode, xcodegen.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$IOS_DIR"

PROJECT="Alltag.xcodeproj"
SCHEME="Alltag"
CONFIGURATION="Debug"
BUNDLE_ID="de.everydaygermany.app"
DERIVED_DATA="build"

# Signing identity. Override DEVELOPMENT_TEAM in the environment to use another
# team; defaults to the project's Apple Development account (QL567J384H).
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-QL567J384H}"

# Device UDID: first positional arg, then $DEVICE_ID, else auto-detect below.
DEVICE_ID="${1:-${DEVICE_ID:-}}"

echo "==> Toolchain"
xcodebuild -version

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "error: xcodegen not found. Install with: brew install xcodegen" >&2
  exit 1
fi

echo "==> Generate Xcode project"
# Link the real llama.cpp/Metal runtime when its framework has been vendored
# (scripts/build-llama-xcframework.sh). Without it, the build falls back to the
# development stub. project.yml only references the framework when this is set.
if [ -d "$IOS_DIR/Vendor/llama.xcframework" ]; then
  export ALLTAG_LLAMA_RUNTIME=true
  echo "    on-device llama.cpp runtime: ENABLED (Vendor/llama.xcframework present)"
else
  echo "    on-device llama.cpp runtime: stub (run scripts/build-llama-xcframework.sh to enable)"
fi
xcodegen generate

# Auto-detect a connected device when none was given. devicectl lists physical
# devices; "connected" is reachable, "unavailable" is paired-but-offline. The
# only UUID on a device line is its identifier, so we pull that out.
if [[ -z "$DEVICE_ID" ]]; then
  echo "==> Detect connected device"
  UUID_RE='[0-9A-Fa-f]{8}-([0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}'
  # newline-separated UDIDs of reachable devices (stock bash 3.2: no mapfile)
  CONNECTED="$(xcrun devicectl list devices 2>/dev/null \
    | grep -iw connected \
    | grep -oE "$UUID_RE" || true)"
  COUNT="$(printf '%s' "$CONNECTED" | grep -c . || true)"

  if [[ "$COUNT" -eq 0 ]]; then
    echo "error: no connected device found. Plug in an iPhone over USB, unlock" >&2
    echo "       it, and accept 'Trust This Computer'. Current devices:" >&2
    xcrun devicectl list devices >&2 || true
    exit 1
  fi
  if [[ "$COUNT" -gt 1 ]]; then
    echo "error: multiple connected devices. Pass one explicitly, e.g.:" >&2
    echo "       ios/scripts/deploy-device.sh $(printf '%s' "$CONNECTED" | head -n1)" >&2
    printf '       candidates:\n' >&2
    printf '         %s\n' $CONNECTED >&2
    exit 1
  fi
  DEVICE_ID="$CONNECTED"
fi

echo "==> Target device: $DEVICE_ID"
xcrun devicectl device info details --device "$DEVICE_ID" 2>/dev/null \
  | grep -iE "marketingName|osVersionNumber" || true

# Build a generic signed device build (no per-device destination needed). On the
# first run, -allowProvisioningUpdates registers the device and mints the team
# provisioning profile; this requires the Xcode Apple ID session to be valid.
echo "==> Build ($CONFIGURATION, signed for team $DEVELOPMENT_TEAM)"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED_DATA" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  CODE_SIGN_STYLE=Automatic \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=YES \
  build

APP_PATH="$DERIVED_DATA/Build/Products/$CONFIGURATION-iphoneos/$SCHEME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "error: built app not found at $APP_PATH" >&2
  exit 1
fi

echo "==> Install $APP_PATH"
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

echo "==> Launch $BUNDLE_ID"
if ! xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID"; then
  echo "" >&2
  echo "Launch failed. If this is the first install with this signature, trust" >&2
  echo "the developer profile on the device, then re-run:" >&2
  echo "  Settings ▸ General ▸ VPN & Device Management ▸ Apple Development ▸ Trust" >&2
  exit 1
fi

echo "==> Done — Alltag is running on the device."
