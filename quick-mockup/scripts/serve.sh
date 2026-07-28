#!/bin/bash
# Starts a local web server in the html/ directory on an available port.
# Tries port 8000 first, then increments until it finds one that's free.

set -e

HTML_DIR="html"
PORT=8000
MAX_PORT=8020

if [ ! -d "$HTML_DIR" ]; then
  echo "Error: $HTML_DIR directory not found."
  exit 1
fi

# Find an available port
while [ $PORT -le $MAX_PORT ]; do
  if ! lsof -iTCP:"$PORT" -sTCP:LISTEN &>/dev/null; then
    break
  fi
  PORT=$((PORT + 1))
done

if [ $PORT -gt $MAX_PORT ]; then
  echo "Error: No available port found between 8000 and $MAX_PORT."
  exit 1
fi

echo "Starting server at http://localhost:$PORT"
echo "Serving files from: $HTML_DIR/"
echo "Press Ctrl+C to stop."
python3 -m http.server "$PORT" --directory "$HTML_DIR"
