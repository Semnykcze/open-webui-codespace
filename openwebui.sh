#!/bin/bash

# Load configuration from config.ini
source <(grep -v '^#' config.ini | sed 's/\$(\(.*\))/$(\1)/g')

# Open WebUI manager
LOG_FILE="$ROOT_DIR/webui-server.log"
PID_FILE="$ROOT_DIR/webui-server.pid"

start_webui() {
  if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "✅ Open WebUI is already running."
  else
    echo "Starting Open WebUI..."
    nohup $PYTHON_BIN -m open_webui.serve > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    echo "✅ Open WebUI started. Logs: $LOG_FILE"
  fi
}

stop_webui() {
  if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "Stopping Open WebUI..."
    kill $(cat "$PID_FILE") && rm -f "$PID_FILE"
    echo "✅ Open WebUI stopped."
  else
    echo "❌ Open WebUI is not running."
  fi
}

restart_webui() {
  echo "Restarting Open WebUI..."
  stop_webui
  start_webui
}

status_webui() {
  if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "✅ Open WebUI is running. PID: $(cat "$PID_FILE")"
  else
    echo "❌ Open WebUI is not running."
  fi
}

case "$1" in
  start)
    start_webui
    ;;
  stop)
    stop_webui
    ;;
  restart)
    restart_webui
    ;;
  status)
    status_webui
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
    ;;
esac