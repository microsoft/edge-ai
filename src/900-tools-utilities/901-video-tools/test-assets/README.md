# Test Assets

This directory contains test data for the video-to-gif CLI tool.

## Directory Structure

```text
test-assets/
├── README.md           # This file
├── input/              # Sample input videos
│   └── sample.mp4      # Test video file (user-provided or generated)
└── expected/           # Expected output samples (optional)
```

## Generating Test Videos

Since we cannot include binary video files in the repository, you can generate test videos using FFmpeg or provide your own.

### Option 1: Generate with FFmpeg (Recommended)

Create a simple test video with a moving color gradient:

```bash
# Create input directory
mkdir -p input

# Generate 5-second test video with moving gradient (requires FFmpeg)
ffmpeg -f lavfi \
  -i testsrc=duration=5:size=1280x720:rate=30 \
  -c:v libx264 \
  -pix_fmt yuv420p \
  input/sample.mp4
```

**Result**: 5-second, 1280x720, 30fps test video with moving patterns

### Option 2: Generate Animated Pattern

Create a test video with animated color bars:

```bash
mkdir -p input

ffmpeg -f lavfi \
  -i smptebars=duration=5:size=1280x720:rate=30 \
  -c:v libx264 \
  -pix_fmt yuv420p \
  input/sample.mp4
```

**Result**: 5-second SMPTE color bars test pattern

### Option 3: Generate with Text Overlay

Create a test video with moving text:

```bash
mkdir -p input

ffmpeg -f lavfi \
  -i color=c=blue:s=1280x720:d=5 \
  -vf "drawtext=text='Video-to-GIF Test':fontsize=60:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2" \
  -c:v libx264 \
  -pix_fmt yuv420p \
  input/sample.mp4
```

**Result**: 5-second blue background with centered text

### Option 4: Use Your Own Video

Copy any MP4 video file to the input directory:

```bash
mkdir -p input
cp /path/to/your/video.mp4 input/sample.mp4
```

## Generating Expected Output

Optionally, generate expected output GIFs for comparison:

```bash
# Ensure input video exists first
mkdir -p expected

# Generate expected output with default settings
../cli/video-to-gif/target/release/video-to-gif \
  --input input/sample.mp4 \
  --output expected/sample-default.gif

# Generate with high quality settings
../cli/video-to-gif/target/release/video-to-gif \
  --input input/sample.mp4 \
  --output expected/sample-high-quality.gif \
  --fps 20 \
  --width 800
```

## Running Example Scripts

After generating test videos, run the example scripts:

```bash
cd ../examples

# Make scripts executable
chmod +x *.sh

# Run basic examples
./basic-usage.sh

# Run batch conversion (processes all MP4s in current directory)
./batch-convert.sh

# Run advanced examples with quality presets
./advanced-options.sh
```

## Test Video Requirements

For consistent testing, use videos with these characteristics:

* **Duration**: 3-10 seconds (keeps file sizes manageable)
* **Resolution**: 1280x720 or 1920x1080 (standard HD formats)
* **Frame Rate**: 24-30 fps (typical video frame rates)
* **Codec**: H.264 (widely compatible)
* **Container**: MP4 (standard format)

## Cleaning Up

Remove generated test files:

```bash
# Remove input videos
rm -rf input/*

# Remove expected outputs
rm -rf expected/*

# Remove example outputs
rm -f ../examples/*.gif
```

## Notes

* Test videos are intentionally **not** included in the repository to keep it lightweight
* Use FFmpeg `testsrc` or `smptebars` for reproducible test patterns
* Generated videos should be 5-10 seconds to balance quality testing and file size
* Example scripts expect `input/sample.mp4` to exist

## Troubleshooting

### FFmpeg Not Found

Ensure FFmpeg is installed:

```bash
# Test FFmpeg
ffmpeg -version

# Install if needed
# Ubuntu/Debian: sudo apt-get install ffmpeg
# macOS: brew install ffmpeg
# Windows: https://ffmpeg.org/download.html
```

### Codec Not Available

If you see "Unknown encoder 'libx264'", install FFmpeg with H.264 support:

```bash
# macOS
brew reinstall ffmpeg

# Ubuntu/Debian (requires universe repository)
sudo apt-get install ffmpeg
```

### Permission Denied

Make sure the test-assets directory is writable:

```bash
chmod +w input expected
```
