#!/bin/bash
# Usage: switch-tmux-pane.sh <socket_path> <session:window.pane>
SOCKET="${1:-}"
TARGET="${2:-}"

TMUX_BIN=$(command -v tmux 2>/dev/null || echo /opt/homebrew/bin/tmux)

if [ -n "$SOCKET" ] && [ -S "$SOCKET" ] && [ -x "$TMUX_BIN" ]; then
  # Pre-select the window and pane in the session so switch-client
  # lands on the exact target (not just the session's last-active window).
  "$TMUX_BIN" -S "$SOCKET" select-window -t "$TARGET" 2>/dev/null || true
  "$TMUX_BIN" -S "$SOCKET" select-pane   -t "$TARGET" 2>/dev/null || true

  # switch-client needs an explicit -c when called outside tmux.
  # Pass the full session:window.pane target so iTerm2 -CC mode
  # switches to the right tab (window) immediately.
  CLIENT=$("$TMUX_BIN" -S "$SOCKET" list-clients -F '#{client_name}' 2>/dev/null | head -1)
  if [ -n "$CLIENT" ]; then
    "$TMUX_BIN" -S "$SOCKET" switch-client -c "$CLIENT" -t "$TARGET" 2>/dev/null || true
  fi
fi

# Bring the terminal to front. In iTerm2 -CC mode, switch-client above
# already drove the tab switch — activate just raises the window.
osascript -e 'tell application "iTerm2" to activate' 2>/dev/null \
  || osascript -e 'tell application "Terminal" to activate' 2>/dev/null
