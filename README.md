## Dotfiles

Current baseline uses:
- zsh + tmux
- rcm (`rcup`) for symlink management
- Homebrew for packages/apps
- Ghostty + Chrome workflow (no iTerm requirement)

## Setup

### 1) Clone

```sh
cd ~
git clone git@github.com:ajoslin/dot --recursive
```

### 2) Bootstrap (general workstation)

```sh
~/dot/config/osx.sh
```

### 2b) Fresh macOS install (recommended order)

```sh
# 1) install apps/tools + dotfiles links
~/dot/config/osx.sh

# 2) apply 24/7 server baseline (Studio)
~/dot/config/studio-macos-baseline.sh --hostname studio-main

# 3) one-command Studio flow (does 1 + 2 + key repeat)
~/dot/config/studio-all-in-one.sh --hostname studio-main --initial-key-repeat 20 --key-repeat 1
```

### 3) Bootstrap (Mac Studio 24/7)

```sh
~/dot/config/studio-all-in-one.sh --hostname studio-main --initial-key-repeat 20 --key-repeat 1
```

### 4) Dotfile symlinks

`osx.sh` now installs `rcm` and runs:

```sh
rcup -d ~/dot
```

### 5) tmux plugins

Inside tmux:

```sh
C-a I
```

## Notes

- OpenClaw + Kimaki are intended to run on the always-on Studio user/session.
- Tailscale is the primary remote access path.
- Use `mosh` for interactive shells and plain `ssh` for port forwarding.
