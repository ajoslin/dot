# Setup Guide

## Quick Start (5 minutes)

The fastest way to get started is with **OpenRouter** - it's free and gives you full video understanding.

### Step 1: Install Tools

```bash
# macOS
brew install ffmpeg yt-dlp
pip install openai

# Linux (Ubuntu/Debian)
sudo apt install ffmpeg
pip install yt-dlp openai

# Windows
# Install ffmpeg from https://ffmpeg.org/download.html
pip install yt-dlp openai
```

### Step 2: Get OpenRouter API Key (Free)

1. Go to [openrouter.ai/keys](https://openrouter.ai/keys)
2. Sign up (Google/GitHub login available)
3. Click "Create Key"
4. Copy the key

### Step 3: Set API Key

```bash
# Set for current session
export OPENROUTER_API_KEY="sk-or-v1-..."

# Add to shell profile to persist (choose one)
echo 'export OPENROUTER_API_KEY="sk-or-v1-..."' >> ~/.zshrc   # macOS/zsh
echo 'export OPENROUTER_API_KEY="sk-or-v1-..."' >> ~/.bashrc  # Linux/bash
```

### Step 4: Verify

```bash
python3 scripts/setup.py      # Check everything
python3 scripts/check_providers.py  # Should show openrouter
```

---

## API Keys by Provider

### Gemini (Google AI Studio) - Recommended for YouTube

Best for: Direct YouTube URL processing (no download needed)

1. Go to [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
2. Sign in with Google account
3. Click "Create API Key"
4. Set: `export GEMINI_API_KEY="..."`

**Free tier:** Generous limits, direct YouTube support

### OpenRouter - Recommended for Simplicity

Best for: Easy setup, access to multiple models

1. Go to [openrouter.ai/keys](https://openrouter.ai/keys)
2. Create account
3. Generate API key
4. Set: `export OPENROUTER_API_KEY="sk-or-v1-..."`

**Free tier:** Access to Gemini Flash for free

### OpenAI Whisper - Best ASR Quality

Best for: High-quality transcription

1. Go to [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Create account (requires payment method)
3. Generate API key
4. Set: `export OPENAI_API_KEY="sk-..."`

**Cost:** ~$0.006/minute of audio

### Groq Whisper - Fastest ASR

Best for: Speed, free tier

1. Go to [console.groq.com/keys](https://console.groq.com/keys)
2. Create account
3. Generate API key
4. Set: `export GROQ_API_KEY="gsk_..."`

**Free tier:** Very generous limits

### AssemblyAI - Best for Analysis

Best for: Speaker diarization, chapters, sentiment

1. Go to [assemblyai.com/app](https://www.assemblyai.com/app)
2. Create account
3. Copy API key from dashboard
4. Set: `export ASSEMBLYAI_API_KEY="..."`

**Free tier:** Limited hours/month

### Deepgram - Fast & Affordable

Best for: Real-time, cost-effective

1. Go to [console.deepgram.com](https://console.deepgram.com/)
2. Create account
3. Generate API key
4. Set: `export DEEPGRAM_API_KEY="..."`

**Free tier:** $200 credit for new accounts

### Local Whisper - Offline/Free

Best for: Privacy, no API costs

```bash
pip install openai-whisper

# No API key needed!
# Requires: ~1-10GB disk space depending on model
# First run downloads the model
```

---

## Persisting API Keys

### Option 1: Shell Profile (Recommended)

Add to `~/.zshrc` (macOS) or `~/.bashrc` (Linux):

```bash
# Video Understanding API Keys
export OPENROUTER_API_KEY="sk-or-v1-..."
export GEMINI_API_KEY="..."  # Optional
```

Then reload: `source ~/.zshrc`

### Option 2: Environment File

Create `~/.video-understand-env`:

```bash
export OPENROUTER_API_KEY="sk-or-v1-..."
```

Source before use: `source ~/.video-understand-env`

### Option 3: direnv (Per-Project)

Install direnv, create `.envrc` in project:

```bash
export OPENROUTER_API_KEY="sk-or-v1-..."
```

Run `direnv allow`

---

## Troubleshooting

### "No providers available"

Run `python3 scripts/setup.py` to diagnose. Usually means:
- No API key is set, or
- API key env var has wrong name

### "ffmpeg not found"

```bash
# macOS
brew install ffmpeg

# Ubuntu/Debian
sudo apt install ffmpeg

# Windows
# Download from https://ffmpeg.org/download.html
# Add to PATH
```

### "yt-dlp not found"

Only needed for YouTube URLs:

```bash
brew install yt-dlp  # macOS
pip install yt-dlp   # Any platform
```

### "ModuleNotFoundError: No module named 'openai'"

```bash
pip install openai
```

### API rate limits

- Switch to a different provider: `--provider groq`
- Use local Whisper for ASR: `pip install openai-whisper`
- Wait and retry (most limits reset per-minute)

### Large video files

- OpenRouter limit: ~50MB
- OpenAI/Groq Whisper: 25MB audio
- For larger files, use Gemini (1GB) or local Whisper (unlimited)
