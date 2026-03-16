#!/bin/bash
# Check AIRI stage-web dev server status
PROJECT_DIR="/proj/wm/airi_test"
PID_FILE="$PROJECT_DIR/.stage-web.pid"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  PID=$(cat "$PID_FILE")
  echo "Server is running (PID: $PID)"
  if curl -s -o /dev/null -w "" http://localhost:5173/ 2>/dev/null; then
    echo "HTTP: OK (http://0.0.0.0:5173/)"
  else
    echo "HTTP: Not responding yet"
  fi
else
  # Check if something is on port 5173 anyway
  pids=$(lsof -ti:5173 2>/dev/null)
  if [ -n "$pids" ]; then
    echo "Server running on port 5173 (PIDs: $pids) but no PID file"
  else
    echo "Server is not running."
  fi
fi
