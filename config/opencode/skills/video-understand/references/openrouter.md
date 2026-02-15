# OpenRouter Video Understanding

OpenRouter provides access to Gemini and other multimodal models via an OpenAI-compatible API.

## Setup

```bash
pip install openai
export OPENROUTER_API_KEY="your-api-key"
```

Get API key: https://openrouter.ai/keys

## Available Models

| Model | Capability | Notes |
|-------|------------|-------|
| `google/gemini-3-flash-preview` | Video + Audio | Fast, free tier available |
| `google/gemini-3-pro-preview` | Video + Audio | Higher quality |

## Basic Usage

OpenRouter requires videos to be base64 encoded:

```python
import base64
from openai import OpenAI

client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=os.environ["OPENROUTER_API_KEY"]
)

# Read and encode video
with open("video.mp4", "rb") as f:
    video_b64 = base64.standard_b64encode(f.read()).decode("utf-8")

response = client.chat.completions.create(
    model="google/gemini-3-flash-preview",
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": "Transcribe this video with timestamps."},
            {
                "type": "image_url",
                "image_url": {
                    "url": f"data:video/mp4;base64,{video_b64}"
                }
            }
        ]
    }]
)

print(response.choices[0].message.content)
```

## MIME Types

| Extension | MIME Type |
|-----------|-----------|
| .mp4 | video/mp4 |
| .webm | video/webm |
| .mov | video/quicktime |
| .avi | video/x-msvideo |

## Downloading for OpenRouter

Unlike direct Gemini API, OpenRouter cannot process YouTube URLs directly. Download first:

```python
import subprocess
import tempfile

def download_for_openrouter(url: str) -> str:
    """Download video and return path."""
    with tempfile.NamedTemporaryFile(suffix=".mp4", delete=False) as f:
        output_path = f.name

    subprocess.run([
        "yt-dlp",
        "-f", "best[ext=mp4][filesize<50M]/best[ext=mp4]",
        "-o", output_path,
        url
    ], check=True)

    return output_path
```

## File Size Limits

- Recommended: Under 20MB for reliable processing
- Maximum: ~50MB (depends on model)
- For larger videos: Extract key segments or use Gemini direct

## Cost Optimization

```python
# Use free tier for testing
model = "google/gemini-3-flash-preview"

# For production, consider caching results
import hashlib

def get_cache_key(video_path: str, prompt: str) -> str:
    with open(video_path, "rb") as f:
        video_hash = hashlib.md5(f.read()).hexdigest()[:16]
    prompt_hash = hashlib.md5(prompt.encode()).hexdigest()[:8]
    return f"{video_hash}_{prompt_hash}"
```

## Error Handling

```python
from openai import APIError, RateLimitError

try:
    response = client.chat.completions.create(...)
except RateLimitError:
    # Wait and retry, or switch to paid model
    time.sleep(60)
except APIError as e:
    if "too large" in str(e).lower():
        # Compress video or extract segment
        pass
```

## Headers for Better Routing

```python
client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=os.environ["OPENROUTER_API_KEY"],
    default_headers={
        "HTTP-Referer": "https://your-app.com",  # For rankings
        "X-Title": "Video Understanding App"      # Shows in dashboard
    }
)
```
