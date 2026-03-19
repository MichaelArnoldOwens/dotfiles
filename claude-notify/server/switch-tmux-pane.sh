#!/bin/bash
# Usage: switch-tmux-pane.sh <socket_path> <session:window.pane>
SOCKET="${1:-}"
TARGET="${2:-}"

if [ -n "$SOCKET" ] && [ -S "$SOCKET" ]; then
  tmux -S "$SOCKET" switch-client -t "$TARGET" 2>/dev/null || true
fi

osascript \
  -e 'tell application "System Events"' \
  -e '  if exists process "iTerm2" then' \
  -e '    tell application "iTerm2" to activate' \
  -e '  else if exists process "Terminal" then' \
  -e '    tell application "Terminal" to activate' \
  -e '  else if exists process "Alacritty" then' \
  -e '    tell application "Alacritty" to activate' \
  -e '  else if exists process "kitty" then' \
  -e '    tell application "kitty" to activate' \
  -e '  end if' \
  -e 'end tell'
