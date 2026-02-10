############ LOCAL ENVIRONMENT ##############
# Load machine-specific secrets and env vars (API keys, personal identity, etc.)
# This file is NOT in the dotfiles repo. See .env.local.template for required vars.
[[ -f ~/.env.local ]] && source ~/.env.local
########################################################

############ TMUX CONFIGURATION ############

# Reload tmux config
alias tmux-reload='tmux source-file ~/.tmux.conf && echo "tmux config reloaded!"'

# Auto-start tmux on new terminal sessions
# - Only starts if tmux is installed
# - Only starts if not already inside tmux
# - Only starts for interactive shells
# - Attaches to existing session "main" or creates it
if command -v tmux &> /dev/null && [[ -z "$TMUX" ]] && [[ $- == *i* ]]; then
  tmux attach-session -t main 2>/dev/null || tmux new-session -s main
fi

########################################################

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# Plugins:
#   git     — 200+ git aliases (ga, gc, gp, gl, gst, etc). Run `alias | grep git` to see all.
#   iterm2  — Enables iTerm2 shell integration (command markers, directory tracking, etc).
#             Note: Shell integration auto-disables inside tmux to avoid conflicts.
#             To force it in tmux, set ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=1.
plugins=(git iterm2)
zstyle :omz:plugins:iterm2 shell-integration yes

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

export GPG_TTY=$(tty)

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

. "$HOME/.local/bin/env"

############ GRAPHITE (gt) PRE-COMMIT TIMER ############

gt() {
  # Only intercept `gt commit ...`
  if [[ "$1" != "commit" ]]; then
    command gt "$@"
    return
  fi

  local STATS_FILE="$HOME/Library/Application Support/git-precommit-stats.json"
  mkdir -p "$(dirname "$STATS_FILE")"
  [[ -f "$STATS_FILE" ]] || echo "{}" > "$STATS_FILE"

  local NO_VERIFY=0
  for arg in "$@"; do
    [[ "$arg" == "--no-verify" || "$arg" == "-n" ]] && NO_VERIFY=1
  done

  local start_ns end_ns elapsed_s
  start_ns=$(python3 - <<'PY'
import time; print(time.time_ns())
PY
)

  command gt "$@"
  local status=$?

  end_ns=$(python3 - <<'PY'
import time; print(time.time_ns())
PY
)

  elapsed_s=$(((end_ns - start_ns) / 1000000000))

  local today repo
  today=$(date "+%Y-%m-%d")
  repo=$(command git rev-parse --show-toplevel 2>/dev/null | sed 's|/|_|g')

  python3 - "$STATS_FILE" "$today" "$elapsed_s" "$NO_VERIFY" "$repo" <<'PY'
import json, sys

path, day, secs, no_verify, repo = sys.argv[1:]
secs = int(secs)
no_verify = int(no_verify)

with open(path, "r") as f:
    raw = f.read().strip()
data = json.loads(raw) if raw else {}

day_entry = data.setdefault(day, {})
repos = data.setdefault("_repos", {})

repo_key = repo or "unknown"
repo_entry = repos.setdefault(repo_key, {})
last = int(repo_entry.get("last_seconds", 0))

if no_verify:
    # Estimate "saved" time based on last observed commit duration for this repo
    if last > 0:
        day_entry["estimated_saved_seconds"] = day_entry.get("estimated_saved_seconds", 0) + last
else:
    # Accumulate actual time spent waiting on commit path (includes hooks)
    day_entry["commit_seconds"] = day_entry.get("commit_seconds", 0) + secs
    repo_entry["last_seconds"] = secs

with open(path, "w") as f:
    json.dump(data, f, indent=2)
PY

  return $status
}

########################################################
