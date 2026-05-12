#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
DRY_RUN=false
DO_FORMULAE=true
DO_CASKS=true
DO_NPM_GLOBALS=true
DO_BUN_GLOBALS=true
DO_SERVICES=true
DO_DEFAULTS=true

usage() {
	cat <<'EOF'
Usage: osx.sh [options]

Install and configure the macOS setup used in this dotfiles repo.

Options:
  --dry-run         Print actions without executing them
  --only FORMULAE   Run only one section: formulae|casks|npm|bun|services|defaults
  --skip SECTION    Skip a section: formulae|casks|npm|bun|services|defaults
  -h, --help        Show this help text

Examples:
  ./osx.sh
  ./osx.sh --dry-run
  ./osx.sh --only formulae
  ./osx.sh --skip defaults
EOF
}

assert_not_root() {
	if [[ "$EUID" -eq 0 ]]; then
		log "Do not run osx.sh as root. Run it as your normal user."
		exit 1
	fi
}

log() {
	printf '[%s] %s\n' "$SCRIPT_NAME" "$*"
}

run() {
	if [[ "$DRY_RUN" == "true" ]]; then
		log "DRY-RUN: $*"
	else
		"$@"
	fi
}

need_cmd() {
	command -v "$1" >/dev/null 2>&1
}

ensure_xcode_clt() {
	if xcode-select -p >/dev/null 2>&1; then
		log "Xcode Command Line Tools already installed"
		return
	fi
	log "Installing Xcode Command Line Tools"
	run xcode-select --install
	log "Finish the GUI install, then re-run $SCRIPT_NAME"
	exit 1
}

ensure_homebrew() {
	if need_cmd brew; then
		log "Homebrew already installed"
		return
	fi

	log "Installing Homebrew"
	run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

brew_install_formula() {
	local formula="$1"
	if brew list --formula "$formula" >/dev/null 2>&1; then
		log "Formula present: $formula"
		return
	fi
	log "Installing formula: $formula"
	run brew install "$formula"
}

brew_install_cask() {
	local cask="$1"
	if brew list --cask "$cask" >/dev/null 2>&1; then
		log "Cask present: $cask"
		return
	fi
	log "Installing cask: $cask"
	run brew install --cask "$cask"
}

install_formulae() {
	log "Installing CLI formulae"

	run brew tap koekeishiya/formulae
	run brew tap mongodb/brew

	local formulae=(
		git
		gh
		1password-cli
		rcm
		neovim
		tmux
		zsh
		zsh-syntax-highlighting
		zsh-history-substring-search
		direnv
		mosh
		node
		pnpm
		ripgrep
		fd
		fzf
		jq
		yq
		sqlite
		uv
		go
		rustup-init
		openssl
		gnupg
		tailscale
		skhd
		yabai
		mongodb-community
		mongosh
		colima
		docker
		watch
		btop
		tree
	)

	for formula in "${formulae[@]}"; do
		brew_install_formula "$formula"
	done
}

ensure_bun() {
	log "Ensuring bun is installed"

	if need_cmd bun; then
		log "bun already installed"
		return
	fi

	log "Installing bun via official installer"
	run /bin/bash -lc "curl -fsSL https://bun.sh/install | bash"

	# Ensure bun is available in this shell after install.
	export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
	export PATH="$BUN_INSTALL/bin:$PATH"

	if ! need_cmd bun; then
		log "bun install completed but bun is still unavailable in PATH"
		log "Open a new shell or ensure ~/.bun/bin is on PATH"
		exit 1
	fi
}

setup_rcup() {
	log "Configuring rcup (rcm) dotfile symlinks"

	if ! need_cmd rcup; then
		log "rcup not found; skipping rcup setup"
		return
	fi

	local dotdir="${DOTFILES_DIR:-$HOME/dot}"
	if [[ ! -d "$dotdir" ]]; then
		log "Dotfiles directory not found at $dotdir; skipping rcup setup"
		return
	fi

	local rcrc_path="${RCRC:-$HOME/.rcrc}"
	if [[ ! -f "$rcrc_path" ]]; then
		log "rcrc not found at $rcrc_path; skipping rcup setup"
		return
	fi

	run rcup -d "$dotdir"
}

install_casks() {
	log "Installing desktop apps (casks)"

	local casks=(
		1password
		ghostty
		google-chrome
		telegram
		raycast
		hammerspoon
		docker
	)

	for cask in "${casks[@]}"; do
		brew_install_cask "$cask"
	done
}

ensure_symlink() {
	local source_path="$1"
	local target_path="$2"

	if [[ ! -e "$source_path" ]]; then
		return
	fi

	if [[ -L "$target_path" ]]; then
		local current
		current="$(readlink "$target_path")"
		if [[ "$current" == "$source_path" ]]; then
			return
		fi
	fi

	if [[ -e "$target_path" ]] && [[ ! -L "$target_path" ]]; then
		log "Skipping link for $target_path (path exists and is not a symlink)"
		return
	fi

	run ln -sfn "$source_path" "$target_path"
}

setup_legacy_runtime_links() {
	log "Ensuring active runtime links for skhd/yabai/hammerspoon"
	ensure_symlink "$HOME/dot/skhdrc" "$HOME/.skhdrc"
	ensure_symlink "$HOME/dot/yabairc" "$HOME/.yabairc"
	ensure_symlink "$HOME/dot/hammerspoon" "$HOME/.hammerspoon"
}

install_npm_globals() {
	log "Installing global npm tools (under ~/.npm-global)"

	local prefix="${NPM_GLOBAL_PREFIX:-$HOME/.npm-global}"
	run mkdir -p "$prefix"

	local packages=(
		@openai/codex
		@anthropic-ai/claude-code
		@dmmulroy/overseer
		task-master-ai
		opencontrol
		agent-browser
		pnpm
		pretty-ts-errors-markdown
	)

	local pkg
	for pkg in "${packages[@]}"; do
		if npm --prefix "$prefix" ls -g --depth=0 "$pkg" >/dev/null 2>&1; then
			log "npm global present: $pkg"
		else
			log "Installing npm global: $pkg"
			run npm install -g --prefix "$prefix" "$pkg"
		fi
	done
}

install_bun_globals() {
	log "Installing global bun tools (~/.bun/install/global)"

	if ! need_cmd bun; then
		log "bun is not installed; skipping bun globals"
		return
	fi

	local packages=(
		@openai/codex
		@anthropic-ai/claude-code
		kimaki
		opencode-ai
		opensrc
		@opencode-ai/plugin
		task-master-ai
		wrangler
		vercel
		pm2
		convex
		@railway/cli
		@biomejs/biome
		sql-formatter
		prettier-plugin-tailwindcss
	)

	local installed
	installed="$(bun pm ls -g 2>/dev/null || true)"

	local pkg
	for pkg in "${packages[@]}"; do
		if printf '%s\n' "$installed" | grep -Fq -- "$pkg@"; then
			log "bun global present: $pkg"
		else
			log "Installing bun global: $pkg"
			run bun add --global "$pkg"
		fi
	done
}

ensure_brew_service_started() {
	local service="$1"
	local status
	status="$(brew services list | awk -v svc="$service" '$1==svc {print $2}')"

	if [[ "$status" == "started" ]]; then
		log "Service already started: $service"
		return
	fi

	if brew list --formula "$service" >/dev/null 2>&1; then
		log "Starting service: $service"
		run brew services start "$service"
	else
		log "Skipping service (formula missing): $service"
	fi
}

configure_services() {
	log "Ensuring active local services are running"

	local services=(
		mongodb-community
	)

	local svc
	for svc in "${services[@]}"; do
		ensure_brew_service_started "$svc"
	done

	log "Datadog agent is installed as a cask; launch from the app or its installer service wrapper when needed"
}

print_mosh_notes() {
	log "MOSH note: install mosh on both client and server (this script does that via Homebrew)"
	log "MOSH note: allow UDP ports 60000-61000 on the server firewall/security group"
	log "MOSH note: keep using plain ssh when you need port forwarding"
}

apply_macos_defaults() {
	log "Applying focused macOS defaults for coding"

	run defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
	run defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
	run defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
	run defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
	run defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
	run defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
	run defaults write NSGlobalDomain KeyRepeat -int 1
	run defaults write NSGlobalDomain InitialKeyRepeat -int 20
	run defaults write NSGlobalDomain AppleShowAllExtensions -bool true
	run defaults write com.apple.finder _FXSortFoldersFirst -bool true
	run defaults write com.apple.dock autohide -bool true
	run defaults write com.apple.dock show-recents -bool false
	run mkdir -p "$HOME/Desktop/Screenshots"
	run defaults write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"

	run killall Finder || true
	run killall Dock || true
	run killall SystemUIServer || true
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--dry-run)
			DRY_RUN=true
			;;
		--only)
			shift
			DO_FORMULAE=false
			DO_CASKS=false
			DO_NPM_GLOBALS=false
			DO_BUN_GLOBALS=false
			DO_SERVICES=false
			DO_DEFAULTS=false
			case "${1:-}" in
			formulae) DO_FORMULAE=true ;;
			casks) DO_CASKS=true ;;
			npm) DO_NPM_GLOBALS=true ;;
			bun) DO_BUN_GLOBALS=true ;;
			services) DO_SERVICES=true ;;
			defaults) DO_DEFAULTS=true ;;
			*)
				log "Unknown --only target: ${1:-}"
				usage
				exit 1
				;;
			esac
			;;
		--skip)
			shift
			case "${1:-}" in
			formulae) DO_FORMULAE=false ;;
			casks) DO_CASKS=false ;;
			npm) DO_NPM_GLOBALS=false ;;
			bun) DO_BUN_GLOBALS=false ;;
			services) DO_SERVICES=false ;;
			defaults) DO_DEFAULTS=false ;;
			*)
				log "Unknown --skip target: ${1:-}"
				usage
				exit 1
				;;
			esac
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			log "Unknown option: $1"
			usage
			exit 1
			;;
		esac
		shift
	done
}

main() {
	assert_not_root
	parse_args "$@"

	ensure_xcode_clt
	ensure_homebrew

	run brew update

	if [[ "$DO_FORMULAE" == "true" ]]; then install_formulae; fi
	if [[ "$DO_BUN_GLOBALS" == "true" ]]; then ensure_bun; fi
	if [[ "$DO_CASKS" == "true" ]]; then install_casks; fi
	setup_rcup
	setup_legacy_runtime_links
	if [[ "$DO_NPM_GLOBALS" == "true" ]]; then install_npm_globals; fi
	if [[ "$DO_BUN_GLOBALS" == "true" ]]; then install_bun_globals; fi
	if [[ "$DO_SERVICES" == "true" ]]; then configure_services; fi
	if [[ "$DO_DEFAULTS" == "true" ]]; then apply_macos_defaults; fi
	print_mosh_notes

	run brew cleanup
	log "Done"
}

main "$@"
