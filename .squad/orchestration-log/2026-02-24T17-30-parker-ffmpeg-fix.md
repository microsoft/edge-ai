# Orchestration Log: Parker — FFmpeg Video Loop Crash Fix

**Session**: 2026-02-24T17:30:00Z
**Agent**: Parker (Edge Developer)
**Status**: COMPLETED
**Mode**: sync (via runSubagent)

## Objective

Fix FFmpeg crashing every ~4 minutes when looping `leaking-pipe.mp4` via `-stream_loop -1` in the ONVIF camera simulator. User Carlos Sardo reported the RTSP stream disconnecting when swapping from `pipe.jpg` to `leaking-pipe.mp4`.

## Root Cause

FFmpeg's RTSP muxer crashes on the timestamp discontinuity when seeking back to frame 0 at the video loop boundary. The RTSP output cannot handle the PTS jump from end-of-file back to zero.

## Changes Made

### `blueprints/leak-detection/services/onvif-camera-simulator/src/rtsp_manager.py`

1. **`-fflags +genpts`** — Added before `-i` in the video source FFmpeg branch. Regenerates presentation timestamps at each loop boundary, eliminating the PTS discontinuity that caused the crash.
2. **1-second delay in `restart_stream()`** — Added `asyncio.sleep(1)` before restarting FFmpeg to allow MediaMTX to fully tear down the old RTSP path, preventing a publish-path race condition.
3. **`-nostdin` on all FFmpeg branches** — Added to all four FFmpeg command construction paths. Prevents stdin-related hangs in headless container environments.

## Outcome

ONVIF camera simulator streams `leaking-pipe.mp4` in a stable continuous loop over RTSP without crashing at loop boundaries.
