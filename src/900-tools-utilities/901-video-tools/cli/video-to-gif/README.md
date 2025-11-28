# video-to-gif

A professional CLI tool for converting video files to optimized GIF format using FFmpeg's two-pass palette generation.

## Features

* **Two-Pass Palette Optimization**: Generates optimal 256-color palette for superior GIF quality
* **Configurable Frame Rate**: Control output FPS (1-30) for file size optimization
* **Flexible Sizing**: Resize output with width parameter while maintaining aspect ratio
* **Multiple Dithering Algorithms**: Choose from sierra2_4a, floyd_steinberg, bayer, or none
* **Single-Pass Fallback**: Option to skip palette generation for faster conversion
* **Progress Logging**: Structured logging with info and debug levels
* **Input Validation**: Comprehensive checks for file existence and FFmpeg availability
* **Cross-Platform**: Works on Linux, macOS, and Windows with FFmpeg installed

## Quick Start

Convert a video to GIF with default settings:

```bash
video-to-gif --input sample.mp4 --output sample.gif
```

Customize quality and size:

```bash
video-to-gif -i video.mp4 -o output.gif --fps 15 --width 640 --dither floyd_steinberg
```

## Installation

### Prerequisites

* **FFmpeg**: Required for video processing
  * Ubuntu/Debian: `sudo apt-get install ffmpeg`
  * macOS: `brew install ffmpeg`
  * Windows: Download from <https://ffmpeg.org/download.html>

* **Rust** (for building from source): <https://rustup.rs/>

### From Source

```bash
# Clone or navigate to the repository
cd src/900-tools-utilities/901-video-tools/cli/video-to-gif

# Build release binary
cargo build --release

# Binary location
./target/release/video-to-gif
```

### Using Docker

```bash
# Build the container
docker build -t video-to-gif .

# Run conversion
docker run -v $(pwd):/work video-to-gif \
  --input /work/input.mp4 \
  --output /work/output.gif
```

## Command-Line Options

### Required Arguments

* `--input`, `-i <PATH>`: Input video file path (must exist)
* `--output`, `-o <PATH>`: Output GIF file path

### Optional Arguments

* `--fps <NUMBER>`: Frame rate for output GIF (1-30, default: 10)
* `--width <PIXELS>`: Width in pixels (100-1920, default: 480)
  * Height is calculated automatically to maintain aspect ratio
* `--dither <ALGORITHM>`: Dithering algorithm (default: sierra2_4a)
  * Options: `sierra2_4a`, `floyd_steinberg`, `bayer`, `none`
* `--skip-palette`: Skip two-pass palette generation (faster but lower quality)
* `--verbose`, `-v`: Enable debug logging (shows FFmpeg commands)

### Help

```bash
video-to-gif --help
```

## Usage Examples

### Basic Conversion

Default settings (10 FPS, 480px width, sierra2_4a dithering):

```bash
video-to-gif -i video.mp4 -o output.gif
```

### High Quality Output

Higher frame rate and larger size for better quality:

```bash
video-to-gif -i video.mp4 -o high-quality.gif --fps 20 --width 800
```

### Low Bandwidth / Small File Size

Lower frame rate and smaller dimensions:

```bash
video-to-gif -i video.mp4 -o small.gif --fps 5 --width 320
```

### Quick Conversion (Skip Palette Generation)

Faster conversion with single-pass (sacrifices quality):

```bash
video-to-gif -i video.mp4 -o quick.gif --skip-palette
```

### Custom Dithering

Try different dithering algorithms:

```bash
# Floyd-Steinberg (classic error diffusion)
video-to-gif -i video.mp4 -o floyd.gif --dither floyd_steinberg

# Bayer (ordered dithering, faster)
video-to-gif -i video.mp4 -o bayer.gif --dither bayer

# No dithering (posterized look)
video-to-gif -i video.mp4 -o none.gif --dither none
```

### Debug Mode

See FFmpeg commands and detailed processing information:

```bash
video-to-gif -i video.mp4 -o debug.gif --verbose
```

## Dithering Algorithm Comparison

| Algorithm       | Quality | Speed   | Best For                          |
|-----------------|---------|---------|-----------------------------------|
| sierra2_4a      | High    | Medium  | General use (default)             |
| floyd_steinberg | High    | Slow    | Photographic content              |
| bayer           | Medium  | Fast    | Graphics with solid colors        |
| none            | Low     | Fastest | Stylized/posterized artistic look |

## Performance Characteristics

### Typical Conversion Times

* **5-second video, 10 FPS, 480px**: ~10-15 seconds
* **30-second video, 15 FPS, 640px**: ~45-60 seconds
* **Single-pass mode**: ~50% faster than two-pass

### File Size Guidelines

* **10 FPS, 480px**: ~500KB per second of video
* **15 FPS, 640px**: ~1.2MB per second of video
* **5 FPS, 320px**: ~150KB per second of video

Actual sizes vary based on video content complexity and dithering algorithm.

## Troubleshooting

### FFmpeg Not Found

**Error**: `FFmpeg is not installed or not in PATH`

**Solutions**:

* **Ubuntu/Debian**: `sudo apt-get install ffmpeg`
* **macOS**: `brew install ffmpeg`
* **Windows**: Download from <https://ffmpeg.org/download.html> and add to PATH
* **Docker**: Use the provided Dockerfile which includes FFmpeg

### Poor Output Quality

**Symptoms**: Banding, color artifacts, blurry output

**Solutions**:

* Increase frame rate: `--fps 15` or `--fps 20`
* Increase width: `--width 640` or `--width 800`
* Try different dithering: `--dither floyd_steinberg`
* Ensure source video quality is sufficient
* Use two-pass mode (default, don't use `--skip-palette`)

### Large File Sizes

**Symptoms**: Output GIF larger than expected

**Solutions**:

* Reduce frame rate: `--fps 5` or `--fps 8`
* Reduce width: `--width 320` or `--width 400`
* Try bayer dithering: `--dither bayer` (slightly smaller files)
* Trim video duration before conversion
* Consider if GIF is the right format (MP4/WebM may be better for long videos)

### Conversion Takes Too Long

**Symptoms**: Processing seems stuck or very slow

**Solutions**:

* Use single-pass mode: `--skip-palette` (50% faster)
* Reduce frame rate: `--fps 5`
* Reduce width: `--width 320`
* Check FFmpeg isn't processing other jobs
* Use debug mode to see progress: `--verbose`

## Technical Details

### FFmpeg Filter Chain

The tool uses FFmpeg's high-quality two-pass conversion process:

**Pass 1 - Palette Generation**:

```bash
ffmpeg -i input.mp4 \
  -vf "fps={fps},scale={width}:-1:flags=lanczos,palettegen=stats_mode=diff" \
  -y palette.png
```

* `fps={fps}`: Sets target frame rate
* `scale={width}:-1:flags=lanczos`: Resizes with Lanczos3 algorithm (high quality)
* `palettegen=stats_mode=diff`: Generates optimized 256-color palette analyzing frame differences

**Pass 2 - GIF Creation**:

```bash
ffmpeg -i input.mp4 -i palette.png \
  -filter_complex "fps={fps},scale={width}:-1:flags=lanczos[x];[x][1:v]paletteuse=dither={dither}:diff_mode=rectangle" \
  -y output.gif
```

* `paletteuse`: Applies generated palette with specified dithering
* `diff_mode=rectangle`: Only updates changed regions (smaller file size)

**Single-Pass Mode** (when `--skip-palette` is used):

```bash
ffmpeg -i input.mp4 \
  -vf "fps={fps},scale={width}:-1:flags=lanczos" \
  -y output.gif
```

Faster but uses FFmpeg's default 256-color palette, which may not be optimal for the specific video content.

## Development

### Building

```bash
cargo build --release
```

### Testing

```bash
cargo test
```

### Linting

```bash
cargo clippy
```

### Running Locally

```bash
# Debug build
cargo run -- -i test.mp4 -o test.gif

# Release build
cargo run --release -- -i test.mp4 -o test.gif
```

## Related Documentation

* Component Overview: [../README.md](../README.md)
* FFmpeg Documentation: <https://ffmpeg.org/documentation.html>
* GIF Optimization Guide: <https://cassidy.codes/blog/2017/04/25/ffmpeg-frames-to-gif-optimization/>

## License

Copyright (c) Microsoft Corporation. All rights reserved.

Licensed under the MIT License. See LICENSE in the project root for license information.
