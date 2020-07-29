
## Prerequisites

1. [zsh](http://www.zsh.org/).
1. [tmux](http://tmux.sourceforge.net/) for terminal multiplexing.
1. [prezto](https://github.com/sorin-ionescu/prezto) because it's simpler and allegedly faster than oh-my-zsh.
1. [rcm](https://github.com/thoughtbot/rcm#installation) to manage dotfiles.
1. [hammerspoon](http://hammerspoon.org) for window switching hotkeys.
1. [ag](https://github.com/ggreer/the_silver_searcher) for fast file searching.
1. emacs (`brew install emacs`)
1. git

```
brew tap thoughtbot/formulae
brew install the_silver_searcher git emacs node reattach-to-user-namespace vim tmux zsh rcm jo direnv asdf jq fzf
```

https://app-updates.agilebits.com/product_history/CLI


There's also vim in there, for old times' sake.

## Setup

### Dotfiles

```sh
cd ~/
git clone git@github.com:ajoslin/dot --recursive
rcup -d ~/dot -v # on first clone, have to specify dot folder for rcup
```

### Tmux / Zsh

```sh
which zsh | pbcopy
sudo vi /etc/shells
# paste zsh path to bottom of list, exit
chsh -s $(which zsh)
```

```
C-a I # tmux-plugins
```

Start a new terminal, and it should start zsh and tmux. Type `<C-A I>` to install Tmux plugins.
