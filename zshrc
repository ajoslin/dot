if [[ -z $TMUX ]]; then
  tmux attach || tmux new-session -s main
fi

source ~/.zprezto/init.zsh
source ~/.config/z/z.sh

zstyle ':completion:*:*:git:*' script ~/.config/git-completion.bash

export EMAIL="andrew@ajoslin.com"
export NAME="Andrew Joslin"

export PIP_USER_BASE_PATH=$(python -m site --user-base)

export ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
export BOX="$ICLOUD_DIR/box"
export TERM=xterm-256color
export CFLAGS=-Qunused-arguments
export CPPFLAGS=-Qunused-arguments
export EDITOR=vim
export RCRC=$HOME/dot/rcrc
export GOPATH=$HOME/gocode
export AWS_REGION=us-west-2
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH="$HOME/.bin:/usr/local/bin:/opt/local/bin:$HOME/terraform:$GOPATH/bin:/usr/local/Cellar/logstash/2.3.2/bin:$HOME/.rvm/bin:$PIP_USER_BASE_PATH/bin:$PATH"

export ANDROID_SDK_ROOT="/usr/local/share/android-sdk"
export ANDROID_HOME=$ANDROID_SDK_ROOT/tools
export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)

if [ -d "$HOME/Library/Python/3.6/bin/" ] ; then
    PATH="$HOME/Library/Python/3.6/bin/:$PATH"
fi

# GPG
# Remember to add `use-agent` to `~/.gnupg/gpg.conf`
# export GPG_TTY=$(tty)
# eval $(gpg-agent --daemon --sh)

alias subl="/Applications/Sublime\ Text.app/Contents/MacOS/Sublime\ Text"
alias gti=git
alias sll=/usr/local/Cellar/sl/5.02/bin/sl
alias gitd='git daemon --base-path=. --export-all --enable=receive-pack --reuseaddr --informative-errors --verbose'
alias pwine="source $HOME/wine/wine-prefix"
alias voobly="pwine Voobly && export STAGING_WRITECOPY=1 && export STAGING_SHARED_MEMORY=1 && wine Voobly.exe"
alias kvoobly="pwine Voobly && wineserver -k"


alias clocker="HOME=~/sync/andrew clocker"

setopt CLOBBER
# Disable zsh autocorrect
unsetopt CORRECT

# added by travis gem
[ -f $HOME/.travis/travis.sh ] && source /Users/andrew/.travis/travis.sh

# This file is not in source control
[ -f $HOME/.tokens ] && source ~/.tokens

export PATH="$HOME/.yarn/bin:$PATH"

vi () {
  FILE=${1:-.}

  # Make sure the socket ID has no slashes, emacs does not like that.
  ls $TMPDIR/emacs$UID | grep -q server || emacs -nw --daemon
  emacsclient -nw $FILE
}

portgrep () {
  lsof -i :$1
}

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[[ -f /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.zsh ]] && . /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.zsh
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[[ -f /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.zsh ]] && . /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.zsh

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/andrew/google-cloud-sdk/path.zsh.inc' ]; then source '/Users/andrew/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/andrew/google-cloud-sdk/completion.zsh.inc' ]; then source '/Users/andrew/google-cloud-sdk/completion.zsh.inc'; fi
