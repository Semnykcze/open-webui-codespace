#!/bin/bash

# Load configuration from config.ini
source <(grep -v '^#' config.ini | sed 's/\$(\(.*\))/$(\1)/g')

# Llama server manager
LOG_FILE="$ROOT_DIR/llama-server.log"
PID_FILE="$ROOT_DIR/llama-server.pid"

start_server() {
  if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "✅ Llama server is already running."
  else
    echo "Starting Llama server..."
    nohup $PYTHON_BIN -m llama_cpp.server \
      --model "$MODEL_DIR/$MODEL_NAME" \
      --host 0.0.0.0 \
      --port 8000 > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    echo "✅ Llama server started. Logs: $LOG_FILE"
  fi
}

stop_server() {
  if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "Stopping Llama server..."
    kill $(cat "$PID_FILE") && rm -f "$PID_FILE"
    echo "✅ Llama server stopped."
  else
    echo "❌ Llama server is not running."
  fi
}

restart_server() {
  echo "Restarting Llama server..."
  stop_server
  start_server
}

status_server() {
  if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "✅ Llama server is running. PID: $(cat "$PID_FILE")"
  else
    echo "❌ Llama server is not running."
  fi
}

case "$1" in
  start)
    start_server
    ;;
  stop)
    stop_server
    ;;
  restart)
    restart_server
    ;;
  status)
    status_server
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
    ;;
esac