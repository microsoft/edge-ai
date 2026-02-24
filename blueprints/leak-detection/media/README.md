---
title: Media Files
description: Directory for JPEG and MP4 media files used as camera sources in the ONVIF Camera Simulator
---

Directory for media files used as camera sources by the ONVIF Camera Simulator service.

## Supported Formats

* **Still images:** `.jpg`, `.jpeg`, `.png`
* **Video files:** `.mp4`, `.avi`

## Adding Custom Files

Place media files in this directory. They appear automatically in the simulator web UI for selection as camera sources.

## Default Test Image

Generate a default test image with FFmpeg:

```bash
ffmpeg -f lavfi -i color=c=blue:s=1920x1080:d=1 -frames:v 1 default.jpg
```

This creates a 1920x1080 blue frame suitable for basic camera stream testing.
