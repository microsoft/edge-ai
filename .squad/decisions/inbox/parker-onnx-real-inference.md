# Decision: Replace Simulated ONNX Inference with Real ort::Session Execution

**Date:** 2026-02-25
**Author:** Parker (Edge Developer)
**Requested by:** Carlos Sardo
**Status:** Implemented

## Context

The 507-ai-inference service was producing wrong predictions ("person", "class_52", "class_355") instead of "leak" despite being configured with the correct YOLOv8n leak detection model. Three layers of bugs prevented real inference from executing:

1. **Simulated ONNX backend** — `onnx.rs` never called `ort::Session::run()`. It loaded the ONNX file but generated hardcoded synthetic predictions using `uuid::Uuid` hashes to pick random class names from COCO-style labels.
2. **Uninitialized YAML config system** — `main.rs` never called `initialize_yaml_config_system()` or `load_model_from_yaml()`, so `ModelConfig.postprocessing` was always `None`. The backend received no class labels, confidence thresholds, or postprocessing type from the YAML config.
3. **Config catch-all ignored model name** — `config.rs::parse_default_models` mapped every unrecognized model name to hardcoded `"default.onnx"` regardless of the actual model name string.

## Decision

Rewrote `onnx.rs` to perform real ONNX Runtime inference, fixed `main.rs` to initialize the YAML config pipeline, and corrected the `config.rs` catch-all.

### Changes

| File | Change |
|------|--------|
| `ai-edge-inference-crate/src/backends/onnx.rs` | Complete rewrite: `OnnxModel` stores `Mutex<ort::session::Session>` with parsed config. `prepare_input_from_image()` resizes and normalizes to NCHW float32. `run_session_inference()` calls `session.run()` via `ort::value::Tensor::from_array`. `process_yolov8_output()` handles `[1, 5, 8400]` format with NMS. `process_classification_output()` as fallback. |
| `ai-edge-inference/src/main.rs` | Added YAML config system initialization block after `engine.initialize()`: calls `initialize_yaml_config_system()` with `MODELS_DIRECTORY` env var, loads model from `MODEL_CONFIG_PATH` env var. |
| `ai-edge-inference/src/config.rs` | Changed `parse_default_models` catch-all from hardcoded `"default.onnx"` to `format!("{}.onnx", model_name)`. |

## Rationale

- **Mutex wrapping** — `ort::session::Session::run()` requires `&mut self` but `InferenceBackend::infer()` takes `&self`. `std::sync::Mutex` provides interior mutability without changing the trait signature.
- **No ndarray for ort input** — The crate enables `ndarray` as a separate dependency but not `ort/ndarray`. Input tensors use `Tensor::from_array((shape_vec, data_vec))` tuple form which is always available.
- **YOLOv8 output layout** — Output shape `[1, 5, 8400]` is row-major with layout `[row][detection]`. Row 0-3 are box coordinates (cx, cy, w, h), row 4 is class confidence. NMS uses IoU threshold 0.4.

## Impact

- Breaking change: the backend no longer produces synthetic predictions. If no ONNX model file is present at the configured path, `load_model` will fail instead of silently succeeding.
- Single result class: `"leak"` with bounding box coordinates when using the `yolov8n-leak.onnx` model.
- Predictions include severity metadata: `high` (>0.7), `medium` (>0.4), `low` (<=0.4).
