export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew";
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}";
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
export MINIO_CONFIG_ENV_FILE=/etc/default/minio

if [[ -z $TMUX ]]; then
  tmux attach || tmux new-session -s main
fi

source ~/.zprezto/init.zsh
source ~/.config/z/z.sh

# zstyle ':completion:*:*:git:*' script ~/.config/git-completion.bash

export EMAIL="andrew@ajoslin.com"
export NAME="Andrew Joslin"

export PIP_USER_BASE_PATH=$(python -m site --user-base)

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
export PATH="$HOME/.bin:/usr/local/opt/openssl/bin:/usr/local/bin:/opt/local/bin:$HOME/terraform:$GOPATH/bin:/usr/local/Cellar/logstash/2.3.2/bin:$HOME/.rvm/bin:$PIP_USER_BASE_PATH/bin:$HOME/flutter/bin:$HOME/tools/lua-language-server/bin:$PATH"

export ANDROID_SDK_ROOT="/Users/andrew/Library/Android/sdk"
export ANDROID_HOME=$ANDROID_SDK_ROOT/tools
# export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)

if [ -d "$HOME/Library/Python/3.6/bin/" ] ; then
    PATH="$HOME/Library/Python/3.6/bin/:$PATH"
fi

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
alias FZF_DEFAULT_COMMAND='ag'
alias vi=nvim
alias sheets='open https://sheets.new'
alias gp='git push'
alias gcp='git cherry-pick'
alias grph="echo 'git rev-parse HEAD | pbcopy' && git rev-parse HEAD | pbcopy"

alias clocker="HOME=~/sync/andrew clocker"

setopt CLOBBER
# Disable zsh autocorrect
unsetopt CORRECT

# This file is not in source control
[ -f $HOME/.tokens ] && source ~/.tokens

export PATH="$HOME/.yarn/bin:$PATH"

portgrep () {
  lsof -i :$1
}

export PATH="/usr/local/opt/postgresql@10/bin:$PATH"

export GOOGLE_APPLICATION_CREDENTIALS=$HOME/Documents/gcp-auth.json


. /opt/homebrew/opt/asdf/libexec/asdf.sh


alias luamake=/Users/andrew/tools/lua-language-server/3rd/luamake/luamake

eval "$(direnv hook zsh)"
export PATH="/opt/homebrew/opt/mongodb-community@4.4/bin:$PATH"

# bun completions
[ -s "/Users/andrew/.bun/_bun" ] && source "/Users/andrew/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="/Users/andrew/Library/Android/sdk/platform-tools":$PATH
export PATH="$PATH:/Users/andrew/.foundry/bin"
export PATH="$PATH:/Users/andrew/.cargo/bin"
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/emulator:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH

export ANDROID_HOME="/Users/andrew/Library/Android/sdk"
alias da='direnv allow'
. "$HOME/.cargo/env"

# Created by `pipx` on 2024-03-18 22:11:47
export PATH="$PATH:/Users/andrew/.local/bin"

# Added by Windsurf
export PATH="/Users/andrew/.codeium/windsurf/bin:$PATH"

export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
export PATH=~/.npm-global/bin:$PATH
