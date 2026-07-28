#!/bin/bash
# Takes screenshots of all HTML files in the html/ directory
# Output goes to screenshots/ at the project root

set -e

HTML_DIR="html"
SCREENSHOTS_DIR="screenshots"

mkdir -p "$SCREENSHOTS_DIR"

# Determine how to run shot-scraper:
# Prefer persistent install (faster, no Chromium re-download) over uvx (ephemeral)
if command -v shot-scraper &>/dev/null; then
  SHOT_CMD="shot-scraper"
elif command -v uvx &>/dev/null; then
  SHOT_CMD="uvx shot-scraper@1.5"
else
  echo "Error: Neither shot-scraper nor uvx found."
  echo "Install with: uv tool install shot-scraper"
  echo "Or install uv: brew install uv"
  exit 1
fi

echo "Using: $SHOT_CMD"

for file in "$HTML_DIR"/*.html; do
  [ -e "$file" ] || continue
  basename=$(basename "$file" .html)
  $SHOT_CMD shot "$file" -o "$SCREENSHOTS_DIR/$basename.png" --width 1600 --height 1000 --retina
  echo "Captured: $SCREENSHOTS_DIR/$basename.png"
done

# Check for stale Playwright Chromium caches
PW_CACHE="$HOME/Library/Caches/ms-playwright"
if [ -d "$PW_CACHE" ]; then
  CHROMIUM_COUNT=$(find "$PW_CACHE" -maxdepth 1 -type d -name 'chromium-*' | wc -l | tr -d ' ')
  if [ "$CHROMIUM_COUNT" -gt 1 ]; then
    CACHE_SIZE=$(du -sh "$PW_CACHE" 2>/dev/null | cut -f1)
    echo ""
    echo "⚠️  Found $CHROMIUM_COUNT cached Chromium versions ($CACHE_SIZE total) in:"
    echo "   $PW_CACHE"
    echo ""
    echo "   To reclaim disk space, run:"
    echo "   rm -rf $PW_CACHE"
    echo "   (Playwright will re-download only what it needs on next use)"
  fi
fi
