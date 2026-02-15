# FFMPEG Frame Extraction (Free Offline)

A completely free, offline approach to video understanding using ffmpeg frame extraction + local whisper transcription.

## How It Works

1. **Frame Extraction**: Uses ffmpeg to extract representative frames from the video
2. **Audio Transcription**: Uses local whisper to transcribe the audio track
3. **Output**: Returns frame image paths + transcript for vision model analysis

This approach is designed for use with Claude Code - the extracted frames can be viewed directly by Claude to understand visual content.

## Setup

```bash
# Required
brew install ffmpeg

# For audio transcription
pip install openai-whisper
```

No API keys required.

## Usage

```bash
# Use ffmpeg provider explicitly
python3 scripts/process_video.py video.mp4 --provider ffmpeg

# Choose extraction mode
python3 scripts/process_video.py video.mp4 --provider ffmpeg -m scene     # Scene detection (default)
python3 scripts/process_video.py video.mp4 --provider ffmpeg -m keyframe  # I-frames only (fast)
python3 scripts/process_video.py video.mp4 --provider ffmpeg -m interval  # Regular intervals
```

## Frame Extraction Modes

### `scene` (Default)
Detects scene changes and extracts frames when visual content changes significantly.

**Best for:**
- Videos with distinct scenes/sections
- Presentations, tutorials
- Most general content

**How it works:**
- Uses ffmpeg's scene detection filter
- Threshold: 0.3 (30% frame difference)
- Falls back to interval sampling if too few scenes detected

### `keyframe`
Extracts only I-frames (keyframes) from the video codec.

**Best for:**
- Quick processing of long videos
- When you need speed over completeness

**Trade-offs:**
- Fastest extraction method
- May miss important visual moments between keyframes
- Frame distribution depends on video encoding

### `interval`
Extracts frames at regular time intervals.

**Best for:**
- Consistent, predictable sampling
- Videos with continuous visual changes
- When scene detection doesn't work well

**Default interval:** ~5 seconds or adjusted to get ~30 frames

## Output Format

```json
{
  "provider": "ffmpeg",
  "model": "scene",
  "capability": "frames_with_transcript",
  "frames": [
    {
      "path": "/path/to/video_frames/frames/frame_0000.jpg",
      "timestamp": 0.0,
      "timestamp_formatted": "00:00"
    },
    {
      "path": "/path/to/video_frames/frames/frame_0001.jpg",
      "timestamp": 5.23,
      "timestamp_formatted": "00:05"
    }
  ],
  "frame_count": 25,
  "transcript": [
    {"start": 0.0, "end": 2.5, "text": "Hello and welcome..."}
  ],
  "text": "Full transcript text...",
  "note": "View the frame images to understand visual content."
}
```

## Quality Comparison

| Aspect | FFMPEG Frames | Gemini API |
|--------|---------------|------------|
| Cost | Free | API pricing |
| Offline | Yes | No |
| Motion capture | Poor (snapshots only) | Good |
| Scene transitions | Missed | Captured |
| Static content quality | 80-90% | 100% |
| Audio quality | Same (whisper) | Native |

## Best Use Cases

Works well for:
- Tutorial/educational videos (mostly static visuals)
- Presentations and slides
- Product demos with distinct scenes
- Interviews and talking heads
- Videos where audio carries most information

Less suitable for:
- Fast-paced action content
- Sports and motion-heavy videos
- Content where timing/transitions matter
- Subtle visual details between frames

## Limits

- **Max frames**: 30 by default (configurable in code)
- **Frame resolution (default)**: Downscaled to max 1280px edge (no unnecessary 4k frames)
- **Frame quality (default)**: JPEG `q:v 5` (balanced detail/size)
- **Frame size target (default)**: ~350 KB per image (soft cap via extra optimization pass)
- **Audio**: Depends on local whisper model (base by default)

## Viewing Frames in Claude Code

After processing, Claude can view the extracted frames using the Read tool:

```
The frames have been extracted to: /path/to/video_frames/frames/
- frame_0000.jpg (00:00)
- frame_0001.jpg (00:05)
...

To understand the visual content, I can view these frames directly.
```
