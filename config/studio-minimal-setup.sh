#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
DRY_RUN=false
HOSTNAME_OVERRIDE=""
SET_NO_SLEEP=true

usage() {
	cat <<'EOF'
Usage: studio-minimal-setup.sh [options]

Minimal bootstrap for a 24/7 Mac Studio dev server.

Options:
  --dry-run           Print actions without executing
  --hostname NAME     Optional hostname to pass to tailscale up
  --skip-no-sleep     Do not modify pmset sleep settings
  -h, --help          Show this help

What this script does:
  1) Ensures Xcode CLT + Homebrew are present
  2) Installs minimal server tools (tailscale, mosh, tmux, git, gh)
  3) Starts tailscaled as a Homebrew service
  4) Optionally sets no-sleep power settings for always-on usage
  5) Prints tailscale/mosh follow-up commands
EOF
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

require_cmd() {
	command -v "$1" >/dev/null 2>&1
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--dry-run)
			DRY_RUN=true
			;;
		--hostname)
			shift
			HOSTNAME_OVERRIDE="${1:-}"
			if [[ -z "$HOSTNAME_OVERRIDE" ]]; then
				log "Missing value for --hostname"
				exit 1
			fi
			;;
		--skip-no-sleep)
			SET_NO_SLEEP=false
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

ensure_xcode_clt() {
	if xcode-select -p >/dev/null 2>&1; then
		log "Xcode Command Line Tools already installed"
		return
	fi
	log "Installing Xcode Command Line Tools"
	run xcode-select --install
	log "Finish GUI install, then run this script again"
	exit 1
}

ensure_homebrew() {
	if require_cmd brew; then
		log "Homebrew already installed"
		return
	fi
	log "Installing Homebrew"
	run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_formula() {
	local formula="$1"
	if brew list --formula "$formula" >/dev/null 2>&1; then
		log "Formula present: $formula"
	else
		log "Installing formula: $formula"
		run brew install "$formula"
	fi
}

install_core_tools() {
	local formulae=(
		tailscale
		mosh
		tmux
		git
		gh
	)

	local f
	for f in "${formulae[@]}"; do
		install_formula "$f"
	done
}

start_tailscaled() {
	local status
	status="$(brew services list | awk '$1=="tailscale" {print $2}')"
	if [[ "$status" == "started" ]]; then
		log "tailscaled service already started"
		return
	fi
	log "Starting tailscaled service"
	run brew services start tailscale
}

set_power_for_server() {
	if [[ "$SET_NO_SLEEP" != "true" ]]; then
		log "Skipping no-sleep power settings"
		return
	fi

	log "Applying always-on power settings (requires sudo)"
	run sudo pmset -c sleep 0
	run sudo pmset -c displaysleep 30
	run sudo pmset -c disksleep 0
	run sudo systemsetup -setrestartfreeze on
	run sudo pmset -a autorestart 1
}

print_next_steps() {
	local hostname_arg=""
	if [[ -n "$HOSTNAME_OVERRIDE" ]]; then
		hostname_arg=" --hostname ${HOSTNAME_OVERRIDE}"
	fi

	log "Next steps"
	printf '  %s\n' "sudo tailscale up --ssh${hostname_arg}"
	printf '  %s\n' "tailscale status"
	printf '  %s\n' "tailscale ip -4"
	printf '  %s\n' "mosh-note: allow UDP 60000-61000 on upstream firewall/security group"
	printf '  %s\n' "ssh-note: keep using plain ssh when you need port forwarding"
}

main() {
	parse_args "$@"
	ensure_xcode_clt
	ensure_homebrew

	run brew update
	install_core_tools
	start_tailscaled
	set_power_for_server
	run brew cleanup

	print_next_steps
	log "Done"
}

main "$@"
