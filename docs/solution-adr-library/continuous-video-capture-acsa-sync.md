---
title: Continuous Video Capture with ACSA Cloud Synchronization
description: Architecture Decision Record for recording continuous video segments at the edge with the Media Capture Service and synchronizing them to Azure Blob Storage through Azure Container Storage enabled by Azure Arc (ACSA) for time-based video retrieval
author: Edge AI Team
ms.date: 2026-10-05
ms.topic: architecture
estimated_reading_time: 8
keywords:
  - video-capture
  - continuous-recording
  - acsa
  - azure-iot-operations
  - blob-storage
  - video-query
  - ffmpeg
  - architecture-decision-record
---

## Status

- [ ] Draft
- [x] Proposed
- [ ] Accepted
- [ ] Deprecated

## Context

Operations and data science teams need to retrieve historical video from edge cameras by camera and time range, for incident investigation, quality analysis, and training data collection. Event-triggered clips only cover the seconds around an alert, so they can't answer questions about periods without an alert.

The solution needs to:

- Record each camera continuously in segments small enough to upload and retrieve individually
- Keep recording through cloud connectivity outages and upload the backlog when connectivity returns
- Store segments in Azure Blob Storage with a layout that supports listing by camera and time range
- Keep enough metadata with each segment to return precise start and end times without opening the video

Two existing components handle video at the edge:

- **Media Connector (508)**: The Azure IoT Operations connector for snapshots, clips, and live RTSP proxying, configured through Device Registry assets
- **Media Capture Service (503)**: A Rust workload that buffers an RTSP stream in memory and writes clips around MQTT-triggered events to an ACSA cloud-backed volume

The Media Connector's `clip-to-fs` task writes clips of a configured duration to a storage path, but it doesn't write segment metadata, apply local retention, or name files for time-range listing. The Media Capture Service already writes to a cloud-backed ACSA volume.

## Decision

Add a continuous recording mode to the Media Capture Service (503). In this mode, the service records back-to-back segments with `ffmpeg` into the ACSA cloud-backed volume, and ACSA uploads them to Azure Blob Storage. The Media Connector (508) remains responsible for snapshots, live stream proxying, and camera management through Device Registry assets.

### Component Responsibilities

| Capability                                     | Component                   |
|------------------------------------------------|-----------------------------|
| Continuous segment recording and cloud archive | Media Capture Service (503) |
| Event-triggered clips with pre-event buffering | Media Capture Service (503) |
| Snapshots to MQTT or the file system           | Media Connector (508)       |
| Live RTSP and RTSPS proxying                   | Media Connector (508)       |
| ONVIF camera management                        | ONVIF connector             |
| Time-based retrieval from Blob Storage         | Video query API (520)       |

### Storage Layout

Each segment and its metadata file are written to a path derived from the camera ID and the segment start time in UTC:

```text
{camera_id}/{YYYY}/{MM}/{DD}/{HH}/segment_{start}_{camera_id}.mp4
{camera_id}/{YYYY}/{MM}/{DD}/{HH}/segment_{start}_{camera_id}.json
```

ACSA preserves the relative path in Blob Storage, so a query for a camera and time range lists one blob prefix per hour. Triggered clips use the same `{camera_id}/{YYYY}/{MM}/{DD}/{HH}/` directories with their own file names, so one prefix listing returns both kinds of recording.

The metadata file holds `camera_id`, `location`, `segment_start`, `segment_end`, `duration_seconds`, and `file_name`.

### Recording Behavior

- `ffmpeg` re-encodes each segment to 360p H.264 with AAC audio to bound CPU, memory, and upload volume
- `ffmpeg` writes to a `.partial` file that is renamed after it succeeds, so only complete segments get final names; partial files from an interrupted run are deleted at startup
- A local retention task deletes segments older than a configurable age as a safety net for volume capacity
- Each deployment records one camera; multiple cameras use one Helm release per camera

## Decision Drivers

- **No custom upload code**: ACSA already provides retry, offline buffering, and upload to Blob Storage for files written to a cloud-backed volume
- **Reuse of an ACSA-integrated workload**: The Media Capture Service already deploys with a cloud-backed volume, MQTT authentication, and a Helm chart
- **Prefix-friendly layout**: Hourly directories let the query API list a time range without scanning the container
- **Bounded edge resources**: Segment re-encoding and local retention keep CPU, memory, and disk use predictable on small edge nodes

## Considered Options

### Option 1: Continuous Mode in the Media Capture Service with ACSA Sync (Selected)

The service writes segments and metadata to the ACSA volume and doesn't call Azure Storage APIs.

- ✅ Upload, retry, and offline buffering are handled by ACSA
- ✅ Reuses the service's existing chart, volume, and deployment model
- ⚠️ Cloud availability lags recording by the ACSA upload delay
- ⚠️ Requires a cloud-backed ACSA volume and storage account access for the ACSA extension identity

### Option 2: Media Connector Clip Tasks

Configure `clip-to-fs` stream tasks on media connector assets to write clips to a mounted volume.

- ✅ No custom workload
- ❌ No segment metadata or local retention control
- ❌ Output naming isn't designed for time-range listing

### Option 3: Direct Upload with the Azure Storage SDK

Upload each segment from the recorder with the Azure Storage SDK.

- ✅ No ACSA dependency and lower upload latency
- ❌ Requires custom retry, offline queueing, and credential handling at the edge
- ❌ Duplicates capabilities ACSA already provides

## Consequences

### Positive

- Continuous video is available in Blob Storage by camera and hour without custom upload code
- Recording continues during connectivity outages, limited by the volume capacity and local retention setting
- The query API can return precise segment times from metadata without downloading video

### Negative

- Segments become available in Blob Storage only after ACSA uploads them
- Local retention deletes segments by age whether or not ACSA has uploaded them, so the retention period must exceed the longest expected outage
- Triggered clips moved from date directories to the hourly camera layout, which affects existing path-based consumers
- Back-to-back recording has a short gap between segments while `ffmpeg` reconnects

### Neutral

- Each camera needs its own deployment, which isolates failures but adds releases to manage
- Storage tiering and deletion in the cloud are managed with Blob Storage lifecycle policies outside this component

## Future Considerations

- Blob index tags written at upload time would allow tag-based queries across cameras
- Recording without re-encoding (stream copy) would reduce CPU use where the camera codec and bit rate are acceptable
- Upload backlog and segment gap metrics would improve operational monitoring

## References

- [Media Capture Service](../../src/500-application/503-media-capture-service/README.md)
- [Video and Image Capture from Edge-Attached Cameras](./edge-video-streaming-and-image-capture.md)
- [Azure Container Storage enabled by Azure Arc overview](https://learn.microsoft.com/azure/azure-arc/container-storage/overview)
- [Configure the media connector](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/howto-use-media-connector)
