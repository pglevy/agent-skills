#!/bin/bash
# Validates Font Awesome icon usage in HTML files against the free CDN CSS.
# Exits 0 if all icons are valid, 1 if any are invalid.

set -e

FA_CSS_URL="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.1/css/all.min.css"
HTML_DIR="${1:-html}"

# Non-icon fa-* classes to skip during validation
SKIP_PATTERN='^fa-(solid|regular|brands|classic|sharp|thin|light|duotone|[0-9]+x|2xs|xs|sm|lg|xl|2xl|fw|ul|li|border|pull-left|pull-right|pull-start|pull-end|beat|bounce|fade|beat-fade|flip|shake|spin|spin-reverse|spin-pulse|pulse|stack|stack-1x|stack-2x|inverse|rotate-90|rotate-180|rotate-270|rotate-by|flip-horizontal|flip-vertical|flip-both|width-auto|width-fixed)$'

if [ ! -d "$HTML_DIR" ]; then
  echo "No $HTML_DIR directory found."
  exit 0
fi

html_files=("$HTML_DIR"/*.html)
if [ ! -e "${html_files[0]}" ]; then
  echo "No HTML files found in $HTML_DIR."
  exit 0
fi

# Fetch valid icon names from CDN
valid_icons=$(curl -sL "$FA_CSS_URL" | grep -oE '\.fa-[a-z0-9-]+\{--fa:' | sed 's/{--fa://' | sed 's/^\.//')

errors=0

for file in "${html_files[@]}"; do
  # Extract all fa-* classes from HTML, one per line
  used_icons=$(grep -oE 'fa-[a-z0-9-]+' "$file" | sort -u)

  for icon in $used_icons; do
    # Skip non-icon classes
    echo "$icon" | grep -qE "$SKIP_PATTERN" && continue
    # Check against valid list
    if ! echo "$valid_icons" | grep -qx "$icon"; then
      echo "INVALID: $icon in $(basename "$file")"
      # Suggest similar valid icons
      stem=$(echo "$icon" | sed 's/^fa-//')
      suggestions=$(echo "$valid_icons" | grep "$stem" | head -3 | tr '\n' ', ' | sed 's/,$//')
      [ -n "$suggestions" ] && echo "  Maybe: $suggestions"
      errors=$((errors + 1))
    fi
  done
done

if [ "$errors" -eq 0 ]; then
  echo "All icons valid."
else
  echo ""
  echo "$errors invalid icon(s) found. Replace with free alternatives or remove."
  exit 1
fi
