# =============================================================================
# .bashrc — bash startup file (interactive shells)
#
# Mirrors .zshrc for the bits that work in bash: sources the portable
# .shellrc for env/PATH/aliases/functions, then layers on bash-only
# settings (history, prompt, completion).
#
# Used directly on Linux devboxes and inside Claude Code's bash subshell.
# On macOS the login shell is zsh; this file only matters if you `bash`
# explicitly.
# =============================================================================

# If not running interactively, don't do anything.
case $- in
    *i*) ;;
      *) return;;
esac

# --- History ---
HISTCONTROL=ignoreboth          # no duplicates, no leading-space commands
HISTSIZE=100000
HISTFILESIZE=100000
shopt -s histappend             # append, don't overwrite

# Update LINES/COLUMNS after each command.
shopt -s checkwinsize

# Make less friendly for non-text input files.
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Identify the chroot you work in (used in the prompt below).
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# --- Prompt ---
# Set a fancy prompt if the terminal supports color.
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt

# Set xterm window title.
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

# --- ls / grep colors ---
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# --- Programmable completion ---
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# --- Optional bash aliases file ---
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# --- Shared portable config (env, PATH, aliases, dx/feat/gt) ---
[ -f ~/.shellrc ] && . ~/.shellrc
export PATH=~/.npm-global/bin:$PATH

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
