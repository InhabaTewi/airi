#!/bin/bash
# Stop AIRI stage-web dev server
set -euo pipefail

PROJECT_DIR="/proj/wm/airi_test"
PID_FILE="$PROJECT_DIR/.stage-web.pid"
PGID_FILE="$PROJECT_DIR/.stage-web.pgid"
PORT_FILE="$PROJECT_DIR/.stage-web.port"
DEFAULT_PORT="5173"

is_airi_web_pid() {
  local pid="$1"
  local cmd
  cmd="$(ps -o command= -p "$pid" 2>/dev/null || true)"
  if [[ "$cmd" == *"@proj-airi/stage-web"* ]] || [[ "$cmd" == *"pnpm"*"stage-web"* ]]; then
    return 0
  fi
  return 1
}

PID=""
PGID=""
PORT=""
[ -f "$PID_FILE" ] && PID="$(cat "$PID_FILE" 2>/dev/null || true)"
[ -f "$PGID_FILE" ] && PGID="$(cat "$PGID_FILE" 2>/dev/null || true)"
[ -f "$PORT_FILE" ] && PORT="$(cat "$PORT_FILE" 2>/dev/null || true)"

if [ -z "$PORT" ]; then
  PORT="$DEFAULT_PORT"
fi

stopped_any="0"

if [ -n "$PGID" ] && pgrep -g "$PGID" >/dev/null 2>&1; then
  echo "Stopping process group: $PGID"
  kill -TERM -- "-$PGID" 2>/dev/null || true
  for _ in $(seq 1 10); do
    sleep 1
    if ! pgrep -g "$PGID" >/dev/null 2>&1; then
      stopped_any="1"
      break
    fi
  done
  if pgrep -g "$PGID" >/dev/null 2>&1; then
    kill -KILL -- "-$PGID" 2>/dev/null || true
    stopped_any="1"
  fi
fi

if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
  echo "Stopping PID: $PID"
  kill "$PID" 2>/dev/null || true
  sleep 1
  if kill -0 "$PID" 2>/dev/null; then
    kill -9 "$PID" 2>/dev/null || true
  fi
  stopped_any="1"
fi

# Final fallback: clear anything still holding the service port.
PORT_PIDS="$(lsof -ti:"$PORT" 2>/dev/null || true)"
if [ -n "$PORT_PIDS" ]; then
  CLEAN_PIDS=""
  for p in $PORT_PIDS; do
    if is_airi_web_pid "$p"; then
      CLEAN_PIDS="$CLEAN_PIDS $p"
    fi
  done
  CLEAN_PIDS="$(echo "$CLEAN_PIDS" | xargs 2>/dev/null || true)"
  if [ -n "$CLEAN_PIDS" ]; then
    echo "Cleaning remaining AIRI stage-web processes on port $PORT: $CLEAN_PIDS"
    echo "$CLEAN_PIDS" | xargs -r kill -9 2>/dev/null || true
    stopped_any="1"
  fi
fi

rm -f "$PID_FILE" "$PGID_FILE" "$PORT_FILE"

if [ "$stopped_any" = "1" ]; then
  echo "Server stopped."
else
  echo "No running server found."
fi
