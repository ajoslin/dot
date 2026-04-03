# ~/.zshenv - Environment variables (loaded for ALL shells, including non-interactive)
# This file is symlinked from ~/dot/zshenv

# Homebrew
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
export MINIO_CONFIG_ENV_FILE=/etc/default/minio

# User identity
export EMAIL="andrew@ajoslin.com"
export NAME="Andrew Joslin"

# Common directories
export ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
export BOX="$ICLOUD_DIR/box"
export GOPATH=$HOME/gocode
export RCRC=$HOME/dot/rcrc

# Tools configuration
export EDITOR=nvim
export CFLAGS=-Qunused-arguments
export CPPFLAGS=-Qunused-arguments
export AWS_REGION=us-west-2
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Android/Java
export ANDROID_SDK_ROOT="/Users/andrew/Library/Android/sdk"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

# GCP & other credentials
export GOOGLE_APPLICATION_CREDENTIALS=$HOME/Documents/gcp-auth.json

# Python
export PIP_USER_BASE_PATH="$HOME/Library/Python/3.11/bin"

# Bun
export BUN_INSTALL="$HOME/.bun"

# PATH setup (directories only - will be filtered for existence in .zshrc)
typeset -aU path
path=(
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
  $path
)

# Source secret tokens (not in source control)
[ -f "$HOME/.tokens" ] && source "$HOME/.tokens"
