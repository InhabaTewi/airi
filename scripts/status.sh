#!/bin/bash
# Check AIRI stage-web dev server status
set -euo pipefail

PROJECT_DIR="/proj/wm/airi_test"
PID_FILE="$PROJECT_DIR/.stage-web.pid"
PGID_FILE="$PROJECT_DIR/.stage-web.pgid"
PORT_FILE="$PROJECT_DIR/.stage-web.port"
DEFAULT_PORT="5173"

PID=""
PGID=""
PORT=""
[ -f "$PID_FILE" ] && PID="$(cat "$PID_FILE" 2>/dev/null || true)"
[ -f "$PGID_FILE" ] && PGID="$(cat "$PGID_FILE" 2>/dev/null || true)"
[ -f "$PORT_FILE" ] && PORT="$(cat "$PORT_FILE" 2>/dev/null || true)"

if [ -z "$PORT" ]; then
  PORT="$DEFAULT_PORT"
fi

running="0"

if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
  running="1"
  echo "Server is running (PID: $PID${PGID:+, PGID: $PGID})"
else
  PORT_PIDS="$(lsof -ti:"$PORT" 2>/dev/null || true)"
  if [ -n "$PORT_PIDS" ]; then
    running="1"
    echo "Server running on port $PORT (PIDs: $PORT_PIDS)"
    if [ -n "$PID" ]; then
      echo "Notice: PID file exists but recorded PID is not alive: $PID"
    fi
  else
    echo "Server is not running."
  fi
fi

if [ "$running" = "1" ]; then
  if curl -fsS -o /dev/null "http://127.0.0.1:${PORT}/" 2>/dev/null; then
    echo "HTTP: OK (http://0.0.0.0:${PORT}/)"
  else
    echo "HTTP: Not responding yet"
  fi
fi
