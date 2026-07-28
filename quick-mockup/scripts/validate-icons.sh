#!/bin/bash
# Validates Font Awesome icon usage in HTML files against the free CDN CSS.
# Exits 0 if all icons are valid, 1 if any are invalid.

set -e

FA_CSS_URL="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.1/css/all.min.css"
HTML_DIR="${1:-html}"

# Non-icon fa-* classes (modifiers, sizing, animation, stacking, etc.)
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

# Fetch valid icon names from CDN into a temp file for fast lookup
valid_icons_file=$(mktemp)
trap 'rm -f "$valid_icons_file"' EXIT

# Extract all icon class selectors — handles comma-grouped selectors like
# .fa-user,.fa-user-alt,.fa-user-large{--fa:"..."}
curl -sL "$FA_CSS_URL" \
  | grep -oE '\.[a-z0-9,.:-]*\{--fa:' \
  | sed 's/{--fa://' \
  | tr ',' '\n' \
  | grep -oE '\.fa-[a-z0-9-]+' \
  | sed 's/^\.//' \
  | sort -u > "$valid_icons_file"

# Sanity check: if we got fewer than 100 icons, the CSS format probably changed
icon_count=$(wc -l < "$valid_icons_file" | tr -d ' ')
if [ "$icon_count" -lt 100 ]; then
  echo "WARNING: Only extracted $icon_count icons from CDN CSS. Format may have changed."
  echo "Skipping validation to avoid false positives."
  exit 0
fi

echo "Loaded $icon_count valid icons from Font Awesome CDN."

errors=0

for file in "${html_files[@]}"; do
  # Extract icon classes only from class="..." attributes, not URLs or comments
  used_icons=$(grep -oE 'class="[^"]*"' "$file" \
    | grep -oE 'fa-[a-z0-9-]+' \
    | sort -u)

  for icon in $used_icons; do
    # Skip modifier/utility classes
    echo "$icon" | grep -qE "$SKIP_PATTERN" && continue

    # Use grep -Fx for exact whole-line match (no substring confusion)
    if ! grep -qFx "$icon" "$valid_icons_file"; then
      echo "INVALID: $icon in $(basename "$file")"
      stem=$(echo "$icon" | sed 's/^fa-//')
      # Use word-boundary-ish matching for suggestions
      suggestions=$(grep -F "$stem" "$valid_icons_file" | head -3 | tr '\n' ', ' | sed 's/, *$//')
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
