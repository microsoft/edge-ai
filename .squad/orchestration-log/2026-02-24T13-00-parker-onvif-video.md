# Orchestration Log: Parker — ONVIF Camera Simulator Video Config

**Session**: 2026-02-24T13:00:00Z
**Agent**: Parker (Edge Developer)
**Status**: COMPLETED
**Mode**: lightweight

## Objective

Update the ONVIF camera simulator to stream `leaking-pipe.mp4` instead of the FFmpeg test pattern, enabling realistic leak detection demo scenarios.

## Changes Made

### 1. Dockerfile

- Added `COPY leaking-pipe.mp4` directive to include the video file in the container image
- Video streams in a loop as the RTSP source

### 2. deployment.yaml

- Changed configuration from test-pattern generator to video file source
- Simulator now serves `leaking-pipe.mp4` over RTSP

### 3. Build Script

- Copies `leaking-pipe.mp4` from `blueprints/leak-detection/media/` into the Docker build context before build
- Cleans up the copied file after build completes
- Video file lives outside the ONVIF service directory to avoid bloating the service source

## Outcome

ONVIF camera simulator streams realistic leaking pipe footage over RTSP for consumption by 503-media-capture-service and 508-media-connector.
