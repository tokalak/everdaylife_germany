#!/usr/bin/env bash
#
# Fetch the on-device LLM weights for local development.
#
#   ios/scripts/fetch-model.sh            # primary (Q4_K_XL, ~2.62 GB)
#   ios/scripts/fetch-model.sh --fallback # low-memory fallback (Q2_K_XL, ~2.19 GB)
#   ios/scripts/fetch-model.sh --all      # both deliverable GGUF quants
#
# The weights are multi-GB and are NOT committed to git (see .gitignore). This
# script reproduces them on demand: the download URLs are read straight out of
# Alltag/Core/LLM/LLMModel.swift, which is the single versioned source of truth
# for model URLs/sizes (X-06) — there is deliberately no second copy here.
#
# Files land in $ALLTAG_MODELS_DIR (default: ios/Models), the same layout the
# app uses at runtime under Application Support/Alltag/Models. After a download
# the script verifies the byte count against the server and prints the SHA-256
# so it can be pinned in LLMModelSpec.sha256 at release time.
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

  # Authoritative size = server Content-Length (follows the HF CDN redirect).
  expected="$(curl -fsIL "$url" | awk 'BEGIN{IGNORECASE=1} /^content-length:/{n=$2} END{gsub(/\r/,"",n); print n}')"

  if [ -f "$dest" ] && [ -n "$expected" ] && [ "$(wc -c <"$dest")" -eq "$expected" ]; then
    echo "==> $name already present and complete (${expected} bytes) — skipping"
  else
    echo "==> Downloading $name (${expected:-unknown} bytes) to $dest"
    curl -fL --retry 3 --retry-delay 2 -C - -o "$dest" "$url"
  fi

  actual="$(wc -c <"$dest")"
  if [ -n "$expected" ] && [ "$actual" -ne "$expected" ]; then
    echo "error: $name size mismatch — got $actual, expected $expected" >&2
    exit 1
  fi
  echo "    bytes:  $actual"
  echo "    sha256: $(shasum -a 256 "$dest" | awk '{print $1}')"
done

echo "==> Done. Models in $MODELS_DIR"
