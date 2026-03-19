---
description: Reload all Claude Code instances running in tmux panes with --continue to preserve each conversation's context. Use when the user wants to restart all Claude instances after config/settings/dotfiles changes without losing their work.
---

# Claude Reload All

Restart every Claude Code instance running across tmux panes. Each instance exits gracefully and immediately resumes with `claude --continue`, so no conversation context is lost.

**Note:** This instance will also be restarted. That's intentional — `--continue` will resume this conversation from its last saved state.

**Queuing behavior:** If other Claude instances are currently busy (running tools/commands), the restart is automatically queued and waits until they all become idle before proceeding. Pass `--force` to skip the wait and restart immediately.

## Instructions

1. Show the user which panes will be restarted:

```bash
~/.local/bin/claude-restart-all --dry-run
```

2. If `$ARGUMENTS` contains `--dry-run` or `--preview`, stop here and report the dry-run output.

3. If `$ARGUMENTS` contains `--force`, restart immediately without waiting:

```bash
~/.local/bin/claude-restart-all --force
```

4. Otherwise, proceed (the script will auto-queue if any instances are busy):

```bash
~/.local/bin/claude-restart-all
```

Report how many instances were restarted. The current instance will be among them — the conversation will resume automatically via `--continue`.
