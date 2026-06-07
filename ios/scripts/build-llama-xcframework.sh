#!/usr/bin/env bash
#
# Build the llama.cpp Metal runtime as an xcframework and vendor it into the
# project, so device builds run the REAL on-device model instead of the
# development stub.
#
#   ios/scripts/build-llama-xcframework.sh                 # build from $LLAMA_CPP_REF (default: master)
#   LLAMA_CPP_REF=b6000 ios/scripts/build-llama-xcframework.sh   # pin a tag/commit
#
# This is the device-only step the rest of Core/LLM was designed around
# (LlamaCppEngine's "integration seam"): the ~3 GB model and a Metal binary
# framework can't live in CI/the Simulator, so the framework is gitignored
# (see .gitignore) and reproduced on demand from upstream, exactly like the
# weights are by scripts/fetch-model.sh.
#
# What it does:
#   1. Clones (or updates) ggml-org/llama.cpp into .llama-build/ at $LLAMA_CPP_REF.
#   2. Runs upstream's ./build-xcframework.sh (Metal backend, all Apple slices).
#   3. Installs the result to Vendor/llama.xcframework.
#
# After this, generate the project WITH the runtime enabled and deploy:
#   ALLTAG_LLAMA_RUNTIME=true xcodegen generate      # or just: scripts/deploy-device.sh
# project.yml only references the framework when ALLTAG_LLAMA_RUNTIME is truthy,
# so CI/Simulator builds (which never run this script) keep building the stub.
#
# REPRODUCIBILITY: master moves fast. After your first successful build, re-run
# with LLAMA_CPP_REF set to the commit printed below to pin the exact runtime.
# The Swift engine targets the modern vocab-based llama.cpp C API (the
# llama_model_load_from_file / llama_sampler_* / llama_*_vocab_* family, ~2025+).
#
# Requirements: git, Xcode (xcodebuild), CMake. Disk: a few GB for the checkout.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

REPO="${LLAMA_CPP_REPO:-https://github.com/ggml-org/llama.cpp.git}"
REF="${LLAMA_CPP_REF:-master}"
WORK="${LLAMA_CPP_BUILD_DIR:-$IOS_DIR/.llama-build}"
VENDOR_DIR="$IOS_DIR/Vendor"
DEST="$VENDOR_DIR/llama.xcframework"

echo "==> llama.cpp source ($REF)"
if [ ! -d "$WORK/.git" ]; then
  git clone "$REPO" "$WORK"
fi
cd "$WORK"
git fetch --tags --force origin
git checkout "$REF"
# Fast-forward when on a branch (a detached tag/commit has no upstream to pull).
git pull --ff-only 2>/dev/null || true
RESOLVED="$(git rev-parse HEAD)"
echo "    at $RESOLVED"

if [ ! -x "./build-xcframework.sh" ]; then
  echo "error: ./build-xcframework.sh not found in llama.cpp at $REF." >&2
  echo "       It exists on recent revisions; pick a newer LLAMA_CPP_REF." >&2
  exit 1
fi

# Upstream's build-xcframework.sh builds EVERY Apple platform (iOS, macOS,
# visionOS, tvOS — device + simulator each), ~8 full ggml+llama compiles. The
# app is iPhone-only (project.yml TARGETED_DEVICE_FAMILY=1), so by default we
# patch the freshly-checked-out script down to just the two iOS slices, cutting
# build time roughly 4x. Set LLAMA_APPLE_PLATFORMS=all to build everything.
# The patch keys on `build-<platform>` tokens, which appear only at the per-
# platform build/assembly CALL sites — never in the function bodies (which use
# the $build_dir variable) — so it's robust across upstream revisions.
PLATFORMS="${LLAMA_APPLE_PLATFORMS:-ios}"
# Always start from the pristine upstream script so a re-run doesn't re-patch an
# already-patched copy.
git checkout -- build-xcframework.sh 2>/dev/null || true
if [ "$PLATFORMS" = "ios" ]; then
  echo "==> Trimming build to iOS-only (set LLAMA_APPLE_PLATFORMS=all to override)"
  # 1) Drop the non-iOS cmake build blocks. iOS sim+device build first; macOS is
  #    the first non-iOS block and all of them precede the assembly phase.
  perl -0pi -e 's/echo "Building for macOS\.\.\.".*?(?=echo "Setting up framework structures)//s' build-xcframework.sh
  # 2) Drop every remaining non-iOS reference (rm -rf, setup/combine call sites,
  #    and the create-xcframework -framework/-debug-symbols pairs).
  perl -ni -e 'print unless m{build-(macos|visionos|tvos)}' build-xcframework.sh
fi

# Reclaim any stale per-platform dirs from a previous/interrupted run.
rm -rf build-macos build-visionos build-visionos-sim build-tvos-sim build-tvos-device

echo "==> Build llama.xcframework (Metal; this takes a while)"
./build-xcframework.sh

BUILT="$WORK/build-apple/llama.xcframework"
if [ ! -d "$BUILT" ]; then
  echo "error: expected $BUILT after build-xcframework.sh; not found." >&2
  exit 1
fi

echo "==> Install -> $DEST"
mkdir -p "$VENDOR_DIR"
rm -rf "$DEST"
cp -R "$BUILT" "$DEST"

cat <<EOF
==> Done. Vendored llama.xcframework from llama.cpp @ ${RESOLVED}

Next:
  • Build & run on a connected iPhone (auto-enables the runtime):
      ios/scripts/deploy-device.sh
  • Or regenerate the project manually with the runtime enabled:
      ALLTAG_LLAMA_RUNTIME=true xcodegen generate

To pin this exact runtime for reproducible builds:
      LLAMA_CPP_REF=${RESOLVED} ios/scripts/build-llama-xcframework.sh
EOF
