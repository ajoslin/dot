#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
DRY_RUN=false
DISPLAY_SLEEP_MINUTES=30
ENABLE_REMOTE_LOGIN=true
SET_HOSTNAME=""

usage() {
	cat <<'EOF'
Usage: studio-macos-baseline.sh [options]

Configure a Mac Studio for 24/7 unattended dev/agent workloads.

Options:
  --dry-run                 Print actions without executing
  --display-sleep <minutes> Display sleep timeout (default: 30)
  --skip-remote-login       Do not enable macOS Remote Login (sshd)
  --hostname <name>         Set LocalHostName/HostName/ComputerName
  -h, --help                Show this help

What this script configures:
  - Always-on power profile (no system sleep)
  - Auto-restart after power/freeze events
  - Disable automatic macOS/app update installs/restarts
  - Keep software update checks enabled (manual patching workflow)
  - Disable UI transitions/animations for faster remote usage
  - Clear all pinned Dock apps and remove Dock recents
  - Enable Remote Login for ssh/mosh workflows (optional)
  - Optional hostname normalization
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

sudo_run() {
	if [[ "$DRY_RUN" == "true" ]]; then
		log "DRY-RUN: sudo $*"
	else
		sudo "$@"
	fi
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--dry-run)
			DRY_RUN=true
			;;
		--display-sleep)
			shift
			DISPLAY_SLEEP_MINUTES="${1:-}"
			if [[ -z "$DISPLAY_SLEEP_MINUTES" ]] || ! [[ "$DISPLAY_SLEEP_MINUTES" =~ ^[0-9]+$ ]]; then
				log "--display-sleep requires an integer value"
				exit 1
			fi
			;;
		--skip-remote-login)
			ENABLE_REMOTE_LOGIN=false
			;;
		--hostname)
			shift
			SET_HOSTNAME="${1:-}"
			if [[ -z "$SET_HOSTNAME" ]]; then
				log "--hostname requires a value"
				exit 1
			fi
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

configure_power() {
	log "Configuring always-on power profile"
	sudo_run pmset -a sleep 0
	sudo_run pmset -a displaysleep "$DISPLAY_SLEEP_MINUTES"
	sudo_run pmset -a disksleep 0
	sudo_run pmset -a standby 0
	sudo_run pmset -a autopoweroff 0
	sudo_run pmset -a tcpkeepalive 1
	sudo_run pmset -a autorestart 1
	sudo_run systemsetup -setrestartfreeze on
}

configure_updates() {
	log "Configuring manual-update policy (checks on, auto-install off)"
	sudo_run defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
	sudo_run defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
	sudo_run defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
	sudo_run defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true
	sudo_run defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
	sudo_run defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool false
	sudo_run defaults write /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired -bool false
}

configure_ui() {
	log "Disabling UI transitions/animations and clearing Dock"
	run defaults write com.apple.universalaccess reduceMotion -bool true
	run defaults write com.apple.universalaccess reduceTransparency -bool true
	run defaults write com.apple.dock launchanim -bool false
	run defaults write com.apple.dock autohide-time-modifier -float 0
	run defaults write com.apple.dock autohide-delay -float 0
	run defaults write com.apple.dock expose-animation-duration -float 0
	run defaults write com.apple.dock persistent-apps -array
	run defaults write com.apple.dock persistent-others -array
	run defaults write com.apple.dock show-recents -bool false
	run killall Dock || true
}

configure_remote_login() {
	if [[ "$ENABLE_REMOTE_LOGIN" != "true" ]]; then
		log "Skipping Remote Login changes"
		return
	fi
	log "Enabling Remote Login (sshd)"
	sudo_run systemsetup -setremotelogin on
}

configure_hostname() {
	if [[ -z "$SET_HOSTNAME" ]]; then
		return
	fi
	log "Setting hostname to $SET_HOSTNAME"
	sudo_run scutil --set LocalHostName "$SET_HOSTNAME"
	sudo_run scutil --set HostName "$SET_HOSTNAME"
	sudo_run scutil --set ComputerName "$SET_HOSTNAME"
}

print_verification() {
	log "Verification commands"
	printf '  %s\n' "pmset -g custom"
	printf '  %s\n' "sudo systemsetup -getremotelogin"
	printf '  %s\n' "defaults read /Library/Preferences/com.apple.SoftwareUpdate"
	printf '  %s\n' "defaults read /Library/Preferences/com.apple.commerce"
}

main() {
	parse_args "$@"
	configure_power
	configure_updates
	configure_ui
	configure_remote_login
	configure_hostname
	print_verification
	log "Done"
}

main "$@"
