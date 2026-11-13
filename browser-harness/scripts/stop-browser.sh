#!/usr/bin/env bash
# Stop the isolated Chrome in this workspace (current dir or BH_WORKSPACE) and its named browser-harness daemon (pony).
# Leaves the default daemon (the user's everyday Chrome) alone.
#
# Usage: scripts/stop-browser.sh          stop this workspace's instance
#        scripts/stop-browser.sh --all    stop every isolated instance on this machine,
#                                         whichever workspace started it
set -uo pipefail

if [[ "${1:-}" == "--all" ]]; then
  NAME="pony"
  RUNTIME="${XDG_CONFIG_HOME:-$HOME/.config}/browser-harness/runtime"
  if [[ -f "$RUNTIME/bu-$NAME.pid" ]]; then
    DPID="$(cat "$RUNTIME/bu-$NAME.pid")"
    kill "$DPID" 2>/dev/null && echo "Stopped browser-harness daemon $NAME (pid $DPID)"
    rm -f "$RUNTIME/bu-$NAME.pid" "$RUNTIME/bu-$NAME.sock" "$RUNTIME/bu-$NAME.spawnlock"
  fi
  # Isolated Chromes are identified by their --user-data-dir ending in /.browser-profile
  # (the main process only, not helpers, which carry --type=). Never matches everyday Chrome.
  found=0
  while read -r pid; do
    [[ -n "$pid" ]] || continue
    cmd="$(ps -o command= -p "$pid" 2>/dev/null)" || continue
    [[ "$cmd" == *"--type="* ]] && continue
    profile="$(sed -n 's/.*--user-data-dir=\(.*\/\.browser-profile\) --.*/\1/p' <<<"$cmd")"
    [[ -n "$profile" ]] || continue
    kill "$pid" 2>/dev/null && echo "Stopped isolated Chrome (pid $pid, workspace ${profile%/.browser-profile})"
    rm -f "${profile%/.browser-profile}/.browser-profile.pid"
    found=$((found + 1))
  done < <(pgrep -f -- '--user-data-dir=.*/\.browser-profile ')
  [[ $found -gt 0 ]] || echo "No isolated Chrome instances running"
  exit 0
fi

ROOT="$(cd "${BH_WORKSPACE:-$PWD}" && pwd)"
PIDFILE="$ROOT/.browser-profile.pid"
NAME="pony"
RUNTIME="${XDG_CONFIG_HOME:-$HOME/.config}/browser-harness/runtime"

if [[ -f "$RUNTIME/bu-$NAME.pid" ]]; then
  DPID="$(cat "$RUNTIME/bu-$NAME.pid")"
  kill "$DPID" 2>/dev/null && echo "Stopped browser-harness daemon $NAME (pid $DPID)"
  rm -f "$RUNTIME/bu-$NAME.pid" "$RUNTIME/bu-$NAME.sock" "$RUNTIME/bu-$NAME.spawnlock"
fi

if [[ -f "$PIDFILE" ]]; then
  PID="$(cat "$PIDFILE")"
  kill "$PID" 2>/dev/null && echo "Stopped isolated Chrome (pid $PID)" || echo "Isolated Chrome was not running"
  rm -f "$PIDFILE"
else
  echo "No isolated Chrome pid file"
fi
