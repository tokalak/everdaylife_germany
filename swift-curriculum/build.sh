#!/usr/bin/env bash
# Build the book PDF from the chapter markdown files.
#   ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

OUT="Swift-for-Backend-Engineers.pdf"
HTML="build/book.html"
mkdir -p build

# Chapter order. Front matter first, then parts in order.
CHAPTERS=(
  chapters/00-preface.md
  chapters/part1.md
  chapters/01-landscape.md
  chapters/02-swift-basics.md
  chapters/03-types.md
  chapters/04-functions-closures.md
  chapters/05-memory-concurrency.md
  chapters/part2.md
  chapters/06-swiftui-model.md
  chapters/07-layout.md
  chapters/08-screens.md
  chapters/09-architecture.md
  chapters/10-persistence.md
  chapters/part3.md
  chapters/11-toolchain.md
  chapters/12-testing.md
  chapters/13-signing.md
  chapters/14-distribution.md
  chapters/15-production.md
  chapters/partA.md
  chapters/A1-cheatsheet.md
  chapters/A2-gotchas.md
  chapters/A3-studyplan.md
  chapters/A4-resources.md
)

echo "==> pandoc: markdown -> html"
pandoc metadata.yaml "${CHAPTERS[@]}" \
  --from=markdown+smart+pipe_tables+backtick_code_blocks+fenced_code_attributes \
  --to=html5 \
  --standalone \
  --template=template.html \
  --toc --toc-depth=2 \
  --syntax-highlighting=tango \
  --section-divs \
  -o "$HTML"

echo "==> weasyprint: html -> pdf"
weasyprint "$HTML" "$OUT" -s book.css 2>/dev/null

echo "==> done: $OUT ($(du -h "$OUT" | cut -f1))"
