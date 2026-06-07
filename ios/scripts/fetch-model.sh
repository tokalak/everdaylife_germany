#!/usr/bin/env bash
#
# Fetch the on-device LLM weights for local development.
#
#   ios/scripts/fetch-model.sh            # primary (Q4_K_XL, ~2.62 GB)
#   ios/scripts/fetch-model.sh --fallback # low-memory fallback (Q2_K_XL, ~2.19 GB)
#   ios/scripts/fetch-model.sh --all      # both deliverable GGUF quants
#
# The weights are multi-GB and are NOT committed to git (see .gitignore). This
# script reproduces them on demand from a single source of truth (X-06):
# Alltag/Core/LLM/LLMModel.swift. Both the download URLs and the exact expected
# byte counts (ModelQuant.approximateByteCount — the same values the app's
# ModelVerifier enforces) are read from that file, matched by quant suffix, so
# there is deliberately no second copy here to drift.
#
# Files land in $ALLTAG_MODELS_DIR (default: ios/Models), the same layout the
# app uses at runtime under Application Support/Alltag/Models. The default-quant
# file in ios/Models is ALSO bundled into the app at build time (project.yml's
# "Bundle on-device model" script), so physical-device builds ship ready with no
# first-run download. After a download the script verifies the exact byte count
# and prints the SHA-256 so it can be pinned in LLMModelSpec.sha256 at release
# time.
#
# Requirements: curl, shasum (both ship with macOS).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CATALOG="$IOS_DIR/Alltag/Core/LLM/LLMModel.swift"
MODELS_DIR="${ALLTAG_MODELS_DIR:-$IOS_DIR/Models}"

# Deliverable GGUF download URLs, in catalog order: [0]=primary, [1]=fallback.
# (The .litertlm candidate-B URL is excluded by the .gguf match.) Read with a
# while-loop rather than mapfile so this works on stock macOS bash 3.2.
URLS=()
while IFS= read -r line; do
  URLS+=("$line")
done < <(grep -oE 'https://[^"]+\.gguf' "$CATALOG")
if [ "${#URLS[@]}" -lt 2 ]; then
  echo "error: expected 2 GGUF URLs in $CATALOG, found ${#URLS[@]}" >&2
  exit 1
fi

# quant-suffix -> exact byte count, joined from ModelQuant's `fileSuffix` and
# `approximateByteCount` switches. The >=7-digit guard ignores the short
# `minimumDeviceMemory` literals (6, 4, 1_024) that share the `case .x:` shape.
SIZE_MAP="$(awk '
  $1=="case" && $3 ~ /^"UD-/   { c=$2; gsub(/[.:]/,"",c); s=$3; gsub(/"/,"",s); suf[c]=s }
  $1=="case" && $3 ~ /^[0-9]/  { c=$2; gsub(/[.:]/,"",c); b=$3; gsub(/_/,"",b);
                                 if (length(b) >= 7) byt[c]=b }
  END { for (c in suf) if (c in byt) print suf[c], byt[c] }
' "$CATALOG")"

# Echo the exact expected byte count for a model filename (empty if unknown).
expected_bytes_for() {
  local name="$1" suf bytes
  while read -r suf bytes; do
    [ -n "$suf" ] || continue
    case "$name" in *"$suf"*) echo "$bytes"; return 0 ;; esac
  done <<EOF
$SIZE_MAP
EOF
}

case "${1:-}" in
  --all)      WANT=("${URLS[0]}" "${URLS[1]}") ;;
  --fallback) WANT=("${URLS[1]}") ;;
  ""|--primary) WANT=("${URLS[0]}") ;;
  *) echo "usage: $0 [--primary|--fallback|--all]" >&2; exit 2 ;;
esac

mkdir -p "$MODELS_DIR"

for url in "${WANT[@]}"; do
  name="${url##*/}"
  dest="$MODELS_DIR/$name"
  expected="$(expected_bytes_for "$name")"
  if [ -z "$expected" ]; then
    echo "error: no pinned byte count for $name in $CATALOG" >&2
    exit 1
  fi

  if [ -f "$dest" ] && [ "$(wc -c <"$dest" | tr -d ' ')" -eq "$expected" ]; then
    echo "==> $name already present and complete ($expected bytes) — skipping"
  else
    echo "==> Downloading $name ($expected bytes) to $dest"
    curl -fL --retry 3 --retry-delay 2 -C - -o "$dest" "$url"
  fi

  actual="$(wc -c <"$dest" | tr -d ' ')"
  if [ "$actual" -ne "$expected" ]; then
    echo "error: $name size mismatch — got $actual, expected $expected" >&2
    exit 1
  fi
  echo "    bytes:  $actual (matches pinned expectedByteCount)"
  echo "    sha256: $(shasum -a 256 "$dest" | awk '{print $1}')"
done

echo "==> Done. Models in $MODELS_DIR"
