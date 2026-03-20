#!/bin/bash
# Usage: switch-tmux-pane.sh <socket_path> <session:window.pane>
SOCKET="${1:-}"
TARGET="${2:-}"

TMUX_BIN=$(command -v tmux 2>/dev/null || echo /opt/homebrew/bin/tmux)

if [ -n "$SOCKET" ] && [ -S "$SOCKET" ] && [ -x "$TMUX_BIN" ]; then
  "$TMUX_BIN" -S "$SOCKET" select-window -t "$TARGET" 2>/dev/null || true

  CLIENT=$("$TMUX_BIN" -S "$SOCKET" list-clients -F '#{client_name}' 2>/dev/null | head -1)
  if [ -n "$CLIENT" ]; then
    "$TMUX_BIN" -S "$SOCKET" switch-client -c "$CLIENT" -t "$TARGET" 2>/dev/null || true
  fi

  # Clear the claude status indicator (✓/⏳) on the target window
  "$TMUX_BIN" -S "$SOCKET" set-option -w -t "$TARGET" @claude_status "" 2>/dev/null || true
fi

osascript -e 'tell application "iTerm2" to activate' 2>/dev/null \
  || osascript -e 'tell application "Terminal" to activate' 2>/dev/null
