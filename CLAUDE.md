# Dotfiles — Claude Code Instructions

This repo is shared between macOS (local) and Linux (devbox). All changes must work on both platforms.

## Sync model

- **SessionStart** hook pulls latest (`git pull --rebase --autostash`)
- **PostToolUse** hooks auto-commit any Write/Edit to files in this repo
- **SessionEnd** hook does `git add -A`, commit, pull-rebase, push
- `.gitignore` is the safety net — it prevents secrets, backups, and Claude state dirs from being committed

## Rules

1. **Never commit secrets.** Local-only files (`.env.local`, `.gitconfig.local`, `settings.local.json`) are gitignored. Don't add them.
2. **Don't hardcode paths or platform assumptions.** Gate macOS-only behavior behind `uname -s` (tmux) or `$OSTYPE == darwin*` (zsh). Linux should always get a safe fallback.
3. **Keep `install.sh` idempotent.** It must be safe to re-run at any time. Backups before overwrites, skip if already linked.
4. **Don't touch the hardcoded file list in PostToolUse hooks.** Those commit individual files on Write/Edit. The SessionEnd hook uses `git add -A` to catch everything else.
5. **Update README.md** when adding new files, aliases, or platform-gated features.

## File layout

| Path | Purpose |
|------|---------|
| `install.sh` | Symlink installer + platform-specific dependency hints |
| `.claude/settings.json` | Hooks, permissions, env vars — synced to all machines |
| `.gitignore` | Protects `git add -A` from staging secrets/backups/state |
| `.env.local.template` | Reference for local API keys |
| `.gitconfig.local.template` | Reference for local git identity |

## Testing changes

After editing any hook or gitignore entry:
```bash
cd ~/dotfiles && git add -A --dry-run   # verify nothing unwanted gets staged
```
