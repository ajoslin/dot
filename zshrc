# Homebrew
export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew";
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
export MINIO_CONFIG_ENV_FILE=/etc/default/minio

# ============================================================================
# FAST ZSH SETUP - Replacing Zprezto for speed
# ============================================================================

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt EXTENDED_HISTORY          # Write timestamp to history file
setopt INC_APPEND_HISTORY        # Append to history immediately
setopt SHARE_HISTORY             # Share history across sessions
setopt HIST_IGNORE_DUPS          # Don't record duplicates
setopt HIST_FIND_NO_DUPS         # Don't display duplicates in search
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks

# Vi keybindings
bindkey -v
export KEYTIMEOUT=1              # Faster mode switching

# Better completion (optimized for speed)
autoload -Uz compinit
# Skip security check and only regenerate cache once per day
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit -i  # -i skips security check
else
  compinit -C  # -C skips check entirely, uses cache
fi

# Completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case insensitive

# Custom lightweight prompt (matching your "andrew" theme)
setopt PROMPT_SUBST
autoload -Uz vcs_info
precmd() {
  vcs_info
  if [[ -n "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ]]; then
    PROMPT='%F{magenta}[ssh]%f %F{blue}%~${vcs_info_msg_0_} %f'
  else
    PROMPT='%F{blue}%~${vcs_info_msg_0_} %f'
  fi
}
zstyle ':vcs_info:git:*' formats '%F{grey}|%F{yellow}%b%f%F{grey}|%F{red}%u%c%f'
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' stagedstr '+'
PROMPT='%F{blue}%~${vcs_info_msg_0_} %f'

# Fast syntax highlighting (Homebrew package)
if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# History substring search (restore Prezto-style lookback search)
history_substring_search_script=''
for candidate in \
  '/opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh' \
  "${ZDOTDIR:-$HOME}/.zprezto/modules/history-substring-search/external/zsh-history-substring-search.zsh" \
  "$HOME/dot/_archive/2026-02-shell-cleanup/dot-zprezto/modules/history-substring-search/external/zsh-history-substring-search.zsh"; do
  if [[ -r "$candidate" ]]; then
    history_substring_search_script="$candidate"
    break
  fi
done

if [[ -n "$history_substring_search_script" ]]; then
  source "$history_substring_search_script"
  for keymap in emacs viins vicmd; do
    bindkey -M "$keymap" '^[[A' history-substring-search-up
    bindkey -M "$keymap" '^[[B' history-substring-search-down
  done
  bindkey -M emacs '^P' history-substring-search-up
  bindkey -M emacs '^N' history-substring-search-down
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
fi
unset history_substring_search_script

# Z directory jumper
source ~/.config/z/z.sh

# zstyle ':completion:*:*:git:*' script ~/.config/git-completion.bash

export EMAIL="andrew@ajoslin.com"
export NAME="Andrew Joslin"

# Cache Python user base path (was running python on every shell startup)
export PIP_USER_BASE_PATH="$HOME/Library/Python/3.11/bin"

export ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
export BOX="$ICLOUD_DIR/box"
export CFLAGS=-Qunused-arguments
export CPPFLAGS=-Qunused-arguments
export EDITOR=nvim
export RCRC=$HOME/dot/rcrc
export GOPATH=$HOME/gocode
export AWS_REGION=us-west-2
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Android
export ANDROID_SDK_ROOT="/Users/andrew/Library/Android/sdk"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

# Other tools
export GOOGLE_APPLICATION_CREDENTIALS=$HOME/Documents/gcp-auth.json
export BUN_INSTALL="$HOME/.bun"

# Consolidated PATH (active directories only)
typeset -a path_entries new_path
path_entries=(
  "$HOME/.bin"
  "$HOME/.opencode/bin"
  "$HOME/.codeium/windsurf/bin"
  "$HOME/.local/bin"
  "$HOME/.cache/lm-studio/bin"
  "$HOME/.npm-global/bin"
  "$BUN_INSTALL/bin"
  "$HOME/.yarn/bin"
  "$HOME/.cargo/bin"
  "$HOME/.foundry/bin"
  "$PIP_USER_BASE_PATH"
  "$ANDROID_SDK_ROOT/platform-tools"
  "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
  "$ANDROID_SDK_ROOT/emulator"
  "$GOPATH/bin"
  "$HOME/flutter/bin"
  "$HOME/tools/lua-language-server/bin"
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "/usr/local/go/bin"
  "/usr/local/bin"
  "/opt/local/bin"
  "$HOME/.rvm/bin"
)

new_path=()
for p in "${path_entries[@]}"; do
  [[ -d "$p" ]] && new_path+=("$p")
done

path=("${new_path[@]}" "${path[@]}")
typeset -U path

# GPG
# Remember to add `use-agent` to `~/.gnupg/gpg.conf`
# export GPG_TTY=$(tty)
# eval $(gpg-agent --daemon --sh)

alias bp=bundle-phobia
alias tf=terraform
alias subl="/Applications/Sublime\ Text.app/Contents/MacOS/sublime_text"
alias gti=git
alias sll=/opt/homebrew/bin/sl
alias gitd='git daemon --base-path=. --export-all --enable=receive-pack --reuseaddr --informative-errors --verbose'
alias pwine="source $HOME/wine/wine-prefix"
alias FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
alias vi=nvim
alias sheets='open https://sheets.new'
alias gp='git push'
alias gcp='git cherry-pick'
alias grph="echo 'git rev-parse HEAD | pbcopy' && git rev-parse HEAD | pbcopy"

alias opencode='OPENCODE_CACHE_AUDIT=1 OPENCODE_EXPERIMENTAL_CACHE_STABILIZATION=1 OPENCODE_EXPERIMENTAL_CACHE_1H_TTL=1 opencode'
alias oc=opencode
alias occ=opencode --continue

alias clocker="HOME=~/sync/andrew clocker"

setopt CLOBBER
# Disable zsh autocorrect
unsetopt CORRECT

# This file is not in source control
[ -f $HOME/.tokens ] && source ~/.tokens

# Functions
portgrep () {
  lsof -i :$1
}

# Aliases (tool-specific)
alias luamake=/Users/andrew/tools/lua-language-server/3rd/luamake/luamake
alias da='direnv allow'
alias tm=task-master

# Lazy-load asdf (only load when actually using it)
asdf() {
  unfunction asdf
  source /opt/homebrew/opt/asdf/libexec/asdf.sh
  asdf "$@"
}

# Lazy-load direnv (faster startup)
eval "$(direnv hook zsh)"

# Bun completions
[ -s "/Users/andrew/.bun/_bun" ] && source "/Users/andrew/.bun/_bun"

# Detect whether current shell was launched from cmux.
is_inside_cmux() {
  local pid cmd ppid depth

  # Fast-path env markers
  [[ "${TERM_PROGRAM:-}" == "cmux" ]] && return 0
  [[ -n "${CMUX:-}" ]] && return 0

  pid="$PPID"
  depth=0
  while [[ "$pid" == <-> && "$pid" -gt 1 && "$depth" -lt 20 ]]; do
    cmd="$(ps -o comm= -p "$pid" 2>/dev/null)"
    [[ -z "$cmd" ]] && break
    [[ "$cmd" == *cmux* ]] && return 0

    ppid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')"
    [[ "$ppid" != <-> ]] && break
    pid="$ppid"
    depth=$((depth + 1))
  done

  return 1
}

is_cmux_like_terminal() {
  [[ "${TERM_PROGRAM:-}" == "cmux" ]] && return 0
  [[ "${TERM_PROGRAM:-}" == "ghostty" ]] && return 0
  [[ "${TERM:-}" == "xterm-ghostty" ]] && return 0
  [[ "${TERM:-}" == "xterm-ghostty-direct" ]] && return 0
  is_inside_cmux && return 0
  return 1
}

# Auto-attach to tmux (at end after PATH is set)
if [[ -o interactive ]] && [[ -z ${TMUX:-} ]] && ! is_cmux_like_terminal && command -v tmux &> /dev/null; then
  tmux attach || tmux new-session -s main
fi
