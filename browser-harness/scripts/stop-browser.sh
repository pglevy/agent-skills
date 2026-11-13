#!/usr/bin/env bash
# Stop the isolated Chrome in this workspace (current dir or BH_WORKSPACE) and its named browser-harness daemon (exp3gen).
# Leaves the default daemon (the user's everyday Chrome) alone.
set -uo pipefail

ROOT="$(cd "${BH_WORKSPACE:-$PWD}" && pwd)"
PIDFILE="$ROOT/.browser-profile.pid"
NAME="exp3gen"
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
