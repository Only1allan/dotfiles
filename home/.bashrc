# ~/.bashrc — portable Omarchy-style bash for Ubuntu WSL
# Interactive shells only; non-interactive shells keep the inherited environment.
case $- in
  *i*) ;;
  *) return ;;
esac

# History
shopt -s histappend
shopt -s checkwinsize
HISTCONTROL=ignoreboth
HISTSIZE=32768
HISTFILESIZE=32768

# Readline behaviour from Omarchy's inputrc
[ -f "$HOME/.inputrc" ] && bind -f "$HOME/.inputrc"

# Completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi

# Editor and pager
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"
export SUDO_EDITOR="$EDITOR"
export BAT_THEME=ansi
export MANROFFOPT="-c"
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
fi

# Browser: wslview opens the Windows default browser
if command -v wslview >/dev/null 2>&1; then
  export BROWSER="${BROWSER:-wslview}"
fi

# User binaries
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# mise (Node and other tools)
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi

# Prompt
if [[ ${TERM:-} != "dumb" ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
  alias cd="zd"
  zd() {
    if (( $# == 0 )); then
      builtin cd ~ || return
    elif [[ -d $1 ]]; then
      builtin cd "$1" || return
    else
      if ! z "$@"; then
        echo "Error: Directory not found"
        return 1
      fi
      printf "\U000F17A9 "
      pwd
    fi
  }
fi

# fzf
if command -v fzf >/dev/null 2>&1; then
  for f in /usr/share/doc/fzf/examples/key-bindings.bash /usr/share/fzf/key-bindings.bash; do
    if [ -f "$f" ]; then . "$f"; break; fi
  done
  for f in /usr/share/doc/fzf/examples/completion.bash /usr/share/fzf/completion.bash; do
    if [ -f "$f" ]; then . "$f"; break; fi
  done
fi

# Ensure command hashing is off for mise
set +h

# File system
if command -v eza >/dev/null 2>&1; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
else
  alias ls='ls --color=auto'
  alias lsa='ls -a'
fi

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# Tools
alias t='tmux attach || tmux new -s Work'
alias vim='nvim'
alias vi='nvim'
command -v docker >/dev/null 2>&1 && alias d='docker'
command -v opencode >/dev/null 2>&1 && alias c='opencode --auto'
command -v claude >/dev/null 2>&1 && alias cx='printf "\033[2J\033[3J\033[H" && claude --permission-mode auto'
command -v codex >/dev/null 2>&1 && alias cy='codex --approve-for-me'
command -v omarchy-agent >/dev/null 2>&1 && alias a='omarchy-agent --inline'
command -v herdr >/dev/null 2>&1 && alias h='herdr'
command -v rails >/dev/null 2>&1 && alias r='rails'
command -v mise >/dev/null 2>&1 && alias mup='MISE_MINIMUM_RELEASE_AGE=0 mise up'

n() { if [ "$#" -eq 0 ]; then command nvim .; else command nvim "$@"; fi; }

if command -v wslview >/dev/null 2>&1; then
  open() ( wslview "$@" >/dev/null 2>&1 & )
fi

if command -v bat >/dev/null 2>&1; then
  BAT_CMD=bat
elif command -v batcat >/dev/null 2>&1; then
  BAT_CMD=batcat
fi
if [ -n "${BAT_CMD:-}" ]; then
  ff() { fzf --preview "$BAT_CMD --style=numbers --color=always {}"; }
  eff() { "$EDITOR" "$(ff)"; }
fi
