#!/usr/bin/env bash

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="${SCRIPT_DIR}/../cli/video-to-gif"

log() {
  printf "========== %s ==========\n" "$1"
}

err() {
  printf "[ ERROR ]: %s\n" "$1" >&2
  exit 1
}

check_ffmpeg() {
  if ! command -v ffmpeg &>/dev/null; then
    err "FFmpeg is not installed or not in PATH.

video-to-gif requires FFmpeg for video processing.

Platform-specific installation instructions:

  macOS (using Homebrew):
    brew install ffmpeg

  Ubuntu/Debian:
    sudo apt-get update
    sudo apt-get install ffmpeg

  Windows:
    Download from https://ffmpeg.org/download.html
    Extract and add to PATH

After installing FFmpeg, run this script again."
  fi
}

if [[ ! -d "$CLI_DIR" ]]; then
  err "CLI directory not found: $CLI_DIR"
fi

cd "$CLI_DIR"

log "Building video-to-gif CLI tool"

if ! command -v cargo &>/dev/null; then
  err "Rust toolchain (cargo) not found. Please install Rust from https://rustup.rs/"
fi

check_ffmpeg

log "Running cargo build --release"
cargo build --release

if [[ ! -f "target/release/video-to-gif" ]]; then
  err "Build failed: binary not found at target/release/video-to-gif"
fi

BINARY_SIZE=$(stat -f%z "target/release/video-to-gif" 2>/dev/null || stat -c%s "target/release/video-to-gif" 2>/dev/null || echo "unknown")

log "Build complete"
echo "Binary: ${CLI_DIR}/target/release/video-to-gif"
echo "Size: ${BINARY_SIZE} bytes"
