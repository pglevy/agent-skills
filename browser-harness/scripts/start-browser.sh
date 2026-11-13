#!/usr/bin/env bash
# Start this workspace's own isolated, headless Chrome for browser-harness.
#
# - Separate profile (.browser-profile/, wiped on every start): no logins, tabs or
#   cookies from the user's everyday Chrome, and nothing carried over between runs.
# - Launched with --remote-debugging-port, so Chrome shows no "Allow remote debugging?" prompt.
# - Popup blocking is off: Appian opens many links (a!safeLink, record links set to NEW_TAB) with window.open,
#   which a fresh automation profile would silently block. New tabs then appear in list_tabs().
# - Headless at a fixed 1440x900 viewport (window 1440x987) with device scale factor 1, so screenshots are 1440x900.
#
# browser-harness reaches it through BU_CDP_URL (use scripts/bh, which sets it).
# Run from the project (workspace) root: the profile, pid file, and log land in the current
# directory (override with BH_WORKSPACE). Add .browser-profile* to that project's .gitignore.
# Usage: scripts/start-browser.sh [--headed]   (--headed shows a window, for watching a run)
set -euo pipefail

ROOT="$(cd "${BH_WORKSPACE:-$PWD}" && pwd)"
PORT="${BH_PORT:-9333}"
PROFILE="$ROOT/.browser-profile"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
LOG="$ROOT/.browser-profile.log"

if curl -fsS "http://127.0.0.1:$PORT/json/version" >/dev/null 2>&1; then
  echo "Isolated Chrome ready on http://127.0.0.1:$PORT (already running; scripts/stop-browser.sh resets it)"
  exit 0
fi

HEADLESS=(--headless=new)
if [[ "${1:-}" == "--headed" ]]; then HEADLESS=(); fi

rm -rf "$PROFILE"
mkdir -p "$PROFILE"

nohup "$CHROME" \
  "${HEADLESS[@]}" \
  --remote-debugging-port="$PORT" \
  --user-data-dir="$PROFILE" \
  --window-size=1440,987 \
  --force-device-scale-factor=1 \
  --disable-popup-blocking \
  --no-first-run \
  --no-default-browser-check \
  --disable-background-networking \
  --disable-sync \
  about:blank >"$LOG" 2>&1 &
echo $! > "$ROOT/.browser-profile.pid"

for _ in $(seq 1 40); do
  if curl -fsS "http://127.0.0.1:$PORT/json/version" >/dev/null 2>&1; then
    echo "Isolated Chrome ready on http://127.0.0.1:$PORT (pid $(cat "$ROOT/.browser-profile.pid"), profile $PROFILE)"
    exit 0
  fi
  sleep 0.25
done
echo "Chrome did not open port $PORT within 10s; see $LOG" >&2
exit 1
