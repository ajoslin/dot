#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Setup script for video-understand skill.
Checks dependencies, installs packages, and guides API key setup.
"""

import os
import shutil
import subprocess
import sys

# ANSI colors
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BLUE = "\033[94m"
BOLD = "\033[1m"
RESET = "\033[0m"


def print_status(symbol, color, message):
    print(f"{color}{symbol}{RESET} {message}")


def ok(message):
    print_status("✓", GREEN, message)


def warn(message):
    print_status("!", YELLOW, message)


def error(message):
    print_status("✗", RED, message)


def info(message):
    print_status("→", BLUE, message)


def header(message):
    print(f"\n{BOLD}{message}{RESET}")


def check_command(cmd):
    """Check if a command is available."""
    return shutil.which(cmd) is not None


def check_python_package(package):
    """Check if a Python package is installed."""
    try:
        __import__(package)
        return True
    except ImportError:
        return False


def run_command(cmd, check=True):
    """Run a shell command."""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        return False, result.stderr
    return True, result.stdout


def check_env_var(*vars):
    """Check if any of the env vars are set."""
    for var in vars:
        if os.environ.get(var, "").strip():
            return var
    return None


def main():
    print(f"\n{BOLD}═══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}           Video Understand Skill - Setup{RESET}")
    print(f"{BOLD}═══════════════════════════════════════════════════════════════{RESET}")

    issues = []

    # ═══════════════════════════════════════════════════════════════
    header("1. Checking System Tools")
    # ═══════════════════════════════════════════════════════════════

    # Python
    python_version = sys.version.split()[0]
    if sys.version_info >= (3, 8):
        ok(f"Python {python_version}")
    else:
        error(f"Python {python_version} (3.8+ required)")
        issues.append("python")

    # ffmpeg
    if check_command("ffmpeg"):
        ok("ffmpeg")
    else:
        error("ffmpeg not found")
        info("Install: brew install ffmpeg")
        issues.append("ffmpeg")

    # ffprobe
    if check_command("ffprobe"):
        ok("ffprobe")
    else:
        error("ffprobe not found (usually installed with ffmpeg)")
        issues.append("ffprobe")

    # yt-dlp
    if check_command("yt-dlp"):
        ok("yt-dlp")
    else:
        warn("yt-dlp not found (needed for YouTube URLs)")
        info("Install: brew install yt-dlp  OR  pip install yt-dlp")
        issues.append("yt-dlp")

    # ═══════════════════════════════════════════════════════════════
    header("2. Checking Python Packages")
    # ═══════════════════════════════════════════════════════════════

    packages = {
        "openai": ("OpenRouter / OpenAI Whisper", "pip install openai"),
        "google.generativeai": ("Gemini", "pip install google-generativeai"),
        "groq": ("Groq Whisper", "pip install groq"),
        "assemblyai": ("AssemblyAI", "pip install assemblyai"),
        "deepgram": ("Deepgram", "pip install deepgram-sdk"),
        "whisper": ("Local Whisper", "pip install openai-whisper"),
    }

    installed_packages = []
    for package, (name, install_cmd) in packages.items():
        # Handle submodule imports
        check_pkg = package.split(".")[0]
        if check_python_package(check_pkg):
            ok(f"{name} ({package})")
            installed_packages.append(package)
        else:
            warn(f"{name} not installed")
            info(f"Install: {install_cmd}")

    if not installed_packages:
        error("No provider packages installed!")
        info("Install at least one: pip install openai  (for OpenRouter)")

    # ═══════════════════════════════════════════════════════════════
    header("3. Checking API Keys")
    # ═══════════════════════════════════════════════════════════════

    api_keys = [
        (["GEMINI_API_KEY", "GOOGLE_API_KEY"], "Gemini", "https://aistudio.google.com/apikey"),
        (["OPENROUTER_API_KEY"], "OpenRouter", "https://openrouter.ai/keys"),
        (["OPENAI_API_KEY"], "OpenAI", "https://platform.openai.com/api-keys"),
        (["GROQ_API_KEY"], "Groq", "https://console.groq.com/keys"),
        (["ASSEMBLYAI_API_KEY"], "AssemblyAI", "https://www.assemblyai.com/app"),
        (["DEEPGRAM_API_KEY"], "Deepgram", "https://console.deepgram.com/"),
    ]

    configured_providers = []
    for env_vars, name, url in api_keys:
        found = check_env_var(*env_vars)
        if found:
            ok(f"{name} ({found})")
            configured_providers.append(name)
        else:
            warn(f"{name} not configured")
            info(f"Get key: {url}")
            info(f"Set: export {env_vars[0]}=\"your-key\"")

    # Local Whisper doesn't need API key
    if check_python_package("whisper"):
        ok("Local Whisper (no API key needed)")
        configured_providers.append("Local Whisper")

    # FFMPEG provider (completely free, no API key)
    if check_command("ffmpeg"):
        ok("FFMPEG frames (no API key needed - extracts screenshots + optional whisper)")
        configured_providers.append("FFMPEG")

    if not configured_providers:
        error("No providers configured!")
        print()
        info("Quickest setup - get a free OpenRouter API key:")
        info("  1. Go to https://openrouter.ai/keys")
        info("  2. Create account and generate key")
        info("  3. Run: export OPENROUTER_API_KEY=\"your-key\"")
        info("  4. Add to ~/.zshrc or ~/.bashrc to persist")

    # ═══════════════════════════════════════════════════════════════
    header("4. Summary")
    # ═══════════════════════════════════════════════════════════════

    print()
    if configured_providers and "ffmpeg" not in issues:
        ok(f"Ready to use with: {', '.join(configured_providers)}")
        print()
        info("Test with:")
        info('  python3 process_video.py "https://www.youtube.com/watch?v=jNQXAC9IVRw"')
        print()
    else:
        warn("Setup incomplete - see issues above")
        print()

    # ═══════════════════════════════════════════════════════════════
    header("Quick Setup Commands")
    # ═══════════════════════════════════════════════════════════════

    print("""
# Install system tools (macOS)
brew install ffmpeg yt-dlp

# === Option A: Free offline (no API key) ===
# Just use ffmpeg for frame extraction + optional whisper for audio
pip install openai-whisper  # Optional, for audio transcription

# === Option B: API-based (better quality) ===
# Install Python package for OpenRouter
pip install openai

# Get free API key
open https://openrouter.ai/keys

# Set API key (add to ~/.zshrc to persist)
export OPENROUTER_API_KEY="your-key-here"

# Verify setup
python3 check_providers.py
""")

    return 0 if configured_providers and "ffmpeg" not in issues else 1


if __name__ == "__main__":
    sys.exit(main())
