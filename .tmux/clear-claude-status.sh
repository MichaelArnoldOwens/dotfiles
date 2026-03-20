#!/usr/bin/env bash
# Clears the Claude Code status indicator from the window name.
# Called by the after-select-window hook when @claude_status == done.
# Strips the trailing " ✓" added by the Stop hook and unsets the variable.
name=$(tmux display-message -p '#W')
tmux set -w -u @claude_status
tmux rename-window "${name% ✓}"
