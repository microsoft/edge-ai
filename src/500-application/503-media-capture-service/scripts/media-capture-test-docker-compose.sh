#!/bin/bash

set -e

# Media Capture Service Test Script - Docker Compose
# Combines simple test scenarios with advanced MQTT testing capabilities
# Designed for use with docker-compose.yml local development environment

# Default MQTT topics for the media capture service
DEFAULT_ALERT_TRIGGER_TOPIC="alerts/trigger"
DEFAULT_ANALYTICS_TRIGGER_TOPIC="analytics/disabled"

# Use environment variables if set, otherwise use defaults
ALERT_TRIGGER_TOPIC="${ALERT_TRIGGER_TOPIC:-$DEFAULT_ALERT_TRIGGER_TOPIC}"
ANALYTICS_TRIGGER_TOPIC="${ANALYTICS_TRIGGER_TOPIC:-$DEFAULT_ANALYTICS_TRIGGER_TOPIC}"

# Docker container name for mosquitto broker
MOSQUITTO_CONTAINER="${MOSQUITTO_CONTAINER:-mosquitto-broker}"

# Get script directory and sample-data path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DATA_DIR="${SCRIPT_DIR}/../services/media-capture-service/sample-data"

# Function to show help
help() {
  echo "Media Capture Service Test Script - Docker Compose"
  echo "=================================================="
  echo ""
  echo "This script tests the media capture service running in local Docker Compose."
  echo "Ensure Docker Compose is running before using this script."
  echo ""
  echo "Quick Test Scenarios:"
  echo "  $0 alert          # Test alert trigger (current time)"
  echo "  $0 alert-past     # Test alert trigger (5 seconds ago)"
  echo "  $0 analytics      # Test analytics disabled trigger"
  echo "  $0 manual         # Test manual trigger"
  echo ""
  echo "Advanced Usage:"
  echo "  $0 [-u [OFFSET_SECS]] [-t TOPIC] [-f FILENAME] [-l] [-m EVENT_TYPE]"
  echo ""
  echo "Options:"
  echo "  -u [OFFSET_SECS]  Update timestamp in JSON file (default: current time)"
  echo "                    Optional offset in seconds (can be negative)"
  echo "  -t TOPIC          MQTT topic (default: alert trigger topic)"
  echo "  -f FILENAME       JSON file (default: alert-true.json)"
  echo "  -l                Show timestamp in local time"
  echo "  -m EVENT_TYPE     Message type: alert or analytics_disabled"
  echo "  -c CONTAINER      Mosquitto container name (default: $MOSQUITTO_CONTAINER)"
  echo "  -h, --help        Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                                    # Test alert with current time"
  echo "  $0 -l                                 # Test alert and show local time"
  echo "  $0 -u -5 -l                          # Test alert 5 seconds ago"
  echo "  $0 -f analytics-disabled.json -m analytics_disabled"
  echo "  $0 -t custom/topic -f manual-trigger.json"
  echo "  $0 -c my-mosquitto-container          # Use different container name"
  echo ""
  echo "Environment Variables:"
  echo "  ALERT_TRIGGER_TOPIC      Default alert topic (current: $ALERT_TRIGGER_TOPIC)"
  echo "  ANALYTICS_TRIGGER_TOPIC  Default analytics topic (current: $ANALYTICS_TRIGGER_TOPIC)"
  echo "  MOSQUITTO_CONTAINER      Mosquitto container name (current: $MOSQUITTO_CONTAINER)"
  echo ""
  echo "Prerequisites:"
  echo "  - Docker and Docker Compose must be installed"
  echo "  - Run 'docker compose up -d' in the media-capture-service directory"
  echo "  - Mosquitto broker container must be running"
}

# Function to check if mosquitto container is running
check_mosquitto_container() {
  if ! docker ps --filter "name=$MOSQUITTO_CONTAINER" --filter "status=running" | grep -q "$MOSQUITTO_CONTAINER"; then
    echo "Error: Mosquitto container '$MOSQUITTO_CONTAINER' is not running."
    echo ""
    echo "Please ensure Docker Compose is running:"
    echo "  cd /workspaces/edge-ai/src/500-application/503-media-capture-service"
    echo "  docker compose up -d"
    echo ""
    echo "Or check if the container has a different name:"
    echo "  docker ps | grep mosquitto"
    exit 1
  fi
  echo "✓ Mosquitto container '$MOSQUITTO_CONTAINER' is running"
}

# Function to run quick test scenarios
run_quick_test() {
  case "$1" in
    "alert" | "a")
      echo "Testing ALERT trigger with current timestamp..."
      run_advanced_test -u -l -f alert-true.json
      ;;
    "alert-past" | "ap")
      echo "Testing ALERT trigger with timestamp 5 seconds ago..."
      run_advanced_test -u -5 -l -f alert-true.json
      ;;
    "analytics" | "an")
      echo "Testing ANALYTICS DISABLED trigger..."
      run_advanced_test -u -l -f analytics-disabled.json -m analytics_disabled
      ;;
    "manual" | "m")
      echo "Testing MANUAL trigger..."
      run_advanced_test -u -l -f manual-trigger.json
      ;;
    *)
      echo "Unknown quick test scenario: $1"
      echo "Available scenarios: alert, alert-past, analytics, manual"
      exit 1
      ;;
  esac
}

# Function to run advanced test with flags
run_advanced_test() {
  UPDATE_TIME=false
  OFFSET_SECS=0
  TOPIC=""
  FILENAME=""
  SHOW_LOCAL_TIME=false
  MESSAGE_TYPE="alert"

  # Parse option flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -u)
        UPDATE_TIME=true
        if [[ "$2" =~ ^-?[0-9]+$ ]]; then
          OFFSET_SECS="$2"
          shift
        fi
        ;;
      -t)
        TOPIC="$2"
        shift
        ;;
      -f)
        FILENAME="$2"
        shift
        ;;
      -l)
        SHOW_LOCAL_TIME=true
        ;;
      -m)
        MESSAGE_TYPE="$2"
        shift
        ;;
      -c)
        MOSQUITTO_CONTAINER="$2"
        shift
        ;;
      *)
        break
        ;;
    esac
    shift
  done

  # Check mosquitto container before proceeding
  check_mosquitto_container

  # Only assign from positional arguments if not already set by flags
  if [ -z "$TOPIC" ] && [ -n "$1" ]; then
    TOPIC=$1
    shift
  fi
  if [ -z "$FILENAME" ] && [ -n "$1" ]; then
    FILENAME=$1
    shift
  fi

  # Apply defaults if not specified
  if [ -z "$TOPIC" ]; then
    if [ "$MESSAGE_TYPE" = "analytics_disabled" ]; then
      TOPIC="$ANALYTICS_TRIGGER_TOPIC"
    else
      TOPIC="$ALERT_TRIGGER_TOPIC"
    fi
    echo "Using default topic: $TOPIC"
  fi

  if [ -z "$FILENAME" ]; then
    if [ "$MESSAGE_TYPE" = "analytics_disabled" ]; then
      FILENAME="analytics-disabled.json"
    else
      FILENAME="alert-true.json"
    fi
    echo "Using default filename: $FILENAME"
  fi

  # Resolve filename path - if it's just a filename, look in sample-data directory
  if [[ "$FILENAME" != /* ]] && [[ ! -f "$FILENAME" ]]; then
    # If filename doesn't start with / (not absolute) and file doesn't exist in current dir,
    # try to find it in the sample-data directory
    SAMPLE_DATA_FILE="${SAMPLE_DATA_DIR}/${FILENAME}"
    if [[ -f "$SAMPLE_DATA_FILE" ]]; then
      FILENAME="$SAMPLE_DATA_FILE"
      echo "Using sample data file: $FILENAME"
    elif [[ -f "${SAMPLE_DATA_DIR}/$(basename "$FILENAME")" ]]; then
      FILENAME="${SAMPLE_DATA_DIR}/$(basename "$FILENAME")"
      echo "Using sample data file: $FILENAME"
    fi
  fi

  # Verify the file exists
  if [[ ! -f "$FILENAME" ]]; then
    echo "Error: File not found: $FILENAME"
    echo ""
    echo "Available sample files in ${SAMPLE_DATA_DIR}:"
    if [[ -d "$SAMPLE_DATA_DIR" ]]; then
      find "$SAMPLE_DATA_DIR" -maxdepth 1 -type f -exec basename {} \; | sort | sed 's/^/  /'
      echo ""
      echo "You can use any of these files with: -f filename"
      echo "For example: $0 -f alert-true.json"
    else
      echo "  (sample-data directory not found at $SAMPLE_DATA_DIR)"
    fi
    exit 1
  fi

  echo "Using file: $FILENAME"
  echo "Using topic: $TOPIC"

  TMPFILE=""
  if [ "$UPDATE_TIME" = true ]; then
    TMPFILE=$(mktemp)
    NOW_MS=$((($(date +%s) + OFFSET_SECS) * 1000 + $(date +%3N)))

    if [ "$MESSAGE_TYPE" = "alert" ]; then
      # Generate a random event_id between 1000 and 9999
      EVENT_ID=$((RANDOM % 9000 + 1000))
      echo "Updating .attributes.devices[].device_data.timestamp and .attributes.devices[].device_data.event_id in $FILENAME to $NOW_MS and $EVENT_ID"
      JQ_FILTER='.'
      JQ_FILTER="$JQ_FILTER | .attributes.devices = (.attributes.devices | map(
                if type == \"object\" and has(\"device_data\") and (.device_data | type == \"object\") then
                    .device_data.timestamp = $NOW_MS | .device_data.event_id = $EVENT_ID
                else . end
            ))"
    elif [ "$MESSAGE_TYPE" = "analytics_disabled" ]; then
      echo "Updating timestamp in $FILENAME to $NOW_MS"
      JQ_FILTER='. | .timestamp = '$NOW_MS
    else
      echo "Error: Unsupported message type: $MESSAGE_TYPE"
      exit 1
    fi

    jq "$JQ_FILTER" "$FILENAME" >"$TMPFILE"
    cat "$TMPFILE" # Show the updated JSON for debugging
    if [ "$SHOW_LOCAL_TIME" = true ]; then
      LOCAL_TIME=$(date -d "@$(($(date +%s) + OFFSET_SECS))" +"%Y-%m-%d %H:%M:%S %Z")
      echo "Local readable time: $LOCAL_TIME"
    fi
    FILENAME="$TMPFILE"
  fi

  # Read and prepare the message content
  FLATTENED_CONTENT=$(tr -d '\n' <"$FILENAME")

  echo "Using mosquitto container: $MOSQUITTO_CONTAINER"
  echo "Sending message to topic: $TOPIC"
  echo "Message content preview:"
  echo "$FLATTENED_CONTENT" | jq . || echo "$FLATTENED_CONTENT"
  echo ""

  # Use docker exec to send MQTT message via the mosquitto container
  # No TLS, no authentication needed for local testing
  docker exec "$MOSQUITTO_CONTAINER" mosquitto_pub \
    -h localhost \
    -p 1883 \
    -t "$TOPIC" \
    -m "$FLATTENED_CONTENT"

  echo "✓ Message sent successfully to $TOPIC"

  # Clean up temp file if used
  if [ -n "$TMPFILE" ]; then
    rm -f "$TMPFILE"
  fi
}

# Main script logic
case "${1:-help}" in
  "alert" | "a" | "alert-past" | "ap" | "analytics" | "an" | "manual" | "m")
    echo "Media Capture Service Local Test Script"
    echo "======================================="
    echo ""
    run_quick_test "$1"
    ;;
  "help" | "h" | "-h" | "--help")
    help
    ;;
  *)
    # If first argument doesn't match quick scenarios, treat as advanced usage
    if [[ "$1" =~ ^- ]]; then
      # Starts with dash, advanced usage
      run_advanced_test "$@"
    else
      # Unknown command, show help
      echo "Unknown command: $1"
      echo ""
      help
      exit 1
    fi
    ;;
esac
