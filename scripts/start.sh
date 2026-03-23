#!/bin/bash
# Start AIRI stage-web dev server in persistent background mode
set -euo pipefail

PROJECT_DIR="/proj/wm/airi_test"
PID_FILE="$PROJECT_DIR/.stage-web.pid"
PGID_FILE="$PROJECT_DIR/.stage-web.pgid"
PORT_FILE="$PROJECT_DIR/.stage-web.port"
LOG_FILE="$PROJECT_DIR/.logs/stage-web.log"
DEFAULT_PORT="5173"
# Run stage-web without inheriting machine-level proxy vars.
# Proxy should be opt-in at component/provider level, not global by default.

pick_free_port() {
  local base_port="$1"
  local port
  for port in $(seq "$base_port" "$((base_port + 100))"); do
    if ! lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
      echo "$port"
      return 0
    fi
  done
  return 1
}

if ! command -v conda >/dev/null 2>&1; then
  echo "Error: conda command not found in PATH"
  exit 1
fi

if [ -f "$PID_FILE" ]; then
  OLD_PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [ -n "${OLD_PID}" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    ACTIVE_PORT="$(cat "$PORT_FILE" 2>/dev/null || true)"
    echo "Server already running (PID: $OLD_PID${ACTIVE_PORT:+, PORT: $ACTIVE_PORT})"
    exit 1
  fi
  rm -f "$PID_FILE" "$PGID_FILE" "$PORT_FILE"
fi

mkdir -p "$PROJECT_DIR/.logs"

PORT="$(pick_free_port "$DEFAULT_PORT" || true)"
if [ -z "$PORT" ]; then
  echo "Failed to find an available port in range ${DEFAULT_PORT}-$((DEFAULT_PORT + 100))"
  exit 1
fi

START_CMD="env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy conda run --no-capture-output -n testenv pnpm -r -F @proj-airi/stage-web run dev -- --host 0.0.0.0 --port ${PORT} --strictPort"

cd "$PROJECT_DIR"
nohup setsid bash -lc "$START_CMD" >> "$LOG_FILE" 2>&1 &
LAUNCH_PID="$!"
echo "$LAUNCH_PID" > "$PID_FILE"
echo "$PORT" > "$PORT_FILE"

sleep 1
if ! kill -0 "$LAUNCH_PID" 2>/dev/null; then
  echo "Failed to start process. Check logs: $LOG_FILE"
  rm -f "$PID_FILE" "$PGID_FILE" "$PORT_FILE"
  exit 1
fi

PGID="$(ps -o pgid= -p "$LAUNCH_PID" 2>/dev/null | tr -d ' ' || true)"
if [ -n "$PGID" ]; then
  echo "$PGID" > "$PGID_FILE"
fi

echo "Starting AIRI stage-web dev server in testenv..."
for i in $(seq 1 30); do
  if curl -fsS -o /dev/null "http://127.0.0.1:${PORT}/" 2>/dev/null; then
    echo "Server is up at http://0.0.0.0:${PORT}/ (PID: $LAUNCH_PID${PGID:+, PGID: $PGID})"
    exit 0
  fi
  sleep 2
done

echo "Warning: Process started but HTTP may still be initializing. Check: tail -f $LOG_FILE"
