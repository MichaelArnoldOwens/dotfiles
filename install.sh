#!/usr/bin/env bash
# =============================================================================
# Dotfiles Installer
#
# Creates symlinks from ~ to this repo. Backs up existing files before replacing.
# Safe to run multiple times (idempotent — skips files already correctly linked).
#
# Usage:
#   ./install.sh
# =============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMESTAMP=$(date +%Y%m%d%H%M%S)

# Files to symlink: "repo_path:target_path"
LINKS=(
  ".tmux.conf:$HOME/.tmux.conf"
  ".tmux/menus.conf:$HOME/.tmux/menus.conf"
  ".zshrc:$HOME/.zshrc"
  ".gitconfig:$HOME/.gitconfig"
  ".gitignore_global:$HOME/.gitignore_global"
  ".config/graphite/aliases:$HOME/.config/graphite/aliases"
  ".claude/settings.json:$HOME/.claude/settings.json"
)

echo "=== Dotfiles Installer ==="
echo "Repo: $DOTFILES_DIR"
echo ""

# --- Create symlinks ---
for entry in "${LINKS[@]}"; do
  src="${DOTFILES_DIR}/${entry%%:*}"
  dst="${entry##*:}"

  # Skip if already correctly linked
  if [[ -L "$dst" ]] && [[ "$(readlink "$dst")" == "$src" ]]; then
    echo "  [skip] $dst (already linked)"
    continue
  fi

  # Back up existing file/symlink
  if [[ -e "$dst" ]] || [[ -L "$dst" ]]; then
    backup="${dst}.backup.${TIMESTAMP}"
    mv "$dst" "$backup"
    echo "  [backup] $dst → $backup"
  fi

  # Create parent directory if needed
  mkdir -p "$(dirname "$dst")"

  # Create symlink
  ln -s "$src" "$dst"
  echo "  [link] $dst → $src"
done

echo ""

# --- Set up local files from templates if they don't exist ---
if [[ ! -f "$HOME/.env.local" ]]; then
  cp "$DOTFILES_DIR/.env.local.template" "$HOME/.env.local"
  echo "  [created] ~/.env.local from template — fill in your API keys"
else
  echo "  [skip] ~/.env.local already exists"
fi

if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  cp "$DOTFILES_DIR/.gitconfig.local.template" "$HOME/.gitconfig.local"
  echo "  [created] ~/.gitconfig.local from template — fill in your name/email/signing key"
else
  echo "  [skip] ~/.gitconfig.local already exists"
fi

echo ""
echo "=== Done ==="
echo ""
echo "Next steps:"
echo "  1. Edit ~/.env.local with your API keys"
echo "  2. Edit ~/.gitconfig.local with your git identity"
echo "  3. Restart your shell: source ~/.zshrc"
echo "  4. Install tmux plugins: prefix + I (capital I)"
