#!/usr/bin/env bash

set -euo pipefail

echo "[init.sh] This legacy bootstrap has been replaced."
echo "[init.sh] Use one of:"
echo "  ~/dot/config/osx.sh"
echo "  ~/dot/config/studio-all-in-one.sh --hostname studio-main --initial-key-repeat 20 --key-repeat 1"

if [[ "${1:-}" == "--run-osx" ]]; then
	exec "$HOME/dot/config/osx.sh"
fi

if [[ "${1:-}" == "--run-studio" ]]; then
	exec "$HOME/dot/config/studio-all-in-one.sh" --hostname studio-main --initial-key-repeat 20 --key-repeat 1
fi
