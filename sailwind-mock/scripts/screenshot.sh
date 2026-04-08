#!/bin/bash
# Takes screenshots of all HTML files in the html/ directory
# Output goes to screenshots/ at the project root

set -e

HTML_DIR="html"
SCREENSHOTS_DIR="screenshots"

mkdir -p "$SCREENSHOTS_DIR"

for file in "$HTML_DIR"/*.html; do
  [ -e "$file" ] || continue
  basename=$(basename "$file" .html)
  uvx shot-scraper shot "$file" -o "$SCREENSHOTS_DIR/$basename.png" --width 1600 --height 1000 --retina
  echo "Captured: $SCREENSHOTS_DIR/$basename.png"
done
