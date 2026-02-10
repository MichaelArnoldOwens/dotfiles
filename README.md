# Dotfiles

Shared developer environment configs for the team. Optimized for a workflow using **Cursor**, **iTerm2**, **Claude Code**, **tmux**, and **Graphite**.

## What's included

| File | What it configures |
|------|--------------------|
| `.tmux.conf` | Pane visibility (inactive dimming), session persistence, vi-style navigation, interactive menus |
| `.zshrc` | Oh My Zsh + Powerlevel10k, iTerm2 shell integration, tmux auto-start, Graphite commit timer |
| `.gitconfig` | Delta syntax-highlighted diffs, SSH commit signing, global gitignore, GitHub SSH rewrite |
| `.gitignore_global` | Machine-wide ignores: `.DS_Store`, editor files, `.env`, `node_modules`, `__pycache__` |
| `.config/graphite/aliases` | Shortcuts for stacked PR workflow (`gt cb`, `gt cs`, `gt ss`, etc.) |
| `.claude/settings.json` | Claude Code `acceptEdits` permission mode (auto-approves file operations) |

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

```bash
# Syntax-highlighted diffs
brew install git-delta

# Tmux plugins (run inside tmux)
# prefix + r        reload config
# prefix + I        install plugins (resurrect, continuum, which-key)

# Video understanding skill for Claude Code (optional)
brew install ffmpeg yt-dlp
pip3 install openai google-generativeai
npx skills add jrusso1020/video-understand-skills -a claude-code -g
```

### 4. Restart your shell

```bash
source ~/.zshrc
```

## File structure

```
~/dotfiles/                     # This repo (version-controlled)
├── .tmux.conf                  → ~/.tmux.conf
├── .zshrc                      → ~/.zshrc
├── .gitconfig                  → ~/.gitconfig
├── .gitignore_global           → ~/.gitignore_global
├── .config/graphite/aliases    → ~/.config/graphite/aliases
├── .claude/settings.json       → ~/.claude/settings.json
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

Prefix is `Ctrl+b`.
