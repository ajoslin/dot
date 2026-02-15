#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Check available video understanding providers based on environment variables.
Returns JSON with available providers and recommended choice.
"""

import json
import os
import shutil
import subprocess
import sys


def check_env_var(*vars):
    """Check if any of the given env vars are set and non-empty."""
    for var in vars:
        val = os.environ.get(var, "").strip()
        if val:
            return var
    return None


def check_command(cmd):
    """Check if a command is available in PATH."""
    return shutil.which(cmd) is not None


def check_vertex_ai():
    """Check if Vertex AI credentials are configured."""
    creds_file = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "")
    if creds_file and os.path.isfile(creds_file):
        return True
    # Also check for ADC (Application Default Credentials)
    adc_path = os.path.expanduser("~/.config/gcloud/application_default_credentials.json")
    return os.path.isfile(adc_path)


def check_local_whisper():
    """Check if local Whisper is available."""
    # Check for whisper CLI (openai-whisper)
    if check_command("whisper"):
        return "whisper"
    # Check for whisper.cpp
    if check_command("whisper-cpp") or check_command("main"):
        return "whisper-cpp"
    # Check if whisper module is importable
    try:
        import whisper
        return "whisper-python"
    except ImportError:
        pass
    return None


def get_available_providers():
    """Detect all available providers and their capabilities."""

    providers = {
        "video_understanding": [],  # Can analyze visual + audio
        "asr_only": [],             # Audio transcription only
    }

    capabilities = {}
    env_vars_used = {}

    # === Full Video Understanding Providers ===

    # 1. Gemini (Google AI Studio)
    gemini_key = check_env_var("GEMINI_API_KEY", "GOOGLE_API_KEY")
    if gemini_key:
        providers["video_understanding"].append("gemini")
        capabilities["gemini"] = {
            "visual": True,
            "audio": True,
            "youtube_native": True,  # Can process YouTube URLs directly
            "local_files": True,
            "max_video_length": "1 hour",
            "models": ["gemini-3-flash-preview", "gemini-3-pro-preview", "gemini-2.5-flash"]
        }
        env_vars_used["gemini"] = gemini_key

    # 2. Vertex AI
    if check_vertex_ai():
        providers["video_understanding"].append("vertex")
        capabilities["vertex"] = {
            "visual": True,
            "audio": True,
            "youtube_native": True,
            "local_files": True,
            "max_video_length": "1 hour",
            "models": ["gemini-3-flash-preview", "gemini-3-pro-preview", "gemini-2.5-flash"],
            "note": "Enterprise Google Cloud"
        }
        env_vars_used["vertex"] = "GOOGLE_APPLICATION_CREDENTIALS"

    # 3. OpenRouter (access to Gemini and other models)
    openrouter_key = check_env_var("OPENROUTER_API_KEY")
    if openrouter_key:
        providers["video_understanding"].append("openrouter")
        capabilities["openrouter"] = {
            "visual": True,
            "audio": True,
            "youtube_native": False,  # Need to download first
            "local_files": True,
            "models": ["google/gemini-3-flash-preview", "google/gemini-3-pro-preview"],
            "note": "Routes to Gemini models; video must be base64 encoded"
        }
        env_vars_used["openrouter"] = "OPENROUTER_API_KEY"

    # === ASR-Only Providers ===

    # 4. OpenAI Whisper API
    openai_key = check_env_var("OPENAI_API_KEY")
    if openai_key:
        providers["asr_only"].append("openai")
        capabilities["openai"] = {
            "visual": False,
            "audio": True,
            "youtube_native": False,
            "local_files": True,
            "max_file_size": "25 MB",
            "models": ["whisper-1"],
            "features": ["timestamps", "language_detection"]
        }
        env_vars_used["openai"] = "OPENAI_API_KEY"

    # 5. AssemblyAI
    assemblyai_key = check_env_var("ASSEMBLYAI_API_KEY")
    if assemblyai_key:
        providers["asr_only"].append("assemblyai")
        capabilities["assemblyai"] = {
            "visual": False,
            "audio": True,
            "youtube_native": False,
            "local_files": True,
            "features": ["timestamps", "speaker_diarization", "chapters", "sentiment"],
            "note": "Rich analysis features"
        }
        env_vars_used["assemblyai"] = "ASSEMBLYAI_API_KEY"

    # 6. Deepgram
    deepgram_key = check_env_var("DEEPGRAM_API_KEY")
    if deepgram_key:
        providers["asr_only"].append("deepgram")
        capabilities["deepgram"] = {
            "visual": False,
            "audio": True,
            "youtube_native": False,
            "local_files": True,
            "features": ["timestamps", "speaker_diarization", "smart_format"],
            "note": "Fast and affordable"
        }
        env_vars_used["deepgram"] = "DEEPGRAM_API_KEY"

    # 7. Groq (Whisper)
    groq_key = check_env_var("GROQ_API_KEY")
    if groq_key:
        providers["asr_only"].append("groq")
        capabilities["groq"] = {
            "visual": False,
            "audio": True,
            "youtube_native": False,
            "local_files": True,
            "max_file_size": "25 MB",
            "models": ["whisper-large-v3", "whisper-large-v3-turbo"],
            "note": "Very fast inference"
        }
        env_vars_used["groq"] = "GROQ_API_KEY"

    # 8. Local Whisper
    local_whisper = check_local_whisper()
    if local_whisper:
        providers["asr_only"].append("local")
        capabilities["local"] = {
            "visual": False,
            "audio": True,
            "youtube_native": False,
            "local_files": True,
            "implementation": local_whisper,
            "models": ["tiny", "base", "small", "medium", "large"],
            "note": "No API key needed, runs locally"
        }
        env_vars_used["local"] = None

    # 9. FFMPEG Screenshots (completely free, offline)
    # Requires ffmpeg; local whisper is optional for audio transcription
    if check_command("ffmpeg"):
        providers["video_understanding"].append("ffmpeg")
        capabilities["ffmpeg"] = {
            "visual": True,  # Via extracted frames
            "audio": bool(local_whisper),  # Via local whisper if available
            "youtube_native": False,
            "local_files": True,
            "models": ["scene", "keyframe", "interval"],
            "note": "Free offline option - extracts frames for vision model analysis" +
                    (" + audio transcription" if local_whisper else " (no audio - install whisper for transcription)")
        }
        env_vars_used["ffmpeg"] = None

    # Determine recommended provider
    recommended = None
    if providers["video_understanding"]:
        # Prefer full video understanding
        recommended = providers["video_understanding"][0]
    elif providers["asr_only"]:
        # Fall back to best ASR
        recommended = providers["asr_only"][0]

    # Check helper tools
    tools = {
        "yt-dlp": check_command("yt-dlp"),
        "ffmpeg": check_command("ffmpeg"),
        "ffprobe": check_command("ffprobe"),
    }

    return {
        "video_understanding": providers["video_understanding"],
        "asr_only": providers["asr_only"],
        "all_providers": providers["video_understanding"] + providers["asr_only"],
        "recommended": recommended,
        "capabilities": capabilities,
        "env_vars_used": env_vars_used,
        "tools": tools,
        "tools_missing": [k for k, v in tools.items() if not v],
    }


def main():
    result = get_available_providers()

    # Pretty print if interactive, compact otherwise
    if sys.stdout.isatty():
        print(json.dumps(result, indent=2))
    else:
        print(json.dumps(result))

    # Exit with error if no providers available
    if not result["recommended"]:
        print("\nERROR: No video understanding providers available!", file=sys.stderr)
        print("Set one of these environment variables:", file=sys.stderr)
        print("  - GEMINI_API_KEY (recommended)", file=sys.stderr)
        print("  - OPENROUTER_API_KEY", file=sys.stderr)
        print("  - OPENAI_API_KEY", file=sys.stderr)
        print("  - ASSEMBLYAI_API_KEY", file=sys.stderr)
        print("  - DEEPGRAM_API_KEY", file=sys.stderr)
        print("  - GROQ_API_KEY", file=sys.stderr)
        print("Or install local whisper: pip install openai-whisper", file=sys.stderr)
        sys.exit(1)

    return result


if __name__ == "__main__":
    main()
