# Dotfiles

Shared developer environment configs for the team. Optimized for a workflow using **Cursor**, **iTerm2**, **Claude Code**, **tmux**, and **Graphite**. Works on both **macOS** (local) and **Linux** (devbox via SSH).

## What's included

| File | What it configures |
|------|--------------------|
| `.tmux.conf` | Pane visibility (inactive dimming), session persistence, vi-style navigation, interactive menus |
| `.tmux/menus.conf` | Interactive tmux menus (prefix + Space) |
| `.zshrc` | Oh My Zsh + Powerlevel10k, iTerm2 shell integration, tmux auto-start, Graphite commit timer |
| `.gitconfig` | Delta syntax-highlighted diffs, SSH commit signing, global gitignore, GitHub SSH rewrite |
| `.gitignore_global` | Machine-wide ignores: `.DS_Store`, editor files, `.env`, `node_modules`, `__pycache__` |
| `.config/graphite/aliases` | Shortcuts for stacked PR workflow (`gt cb`, `gt cs`, `gt ss`, etc.) |
| `.claude/settings.json` | Claude Code `acceptEdits` permission mode, auto-sync hooks, secret scanning |
| `.local/bin/claude-burn` | Daily Claude token usage counter displayed in tmux status bar |
| `.claude/mcp-servers.json` | MCP server definitions (merged into `~/.claude.json` by install.sh) |

## Setup

### 1. Clone and install

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

The install script will:
- Back up any existing config files (e.g. `~/.tmux.conf.backup.20260209`)
- Create symlinks from `~` to the repo
- Generate `~/.env.local` and `~/.gitconfig.local` from templates if they don't exist
- Print platform-specific dependency install commands

### 2. Fill in your local config

**`~/.gitconfig.local`** — your git identity (required):

```gitconfig
[user]
    name = Your Name
    email = your-email@example.com
    signingkey = ~/.ssh/id_ed25519.pub
```

**`~/.env.local`** — API keys (optional, for Claude Code video skill):

```bash
export OPENROUTER_API_KEY="your-key-here"
export GEMINI_API_KEY="your-key-here"
```

### 3. Install dependencies

#### macOS (Homebrew)

```bash
brew install git-delta              # syntax-highlighted diffs
brew install ffmpeg yt-dlp          # video skill (optional)
pip3 install openai google-generativeai  # video skill (optional)
```

#### Linux (apt)

```bash
sudo apt install git-delta          # syntax-highlighted diffs
sudo apt install ffmpeg             # video skill (optional)
pip3 install yt-dlp openai google-generativeai  # video skill (optional)
```

#### Tmux plugins (both platforms)

```bash
# Run inside tmux:
# prefix + r        reload config
# prefix + I        install plugins (resurrect, continuum, which-key)
```

### 4. Restart your shell

```bash
source ~/.zshrc
```

## How syncing works

Claude Code hooks keep dotfiles in sync across machines automatically:

| Event | What happens |
|-------|-------------|
| **SessionStart** | `git pull --rebase --autostash` — pulls latest changes, auto-stashes dirty work |
| **PostToolUse** (Write/Edit) | Auto-commits any dotfile change immediately |
| **SessionEnd** | `git add -A && commit && pull --rebase && push` — full sync cycle |

The flow is conflict-safe:
- `--autostash` handles dirty working trees during pull
- Pull-rebase before push prevents silent push failures
- If anything fails, the next SessionStart pull will self-heal
- `.gitignore` prevents secrets and local state from being committed

## Platform-specific behavior

Some features are gated by platform to avoid issues on the wrong OS:

| Feature | macOS | Linux | How it's gated |
|---------|-------|-------|----------------|
| Token usage in status bar | Yes | Yes | `claude-burn` script via `#()` in status-right |
|---------|-------|-------|----------------|
| Light tmux theme | Yes | No (dark default) | `uname -s` check in `.tmux.conf` |
| F12 nested tmux toggle | Yes | No | `uname -s` check in `.tmux.conf` |
| iTerm2 shell integration | Yes | No (skipped) | `$OSTYPE` check in `.zshrc` |
| `ce` alias (open Cursor) | Yes | No | `$OSTYPE` check in `.zshrc` |

## File structure

```
~/dotfiles/                     # This repo (version-controlled)
├── CLAUDE.md                   # Claude Code repo instructions (auto-loaded)
├── .tmux.conf                  → ~/.tmux.conf
├── .tmux/menus.conf            → ~/.tmux/menus.conf
├── .zshrc                      → ~/.zshrc
├── .gitconfig                  → ~/.gitconfig
├── .gitignore_global           → ~/.gitignore_global
├── .config/graphite/aliases    → ~/.config/graphite/aliases
├── .claude/settings.json       → ~/.claude/settings.json
├── .local/bin/claude-burn      → ~/.local/bin/claude-burn
├── .claude/mcp-servers.json    # MCP servers (merged into ~/.claude.json)
├── .env.local.template         # Reference for ~/.env.local
├── .gitconfig.local.template   # Reference for ~/.gitconfig.local
└── install.sh                  # Symlink installer

~/.env.local                    # Your API keys (NOT in repo)
~/.gitconfig.local              # Your git identity (NOT in repo)
~/.claude/settings.local.json   # Your Claude Code permissions (NOT in repo)
~/.config/graphite/user_config  # Your Graphite auth token (NOT in repo)
```

## Secrets

All secrets and personal identity live in local-only files that are **never committed**:

- `~/.env.local` — sourced by `.zshrc` on shell startup, holds API keys
- `~/.gitconfig.local` — included by `.gitconfig`, holds name/email/signing key
- `~/.claude/settings.local.json` — Claude Code permission overrides
- `~/.config/graphite/user_config` — created by `gt auth`

The repo `.gitignore` and `~/.gitignore_global` both exclude these files.

## MCP servers

The following MCP servers are pre-configured and merged into `~/.claude.json` by `install.sh`:

| Server | Type | What it provides |
|--------|------|------------------|
| PostHog | HTTP | Analytics queries, feature flags, experiments |
| Datadog | HTTP | Logs, metrics, monitors, incidents, dashboards |
| Mux | HTTP | Video asset management, playback, QoE data |
| Linear | HTTP | Issue tracking, projects, documents |
| Notion | HTTP | Pages, databases, team wikis |
| Slack | HTTP + OAuth | Channel search, messaging, canvases |
| Graphite | stdio (`gt mcp`) | Stacked PR workflow (requires `gt` installed) |

HTTP servers authenticate via browser OAuth on first use. Slack requires an additional OAuth handshake (port 3118).

**Cloud connectors** (claude.ai Figma, Excalidraw) and **plugins** (figma, ralph-loop) are account-level — they follow your Anthropic login and don't need local config.

To add or remove servers, edit `.claude/mcp-servers.json` and re-run `./install.sh`.

## Claude token usage (`claude-burn`)

The tmux status bar shows daily Claude Code output token usage with a 7-day sparkline trend (e.g., `221K ▁▁▁▂▅▂█`). The script scans JSONL transcript files in `~/.claude/projects/` every tmux status-interval tick (~15s).

### Color thresholds (optional)

By default the counter uses a neutral color. To add green/yellow/red thresholds based on daily output token count:

```bash
mkdir -p ~/.config/claude-burn
cat > ~/.config/claude-burn/config << 'EOF'
# Thresholds for color-coding (output tokens per day)
# green:  below warn
# yellow: between warn and alert
# red:    at or above alert
warn=500000
alert=1500000
EOF
```

Changes take effect on the next tmux status refresh (no reload needed). To disable color, delete the config file or set values to 0.

### Cache

Historical daily totals are cached in `~/.cache/claude-burn/day-YYYY-MM-DD.txt` (one integer per file). Today and yesterday are always recomputed live. The cache warms over 7 days — until then, uncached days show as `▁` in the sparkline.

## Graphite aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `gt ls` | `log short` | View branch stack (compact) |
| `gt ll` | `log long` | View branch stack (detailed) |
| `gt ss` | `submit --stack` | Submit entire stack for review |
| `gt co` | `checkout` | Switch branches |
| `gt cb` | `create` | Create a new stacked branch |
| `gt cs` | `commit --stack` | Commit and restack dependents |
| `gt ca` | `commit --amend` | Amend last commit |
| `gt bd` | `branch delete` | Delete a branch |
| `gt bi` | `branch info` | Show current branch info |
| `gt bs` | `branch submit` | Submit branch as PR |
| `gt rs` | `repo sync` | Sync with remote + restack |
| `gt ds` | `dash` | Open Graphite web dashboard |

## tmux quick reference

| Shortcut | Action |
|----------|--------|
| `prefix + r` | Reload config |
| `prefix + I` | Install/update TPM plugins |
| `prefix + ?` | Help menu |
| `prefix + Space` | Quick actions menu |
| `prefix + \|` | Split vertical |
| `prefix + -` | Split horizontal |
| `prefix + h/j/k/l` | Navigate panes |
| `prefix + H/J/K/L` | Resize panes |
| `prefix + Ctrl-s` | Save session |
| `prefix + Ctrl-r` | Restore session |

Prefix is `Ctrl+Space` (changed from default `Ctrl+b` to avoid conflict with Claude Code's background-task shortcut).
