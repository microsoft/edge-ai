#!/bin/bash

set -e

# Media Capture Service Test Script - Kubernetes
# Combines simple test scenarios with advanced MQTT testing capabilities
# Designed for use with deployed Kubernetes clusters

# Default MQTT topics for the media capture service
DEFAULT_ALERT_TRIGGER_TOPIC="alerts/trigger"
DEFAULT_ANALYTICS_TRIGGER_TOPIC="analytics/disabled"

# Use environment variables if set, otherwise use defaults
ALERT_TRIGGER_TOPIC="${ALERT_TRIGGER_TOPIC:-$DEFAULT_ALERT_TRIGGER_TOPIC}"
ANALYTICS_TRIGGER_TOPIC="${ANALYTICS_TRIGGER_TOPIC:-$DEFAULT_ANALYTICS_TRIGGER_TOPIC}"

# Get script directory and sample-data path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DATA_DIR="${SCRIPT_DIR}/../services/media-capture-service/sample-data"

# Function to show help
help() {
    echo "Media Capture Service Test Script - Kubernetes"
    echo "============================================="
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
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Test alert with current time"
    echo "  $0 -l                                 # Test alert and show local time"
    echo "  $0 -u -5 -l                          # Test alert 5 seconds ago"
    echo "  $0 -f analytics-disabled.json -m analytics_disabled"
    echo "  $0 -t custom/topic -f manual-trigger.json"
    echo ""
    echo "Environment Variables:"
    echo "  ALERT_TRIGGER_TOPIC      Default alert topic (current: $ALERT_TRIGGER_TOPIC)"
    echo "  ANALYTICS_TRIGGER_TOPIC  Default analytics topic (current: $ANALYTICS_TRIGGER_TOPIC)"
    echo "  FIELD_NAMESPACE          Kubernetes namespace (default: azure-iot-operations)"
}

# Function to run quick test scenarios
run_quick_test() {
    case "$1" in
        "alert"|"a")
            echo "Testing ALERT trigger with current timestamp..."
            run_advanced_test -u -l -f alert-true.json
            ;;
        "alert-past"|"ap")
            echo "Testing ALERT trigger with timestamp 5 seconds ago..."
            run_advanced_test -u -5 -l -f alert-true.json
            ;;
        "analytics"|"an")
            echo "Testing ANALYTICS DISABLED trigger..."
            run_advanced_test -u -l -f analytics-disabled.json -m analytics_disabled
            ;;
        "manual"|"m")
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
            *)
                break
                ;;
        esac
        shift
    done

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
        NOW_MS=$(( ($(date +%s) + OFFSET_SECS) * 1000 + $(date +%3N) ))

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

        jq "$JQ_FILTER" "$FILENAME" > "$TMPFILE"
        cat "$TMPFILE" # Show the updated JSON for debugging
        if [ "$SHOW_LOCAL_TIME" = true ]; then
            LOCAL_TIME=$(date -d "@$(( $(date +%s) + OFFSET_SECS ))" +"%Y-%m-%d %H:%M:%S %Z")
            echo "Local readable time: $LOCAL_TIME"
        fi
        FILENAME="$TMPFILE"
    fi

    FLATTENED_CONTENT=$(tr -d '\n' < "$FILENAME")
    ESCAPED_MESSAGE=${FLATTENED_CONTENT//\"/\\\"}

    # Get the mqtt-tools pod name dynamically
    MQTT_TOOLS_POD=$(kubectl get pods -n "${FIELD_NAMESPACE:-azure-iot-operations}" -l app=mqtt-tools -o jsonpath='{.items[0].metadata.name}')
    if [ -z "$MQTT_TOOLS_POD" ]; then
        echo "Error: No mqtt-tools pod found. Please deploy the mqtt-tools first:"
        echo "kubectl apply -f /workspaces/edge-ai/src/900-tools-utilities/900-mqtt-tools/yaml/mqtt-tools.yaml"
        exit 1
    fi

    echo "Using mqtt-tools pod: $MQTT_TOOLS_POD"
    echo "Sending message to $TOPIC"
    kubectl exec --stdin --tty "$MQTT_TOOLS_POD" -n "${FIELD_NAMESPACE:-azure-iot-operations}" -- sh -c "mosquitto_pub --host aio-broker.azure-iot-operations --port 18883 --username 'K8S-SAT' --pw \$(cat /var/run/secrets/tokens/broker-sat) --debug --cafile /var/run/certs/ca.crt --topic $TOPIC --message \"$ESCAPED_MESSAGE\""

    # Clean up temp file if used
    if [ -n "$TMPFILE" ]; then
        rm -f "$TMPFILE"
    fi
}

# Main script logic
case "${1:-help}" in
    "alert"|"a"|"alert-past"|"ap"|"analytics"|"an"|"manual"|"m")
        echo "Media Capture Service Quick Test Script"
        echo "======================================="
        echo ""
        run_quick_test "$1"
        ;;
    "help"|"h"|"-h"|"--help")
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
