#!/bin/bash
# Stop AIRI stage-web dev server
PROJECT_DIR="/proj/wm/airi_test"
PID_FILE="$PROJECT_DIR/.stage-web.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "No PID file found. Checking for running processes..."
  pids=$(lsof -ti:5173 2>/dev/null)
  if [ -n "$pids" ]; then
    echo "Killing processes on port 5173: $pids"
    echo "$pids" | xargs kill -9 2>/dev/null
    echo "Stopped."
  else
    echo "No server running."
  fi
  exit 0
fi

PID=$(cat "$PID_FILE")
if kill -0 "$PID" 2>/dev/null; then
  # Kill the process tree
  pkill -P "$PID" 2>/dev/null
  kill "$PID" 2>/dev/null
  sleep 2
  # Force kill if still running
  if kill -0 "$PID" 2>/dev/null; then
    kill -9 "$PID" 2>/dev/null
    pkill -9 -P "$PID" 2>/dev/null
  fi
  echo "Server stopped (PID: $PID)"
else
  echo "Process $PID not running."
fi

# Also kill any remaining vite processes on port 5173
lsof -ti:5173 2>/dev/null | xargs -r kill -9 2>/dev/null

rm -f "$PID_FILE"
