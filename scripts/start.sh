#!/bin/bash
# Start AIRI stage-web dev server
set -e

PROJECT_DIR="/proj/wm/airi_test"
PID_FILE="$PROJECT_DIR/.stage-web.pid"
LOG_FILE="$PROJECT_DIR/.logs/stage-web.log"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "Server already running (PID: $(cat "$PID_FILE"))"
  exit 1
fi

mkdir -p "$PROJECT_DIR/.logs"

cd "$PROJECT_DIR"
nohup conda run -n testenv pnpm dev > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"

echo "Starting AIRI stage-web dev server..."
for i in $(seq 1 30); do
  if curl -s -o /dev/null http://localhost:5173/ 2>/dev/null; then
    echo "Server is up at http://0.0.0.0:5173/ (PID: $(cat "$PID_FILE"))"
    exit 0
  fi
  sleep 2
done

echo "Warning: Server started but may still be initializing. Check: tail -f $LOG_FILE"
