# Video Sources

Handling different video input types: YouTube, local files, and other URLs.

## Source Detection

```python
import re
from urllib.parse import urlparse

def detect_source_type(source: str) -> str:
    """Detect if source is YouTube, URL, or local file."""

    youtube_patterns = [
        r'youtube\.com/watch\?v=',
        r'youtu\.be/',
        r'youtube\.com/embed/',
        r'youtube\.com/v/',
        r'youtube\.com/shorts/',
    ]

    if any(re.search(p, source) for p in youtube_patterns):
        return "youtube"

    if source.startswith(("http://", "https://")):
        return "url"

    return "local"
```

## YouTube Videos

### Direct Processing (Gemini)

Gemini can process YouTube URLs without downloading:

```python
import google.generativeai as genai

model = genai.GenerativeModel("gemini-3-flash-preview")
response = model.generate_content([
    "Transcribe this video",
    {"video_url": "https://www.youtube.com/watch?v=VIDEO_ID"}
])
```

### Downloading (Other Providers)

For ASR providers or OpenRouter, download first:

```bash
# Install yt-dlp
pip install yt-dlp
# or
brew install yt-dlp
```

```python
import subprocess
import tempfile

def download_youtube(url: str, output_dir: str = None) -> str:
    """Download YouTube video, return path."""

    if output_dir is None:
        output_dir = tempfile.mkdtemp()

    output_template = f"{output_dir}/video.%(ext)s"

    cmd = [
        "yt-dlp",
        "-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best",
        "-o", output_template,
        "--no-playlist",
        url
    ]

    subprocess.run(cmd, check=True, capture_output=True)

    # Find downloaded file
    import os
    for f in os.listdir(output_dir):
        if f.startswith("video."):
            return os.path.join(output_dir, f)

    raise FileNotFoundError("Download failed")
```

### Size-Limited Download

For OpenRouter (needs base64 encoding), limit file size:

```python
def download_youtube_small(url: str, max_mb: int = 50) -> str:
    """Download YouTube video with size limit."""

    output_dir = tempfile.mkdtemp()
    output_template = f"{output_dir}/video.%(ext)s"

    cmd = [
        "yt-dlp",
        "-f", f"best[ext=mp4][filesize<{max_mb}M]/best[ext=mp4]",
        "-o", output_template,
        "--no-playlist",
        url
    ]

    subprocess.run(cmd, check=True, capture_output=True)
    # ... find and return file
```

## Other Video URLs

For non-YouTube URLs (Vimeo, direct links, etc.):

```python
def download_video_url(url: str, output_dir: str) -> str:
    """Download video from URL using yt-dlp."""

    output_template = f"{output_dir}/video.%(ext)s"

    cmd = [
        "yt-dlp",
        "-o", output_template,
        url
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        # Fallback to direct download with requests
        return download_direct(url, output_dir)

    # Find downloaded file
    # ...

def download_direct(url: str, output_dir: str) -> str:
    """Direct download for simple video URLs."""
    import requests
    from urllib.parse import urlparse

    response = requests.get(url, stream=True)
    response.raise_for_status()

    # Get filename from URL or content-disposition
    filename = urlparse(url).path.split("/")[-1] or "video.mp4"
    filepath = os.path.join(output_dir, filename)

    with open(filepath, "wb") as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)

    return filepath
```

## Local Files

### Supported Formats

Most providers support common video formats:
- MP4 (recommended)
- MOV
- AVI
- MKV
- WEBM
- FLV

### Format Conversion

Convert to MP4 if needed:

```python
def convert_to_mp4(input_path: str, output_path: str = None) -> str:
    """Convert video to MP4 format."""

    if output_path is None:
        output_path = input_path.rsplit(".", 1)[0] + ".mp4"

    cmd = [
        "ffmpeg",
        "-i", input_path,
        "-c:v", "libx264",
        "-c:a", "aac",
        "-y",
        output_path
    ]

    subprocess.run(cmd, check=True, capture_output=True)
    return output_path
```

## Audio Extraction

For ASR-only providers:

```python
def extract_audio(video_path: str, output_path: str = None) -> str:
    """Extract audio from video for ASR processing."""

    if output_path is None:
        output_path = video_path.rsplit(".", 1)[0] + ".mp3"

    cmd = [
        "ffmpeg",
        "-i", video_path,
        "-vn",              # No video
        "-ar", "16000",     # 16kHz (optimal for Whisper)
        "-ac", "1",         # Mono
        "-c:a", "libmp3lame",
        "-ab", "128k",
        "-y",
        output_path
    ]

    subprocess.run(cmd, check=True, capture_output=True)
    return output_path
```

## Video Metadata

Get duration and info:

```python
import json
import subprocess

def get_video_info(path: str) -> dict:
    """Get video metadata using ffprobe."""

    cmd = [
        "ffprobe",
        "-v", "error",
        "-show_entries", "format=duration,size:stream=width,height,codec_name",
        "-of", "json",
        path
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    data = json.loads(result.stdout)

    return {
        "duration": float(data["format"].get("duration", 0)),
        "size_bytes": int(data["format"].get("size", 0)),
        "width": data["streams"][0].get("width") if data.get("streams") else None,
        "height": data["streams"][0].get("height") if data.get("streams") else None,
    }
```

## Handling Large Files

For videos > 50MB (OpenRouter limit) or > 1 hour:

```python
def extract_segment(video_path: str, start_sec: float, duration_sec: float, output_path: str) -> str:
    """Extract a segment from video."""

    cmd = [
        "ffmpeg",
        "-i", video_path,
        "-ss", str(start_sec),
        "-t", str(duration_sec),
        "-c", "copy",  # Fast, no re-encoding
        "-y",
        output_path
    ]

    subprocess.run(cmd, check=True, capture_output=True)
    return output_path

def split_video(video_path: str, segment_duration: int = 300) -> list:
    """Split video into segments (default 5 min each)."""

    info = get_video_info(video_path)
    total_duration = info["duration"]

    segments = []
    start = 0
    i = 0

    while start < total_duration:
        output_path = f"{video_path}.part{i}.mp4"
        extract_segment(video_path, start, segment_duration, output_path)
        segments.append(output_path)
        start += segment_duration
        i += 1

    return segments
```
