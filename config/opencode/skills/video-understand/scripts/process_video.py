#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Main video processing script with automatic provider selection.
Handles YouTube URLs, local files, and other video URLs.

Features:
- Multi-provider support with automatic fallback
- Model selection per provider
- Robust path handling (macOS special characters, unicode, etc.)
- Progress output and verbose mode
- File size warnings for API limits
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unicodedata
from pathlib import Path
from urllib.parse import urlparse

# Import provider check
from check_providers import get_available_providers

# === Default Models ===
DEFAULT_MODELS = {
    "gemini": "gemini-3-flash-preview",      # Latest model
    "vertex": "gemini-3-flash-preview",      # Latest model
    "openrouter": "google/gemini-3-flash-preview",  # Latest via OpenRouter (note: google/ prefix)
    "openai": "whisper-1",
    "groq": "whisper-large-v3-turbo",
    "assemblyai": "best",  # AssemblyAI auto-selects
    "deepgram": "nova-2",
    "local": "base",
    "ffmpeg": "scene",  # Frame extraction mode: scene detection
}

# === Available Models ===
AVAILABLE_MODELS = {
    "gemini": ["gemini-3-flash-preview", "gemini-3-pro-preview", "gemini-2.5-flash", "gemini-2.5-pro"],
    "vertex": ["gemini-3-flash-preview", "gemini-3-pro-preview", "gemini-2.5-flash", "gemini-2.5-pro"],
    "openrouter": [
        "google/gemini-3-flash-preview",
        "google/gemini-3-pro-preview",
    ],
    "openai": ["whisper-1"],
    "groq": ["whisper-large-v3", "whisper-large-v3-turbo"],
    "assemblyai": ["best", "nano"],
    "deepgram": ["nova-2", "nova", "enhanced", "base"],
    "local": ["tiny", "base", "small", "medium", "large", "large-v3"],
    "ffmpeg": ["scene", "keyframe", "interval"],  # Frame extraction modes
}

# File size limits (in MB)
FILE_SIZE_LIMITS = {
    "openrouter": 50,  # Base64 encoding limit
    "openai": 25,      # Whisper API limit
    "groq": 25,        # Whisper API limit
}

# Frame extraction defaults (for ffmpeg provider)
# Keeps images readable while avoiding huge 4k screenshots.
FRAME_DEFAULTS = {
    "max_dimension": 1280,   # Max width/height for extracted frames
    "jpeg_quality": 5,       # ffmpeg q:v (2 is near-lossless; 5 is much smaller)
    "max_size_kb": 350,      # Soft per-frame size ceiling
    "min_dimension": 640,    # Never downscale below this max edge during optimization
    "max_passes": 3,
}


def log(msg: str, verbose: bool = True):
    """Print status message to stderr."""
    if verbose:
        print(f"[video-understand] {msg}", file=sys.stderr)


def normalize_path(path: str) -> str:
    """
    Normalize a file path to handle macOS special characters, unicode, etc.

    Handles:
    - Unicode normalization (NFD -> NFC for macOS)
    - Tilde expansion (~)
    - Symlink resolution
    - Relative to absolute path conversion
    """
    if not path:
        return path

    # Expand user home directory
    path = os.path.expanduser(path)

    # Normalize unicode (macOS uses NFD, most systems expect NFC)
    path = unicodedata.normalize("NFC", path)

    # Convert to absolute path
    path = os.path.abspath(path)

    # Try to resolve the path (follows symlinks, normalizes case on case-insensitive FS)
    try:
        resolved = Path(path).resolve()
        if resolved.exists():
            return str(resolved)
    except (OSError, ValueError):
        pass

    return path


def normalize_whitespace(s: str) -> str:
    """Normalize all whitespace variants to regular spaces."""
    import re
    # Replace various Unicode whitespace characters with regular space
    # This handles: \u202f (narrow no-break space), \u00a0 (no-break space), etc.
    return re.sub(r'[\s\u00a0\u202f\u2007\u2008\u2009\u200a\u200b]+', ' ', s)


def find_file_fuzzy(path: str) -> str:
    """
    Try to find a file even if the exact path doesn't match.
    Handles macOS filename encoding issues including:
    - Unicode normalization (NFD vs NFC)
    - Special whitespace characters (narrow no-break space, etc.)
    - Case-insensitive matching
    """
    # First try the normalized path
    normalized = normalize_path(path)
    if os.path.isfile(normalized):
        return normalized

    # Try the original path
    if os.path.isfile(path):
        return path

    # If the file doesn't exist, try to find it in the parent directory
    parent = os.path.dirname(normalized) or "."
    basename = os.path.basename(normalized)

    if not os.path.isdir(parent):
        return normalized  # Can't search, return as-is

    # Normalize for comparison
    basename_nfc = unicodedata.normalize("NFC", basename)
    basename_nfd = unicodedata.normalize("NFD", basename)
    basename_ws = normalize_whitespace(basename_nfc)

    for entry in os.listdir(parent):
        entry_nfc = unicodedata.normalize("NFC", entry)
        entry_nfd = unicodedata.normalize("NFD", entry)
        entry_ws = normalize_whitespace(entry_nfc)

        # Exact match with unicode normalization
        if entry_nfc == basename_nfc or entry_nfd == basename_nfd:
            return os.path.join(parent, entry)

        # Match with whitespace normalization (handles \u202f, \u00a0, etc.)
        if entry_ws == basename_ws:
            return os.path.join(parent, entry)

        # Case-insensitive match
        if entry_nfc.lower() == basename_nfc.lower():
            return os.path.join(parent, entry)

        # Case-insensitive with whitespace normalization
        if entry_ws.lower() == basename_ws.lower():
            return os.path.join(parent, entry)

    return normalized


def is_youtube_url(url: str) -> bool:
    """Check if URL is a YouTube video."""
    patterns = [
        r'(youtube\.com/watch\?v=)',
        r'(youtu\.be/)',
        r'(youtube\.com/embed/)',
        r'(youtube\.com/v/)',
        r'(youtube\.com/shorts/)',
    ]
    return any(re.search(p, url) for p in patterns)


def get_file_size_mb(path: str) -> float:
    """Get file size in megabytes."""
    return os.path.getsize(path) / (1024 * 1024)


def download_video(url: str, output_dir: str, max_size_mb: int = None, verbose: bool = True) -> str:
    """Download video using yt-dlp."""
    log(f"Downloading video from: {url}", verbose)

    output_path = os.path.join(output_dir, "video.%(ext)s")

    # Build format string based on size limit
    if max_size_mb:
        format_str = f"best[ext=mp4][filesize<{max_size_mb}M]/best[ext=mp4][filesize<{max_size_mb * 2}M]/best"
    else:
        format_str = "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"

    cmd = [
        "yt-dlp",
        "-f", format_str,
        "-o", output_path,
        "--no-playlist",
        url
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"yt-dlp failed: {result.stderr}")

    # Find the downloaded file
    for f in os.listdir(output_dir):
        if f.startswith("video."):
            full_path = os.path.join(output_dir, f)
            size_mb = get_file_size_mb(full_path)
            log(f"Downloaded: {f} ({size_mb:.1f} MB)", verbose)
            return full_path

    raise FileNotFoundError("Downloaded video not found")


def convert_to_mp4(input_path: str, output_dir: str, verbose: bool = True) -> str:
    """Convert video to MP4 format if needed."""
    ext = Path(input_path).suffix.lower()

    # These formats are generally well-supported
    supported = {".mp4", ".mov", ".webm", ".m4v"}

    if ext in supported:
        return input_path

    log(f"Converting {ext} to MP4...", verbose)
    output_path = os.path.join(output_dir, "converted.mp4")

    cmd = [
        "ffmpeg", "-i", input_path,
        "-c:v", "libx264",
        "-c:a", "aac",
        "-y",
        output_path
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        log(f"Conversion failed, using original: {result.stderr[:200]}", verbose)
        return input_path

    return output_path


def compress_video(input_path: str, output_dir: str, target_size_mb: int = 40, verbose: bool = True) -> str:
    """
    Compress video to fit within size limits.

    Uses ffmpeg to reduce resolution and bitrate while maintaining quality.
    Target size is set slightly below limit to account for base64 overhead.
    """
    current_size = get_file_size_mb(input_path)

    if current_size <= target_size_mb:
        return input_path

    log(f"Compressing video ({current_size:.1f} MB → target {target_size_mb} MB)...", verbose)

    output_path = os.path.join(output_dir, "compressed.mp4")

    # Get video duration for bitrate calculation
    duration_cmd = [
        "ffprobe", "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1",
        input_path
    ]
    result = subprocess.run(duration_cmd, capture_output=True, text=True)

    try:
        duration = float(result.stdout.strip())
    except (ValueError, AttributeError):
        duration = 120  # Default assumption

    # Calculate target bitrate (in kbps)
    # target_size_mb * 8 * 1024 / duration = kbps, with 90% for video, 10% for audio
    target_total_bitrate = int((target_size_mb * 8 * 1024) / duration * 0.9)
    video_bitrate = max(200, min(target_total_bitrate - 64, 2000))  # 200-2000 kbps for video
    audio_bitrate = 64  # 64 kbps for audio

    # Determine scale based on compression ratio needed
    compression_ratio = current_size / target_size_mb
    if compression_ratio > 10:
        scale = "480:-2"  # Very aggressive - 480p
    elif compression_ratio > 5:
        scale = "640:-2"  # Aggressive - 640p
    elif compression_ratio > 2:
        scale = "854:-2"  # Moderate - 480p
    else:
        scale = "1280:-2"  # Light - 720p

    cmd = [
        "ffmpeg", "-i", input_path,
        "-vf", f"scale={scale}",
        "-c:v", "libx264",
        "-b:v", f"{video_bitrate}k",
        "-maxrate", f"{video_bitrate * 2}k",
        "-bufsize", f"{video_bitrate * 2}k",
        "-preset", "fast",
        "-c:a", "aac",
        "-b:a", f"{audio_bitrate}k",
        "-y",
        output_path
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        log(f"Compression failed: {result.stderr[:200]}", verbose)
        return input_path

    new_size = get_file_size_mb(output_path)
    log(f"Compressed: {current_size:.1f} MB → {new_size:.1f} MB", verbose)

    # If still too large, try again with more aggressive settings
    if new_size > target_size_mb:
        log("Still too large, applying more aggressive compression...", verbose)
        output_path2 = os.path.join(output_dir, "compressed2.mp4")
        cmd = [
            "ffmpeg", "-i", output_path,
            "-vf", "scale=480:-2",
            "-c:v", "libx264",
            "-crf", "32",
            "-preset", "fast",
            "-c:a", "aac",
            "-b:a", "48k",
            "-y",
            output_path2
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            final_size = get_file_size_mb(output_path2)
            log(f"Final size: {final_size:.1f} MB", verbose)
            return output_path2

    return output_path


def extract_audio(video_path: str, output_dir: str, verbose: bool = True) -> str:
    """Extract audio from video using ffmpeg."""
    log("Extracting audio...", verbose)

    audio_path = os.path.join(output_dir, "audio.mp3")
    cmd = [
        "ffmpeg", "-i", video_path,
        "-vn",           # No video
        "-acodec", "libmp3lame",
        "-ab", "128k",
        "-ar", "16000",  # 16kHz for Whisper
        "-y",            # Overwrite
        audio_path
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"Audio extraction failed: {result.stderr}")

    return audio_path


def get_video_info(path: str) -> dict:
    """Get video metadata using ffprobe."""
    cmd = [
        "ffprobe", "-v", "error",
        "-show_entries", "format=duration,size:stream=width,height",
        "-of", "json",
        path
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        return {}

    try:
        data = json.loads(result.stdout)
        return {
            "duration_seconds": float(data.get("format", {}).get("duration", 0)),
            "size_bytes": int(data.get("format", {}).get("size", 0)),
        }
    except (json.JSONDecodeError, KeyError, ValueError):
        return {}


def get_media_dimensions(path: str) -> tuple:
    """Get width and height for a video/image using ffprobe."""
    cmd = [
        "ffprobe", "-v", "error",
        "-select_streams", "v:0",
        "-show_entries", "stream=width,height",
        "-of", "csv=p=0:s=x",
        path,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        return None, None

    raw = result.stdout.strip()
    if "x" not in raw:
        return None, None

    try:
        width_str, height_str = raw.split("x", 1)
        return int(width_str), int(height_str)
    except (ValueError, TypeError):
        return None, None


def optimize_frame_image(
    frame_path: str,
    max_dimension: int,
    jpeg_quality: int,
    max_size_kb: int,
    min_dimension: int,
    max_passes: int,
    verbose: bool = True,
) -> dict:
    """Downscale/re-encode a frame image to keep storage and token usage reasonable."""
    if not os.path.exists(frame_path):
        return {
            "optimized": False,
            "size_before_kb": 0.0,
            "size_after_kb": 0.0,
        }

    size_before_kb = os.path.getsize(frame_path) / 1024.0
    width, height = get_media_dimensions(frame_path)
    current_max_edge = max(width, height) if width and height else max_dimension
    target_dimension = min(max_dimension, current_max_edge)
    quality = max(2, min(31, int(jpeg_quality)))

    # If already within limits, keep as-is.
    if size_before_kb <= max_size_kb and current_max_edge <= max_dimension:
        return {
            "optimized": False,
            "size_before_kb": round(size_before_kb, 2),
            "size_after_kb": round(size_before_kb, 2),
        }

    temp_path = f"{frame_path}.tmp.jpg"

    for attempt in range(max_passes):
        scale_filter = (
            f"scale='min({target_dimension},iw)':'min({target_dimension},ih)':"
            "force_original_aspect_ratio=decrease"
        )
        cmd = [
            "ffmpeg", "-i", frame_path,
            "-vf", scale_filter,
            "-q:v", str(quality),
            "-frames:v", "1",
            "-y",
            temp_path,
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0 or not os.path.exists(temp_path):
            break

        shutil.move(temp_path, frame_path)
        size_after_kb = os.path.getsize(frame_path) / 1024.0
        out_w, out_h = get_media_dimensions(frame_path)
        max_edge_after = max(out_w, out_h) if out_w and out_h else target_dimension

        if size_after_kb <= max_size_kb:
            break

        if max_edge_after <= min_dimension:
            break

        target_dimension = max(min_dimension, int(target_dimension * 0.8))
        quality = min(31, quality + 2)

    size_after_kb = os.path.getsize(frame_path) / 1024.0

    if size_after_kb < size_before_kb and verbose:
        log(
            f"Optimized frame {os.path.basename(frame_path)}: "
            f"{size_before_kb:.0f}KB -> {size_after_kb:.0f}KB",
            verbose,
        )

    return {
        "optimized": size_after_kb < size_before_kb,
        "size_before_kb": round(size_before_kb, 2),
        "size_after_kb": round(size_after_kb, 2),
    }


def extract_frames(
    video_path: str,
    output_dir: str,
    mode: str = "scene",
    max_frames: int = 30,
    interval_seconds: float = 5.0,
    scene_threshold: float = 0.3,
    frame_max_dimension: int = FRAME_DEFAULTS["max_dimension"],
    frame_jpeg_quality: int = FRAME_DEFAULTS["jpeg_quality"],
    frame_max_size_kb: int = FRAME_DEFAULTS["max_size_kb"],
    verbose: bool = True
) -> list:
    """
    Extract representative frames from a video using ffmpeg.

    Args:
        video_path: Path to the video file
        output_dir: Directory to save extracted frames
        mode: Extraction mode - "scene" (scene detection), "keyframe" (I-frames), "interval" (regular intervals)
        max_frames: Maximum number of frames to extract
        interval_seconds: Interval between frames for "interval" mode
        scene_threshold: Scene change detection threshold (0-1, lower = more sensitive)
        verbose: Print progress messages

    Returns:
        List of dicts with frame info: [{"path": "...", "timestamp": 0.0}, ...]
    """
    log(f"Extracting frames (mode: {mode})...", verbose)

    # Get video duration for calculations
    info = get_video_info(video_path)
    duration = info.get("duration_seconds", 60)

    frames_dir = os.path.join(output_dir, "frames")
    os.makedirs(frames_dir, exist_ok=True)

    scale_filter = (
        f"scale='min({frame_max_dimension},iw)':'min({frame_max_dimension},ih)':"
        "force_original_aspect_ratio=decrease"
    )

    if mode == "scene":
        # Scene detection: extract frames when scene changes significantly
        # First pass: detect scene changes and get timestamps
        detect_cmd = [
            "ffmpeg", "-i", video_path,
            "-vf", f"select='gt(scene,{scene_threshold})',showinfo",
            "-vsync", "vfr",
            "-f", "null", "-"
        ]

        result = subprocess.run(detect_cmd, capture_output=True, text=True)

        # Parse timestamps from showinfo output
        timestamps = [0.0]  # Always include first frame
        for line in result.stderr.split('\n'):
            if 'pts_time:' in line:
                try:
                    pts_match = re.search(r'pts_time:(\d+\.?\d*)', line)
                    if pts_match:
                        ts = float(pts_match.group(1))
                        # Avoid frames too close together (< 1 second apart)
                        if not timestamps or ts - timestamps[-1] >= 1.0:
                            timestamps.append(ts)
                except (ValueError, AttributeError):
                    pass

        # If scene detection found too few frames, fall back to interval
        if len(timestamps) < 5:
            log(f"Scene detection found only {len(timestamps)} frames, adding interval samples...", verbose)
            interval = duration / (max_frames + 1)
            for i in range(1, max_frames + 1):
                ts = i * interval
                if ts < duration and ts not in timestamps:
                    timestamps.append(ts)
            timestamps = sorted(set(timestamps))

        # Limit to max_frames
        if len(timestamps) > max_frames:
            # Keep evenly distributed frames
            step = len(timestamps) / max_frames
            timestamps = [timestamps[int(i * step)] for i in range(max_frames)]

        # Extract frames at detected timestamps
        frames = []
        for i, ts in enumerate(timestamps[:max_frames]):
            output_path = os.path.join(frames_dir, f"frame_{i:04d}.jpg")
            cmd = [
                "ffmpeg", "-ss", str(ts),
                "-i", video_path,
                "-vframes", "1",
                "-vf", scale_filter,
                "-q:v", str(frame_jpeg_quality),
                "-y",
                output_path
            ]
            subprocess.run(cmd, capture_output=True)
            if os.path.exists(output_path):
                frames.append({"path": output_path, "timestamp": round(ts, 2)})

    elif mode == "keyframe":
        # Extract I-frames (keyframes) only - very fast
        cmd = [
            "ffmpeg", "-i", video_path,
            "-vf", f"select='eq(pict_type,I)',{scale_filter}",
            "-vsync", "vfr",
            "-q:v", str(frame_jpeg_quality),
            "-frames:v", str(max_frames),
            os.path.join(frames_dir, "frame_%04d.jpg")
        ]

        subprocess.run(cmd, capture_output=True)

        # Get timestamps for extracted frames using ffprobe
        frames = []
        for f in sorted(os.listdir(frames_dir)):
            if f.endswith('.jpg'):
                frame_path = os.path.join(frames_dir, f)
                frame_num = int(re.search(r'(\d+)', f).group(1)) - 1
                # Estimate timestamp (keyframes are typically every 2-5 seconds)
                estimated_ts = frame_num * (duration / max(len(os.listdir(frames_dir)), 1))
                frames.append({"path": frame_path, "timestamp": round(estimated_ts, 2)})

    elif mode == "interval":
        # Extract frames at regular intervals
        # Calculate interval to get approximately max_frames
        actual_interval = max(interval_seconds, duration / max_frames)

        cmd = [
            "ffmpeg", "-i", video_path,
            "-vf", f"fps=1/{actual_interval},{scale_filter}",
            "-q:v", str(frame_jpeg_quality),
            "-frames:v", str(max_frames),
            os.path.join(frames_dir, "frame_%04d.jpg")
        ]

        subprocess.run(cmd, capture_output=True)

        frames = []
        for i, f in enumerate(sorted(os.listdir(frames_dir))):
            if f.endswith('.jpg'):
                frame_path = os.path.join(frames_dir, f)
                ts = i * actual_interval
                frames.append({"path": frame_path, "timestamp": round(ts, 2)})

    else:
        raise ValueError(f"Unknown extraction mode: {mode}. Use 'scene', 'keyframe', or 'interval'.")

    optimized_count = 0
    total_before_kb = 0.0
    total_after_kb = 0.0
    for frame in frames:
        opt = optimize_frame_image(
            frame_path=frame["path"],
            max_dimension=frame_max_dimension,
            jpeg_quality=frame_jpeg_quality,
            max_size_kb=frame_max_size_kb,
            min_dimension=FRAME_DEFAULTS["min_dimension"],
            max_passes=FRAME_DEFAULTS["max_passes"],
            verbose=verbose,
        )
        total_before_kb += opt["size_before_kb"]
        total_after_kb += opt["size_after_kb"]
        if opt["optimized"]:
            optimized_count += 1

    if total_after_kb and verbose:
        log(
            f"Frame storage: {total_before_kb / 1024:.1f}MB -> {total_after_kb / 1024:.1f}MB "
            f"({optimized_count}/{len(frames)} optimized)",
            verbose,
        )

    log(f"Extracted {len(frames)} frames", verbose)
    return frames


def check_whisper_available() -> bool:
    """Check if local whisper is available."""
    if shutil.which("whisper"):
        return True
    try:
        import whisper
        return True
    except ImportError:
        return False


def process_with_ffmpeg(
    video_path: str,
    output_dir: str,
    mode: str = "scene",
    max_frames: int = 30,
    whisper_model: str = "base",
    verbose: bool = True
) -> dict:
    """
    Process video using ffmpeg frame extraction + optional local whisper.

    This is a completely free, offline approach:
    1. Extract representative frames using ffmpeg
    2. Optionally transcribe audio using local whisper (if available)
    3. Return frame paths + transcript for vision model analysis

    Args:
        video_path: Path to the video file
        output_dir: Directory for output files (frames will be saved here)
        mode: Frame extraction mode (scene/keyframe/interval)
        max_frames: Maximum number of frames to extract
        whisper_model: Local whisper model to use for transcription
        verbose: Print progress messages

    Returns:
        dict with frames, transcript, and metadata
    """
    has_whisper = check_whisper_available()
    log(f"Processing with FFMPEG (mode: {mode}, whisper: {'yes' if has_whisper else 'no'})...", verbose)

    # Extract frames
    frames = extract_frames(
        video_path,
        output_dir,
        mode=mode,
        max_frames=max_frames,
        verbose=verbose
    )

    # Build frame descriptions with timestamps
    frame_info = []
    for frame in frames:
        ts = frame["timestamp"]
        # Format timestamp as MM:SS
        mins = int(ts // 60)
        secs = int(ts % 60)
        frame_info.append({
            "path": frame["path"],
            "timestamp": ts,
            "timestamp_formatted": f"{mins:02d}:{secs:02d}"
        })

    result = {
        "provider": "ffmpeg",
        "model": mode,
        "frames": frame_info,
        "frame_count": len(frame_info),
        "frame_defaults": {
            "max_dimension": FRAME_DEFAULTS["max_dimension"],
            "jpeg_quality": FRAME_DEFAULTS["jpeg_quality"],
            "max_size_kb": FRAME_DEFAULTS["max_size_kb"],
        },
    }

    # Try to transcribe audio if whisper is available
    if has_whisper:
        try:
            audio_path = extract_audio(video_path, output_dir, verbose=verbose)
            transcript_result = process_with_local_whisper(audio_path, model=whisper_model, verbose=verbose)
            result.update({
                "capability": "frames_with_transcript",
                "transcript": transcript_result.get("transcript", []),
                "text": transcript_result.get("text", ""),
                "language": transcript_result.get("language"),
                "note": "View the frame images to understand visual content. Transcript provides audio context."
            })
        except Exception as e:
            log(f"Audio transcription failed: {e}", verbose)
            result.update({
                "capability": "frames_only",
                "transcript": [],
                "text": "",
                "note": "View the frame images to understand visual content. Audio transcription failed."
            })
    else:
        result.update({
            "capability": "frames_only",
            "transcript": [],
            "text": "",
            "note": "View the frame images to understand visual content. Install whisper for audio transcription: pip install openai-whisper"
        })

    return result


# === Provider-specific processors ===

def process_with_gemini(source: str, prompt: str, model: str = None, is_url: bool = False, verbose: bool = True) -> dict:
    """Process video with Google Gemini."""
    import google.generativeai as genai

    model_name = model or DEFAULT_MODELS["gemini"]
    log(f"Processing with Gemini ({model_name})...", verbose)

    api_key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
    genai.configure(api_key=api_key)

    genai_model = genai.GenerativeModel(model_name)

    if is_url and is_youtube_url(source):
        # Gemini can handle YouTube URLs directly
        log("Sending YouTube URL directly to Gemini...", verbose)
        response = genai_model.generate_content([
            prompt,
            {"video_url": source}
        ])
    else:
        # Upload local file
        log("Uploading video to Gemini...", verbose)
        video_file = genai.upload_file(source)

        # Wait for processing
        import time
        while video_file.state.name == "PROCESSING":
            log("Waiting for Gemini to process video...", verbose)
            time.sleep(2)
            video_file = genai.get_file(video_file.name)

        if video_file.state.name == "FAILED":
            raise RuntimeError(f"Video processing failed: {video_file.state.name}")

        log("Generating response...", verbose)
        response = genai_model.generate_content([prompt, video_file])

    return {
        "provider": "gemini",
        "model": model_name,
        "capability": "full_video",
        "response": response.text,
    }


def process_with_openrouter(video_path: str, prompt: str, model: str = None, verbose: bool = True) -> dict:
    """Process video with OpenRouter (using Gemini models)."""
    import base64
    from openai import OpenAI

    model_name = model or DEFAULT_MODELS["openrouter"]
    log(f"Processing with OpenRouter ({model_name})...", verbose)

    # Check file size
    size_mb = get_file_size_mb(video_path)
    limit = FILE_SIZE_LIMITS.get("openrouter", 50)
    if size_mb > limit:
        log(f"WARNING: File size ({size_mb:.1f} MB) exceeds recommended limit ({limit} MB)", verbose)

    client = OpenAI(
        base_url="https://openrouter.ai/api/v1",
        api_key=os.environ["OPENROUTER_API_KEY"]
    )

    # Read and encode video
    log(f"Encoding video ({size_mb:.1f} MB)...", verbose)
    with open(video_path, "rb") as f:
        video_b64 = base64.standard_b64encode(f.read()).decode("utf-8")

    # Get mime type
    ext = Path(video_path).suffix.lower()
    mime_types = {".mp4": "video/mp4", ".webm": "video/webm", ".mov": "video/quicktime", ".m4v": "video/x-m4v"}
    mime_type = mime_types.get(ext, "video/mp4")

    log("Sending to OpenRouter...", verbose)

    # Retry logic for transient errors
    import time
    max_retries = 3
    last_error = None

    for attempt in range(max_retries):
        try:
            response = client.chat.completions.create(
                model=model_name,
                messages=[{
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:{mime_type};base64,{video_b64}"
                            }
                        }
                    ]
                }]
            )

            # Validate response
            if not response.choices:
                raise RuntimeError("OpenRouter returned empty response. Video may be too large or unsupported.")

            content = response.choices[0].message.content
            if not content:
                raise RuntimeError("OpenRouter returned empty content. Try a smaller video or different model.")

            return {
                "provider": "openrouter",
                "model": model_name,
                "capability": "full_video",
                "response": content,
            }

        except Exception as e:
            last_error = e
            error_str = str(e).lower()

            # Don't retry for content/size errors
            if "too large" in error_str or "size" in error_str:
                raise RuntimeError(f"Video too large for OpenRouter ({size_mb:.1f} MB). Try compressing or use Gemini API directly.") from e

            # Retry on transient errors (5xx, timeout, cloudflare)
            if attempt < max_retries - 1 and ("5" in str(getattr(e, 'status_code', '')) or
                                               "timeout" in error_str or
                                               "temporarily" in error_str or
                                               "cloudflare" in error_str or
                                               "1105" in error_str):
                wait_time = (attempt + 1) * 5  # 5, 10, 15 seconds
                log(f"Transient error, retrying in {wait_time}s (attempt {attempt + 2}/{max_retries})...", verbose)
                time.sleep(wait_time)
                continue

            raise

    raise last_error


def process_with_openai_whisper(audio_path: str, model: str = None, verbose: bool = True) -> dict:
    """Transcribe audio with OpenAI Whisper API."""
    from openai import OpenAI

    model_name = model or DEFAULT_MODELS["openai"]
    log(f"Transcribing with OpenAI Whisper ({model_name})...", verbose)

    client = OpenAI()

    with open(audio_path, "rb") as f:
        transcript = client.audio.transcriptions.create(
            model=model_name,
            file=f,
            response_format="verbose_json",
            timestamp_granularities=["segment"]
        )

    segments = []
    if hasattr(transcript, 'segments') and transcript.segments:
        for seg in transcript.segments:
            segments.append({
                "start": seg.start,
                "end": seg.end,
                "text": seg.text.strip()
            })

    return {
        "provider": "openai",
        "model": model_name,
        "capability": "asr_only",
        "transcript": segments,
        "text": transcript.text,
        "language": getattr(transcript, 'language', None),
    }


def process_with_groq_whisper(audio_path: str, model: str = None, verbose: bool = True) -> dict:
    """Transcribe audio with Groq Whisper."""
    from groq import Groq

    model_name = model or DEFAULT_MODELS["groq"]
    log(f"Transcribing with Groq Whisper ({model_name})...", verbose)

    client = Groq()

    with open(audio_path, "rb") as f:
        transcript = client.audio.transcriptions.create(
            model=model_name,
            file=f,
            response_format="verbose_json",
        )

    segments = []
    if hasattr(transcript, 'segments') and transcript.segments:
        for seg in transcript.segments:
            segments.append({
                "start": seg["start"],
                "end": seg["end"],
                "text": seg["text"].strip()
            })

    return {
        "provider": "groq",
        "model": model_name,
        "capability": "asr_only",
        "transcript": segments,
        "text": transcript.text,
        "language": getattr(transcript, 'language', None),
    }


def process_with_assemblyai(audio_path: str, model: str = None, verbose: bool = True) -> dict:
    """Transcribe audio with AssemblyAI."""
    import assemblyai as aai

    model_name = model or DEFAULT_MODELS["assemblyai"]
    log(f"Transcribing with AssemblyAI ({model_name})...", verbose)

    aai.settings.api_key = os.environ["ASSEMBLYAI_API_KEY"]

    config = aai.TranscriptionConfig(
        speaker_labels=True,
        auto_chapters=True,
        speech_model=aai.SpeechModel.best if model_name == "best" else aai.SpeechModel.nano,
    )

    transcriber = aai.Transcriber()
    transcript = transcriber.transcribe(audio_path, config=config)

    if transcript.status == aai.TranscriptStatus.error:
        raise RuntimeError(f"Transcription failed: {transcript.error}")

    segments = []
    if transcript.utterances:
        for utt in transcript.utterances:
            segments.append({
                "start": utt.start / 1000,
                "end": utt.end / 1000,
                "text": utt.text,
                "speaker": utt.speaker,
            })

    chapters = []
    if transcript.chapters:
        for ch in transcript.chapters:
            chapters.append({
                "start": ch.start / 1000,
                "end": ch.end / 1000,
                "headline": ch.headline,
                "summary": ch.summary,
            })

    return {
        "provider": "assemblyai",
        "model": model_name,
        "capability": "asr_only",
        "transcript": segments,
        "text": transcript.text,
        "chapters": chapters,
    }


def process_with_deepgram(audio_path: str, model: str = None, verbose: bool = True) -> dict:
    """Transcribe audio with Deepgram."""
    from deepgram import DeepgramClient, PrerecordedOptions

    model_name = model or DEFAULT_MODELS["deepgram"]
    log(f"Transcribing with Deepgram ({model_name})...", verbose)

    client = DeepgramClient(os.environ["DEEPGRAM_API_KEY"])

    with open(audio_path, "rb") as f:
        buffer_data = f.read()

    payload = {"buffer": buffer_data}

    options = PrerecordedOptions(
        model=model_name,
        smart_format=True,
        utterances=True,
        punctuate=True,
        diarize=True,
    )

    response = client.listen.prerecorded.v("1").transcribe_file(payload, options)
    result = response.to_dict()

    segments = []
    if "utterances" in result.get("results", {}):
        for utt in result["results"]["utterances"]:
            segments.append({
                "start": utt["start"],
                "end": utt["end"],
                "text": utt["transcript"],
                "speaker": utt.get("speaker"),
            })

    return {
        "provider": "deepgram",
        "model": model_name,
        "capability": "asr_only",
        "transcript": segments,
        "text": result["results"]["channels"][0]["alternatives"][0]["transcript"],
    }


def process_with_local_whisper(audio_path: str, model: str = None, verbose: bool = True) -> dict:
    """Transcribe audio with local Whisper."""
    model_name = model or DEFAULT_MODELS["local"]
    log(f"Transcribing with local Whisper ({model_name})...", verbose)

    try:
        import whisper

        log("Loading Whisper model...", verbose)
        model_obj = whisper.load_model(model_name)

        log("Transcribing...", verbose)
        result = model_obj.transcribe(audio_path)

        segments = []
        for seg in result["segments"]:
            segments.append({
                "start": seg["start"],
                "end": seg["end"],
                "text": seg["text"].strip()
            })

        return {
            "provider": "local",
            "model": model_name,
            "capability": "asr_only",
            "transcript": segments,
            "text": result["text"],
            "language": result.get("language"),
        }
    except ImportError:
        # Fall back to CLI
        log("Using Whisper CLI...", verbose)
        cmd = ["whisper", audio_path, "--model", model_name, "--output_format", "json"]
        subprocess.run(cmd, check=True, capture_output=True)

        json_path = Path(audio_path).with_suffix(".json")
        with open(json_path) as f:
            result = json.load(f)

        segments = []
        for seg in result["segments"]:
            segments.append({
                "start": seg["start"],
                "end": seg["end"],
                "text": seg["text"].strip()
            })

        return {
            "provider": "local",
            "model": model_name,
            "capability": "asr_only",
            "transcript": segments,
            "text": result["text"],
        }


def process_video(
    source: str,
    prompt: str = None,
    provider: str = None,
    model: str = None,
    asr_only: bool = False,
    verbose: bool = True,
) -> dict:
    """
    Process a video with automatic provider selection.

    Args:
        source: YouTube URL, local file path, or video URL
        prompt: Prompt for video understanding (used by Gemini/OpenRouter)
        provider: Force specific provider (optional)
        model: Force specific model (optional)
        asr_only: Force ASR-only mode even if video understanding available
        verbose: Print progress messages

    Returns:
        dict with transcript, analysis, and metadata
    """

    # Default prompt
    if prompt is None:
        prompt = "Provide a detailed transcript with timestamps. Also describe any important visual elements, on-screen text, and key moments."

    # Check available providers
    providers = get_available_providers()

    if provider:
        if provider not in providers["all_providers"]:
            available = providers["all_providers"] or ["none"]
            raise ValueError(f"Provider '{provider}' not available. Available: {', '.join(available)}")
    elif asr_only:
        provider = providers["asr_only"][0] if providers["asr_only"] else None
    else:
        provider = providers["recommended"]

    if not provider:
        raise RuntimeError(
            "No video understanding providers available. "
            "Set one of: GEMINI_API_KEY, OPENROUTER_API_KEY, OPENAI_API_KEY, etc."
        )

    log(f"Using provider: {provider}", verbose)

    # Determine source type
    is_url = source.startswith(("http://", "https://"))
    is_youtube = is_url and is_youtube_url(source)

    # Handle local files with path normalization
    if not is_url:
        source = find_file_fuzzy(source)
        is_local = os.path.isfile(source)
        if not is_local:
            raise FileNotFoundError(f"Source not found: {source}")
    else:
        is_local = False

    result = {
        "source": {
            "type": "youtube" if is_youtube else ("url" if is_url else "local"),
            "path": source,
        }
    }

    # Add video info for local files
    if is_local:
        info = get_video_info(source)
        if info:
            result["source"]["duration_seconds"] = info.get("duration_seconds")
            result["source"]["size_mb"] = round(info.get("size_bytes", 0) / (1024 * 1024), 2)

    # === Full Video Understanding ===
    if provider in providers["video_understanding"] and not asr_only:

        if provider == "gemini":
            if is_youtube:
                result.update(process_with_gemini(source, prompt, model=model, is_url=True, verbose=verbose))
            elif is_local:
                result.update(process_with_gemini(source, prompt, model=model, is_url=False, verbose=verbose))
            else:
                with tempfile.TemporaryDirectory() as tmpdir:
                    video_path = download_video(source, tmpdir, verbose=verbose)
                    result.update(process_with_gemini(video_path, prompt, model=model, is_url=False, verbose=verbose))

        elif provider == "openrouter":
            max_size = FILE_SIZE_LIMITS.get("openrouter", 50)
            # Target slightly below limit to account for base64 overhead (~33%)
            target_size = int(max_size * 0.7)

            if is_local:
                with tempfile.TemporaryDirectory() as tmpdir:
                    # Convert format if needed
                    video_path = convert_to_mp4(source, tmpdir, verbose=verbose)
                    # Auto-compress if too large
                    video_path = compress_video(video_path, tmpdir, target_size_mb=target_size, verbose=verbose)
                    result.update(process_with_openrouter(video_path, prompt, model=model, verbose=verbose))
            else:
                with tempfile.TemporaryDirectory() as tmpdir:
                    video_path = download_video(source, tmpdir, max_size_mb=max_size, verbose=verbose)
                    video_path = convert_to_mp4(video_path, tmpdir, verbose=verbose)
                    # Auto-compress if still too large after download
                    video_path = compress_video(video_path, tmpdir, target_size_mb=target_size, verbose=verbose)
                    result.update(process_with_openrouter(video_path, prompt, model=model, verbose=verbose))

        elif provider == "vertex":
            raise NotImplementedError("Vertex AI support coming soon. Use GEMINI_API_KEY instead.")

        elif provider == "ffmpeg":
            # Free offline approach: extract frames + transcribe with local whisper
            # Frames are saved persistently for Claude to view
            mode = model or DEFAULT_MODELS["ffmpeg"]

            # Create persistent output directory for frames
            frames_output_dir = os.path.join(os.path.dirname(source) if is_local else tempfile.gettempdir(), "video_frames")
            os.makedirs(frames_output_dir, exist_ok=True)

            if is_local:
                result.update(process_with_ffmpeg(source, frames_output_dir, mode=mode, verbose=verbose))
            else:
                with tempfile.TemporaryDirectory() as tmpdir:
                    video_path = download_video(source, tmpdir, verbose=verbose)
                    result.update(process_with_ffmpeg(video_path, frames_output_dir, mode=mode, verbose=verbose))

    # === ASR-Only Providers ===
    else:
        with tempfile.TemporaryDirectory() as tmpdir:
            if is_url:
                video_path = download_video(source, tmpdir, verbose=verbose)
            else:
                video_path = source

            audio_path = extract_audio(video_path, tmpdir, verbose=verbose)

            # Check file size for providers with limits
            if provider in FILE_SIZE_LIMITS:
                size_mb = get_file_size_mb(audio_path)
                limit = FILE_SIZE_LIMITS[provider]
                if size_mb > limit:
                    log(f"WARNING: Audio file ({size_mb:.1f} MB) exceeds {provider} limit ({limit} MB)", verbose)

            if provider == "openai":
                result.update(process_with_openai_whisper(audio_path, model=model, verbose=verbose))
            elif provider == "groq":
                result.update(process_with_groq_whisper(audio_path, model=model, verbose=verbose))
            elif provider == "assemblyai":
                result.update(process_with_assemblyai(audio_path, model=model, verbose=verbose))
            elif provider == "deepgram":
                result.update(process_with_deepgram(audio_path, model=model, verbose=verbose))
            elif provider == "local":
                result.update(process_with_local_whisper(audio_path, model=model, verbose=verbose))
            else:
                raise ValueError(f"Unknown provider: {provider}")

    log("Done!", verbose)
    return result


def list_models():
    """Print available models for each provider."""
    providers = get_available_providers()

    print("Available models by provider:\n")

    for provider in providers["all_providers"]:
        models = AVAILABLE_MODELS.get(provider, [])
        default = DEFAULT_MODELS.get(provider, "")

        print(f"  {provider}:")
        for m in models:
            marker = " (default)" if m == default else ""
            print(f"    - {m}{marker}")
        print()

    if not providers["all_providers"]:
        print("  No providers available. Set API keys to enable providers.")


def main():
    parser = argparse.ArgumentParser(
        description="Process video for understanding/transcription",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Process YouTube video
  %(prog)s "https://youtube.com/watch?v=..."

  # Process local file
  %(prog)s video.mp4

  # Use specific provider and model
  %(prog)s video.mp4 --provider openrouter --model google/gemini-3-pro-preview

  # Custom prompt
  %(prog)s video.mp4 -p "List all products shown with timestamps"

  # ASR-only (transcription without visual analysis)
  %(prog)s video.mp4 --asr-only

  # List available models
  %(prog)s --list-models
        """
    )

    parser.add_argument("source", nargs="?", help="YouTube URL, video URL, or local file path")
    parser.add_argument("-p", "--prompt", help="Custom prompt for video understanding")
    parser.add_argument("--provider", help="Force specific provider (gemini, openrouter, openai, groq, assemblyai, deepgram, local)")
    parser.add_argument("-m", "--model", help="Force specific model (use --list-models to see options)")
    parser.add_argument("--asr-only", action="store_true", help="Force ASR-only mode (no visual analysis)")
    parser.add_argument("-o", "--output", help="Output JSON file (default: stdout)")
    parser.add_argument("-q", "--quiet", action="store_true", help="Suppress progress messages")
    parser.add_argument("--list-models", action="store_true", help="List available models and exit")
    parser.add_argument("--list-providers", action="store_true", help="List available providers and exit")

    args = parser.parse_args()

    # Handle list commands
    if args.list_models:
        list_models()
        return

    if args.list_providers:
        providers = get_available_providers()
        print(json.dumps(providers, indent=2))
        return

    # Require source for processing
    if not args.source:
        parser.print_help()
        sys.exit(1)

    try:
        result = process_video(
            source=args.source,
            prompt=args.prompt,
            provider=args.provider,
            model=args.model,
            asr_only=args.asr_only,
            verbose=not args.quiet,
        )

        output = json.dumps(result, indent=2, ensure_ascii=False)

        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                f.write(output)
            print(f"Output written to: {args.output}", file=sys.stderr)
        else:
            print(output)

    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nInterrupted.", file=sys.stderr)
        sys.exit(130)


if __name__ == "__main__":
    main()
