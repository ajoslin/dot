# Studio + OpenClaw Checklist

This checklist assumes:
- Host: `studio-main`
- Service user: `openclaw` (standard user, non-admin)
- Network: Tailscale-only ingress for admin/dev access

Quick path (all-in-one):

```bash
~/dot/config/studio-all-in-one.sh --hostname studio-main --initial-key-repeat 20 --key-repeat 1
```

## 1) macOS baseline (first principles)

Run:

```bash
~/dot/config/studio-macos-baseline.sh --hostname studio-main
```

Verify:

```bash
pmset -g custom
sudo systemsetup -getremotelogin
defaults read /Library/Preferences/com.apple.SoftwareUpdate
defaults read /Library/Preferences/com.apple.commerce
```

Expected direction:
- System sleep disabled
- Auto-restart enabled after power/freeze events
- Remote Login enabled (for ssh/mosh)
- Auto-update install/restart disabled (manual maintenance windows)
- Reduce Motion enabled, UI transitions minimized
- Dock fully unpinned (no persistent apps/others)

## 2) Minimal server dependencies

Run:

```bash
~/dot/config/studio-minimal-setup.sh --hostname studio-main
```

Verify:

```bash
brew services list | grep -E 'tailscale|mongodb-community'
tailscale status
tailscale ip -4
```

## 3) Tailscale + remote shell model

On Studio:

```bash
sudo tailscale up --ssh --hostname studio-main
```

On network edge/firewall:
- Allow UDP `60000-61000` for mosh.

Operational rule:
- Use `mosh` for interactive shell.
- Use plain `ssh` when you need port forwarding.

## 4) Dedicated service user hardening

- `openclaw` should be a standard user, not admin.
- Keep personal account separate; do not store personal secrets in `openclaw` profile.
- Enable FileVault.
- Use separate browser/profile if any web auth is required.
- Keep ownership strict under `/Users/openclaw`.

Recommended permissions:

```bash
chmod 700 /Users/openclaw/.openclaw
chmod 600 /Users/openclaw/.openclaw/*
```

## 5) OpenClaw baseline config

Template file:
- `dot/config/openclaw/studio-main.openclaw.jsonc`

Baseline choices:
- Gateway bind on loopback only
- Tailscale serve mode enabled
- Token auth required
- Channel DM policy set to pairing
- Agent sandboxing disabled (`mode: off`) per your trusted-user model
- Elevated tools disabled by default

Before starting OpenClaw:
- Export `OPENCLAW_GATEWAY_TOKEN` with a strong random token.
- Confirm runtime workspace root exists (`/Users/openclaw/dev`).

## 6) OpenClaw operational checks

Run after start and after every reboot:

```bash
openclaw doctor
openclaw status
openclaw gateway status
openclaw logs --follow
openclaw security audit --deep
```

If permissions drift:

```bash
openclaw security audit --fix
```

## 7) Reliability playbook (24/7)

- Wired Ethernet preferred over Wi-Fi.
- Use a UPS.
- Keep a monthly manual patch window (macOS + brew + OpenClaw/Kimaki updates).
- Reboot intentionally after updates, then run section 6 checks.
- Keep LaunchAgent/service logs monitored.

## 8) Optional stronger isolation

Current model is good for trusted workflows under dedicated `openclaw` user.

Add stronger isolation if any untrusted traffic/prompts are expected:
- Re-enable sandbox mode for all agents.
- Split bot channels and OpenClaw into separate service users.
- Restrict channel access with explicit allowlists.
