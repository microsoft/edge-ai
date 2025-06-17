#!/usr/bin/env bash

# serve-docs.sh - Start docsify documentation server with verbose logging
# Usage: ./serve-docs.sh [options]
# Options:
#   --verbose     Enable verbose logging
#   --open        Open browser automatically
#   --port PORT   Specify port (default: 8080)

set -e

# Default values
PORT=8080
VERBOSE=false
OPEN=false
INDEX_FILE="index.html"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  --verbose)
    VERBOSE=true
    shift
    ;;
  --open)
    OPEN=true
    shift
    ;;
  --port)
    PORT="$2"
    shift 2
    ;;
  -h | --help)
    echo "Usage: $0 [--verbose] [--open] [--port PORT]"
    echo "  --verbose     Enable verbose logging"
    echo "  --open        Open browser automatically"
    echo "  --port PORT   Specify port (default: 8080)"
    exit 0
    ;;
  *)
    echo "Unknown option: $1"
    exit 1
    ;;
  esac
done

# Change to workspace root
cd "$(dirname "$0")/.."

echo "🚀 Starting docsify documentation server..."
echo "📁 Working directory: $(pwd)"
echo "🌐 Port: $PORT"
echo "📄 Index file: $INDEX_FILE"

if [ "$VERBOSE" = true ]; then
  echo "🔍 Verbose logging enabled"
fi

if [ "$OPEN" = true ]; then
  echo "🌐 Browser will open automatically"
fi

echo ""
echo "Checking dependencies..."

# Check if docsify package is available via npx
echo "✅ Using docsify via npx"

# Check if index file exists
if [ ! -f "$INDEX_FILE" ]; then
  echo "❌ Index file not found: $INDEX_FILE"
  exit 1
else
  echo "✅ Index file found: $INDEX_FILE"
fi

echo ""
echo "🔄 Starting server..."
echo "📖 Documentation will be available at: http://localhost:$PORT"
echo ""

# Build docsify command with options - use npx for reliability and force resolution of marked
DOCSIFY_CMD="npx --yes docsify serve . --port $PORT --index-name $INDEX_FILE"

if [ "$OPEN" = true ]; then
  DOCSIFY_CMD="$DOCSIFY_CMD --open"
fi

# Start docsify with appropriate options
if [ "$VERBOSE" = true ]; then
  echo "🔍 Running: $DOCSIFY_CMD"
  eval "$DOCSIFY_CMD"
else
  eval "$DOCSIFY_CMD"
fi
