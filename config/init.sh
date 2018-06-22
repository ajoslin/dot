#!/bin/sh

echo "Sign in as sudo, we'll need it..."

# Ask for the administrator password upfront
sudo -v

set -x

echo "-- brew install"
brew update
brew tap thoughtbot/formulae
brew install git node tmux vim the_silver_searcher zsh rcm lua luarocks caius/jo/jo
brew install go --cross-compile-common

mkdir -p $HOME/gocode

echo "-- configure zsh"
sudo bash -c "echo $(which zsh) >> /etc/shells"
chsh -s $(which zsh)

echo "-- Clone dotfiles"
cd $HOME
git clone git@github.com:ajoslin/dot --recursive
rcup -d ~/dot

echo "-- Installing global packages"
npm install -g babel-cli \
  bower \
  browserify-size \
  clocker \
  cordova \
  degree \
  generator-bd \
  github-markdown-preview \
  httpster \
  invoicer \
  ionic \
  ios-deploy \
  ios-sim \
  linklocal \
  n \
  ngrok \
  node-sass \
  nodemon \
  pnpm \
  react-native-cli \
  standard \
  standard-format \
  yo \
  tap-spec \
  tape

echo "-- Installing Mjolnir..."
luarocks install mjolnir.hotkey
luarocks install mjolnir.application

cd ~/Downloads
curl -L -o mjolnir.zip https://github.com/sdegutis/mjolnir/releases/download/0.4.3/Mjolnir-0.4.3.zip
unzip mjolnir.zip
sudo mv Mjolnir.app /Applications/

./osx.sh
