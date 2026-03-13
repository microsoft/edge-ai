#!/bin/bash
# Install ffmpeg in Azure Functions Linux environment
# This script runs during function app deployment

set -e

echo "Installing ffmpeg..."

# Check if running in Azure Functions environment
if [ -n "$HOME" ] && [ -d "$HOME" ]; then
    INSTALL_DIR="$HOME/bin"
    mkdir -p "$INSTALL_DIR"
    
    # Download static ffmpeg build
    FFMPEG_URL="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
    TEMP_DIR=$(mktemp -d)
    
    echo "Downloading ffmpeg from $FFMPEG_URL..."
    curl -L "$FFMPEG_URL" -o "$TEMP_DIR/ffmpeg.tar.xz"
    
    echo "Extracting ffmpeg..."
    tar xf "$TEMP_DIR/ffmpeg.tar.xz" -C "$TEMP_DIR"
    
    # Find and copy ffmpeg binary
    FFMPEG_BIN=$(find "$TEMP_DIR" -name "ffmpeg" -type f | head -n 1)
    if [ -n "$FFMPEG_BIN" ]; then
        cp "$FFMPEG_BIN" "$INSTALL_DIR/ffmpeg"
        chmod +x "$INSTALL_DIR/ffmpeg"
        echo "✓ ffmpeg installed to $INSTALL_DIR/ffmpeg"
    else
        echo "✗ Failed to find ffmpeg binary"
        exit 1
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
    # Add to PATH (for current session)
    export PATH="$INSTALL_DIR:$PATH"
    
    # Verify installation
    if command -v ffmpeg &> /dev/null; then
        ffmpeg -version | head -n 1
        echo "✓ ffmpeg is ready"
    else
        echo "✗ ffmpeg not found in PATH"
        exit 1
    fi
else
    echo "Not in Azure Functions environment, skipping installation"
fi
