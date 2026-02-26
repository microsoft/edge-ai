# Decision: Switch 507-ai-inference to YOLOv8n Leak Model

**Date:** 2026-02-25
**Author:** Parker (Edge Developer)
**Requested by:** Carlos Sardo
**Status:** Implemented

## Context

The 507-ai-inference deployment was configured to download and use `tinyyolov2-8.onnx` as its default model. This is a generic 20-class COCO object detection model, not suitable for leak detection.

## Decision

Switched all model references to `yolov8n-leak.onnx` — a YOLOv8 Nano model fine-tuned for single-class industrial leak detection.

### Changes

1. **Init container** — downloads `yolov8n-leak.onnx` from GitHub as `default.onnx`
2. **DEFAULT_MODELS env var** — changed to `yolov8n-leak` (maps to `default.onnx` via catch-all in Rust config parser)
3. **Model config path** — corrected from relative `models/yolov8n_leak.onnx` to absolute `/models/yolov8n-leak/yolov8n-leak.onnx`
4. **Model-downloader job** — now writes `yolov8n_leak.yaml` config to PVC via heredoc, matching `MODEL_CONFIG_PATH`

## Rationale

- Model config inlined in the job script (heredoc) rather than a ConfigMap keeps the model-downloader self-contained.
- The Rust `parse_default_models` catch-all means `yolov8n-leak` still resolves to `default.onnx` at runtime — no Rust code changes needed.

## Impact

- Breaking change: init container no longer downloads Tiny YOLOv2. Any workflow depending on that model at `/models/default.onnx` will now get the leak detection model instead.
- Single result class: `"leak"` (was 20 COCO classes).
