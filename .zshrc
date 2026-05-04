# =============================================================================
# .zshrc — zsh startup file (interactive shells)
#
# Shared/portable config (env, PATH, aliases, dx/feat/gt) lives in .shellrc
# and is sourced at the bottom. Everything in this file is zsh-only:
# Oh My Zsh, Powerlevel10k, completion zstyles, plugins.
# =============================================================================

############ TMUX AUTO-START ############
# Auto-start tmux on new terminal sessions:
# - Only if tmux is installed
# - Only if not already inside tmux
# - Only for interactive shells
# Uses "grouped sessions" so each terminal window gets its own independent
# view of the shared windows. Closing the terminal destroys the grouped
# session but keeps the windows.
if command -v tmux &> /dev/null && [[ -z "$TMUX" ]] && [[ $- == *i* ]]; then
  if tmux has-session -t main 2>/dev/null; then
    exec tmux new-session -t main
  else
    exec tmux new-session -s main
  fi
fi
########################################################

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

############ OH MY ZSH ############
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins:
#   git                — 200+ git aliases (ga, gc, gp, gl, gst, etc).
#   iterm2             — Enables iTerm2 shell integration (macOS only).
#   zsh-autosuggestions — Fish-like inline suggestions (grey shadow text).
#   zsh-completions    — Extra completion definitions for hundreds of CLIs.
plugins=(git zsh-autosuggestions zsh-completions)
if [[ "$OSTYPE" == darwin* ]]; then
  plugins+=(iterm2)
  zstyle :omz:plugins:iterm2 shell-integration yes
fi

# --- History ---
# Larger history so zsh-autosuggestions has more to draw from.
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
# HIST_IGNORE_ALL_DUPS: drop older duplicates so suggestions stay fresh.
# HIST_REDUCE_BLANKS:   normalize whitespace before saving.
# HIST_IGNORE_SPACE:    leading-space commands are not recorded.
setopt HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_IGNORE_SPACE

# --- Completion system ---
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{cyan}-- %d --%f'

# --- Autosuggestion settings ---
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=245"

source $ZSH/oh-my-zsh.sh

# Powerlevel10k config (run `p10k configure` to regenerate).
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

############ SHARED PORTABLE CONFIG ############
# Sources env, PATH, aliases, and dx/feat/gt functions shared with .bashrc.
[[ -f ~/.shellrc ]] && source ~/.shellrc
########################################################
