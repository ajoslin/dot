#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
DRY_RUN=false
HOSTNAME="studio-main"
DISPLAY_SLEEP_MINUTES=30
INITIAL_KEY_REPEAT=20
KEY_REPEAT=1
RUN_OSX=true
RUN_BASELINE=true
RUN_KEY_REPEAT=true
RESUME_FROM=""

usage() {
	cat <<'EOF'
Usage: studio-all-in-one.sh [options]

One-command Studio bootstrap:
  1) Full osx setup (packages/apps/services/defaults)
  2) macOS 24/7 baseline (power/update/remote login/hostname)
  3) key repeat settings via ~/dot/bin/key-repeat

Options:
  --dry-run                  Print actions without executing
  --hostname <name>          Hostname to apply (default: studio-main)
  --display-sleep <minutes>  Display sleep timeout (default: 30)
  --initial-key-repeat <n>   InitialKeyRepeat value (default: 20)
  --key-repeat <n>           KeyRepeat value (default: 1)
  --skip-osx                 Skip osx.sh step
  --skip-baseline            Skip studio-macos-baseline.sh step
  --skip-key-repeat          Skip key-repeat step
  --resume-from <step>       Resume from: osx|baseline|key-repeat
  -h, --help                 Show this help
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

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--dry-run)
			DRY_RUN=true
			;;
		--hostname)
			shift
			HOSTNAME="${1:-}"
			[[ -z "$HOSTNAME" ]] && {
				log "Missing value for --hostname"
				exit 1
			}
			;;
		--display-sleep)
			shift
			DISPLAY_SLEEP_MINUTES="${1:-}"
			[[ -z "$DISPLAY_SLEEP_MINUTES" ]] && {
				log "Missing value for --display-sleep"
				exit 1
			}
			;;
		--initial-key-repeat)
			shift
			INITIAL_KEY_REPEAT="${1:-}"
			[[ -z "$INITIAL_KEY_REPEAT" ]] && {
				log "Missing value for --initial-key-repeat"
				exit 1
			}
			;;
		--key-repeat)
			shift
			KEY_REPEAT="${1:-}"
			[[ -z "$KEY_REPEAT" ]] && {
				log "Missing value for --key-repeat"
				exit 1
			}
			;;
		--skip-osx)
			RUN_OSX=false
			;;
		--skip-baseline)
			RUN_BASELINE=false
			;;
		--skip-key-repeat)
			RUN_KEY_REPEAT=false
			;;
		--resume-from)
			shift
			RESUME_FROM="${1:-}"
			case "$RESUME_FROM" in
			osx)
				RUN_OSX=true
				RUN_BASELINE=true
				RUN_KEY_REPEAT=true
				;;
			baseline)
				RUN_OSX=false
				RUN_BASELINE=true
				RUN_KEY_REPEAT=true
				;;
			key-repeat)
				RUN_OSX=false
				RUN_BASELINE=false
				RUN_KEY_REPEAT=true
				;;
			*)
				log "Unknown --resume-from value: $RESUME_FROM"
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
	parse_args "$@"

	if [[ "$RUN_OSX" == "true" ]]; then
		log "Running full osx setup"
		if [[ "$DRY_RUN" == "true" ]]; then
			run "$HOME/dot/config/osx.sh" --dry-run
		else
			run "$HOME/dot/config/osx.sh"
		fi
	else
		log "Skipping osx setup step"
	fi

	if [[ "$RUN_BASELINE" == "true" ]]; then
		log "Applying Studio macOS baseline"
		if [[ "$DRY_RUN" == "true" ]]; then
			run "$HOME/dot/config/studio-macos-baseline.sh" --dry-run --hostname "$HOSTNAME" --display-sleep "$DISPLAY_SLEEP_MINUTES"
		else
			run "$HOME/dot/config/studio-macos-baseline.sh" --hostname "$HOSTNAME" --display-sleep "$DISPLAY_SLEEP_MINUTES"
		fi
	else
		log "Skipping Studio macOS baseline step"
	fi

	if [[ "$RUN_KEY_REPEAT" == "true" ]]; then
		log "Applying key repeat via ~/dot/bin/key-repeat"
		run "$HOME/dot/bin/key-repeat" "$INITIAL_KEY_REPEAT" "$KEY_REPEAT"
	else
		log "Skipping key repeat step"
	fi

	log "Done"
	log "Next: run 'sudo tailscale up --ssh --hostname $HOSTNAME' if not already joined"
}

main "$@"
