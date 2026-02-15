# Output Format

All providers return a consistent JSON structure for easy integration.

## Schema

```json
{
  "provider": "string",
  "capability": "full_video | asr_only",
  "source": {
    "type": "youtube | url | local",
    "path": "string"
  },
  "transcript": [
    {
      "start": 0.0,
      "end": 2.5,
      "text": "Hello and welcome",
      "speaker": "Speaker A"
    }
  ],
  "text": "Full transcript as single string",
  "visual_analysis": {
    "scenes": [
      {
        "start": 0.0,
        "end": 10.0,
        "description": "Speaker at desk with laptop"
      }
    ],
    "on_screen_text": [
      {
        "time": 5.0,
        "text": "Chapter 1: Introduction"
      }
    ],
    "key_moments": [
      {
        "time": 30.0,
        "description": "Product demo begins"
      }
    ]
  },
  "summary": "Brief summary of video content",
  "chapters": [
    {
      "start": 0.0,
      "end": 60.0,
      "headline": "Introduction",
      "summary": "Speaker introduces the topic"
    }
  ],
  "metadata": {
    "duration_seconds": 120.5,
    "language": "en",
    "speakers_detected": 2
  }
}
```

## Field Availability by Provider

| Field | Gemini | OpenRouter | OpenAI | Groq | AssemblyAI | Deepgram | Local |
|-------|--------|------------|--------|------|------------|----------|-------|
| transcript | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| text | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| visual_analysis | ✓ | ✓ | - | - | - | - | - |
| summary | ✓ | ✓ | - | - | ✓* | - | - |
| chapters | - | - | - | - | ✓ | - | - |
| speaker | - | - | - | - | ✓ | ✓ | - |
| language | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

*AssemblyAI provides chapter summaries, not overall summary.

## Usage Examples

### Basic Transcript Access

```python
result = process_video("video.mp4")

# Full text
print(result["text"])

# With timestamps
for segment in result["transcript"]:
    print(f"[{segment['start']:.1f}s] {segment['text']}")
```

### Visual Analysis (Gemini/OpenRouter only)

```python
result = process_video("video.mp4")

if result["capability"] == "full_video":
    # Scene descriptions
    for scene in result.get("visual_analysis", {}).get("scenes", []):
        print(f"[{scene['start']:.0f}s] {scene['description']}")

    # On-screen text
    for text in result.get("visual_analysis", {}).get("on_screen_text", []):
        print(f"[{text['time']:.0f}s] TEXT: {text['text']}")
```

### Speaker Diarization (AssemblyAI/Deepgram)

```python
result = process_video("video.mp4", provider="assemblyai")

for segment in result["transcript"]:
    speaker = segment.get("speaker", "Unknown")
    print(f"{speaker}: {segment['text']}")
```

### Chapters (AssemblyAI)

```python
result = process_video("video.mp4", provider="assemblyai")

for chapter in result.get("chapters", []):
    print(f"\n## {chapter['headline']}")
    print(f"({chapter['start']:.0f}s - {chapter['end']:.0f}s)")
    print(chapter['summary'])
```

## Normalizing Output

Helper function to ensure consistent structure:

```python
def normalize_output(result: dict) -> dict:
    """Ensure all expected fields exist."""
    defaults = {
        "provider": "unknown",
        "capability": "asr_only",
        "source": {"type": "unknown", "path": ""},
        "transcript": [],
        "text": "",
        "visual_analysis": None,
        "summary": None,
        "chapters": [],
        "metadata": {}
    }

    for key, default in defaults.items():
        if key not in result:
            result[key] = default

    return result
```

## Converting Timestamps

```python
def format_timestamp(seconds: float) -> str:
    """Convert seconds to MM:SS or HH:MM:SS."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)

    if hours > 0:
        return f"{hours:02d}:{minutes:02d}:{secs:02d}"
    return f"{minutes:02d}:{secs:02d}"

# Usage
for seg in result["transcript"]:
    ts = format_timestamp(seg["start"])
    print(f"[{ts}] {seg['text']}")
```
