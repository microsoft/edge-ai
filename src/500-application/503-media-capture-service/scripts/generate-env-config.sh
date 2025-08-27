#!/bin/bash

# Generate Environment Configuration for Media Capture Service
# This script creates a .env file with all required environment variables
# for running the media-capture-service with Docker Compose or other deployment methods.
# It uses current environment variables as values, with sensible defaults for unset variables.

set -e  # Exit immediately if a command exits with a non-zero status

CURRENT_DIR=$(dirname "$0")

# Default environment variables
AIO_BROKER_HOSTNAME=${AIO_BROKER_HOSTNAME:-aio-broker.azure-iot-operations}
AIO_BROKER_TCP_PORT=${AIO_BROKER_TCP_PORT:-18883}
AIO_TLS_CA_FILE=${AIO_TLS_CA_FILE:-/var/run/certs/ca.crt}
AIO_SAT_FILE=${AIO_SAT_FILE:-/var/run/secrets/tokens/mq-sat}
RUST_LOG=${RUST_LOG:-info}
TRIGGER_TOPICS=${TRIGGER_TOPICS:-'["alerts/trigger", "analytics/disabled"]'}
MEDIA_CLOUD_SYNC_DIR=${MEDIA_CLOUD_SYNC_DIR:-/cloud-sync/media}
RTSP_URL=${RTSP_URL:-rtsp://mock-camera-fof.eastus2.azurecontainer.io:8554/live}
VIDEO_FPS=${VIDEO_FPS:-20}
FRAME_WIDTH=${FRAME_WIDTH:-896}
FRAME_HEIGHT=${FRAME_HEIGHT:-512}
BUFFER_SECONDS=${BUFFER_SECONDS:-60} # if you want to be able to access clips from up to 1 minute ago if needed
AIO_MQTT_CLIENT_ID=${AIO_MQTT_CLIENT_ID:-media-capture-service}
CAPTURE_DURATION_SECONDS=${CAPTURE_DURATION_SECONDS:-10}
VIDEO_FEED_DELAY_SECONDS=${VIDEO_FEED_DELAY_SECONDS:-5}

# Generate .env file
cat <<EOF > "${CURRENT_DIR}"/../.env
# Container Registry Configuration
ACR_NAME=${ACR_NAME}

# Azure IoT Operations Configuration
AIO_BROKER_HOSTNAME=${AIO_BROKER_HOSTNAME}
AIO_BROKER_TCP_PORT=${AIO_BROKER_TCP_PORT}
AIO_TLS_CA_FILE=${AIO_TLS_CA_FILE}
AIO_SAT_FILE=${AIO_SAT_FILE}
AIO_MQTT_CLIENT_ID=${AIO_MQTT_CLIENT_ID}

# Logging Configuration
RUST_LOG=${RUST_LOG}

# MQTT Topics Configuration
TRIGGER_TOPICS=${TRIGGER_TOPICS}

# Media Storage Configuration
MEDIA_CLOUD_SYNC_DIR=${MEDIA_CLOUD_SYNC_DIR}

# RTSP Camera Configuration
RTSP_URL=${RTSP_URL}

# Video Processing Configuration
VIDEO_FPS=${VIDEO_FPS}
FRAME_WIDTH=${FRAME_WIDTH}
FRAME_HEIGHT=${FRAME_HEIGHT}
BUFFER_SECONDS=${BUFFER_SECONDS}
CAPTURE_DURATION_SECONDS=${CAPTURE_DURATION_SECONDS}
VIDEO_FEED_DELAY_SECONDS=${VIDEO_FEED_DELAY_SECONDS}
EOF
