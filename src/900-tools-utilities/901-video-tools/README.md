# Video Tools Component

## Overview

The Video Tools Component provides professional video processing utilities optimized for edge AI deployments. This component includes CLI tools for video manipulation, format conversion, and optimization tasks commonly needed in edge computing scenarios.

**Component ID**: `901-video-tools`

**Category**: Tools & Utilities

**Status**: Active Development

## Tools Included

### video-to-gif

A professional CLI tool for converting video files to optimized GIF format using FFmpeg's two-pass palette generation.

**Key Features**:

* Two-pass palette optimization for superior quality
* Configurable frame rate (1-30 FPS)
* Flexible sizing with aspect ratio preservation
* Multiple dithering algorithms
* Cross-platform support (Linux, macOS, Windows)

**Documentation**: [cli/video-to-gif/README.md](./cli/video-to-gif/README.md)

**Quick Start**:

```bash
cd cli/video-to-gif
cargo build --release
./target/release/video-to-gif -i input.mp4 -o output.gif
```

## Prerequisites

### Technical Prerequisites

* **FFmpeg**: Required for all video processing operations
  * Ubuntu/Debian: `sudo apt-get install ffmpeg`
  * macOS: `brew install ffmpeg`
  * Windows: Download from <https://ffmpeg.org/download.html>

* **Rust** (for building from source): <https://rustup.rs/>
  * Version 1.80 or higher recommended

* **Docker** (optional): For containerized deployment
  * <https://docs.docker.com/get-docker/>

### Organizational Prerequisites

* Basic command-line proficiency
* Understanding of video formats and codecs (for advanced usage)
* Rust development expertise (for code modifications)

## Installation

### Option 1: Build from Source (Recommended)

```bash
# Navigate to the tool directory
cd src/900-tools-utilities/901-video-tools/cli/video-to-gif

# Build release binary
cargo build --release

# Binary location
./target/release/video-to-gif

# Optionally, add to PATH
sudo cp target/release/video-to-gif /usr/local/bin/
```

### Option 2: Docker

```bash
# Build container image
cd src/900-tools-utilities/901-video-tools/cli/video-to-gif
docker build -t video-to-gif .

# Run conversion
docker run -v $(pwd):/work video-to-gif \
  --input /work/input.mp4 \
  --output /work/output.gif
```

### Option 3: Development Mode

```bash
# Run without building binary
cd cli/video-to-gif
cargo run -- --input test.mp4 --output test.gif
```

## Quick Start

### Basic Video to GIF Conversion

```bash
video-to-gif --input sample.mp4 --output sample.gif
```

### High Quality Conversion

```bash
video-to-gif -i video.mp4 -o high-quality.gif --fps 20 --width 800
```

### Small File Size Conversion

```bash
video-to-gif -i video.mp4 -o small.gif --fps 5 --width 320
```

### Batch Processing

```bash
for video in *.mp4; do
  video-to-gif -i "$video" -o "${video%.mp4}.gif"
done
```

## Component Structure

```text
src/900-tools-utilities/901-video-tools/
├── README.md                       # This documentation
├── .env.example                    # Environment configuration template
├── cli/                            # CLI tools
│   └── video-to-gif/               # Video to GIF converter
│       ├── README.md               # Tool-specific documentation
│       ├── Cargo.toml              # Rust dependencies
│       ├── Dockerfile              # Container image definition
│       └── src/                    # Rust source code
├── scripts/                        # Supporting scripts
└── test-assets/                    # Test data
    ├── input/                      # Sample input videos
    └── README.md                   # Test data generation instructions
```

## Configuration

Environment variables can be configured using the `.env.example` template:

```bash
# Copy template
cp .env.example .env

# Edit configuration
vim .env
```

**Key Variables**:

* `VIDEO_TO_GIF_FPS`: Default frame rate (default: 10)
* `VIDEO_TO_GIF_WIDTH`: Default width in pixels (default: 480)
* `RUST_LOG`: Logging level (info, debug, warn, error)
* `FFMPEG_PATH`: Custom FFmpeg binary location (optional)

## Troubleshooting

### FFmpeg Not Found

Ensure FFmpeg is installed and in your PATH:

```bash
# Test FFmpeg installation
ffmpeg -version

# If missing, install based on your OS (see Prerequisites)
```

### Build Errors

Ensure Rust is up to date:

```bash
rustup update stable
cargo clean
cargo build --release
```

### Docker Build Issues

Ensure Docker daemon is running:

```bash
docker info
```

For detailed troubleshooting, see individual tool documentation:

* [video-to-gif troubleshooting](./cli/video-to-gif/README.md#troubleshooting)

## Performance Considerations

* **Two-pass conversion**: Higher quality but slower (~2x processing time)
* **Single-pass conversion**: Faster but lower quality (use `--skip-palette` flag)
* **Frame rate**: Lower FPS significantly reduces file size
* **Resolution**: Lower width reduces both processing time and file size
* **Dithering**: Bayer is fastest, Floyd-Steinberg is slowest but highest quality

## Contributing

This component follows standard edge-ai contribution guidelines:

* Follow Rust conventions and clippy recommendations
* Include documentation for new features
* Add examples for common use cases
* Ensure all tests pass before submitting PRs

See [CONTRIBUTING.md](../../../CONTRIBUTING.md) for detailed guidelines.

## Related Components

* **503-media-capture-service**: Video capture from RTSP streams
* **900-mqtt-tools**: MQTT testing and diagnostics

## Support

For issues, questions, or feature requests:

* Review individual tool documentation
* Check troubleshooting sections
* Consult FFmpeg documentation for video processing questions
* See project [SUPPORT.md](../../../SUPPORT.md) for community resources

## License

Copyright (c) Microsoft Corporation. All rights reserved.

Licensed under the MIT License. See LICENSE in the project root for license information.
