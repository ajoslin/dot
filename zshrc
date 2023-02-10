export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew";
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}";
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";

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

export ANDROID_SDK_ROOT="/usr/local/share/android-sdk"
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
alias sll=/usr/local/Cellar/sl/5.02/bin/sl
alias gitd='git daemon --base-path=. --export-all --enable=receive-pack --reuseaddr --informative-errors --verbose'
alias pwine="source $HOME/wine/wine-prefix"
alias FZF_DEFAULT_COMMAND='ag'
alias vi=nvim

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

alias pod='arch -x86_64 pod'

. /opt/homebrew/opt/asdf/libexec/asdf.sh


alias luamake=/Users/andrew/tools/lua-language-server/3rd/luamake/luamake
