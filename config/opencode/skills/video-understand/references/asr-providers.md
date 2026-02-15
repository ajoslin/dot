# ASR Providers

Audio-only transcription providers. Use when full video understanding isn't available or only transcript is needed.

## Provider Comparison

| Provider | Speed | Quality | Features | Cost |
|----------|-------|---------|----------|------|
| OpenAI Whisper | Medium | High | Timestamps, language detect | $0.006/min |
| Groq Whisper | Very Fast | High | Timestamps | Free tier + pay |
| AssemblyAI | Medium | Very High | Speakers, chapters, sentiment | $0.0025/min |
| Deepgram | Fast | High | Speakers, smart format | $0.0043/min |
| Local Whisper | Slow | High | Offline, free | Free (compute) |

---

## OpenAI Whisper API

```bash
pip install openai
export OPENAI_API_KEY="your-key"
```

```python
from openai import OpenAI

client = OpenAI()

with open("audio.mp3", "rb") as f:
    transcript = client.audio.transcriptions.create(
        model="whisper-1",
        file=f,
        response_format="verbose_json",
        timestamp_granularities=["segment"]
    )

for segment in transcript.segments:
    print(f"[{segment.start:.1f}s] {segment.text}")
```

**Limits:** 25MB max file size, most audio formats supported.

---

## Groq Whisper

Extremely fast inference using Groq's LPU.

```bash
pip install groq
export GROQ_API_KEY="your-key"
```

```python
from groq import Groq

client = Groq()

with open("audio.mp3", "rb") as f:
    transcript = client.audio.transcriptions.create(
        model="whisper-large-v3-turbo",  # or whisper-large-v3
        file=f,
        response_format="verbose_json"
    )

print(transcript.text)
```

**Models:**
- `whisper-large-v3-turbo` - Fastest
- `whisper-large-v3` - Highest quality

---

## AssemblyAI

Best for advanced features like speaker diarization and content analysis.

```bash
pip install assemblyai
export ASSEMBLYAI_API_KEY="your-key"
```

```python
import assemblyai as aai

aai.settings.api_key = os.environ["ASSEMBLYAI_API_KEY"]

config = aai.TranscriptionConfig(
    speaker_labels=True,      # Who said what
    auto_chapters=True,       # Auto-generate chapters
    entity_detection=True,    # Detect names, places, etc.
    sentiment_analysis=True,  # Per-sentence sentiment
)

transcriber = aai.Transcriber()
transcript = transcriber.transcribe("audio.mp3", config=config)

# Speakers
for utterance in transcript.utterances:
    print(f"Speaker {utterance.speaker}: {utterance.text}")

# Chapters
for chapter in transcript.chapters:
    print(f"\n## {chapter.headline}")
    print(chapter.summary)
```

**Unique Features:**
- Speaker diarization (who said what)
- Auto chapters with summaries
- Content safety detection
- PII redaction
- Sentiment analysis

---

## Deepgram

Fast and affordable with good accuracy.

```bash
pip install deepgram-sdk
export DEEPGRAM_API_KEY="your-key"
```

```python
from deepgram import DeepgramClient, PrerecordedOptions

client = DeepgramClient(os.environ["DEEPGRAM_API_KEY"])

with open("audio.mp3", "rb") as f:
    buffer_data = f.read()

options = PrerecordedOptions(
    model="nova-2",
    smart_format=True,  # Punctuation, formatting
    utterances=True,    # Split by speaker turns
    diarize=True,       # Speaker detection
)

response = client.listen.prerecorded.v("1").transcribe_file(
    {"buffer": buffer_data}, options
)

result = response.to_dict()
print(result["results"]["channels"][0]["alternatives"][0]["transcript"])
```

**Models:**
- `nova-2` - Best accuracy (recommended)
- `nova` - Fast, good accuracy
- `enhanced` - Legacy, cheaper

---

## Local Whisper

No API key needed. Runs on your machine.

### Install

```bash
# Python package
pip install openai-whisper

# Or Whisper.cpp (faster, lower memory)
brew install whisper-cpp  # macOS
```

### Python Usage

```python
import whisper

model = whisper.load_model("base")  # tiny, base, small, medium, large
result = model.transcribe("audio.mp3")

print(result["text"])

for segment in result["segments"]:
    print(f"[{segment['start']:.1f}s] {segment['text']}")
```

### CLI Usage

```bash
whisper audio.mp3 --model base --output_format json
```

### Model Sizes

| Model | Size | VRAM | Quality |
|-------|------|------|---------|
| tiny | 39M | ~1GB | Basic |
| base | 74M | ~1GB | Good |
| small | 244M | ~2GB | Better |
| medium | 769M | ~5GB | Great |
| large | 1550M | ~10GB | Best |

---

## Audio Extraction

All ASR providers need audio input. Extract from video:

```bash
# Basic extraction
ffmpeg -i video.mp4 -vn -acodec libmp3lame -ab 128k audio.mp3

# Optimized for Whisper (16kHz mono)
ffmpeg -i video.mp4 -vn -ar 16000 -ac 1 -c:a libmp3lame audio.mp3
```

```python
import subprocess

def extract_audio(video_path: str, output_path: str):
    subprocess.run([
        "ffmpeg", "-i", video_path,
        "-vn",           # No video
        "-ar", "16000",  # 16kHz
        "-ac", "1",      # Mono
        "-c:a", "libmp3lame",
        "-y",            # Overwrite
        output_path
    ], check=True)
```
