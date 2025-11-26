#!/usr/bin/env bash

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="${SCRIPT_DIR}/../cli/video-to-gif"
TEST_ASSETS_DIR="${SCRIPT_DIR}/../test-assets"
INPUT_DIR="${TEST_ASSETS_DIR}/input"
OUTPUT_DIR="${TEST_ASSETS_DIR}/output"

log() {
  printf "========== %s ==========\n" "$1"
}

err() {
  printf "[ ERROR ]: %s\n" "$1" >&2
  exit 1
}

info() {
  printf "[ INFO ]: %s\n" "$1"
}

if [[ ! -d "$CLI_DIR" ]]; then
  err "CLI directory not found: $CLI_DIR"
fi

BINARY="${CLI_DIR}/target/release/video-to-gif"

if [[ ! -f "$BINARY" ]]; then
  log "Binary not found, building..."
  "${SCRIPT_DIR}/build-local.sh"
fi

mkdir -p "$OUTPUT_DIR"

if [[ ! -d "$INPUT_DIR" || -z "$(ls -A "$INPUT_DIR" 2>/dev/null)" ]]; then
  info "No test videos found in ${INPUT_DIR}"
  info "Please add test video files or run: cd test-assets && bash README.md examples to generate test videos"
  exit 0
fi

TEST_VIDEO=$(find "$INPUT_DIR" -type f \( -name "*.mp4" -o -name "*.avi" -o -name "*.mov" \) | head -n 1)

if [[ -z "$TEST_VIDEO" ]]; then
  info "No video files found in ${INPUT_DIR}"
  info "Supported formats: .mp4, .avi, .mov"
  exit 0
fi

TEST_BASENAME=$(basename "$TEST_VIDEO")
TEST_NAME="${TEST_BASENAME%.*}"
OUTPUT_GIF="${OUTPUT_DIR}/${TEST_NAME}.gif"

log "Testing video-to-gif conversion"
info "Input: $TEST_VIDEO"
info "Output: $OUTPUT_GIF"

"$BINARY" \
  --input "$TEST_VIDEO" \
  --output "$OUTPUT_GIF" \
  --fps 10 \
  --width 480

if [[ ! -f "$OUTPUT_GIF" ]]; then
  err "Conversion failed: output file not created"
fi

GIF_SIZE=$(stat -f%z "$OUTPUT_GIF" 2>/dev/null || stat -c%s "$OUTPUT_GIF" 2>/dev/null || echo "unknown")

log "Conversion test successful"
echo "Output: $OUTPUT_GIF"
echo "Size: ${GIF_SIZE} bytes"

if command -v file &>/dev/null; then
  echo "Type: $(file "$OUTPUT_GIF")"
fi
