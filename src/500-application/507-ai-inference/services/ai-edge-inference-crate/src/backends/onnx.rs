use std::collections::HashMap;
use std::sync::Mutex;
use tracing::{debug, info};
use async_trait::async_trait;

use crate::backend::{
    InferenceBackend, BackendConfig, BackendError, BackendStatus, BackendType,
    DeviceType, OptimizationLevel
};
use crate::{InferenceInput, InferenceResult, ModelConfig};

/// ONNX Runtime backend implementation
#[cfg(feature = "onnx-runtime")]
pub struct OnnxRuntimeBackend {
    environment_initialized: bool,
    config: Option<BackendConfig>,
    loaded_models: HashMap<String, OnnxModel>,
    stats: Mutex<BackendStats>,
}

#[cfg(feature = "onnx-runtime")]
impl std::fmt::Debug for OnnxRuntimeBackend {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("OnnxRuntimeBackend")
            .field("environment_initialized", &self.environment_initialized)
            .field("config", &self.config)
            .field("loaded_models", &self.loaded_models.keys().collect::<Vec<_>>())
            .field("stats", &self.stats.lock().ok().map(|stats| stats.clone()))
            .finish()
    }
}

#[cfg(feature = "onnx-runtime")]
struct OnnxModel {
    name: String,
    model_path: String,
    session: Mutex<ort::session::Session>,
    input_name: String,
    input_shape: Vec<i64>,
    class_labels: Vec<String>,
    confidence_threshold: f32,
    nms_threshold: f32,
    top_k: usize,
    postprocess_type: String,
}

#[cfg(feature = "onnx-runtime")]
impl std::fmt::Debug for OnnxModel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("OnnxModel")
            .field("name", &self.name)
            .field("model_path", &self.model_path)
            .field("input_name", &self.input_name)
            .field("input_shape", &self.input_shape)
            .field("class_labels", &self.class_labels)
            .field("confidence_threshold", &self.confidence_threshold)
            .field("nms_threshold", &self.nms_threshold)
            .field("top_k", &self.top_k)
            .field("postprocess_type", &self.postprocess_type)
            .finish()
    }
}

#[cfg(feature = "onnx-runtime")]
#[derive(Debug, Clone)]
struct BackendStats {
    models_loaded: usize,
    total_inferences: u64,
    total_errors: u64,
    average_inference_time_ms: f64,
}

#[cfg(feature = "onnx-runtime")]
impl Default for OnnxRuntimeBackend {
    fn default() -> Self {
        Self::new()
    }
}

/// ONNX Runtime session options derived from [`BackendConfig`].
///
/// `None` leaves the ONNX Runtime default in place.
#[cfg(feature = "onnx-runtime")]
#[derive(Debug, Default, Clone, Copy)]
struct SessionOptions {
    optimization_level: Option<ort::session::builder::GraphOptimizationLevel>,
    parallel_execution: Option<bool>,
    intra_threads: Option<usize>,
    inter_threads: Option<usize>,
}

#[cfg(feature = "onnx-runtime")]
impl SessionOptions {
    fn from_config(config: Option<&BackendConfig>) -> Self {
        let Some(config) = config else {
            return Self::default();
        };
        let onnx_config = config.onnx_config.as_ref();
        Self {
            optimization_level: Some(graph_optimization_level(&config.optimization_level)),
            parallel_execution: Some(config.parallel_execution),
            intra_threads: onnx_config.and_then(|onnx| onnx.intra_op_num_threads),
            inter_threads: onnx_config.and_then(|onnx| onnx.inter_op_num_threads),
        }
    }

    /// Applies each configured option to `target`, naming the option in any error.
    fn apply<T: SessionOptionTarget>(&self, target: T) -> Result<T, BackendError> {
        let mut target = target;
        if let Some(level) = self.optimization_level {
            target = target
                .set_optimization_level(level)
                .map_err(|e| session_option_error(OPTION_OPTIMIZATION_LEVEL, e))?;
        }
        if let Some(parallel) = self.parallel_execution {
            target = target
                .set_parallel_execution(parallel)
                .map_err(|e| session_option_error(OPTION_PARALLEL_EXECUTION, e))?;
        }
        if let Some(threads) = self.intra_threads {
            target = target
                .set_intra_threads(threads)
                .map_err(|e| session_option_error(OPTION_INTRA_THREADS, e))?;
        }
        if let Some(threads) = self.inter_threads {
            target = target
                .set_inter_threads(threads)
                .map_err(|e| session_option_error(OPTION_INTER_THREADS, e))?;
        }
        Ok(target)
    }

    fn builder(&self) -> Result<ort::session::builder::SessionBuilder, BackendError> {
        let builder = ort::session::Session::builder().map_err(|e| {
            BackendError::ModelLoadFailed(format!("Failed to create session builder: {}", e))
        })?;
        self.apply(builder)
    }

    /// Describes the effective settings; `default` means ONNX Runtime chooses.
    fn describe(&self) -> std::collections::BTreeMap<String, String> {
        fn value<T: std::fmt::Debug>(option: Option<T>) -> String {
            option
                .map(|v| format!("{:?}", v).to_lowercase())
                .unwrap_or_else(|| "default".to_string())
        }
        [
            (OPTION_OPTIMIZATION_LEVEL, value(self.optimization_level)),
            (OPTION_PARALLEL_EXECUTION, value(self.parallel_execution)),
            (OPTION_INTRA_THREADS, value(self.intra_threads)),
            (OPTION_INTER_THREADS, value(self.inter_threads)),
        ]
        .into_iter()
        .map(|(name, value)| (name.to_string(), value))
        .collect()
    }
}

#[cfg(feature = "onnx-runtime")]
const OPTION_OPTIMIZATION_LEVEL: &str = "optimization level";
#[cfg(feature = "onnx-runtime")]
const OPTION_PARALLEL_EXECUTION: &str = "parallel execution";
#[cfg(feature = "onnx-runtime")]
const OPTION_INTRA_THREADS: &str = "intra-op thread count";
#[cfg(feature = "onnx-runtime")]
const OPTION_INTER_THREADS: &str = "inter-op thread count";

/// Session option setters, implemented by the ONNX Runtime session builder.
#[cfg(feature = "onnx-runtime")]
trait SessionOptionTarget: Sized {
    fn set_optimization_level(
        self,
        level: ort::session::builder::GraphOptimizationLevel,
    ) -> Result<Self, String>;
    fn set_parallel_execution(self, parallel: bool) -> Result<Self, String>;
    fn set_intra_threads(self, threads: usize) -> Result<Self, String>;
    fn set_inter_threads(self, threads: usize) -> Result<Self, String>;
}

#[cfg(feature = "onnx-runtime")]
impl SessionOptionTarget for ort::session::builder::SessionBuilder {
    fn set_optimization_level(
        self,
        level: ort::session::builder::GraphOptimizationLevel,
    ) -> Result<Self, String> {
        self.with_optimization_level(level)
            .map_err(|e| e.to_string())
    }

    fn set_parallel_execution(self, parallel: bool) -> Result<Self, String> {
        self.with_parallel_execution(parallel)
            .map_err(|e| e.to_string())
    }

    fn set_intra_threads(self, threads: usize) -> Result<Self, String> {
        self.with_intra_threads(threads).map_err(|e| e.to_string())
    }

    fn set_inter_threads(self, threads: usize) -> Result<Self, String> {
        self.with_inter_threads(threads).map_err(|e| e.to_string())
    }
}

#[cfg(feature = "onnx-runtime")]
fn graph_optimization_level(
    level: &OptimizationLevel,
) -> ort::session::builder::GraphOptimizationLevel {
    use ort::session::builder::GraphOptimizationLevel;
    match level {
        OptimizationLevel::None => GraphOptimizationLevel::Disable,
        OptimizationLevel::Basic => GraphOptimizationLevel::Level1,
        OptimizationLevel::Extended => GraphOptimizationLevel::Level2,
        OptimizationLevel::All => GraphOptimizationLevel::All,
    }
}

#[cfg(feature = "onnx-runtime")]
fn session_option_error(option: &str, error: impl std::fmt::Display) -> BackendError {
    BackendError::ModelLoadFailed(format!("Failed to set ONNX Runtime {}: {}", option, error))
}

/// Raw detection before NMS
#[cfg(feature = "onnx-runtime")]
#[derive(Debug, Clone)]
struct RawDetection {
    x1: f32,
    y1: f32,
    x2: f32,
    y2: f32,
    confidence: f32,
    class_id: usize,
}

#[cfg(feature = "onnx-runtime")]
impl OnnxRuntimeBackend {
    pub fn new() -> Self {
        Self {
            environment_initialized: false,
            config: None,
            loaded_models: HashMap::new(),
            stats: Mutex::new(BackendStats {
                models_loaded: 0,
                total_inferences: 0,
                total_errors: 0,
                average_inference_time_ms: 0.0,
            }),
        }
    }

    fn record_inference_stats(&self, elapsed_ms: f64, successful: bool) {
        let mut stats = match self.stats.lock() {
            Ok(stats) => stats,
            Err(error) => {
                debug!("Failed to update backend stats due to poisoned lock: {}", error);
                return;
            }
        };

        stats.total_inferences += 1;

        if !successful {
            stats.total_errors += 1;
        }

        let count = stats.total_inferences as f64;
        let previous = stats.average_inference_time_ms;
        stats.average_inference_time_ms = ((previous * (count - 1.0)) + elapsed_ms) / count;
    }

    /// Parse postprocessing config from ModelConfig JSON
    fn parse_postprocessing(model_config: &ModelConfig) -> (Vec<String>, f32, f32, usize, String) {
        // Default top-K for classification outputs; overridable via postprocessing.top_k.
        const DEFAULT_TOP_K: usize = 3;

        let mut class_labels: Vec<String> = Vec::new();
        let mut confidence_threshold = model_config.confidence_threshold.unwrap_or(0.5);
        let mut nms_threshold = 0.4f32;
        let mut top_k: usize = DEFAULT_TOP_K;
        let mut postprocess_type = "classification".to_string();

        if let Some(post) = &model_config.postprocessing {
            if let Some(pt) = post.get("postprocess_type").and_then(|v| v.as_str()) {
                postprocess_type = pt.to_string();
            }
            if let Some(ct) = post.get("confidence_threshold").and_then(|v| v.as_f64()) {
                confidence_threshold = ct as f32;
            }
            if let Some(nt) = post.get("nms_threshold").and_then(|v| v.as_f64()) {
                nms_threshold = nt as f32;
            }
            if let Some(k) = post.get("top_k").and_then(|v| v.as_u64()) {
                top_k = k as usize;
            }
            if let Some(labels) = post.get("class_labels").and_then(|v| v.as_array()) {
                class_labels = labels.iter()
                    .filter_map(|v| v.as_str().map(|s| s.to_string()))
                    .collect();
            }
        }

        (class_labels, confidence_threshold, nms_threshold, top_k, postprocess_type)
    }

    /// Parse input shape from ModelConfig preprocessing JSON or use defaults
    fn parse_input_shape(model_config: &ModelConfig) -> Vec<i64> {
        if let Some(pre) = &model_config.preprocessing {
            if let Some(target_size) = pre.get("target_size").and_then(|v| v.as_array()) {
                let dims: Vec<i64> = target_size.iter()
                    .filter_map(|v| v.as_i64())
                    .collect();
                if dims.len() == 2 {
                    return vec![1, 3, dims[0], dims[1]];
                }
            }
            if let Some(shape) = pre.get("shape").and_then(|v| v.as_array()) {
                let dims: Vec<i64> = shape.iter()
                    .filter_map(|v| v.as_i64())
                    .collect();
                if dims.len() == 4 {
                    return dims;
                }
            }
        }
        // Default to YOLOv8 640x640 input
        vec![1, 3, 640, 640]
    }

    /// Prepare NCHW float32 tensor data from a DynamicImage
    /// Returns (shape, data) tuple suitable for ort::Tensor::from_array
    fn prepare_input_from_image(
        &self,
        img: &image::DynamicImage,
        input_shape: &[i64],
    ) -> Result<(Vec<i64>, Vec<f32>), BackendError> {
        if input_shape.len() != 4 {
            return Err(BackendError::InferenceFailed(format!(
                "invalid input shape {:?}: expected 4D NCHW",
                input_shape,
            )));
        }
        let channels = input_shape[1] as usize;
        let height = input_shape[2] as u32;
        let width = input_shape[3] as u32;

        debug!("Resizing image to {}x{} for model input", width, height);
        let resized = img.resize_exact(width, height, image::imageops::FilterType::Triangle);
        let rgb = resized.to_rgb8();

        let h = height as usize;
        let w = width as usize;
        let mut tensor_data = vec![0.0f32; channels * h * w];

        for y in 0..h {
            for x in 0..w {
                let pixel = rgb.get_pixel(x as u32, y as u32);
                for c in 0..channels.min(3) {
                    tensor_data[c * h * w + y * w + x] = pixel[c] as f32 / 255.0;
                }
            }
        }

        Ok((input_shape.to_vec(), tensor_data))
    }

    /// Run inference through the ONNX session
    ///
    /// Returns the real output tensor shape reported by ORT alongside the flat data,
    /// so postprocessing does not have to guess dimensions from `num_classes` (which
    /// is unreliable when `class_labels` is empty).
    fn run_session_inference(
        &self,
        model: &OnnxModel,
        input_shape: Vec<i64>,
        input_data: Vec<f32>,
    ) -> Result<(Vec<usize>, Vec<f32>), BackendError> {
        debug!("Running ONNX session inference for model '{}'", model.name);

        let tensor = ort::value::Tensor::from_array((input_shape, input_data))
            .map_err(|e| BackendError::InferenceFailed(format!("Failed to create input tensor: {}", e)))?;

        let inputs = ort::inputs![&model.input_name => tensor.upcast()];

        let mut session = model.session.lock()
            .map_err(|e| BackendError::InferenceFailed(format!("Failed to lock session mutex: {}", e)))?;

        let outputs = session
            .run(inputs)
            .map_err(|e| BackendError::InferenceFailed(format!("ONNX session run failed: {}", e)))?;

        let (shape, data) = outputs[0]
            .try_extract_tensor::<f32>()
            .map_err(|e| BackendError::InferenceFailed(format!("Failed to extract output tensor: {}", e)))?;

        debug!("Output tensor shape: {:?}", shape);
        let shape_vec: Vec<usize> = shape.iter().map(|&d| d as usize).collect();
        Ok((shape_vec, data.to_vec()))
    }

    /// Process YOLOv8 output tensor
    /// Input shape: [1, 4+num_classes, num_detections] (raw from model)
    /// Must transpose to iterate per-detection: [num_detections, 4+num_classes]
    fn process_yolov8_output(
        &self,
        output_data: &[f32],
        output_shape: &[usize],
        model: &OnnxModel,
    ) -> Result<Vec<crate::Prediction>, BackendError> {
        if output_shape.len() != 3 || output_shape[0] != 1 {
            return Err(BackendError::PostprocessingFailed(
                format!("Unexpected YOLOv8 output shape: {:?}", output_shape),
            ));
        }

        let rows = output_shape[1]; // 4 + num_classes (5 for single-class)
        let cols = output_shape[2]; // num_detections (8400)
        let num_classes = rows.saturating_sub(4);

        if num_classes == 0 {
            return Err(BackendError::PostprocessingFailed(
                format!("Output has {} rows, need at least 5 (4 box + 1 class)", rows),
            ));
        }

        // Validate against configured class labels. A mismatch usually means a
        // model+config mismatch (e.g. COCO labels paired with a single-class model)
        // which silently produces nonsense detections, so fail loudly instead.
        if !model.class_labels.is_empty() && model.class_labels.len() != num_classes {
            return Err(BackendError::PostprocessingFailed(format!(
                "Model '{}' output has {} classes but {} class labels are configured; \
                 check that postprocessing.class_labels matches the model",
                model.name,
                num_classes,
                model.class_labels.len(),
            )));
        }

        debug!("Processing YOLOv8 output: {} detections, {} classes", cols, num_classes);

        let mut detections: Vec<RawDetection> = Vec::new();

        for det_idx in 0..cols {
            // Data is laid out as [1, rows, cols] in row-major:
            // output_data[row * cols + det_idx]
            let cx = output_data[det_idx];
            let cy = output_data[cols + det_idx];
            let w = output_data[2 * cols + det_idx];
            let h = output_data[3 * cols + det_idx];

            // Find best class
            let mut best_conf = 0.0f32;
            let mut best_class = 0usize;
            for c in 0..num_classes {
                let conf = output_data[(4 + c) * cols + det_idx];
                if conf > best_conf {
                    best_conf = conf;
                    best_class = c;
                }
            }

            if best_conf >= model.confidence_threshold {
                detections.push(RawDetection {
                    x1: cx - w / 2.0,
                    y1: cy - h / 2.0,
                    x2: cx + w / 2.0,
                    y2: cy + h / 2.0,
                    confidence: best_conf,
                    class_id: best_class,
                });
            }
        }

        debug!("Found {} detections above threshold {}", detections.len(), model.confidence_threshold);

        // Apply NMS
        let kept = Self::apply_nms(&mut detections, model.nms_threshold);
        debug!("After NMS: {} detections", kept.len());

        // Convert to Prediction
        let predictions: Vec<crate::Prediction> = kept.into_iter().map(|det| {
            let class_name = model.class_labels.get(det.class_id)
                .cloned()
                .unwrap_or_else(|| format!("class_{}", det.class_id));

            crate::Prediction {
                class: class_name,
                confidence: det.confidence,
                bbox: Some([det.x1, det.y1, det.x2, det.y2]),
                metadata: {
                    let mut map = HashMap::new();
                    map.insert("backend".to_string(), serde_json::Value::String("onnx-runtime".to_string()));
                    map.insert("class_index".to_string(), serde_json::Value::Number((det.class_id as u64).into()));
                    map.insert("model_name".to_string(), serde_json::Value::String(model.name.clone()));
                    map
                },
                severity: if det.confidence > 0.7 { Some("high".to_string()) }
                         else if det.confidence > 0.4 { Some("medium".to_string()) }
                         else { Some("low".to_string()) },
            }
        }).collect();

        Ok(predictions)
    }

    /// Process classification-style output (flat logits/probabilities)
    fn process_classification_output(
        &self,
        output_data: &[f32],
        model: &OnnxModel,
    ) -> Result<Vec<crate::Prediction>, BackendError> {
        let mut indexed: Vec<(usize, f32)> = output_data.iter().enumerate()
            .map(|(i, &v)| (i, v))
            .collect();
        indexed.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));

        let predictions: Vec<crate::Prediction> = indexed.iter()
            .take(model.top_k)
            .filter(|(_, conf)| *conf > model.confidence_threshold)
            .map(|(class_idx, confidence)| {
                let class_name = model.class_labels.get(*class_idx)
                    .cloned()
                    .unwrap_or_else(|| format!("class_{}", class_idx));

                crate::Prediction {
                    class: class_name,
                    confidence: *confidence,
                    bbox: None,
                    metadata: {
                        let mut map = HashMap::new();
                        map.insert("backend".to_string(), serde_json::Value::String("onnx-runtime".to_string()));
                        map.insert("class_index".to_string(), serde_json::Value::Number((*class_idx as u64).into()));
                        map.insert("model_name".to_string(), serde_json::Value::String(model.name.clone()));
                        map
                    },
                    severity: if *confidence > 0.7 { Some("high".to_string()) }
                             else if *confidence > 0.4 { Some("medium".to_string()) }
                             else { Some("low".to_string()) },
                }
            })
            .collect();

        Ok(predictions)
    }

    /// Greedy NMS: suppress overlapping detections
    fn apply_nms(detections: &mut [RawDetection], nms_threshold: f32) -> Vec<RawDetection> {
        detections.sort_by(|a, b| b.confidence.partial_cmp(&a.confidence).unwrap_or(std::cmp::Ordering::Equal));
        let mut keep: Vec<RawDetection> = Vec::new();
        let mut suppressed = vec![false; detections.len()];

        for i in 0..detections.len() {
            if suppressed[i] { continue; }
            keep.push(detections[i].clone());
            for j in (i + 1)..detections.len() {
                if suppressed[j] { continue; }
                if detections[i].class_id == detections[j].class_id
                    && Self::iou(&detections[i], &detections[j]) > nms_threshold
                {
                    suppressed[j] = true;
                }
            }
        }
        keep
    }

    /// Intersection-over-Union for two bounding boxes
    fn iou(a: &RawDetection, b: &RawDetection) -> f32 {
        let inter_x1 = a.x1.max(b.x1);
        let inter_y1 = a.y1.max(b.y1);
        let inter_x2 = a.x2.min(b.x2);
        let inter_y2 = a.y2.min(b.y2);

        let inter_area = (inter_x2 - inter_x1).max(0.0) * (inter_y2 - inter_y1).max(0.0);
        let area_a = (a.x2 - a.x1) * (a.y2 - a.y1);
        let area_b = (b.x2 - b.x1) * (b.y2 - b.y1);
        let union_area = area_a + area_b - inter_area;

        if union_area <= 0.0 { 0.0 } else { inter_area / union_area }
    }
}

#[cfg(feature = "onnx-runtime")]
#[async_trait]
impl InferenceBackend for OnnxRuntimeBackend {
    async fn initialize(&mut self, config: &BackendConfig) -> Result<(), BackendError> {
        info!("Initializing ONNX Runtime backend");
        self.environment_initialized = true;
        self.config = Some(config.clone());
        info!("ONNX Runtime backend initialized");
        Ok(())
    }

    async fn load_model(&mut self, model_name: &str, model_config: &ModelConfig) -> Result<(), BackendError> {
        info!("Loading ONNX model '{}' from '{}'", model_name, model_config.model_path);

        if !self.environment_initialized {
            return Err(BackendError::BackendNotInitialized("Environment not initialized".to_string()));
        }

        // Build ort session from ONNX file with the configured session options
        let session_options = SessionOptions::from_config(self.config.as_ref());
        debug!("ONNX session options for model '{}': {:?}", model_name, session_options);
        let session = session_options
            .builder()?
            .commit_from_file(&model_config.model_path)
            .map_err(|e| BackendError::ModelLoadFailed(format!("Failed to load ONNX model '{}': {}", model_config.model_path, e)))?;

        // Extract input/output names from session metadata
        let input_name = session.inputs().first()
            .map(|i| i.name().to_string())
            .unwrap_or_else(|| "images".to_string());
        info!("Model input name: '{}'", input_name);

        // Parse postprocessing config from ModelConfig
        let (class_labels, confidence_threshold, nms_threshold, top_k, postprocess_type) =
            Self::parse_postprocessing(model_config);

        // Parse input shape
        let input_shape = Self::parse_input_shape(model_config);

        info!(
            "Model '{}': postprocess={}, classes={:?}, conf_thresh={}, nms_thresh={}, top_k={}, input_shape={:?}",
            model_name, postprocess_type, class_labels, confidence_threshold, nms_threshold, top_k, input_shape
        );

        let model = OnnxModel {
            name: model_name.to_string(),
            model_path: model_config.model_path.clone(),
            session: Mutex::new(session),
            input_name,
            input_shape,
            class_labels,
            confidence_threshold,
            nms_threshold,
            top_k,
            postprocess_type,
        };

        self.loaded_models.insert(model_name.to_string(), model);
        match self.stats.lock() {
            Ok(mut stats) => {
                stats.models_loaded += 1;
            }
            Err(error) => {
                debug!("Failed to update model count after load: {}", error);
            }
        }

        info!("ONNX model '{}' loaded with real ort::Session", model_name);
        Ok(())
    }

    async fn unload_model(&mut self, model_name: &str) -> Result<(), BackendError> {
        info!("Unloading ONNX model: {}", model_name);

        if self.loaded_models.remove(model_name).is_some() {
            match self.stats.lock() {
                Ok(mut stats) => {
                    stats.models_loaded = stats.models_loaded.saturating_sub(1);
                }
                Err(error) => {
                    debug!("Failed to update model count after unload: {}", error);
                }
            }
            info!("ONNX model '{}' unloaded", model_name);
            Ok(())
        } else {
            Err(BackendError::ModelUnloadFailed(format!("Model '{}' not found", model_name)))
        }
    }

    async fn infer(&self, input: InferenceInput, model_name: Option<&str>) -> Result<InferenceResult, BackendError> {
        let start = std::time::Instant::now();

        let result = (|| -> Result<InferenceResult, BackendError> {
            if !self.environment_initialized {
                return Err(BackendError::BackendNotInitialized("Environment not initialized".to_string()));
            }

            let model_key = model_name.unwrap_or("default");
            debug!("Running ONNX inference with model '{}'", model_key);

            let model = self.loaded_models.get(model_key)
                .or_else(|| {
                    if model_key == "default" {
                        let fallback = self.loaded_models.values().next();
                        if let Some(m) = fallback {
                            info!("Model 'default' not found, falling back to '{}'", m.name);
                        }
                        fallback
                    } else {
                        None
                    }
                })
                .ok_or_else(|| BackendError::ModelLoadFailed(format!("Model '{}' not loaded", model_key)))?;

            // Extract DynamicImage from input
            let image = match &input {
                InferenceInput::Image { data, metadata: _ } => data,
                InferenceInput::TimeSeries { .. } => {
                    return Err(BackendError::InferenceFailed(
                        "ONNX backend does not support time series input".to_string(),
                    ));
                }
            };

            // Prepare input tensor from image
            let (input_shape, input_data) = self.prepare_input_from_image(image, &model.input_shape)?;
            debug!("Input tensor shape: {:?}", input_shape);

            // Run real ONNX session inference (shape is the authoritative shape reported by ORT)
            let (output_shape, output_data) = self.run_session_inference(model, input_shape, input_data)?;
            debug!("Output shape: {:?}, postprocess_type: {}", output_shape, model.postprocess_type);

            let predictions = match model.postprocess_type.as_str() {
                "yolov8" | "yolo" | "yolov5" => {
                    self.process_yolov8_output(&output_data, &output_shape, model)?
                }
                _ => {
                    self.process_classification_output(&output_data, model)?
                }
            };

            let confidence = predictions.iter()
                .map(|p| p.confidence)
                .fold(0.0f32, f32::max);

            let elapsed_ms = start.elapsed().as_secs_f64() * 1000.0;

            Ok(InferenceResult {
                model_name: model.name.clone(),
                model_type: "onnx".to_string(),
                predictions,
                confidence,
                inference_time_ms: elapsed_ms,
                metadata: serde_json::json!({
                    "backend": "onnx-runtime",
                    "model_path": model.model_path,
                    "inference_type": "real",
                    "request_id": uuid::Uuid::new_v4().to_string()
                }),
            })
        })();

        let elapsed_ms = start.elapsed().as_secs_f64() * 1000.0;
        self.record_inference_stats(elapsed_ms, result.is_ok());

        result
    }

    async fn get_loaded_models(&self) -> Vec<String> {
        self.loaded_models.keys().cloned().collect()
    }

    async fn get_status(&self) -> BackendStatus {
        let total_inferences = self
            .stats
            .lock()
            .ok()
            .map(|stats| stats.total_inferences)
            .unwrap_or(0);

        BackendStatus {
            backend_type: BackendType::OnnxRuntime,
            initialized: self.environment_initialized,
            loaded_models: self.loaded_models.keys().cloned().collect(),
            device_type: DeviceType::Cpu,
            memory_usage_mb: 0.0,
            last_inference_time_ms: None,
            total_inferences,
            errors: vec![],
            session_settings: SessionOptions::from_config(self.config.as_ref()).describe(),
        }
    }

    fn backend_type(&self) -> BackendType {
        BackendType::OnnxRuntime
    }
}

#[cfg(all(test, feature = "onnx-runtime"))]
mod tests {
    use super::*;
    use crate::backend::OnnxConfig;
    use ort::session::builder::GraphOptimizationLevel;

    const IDENTITY_MODEL: &str =
        concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/identity.onnx");

    fn backend_config(
        level: OptimizationLevel,
        intra: Option<usize>,
        inter: Option<usize>,
    ) -> BackendConfig {
        backend_config_with_parallel(level, false, intra, inter)
    }

    fn backend_config_with_parallel(
        level: OptimizationLevel,
        parallel: bool,
        intra: Option<usize>,
        inter: Option<usize>,
    ) -> BackendConfig {
        BackendConfig {
            backend_type: BackendType::OnnxRuntime,
            device_type: DeviceType::Cpu,
            optimization_level: level,
            parallel_execution: parallel,
            onnx_config: Some(OnnxConfig {
                execution_providers: vec!["CPUExecutionProvider".to_string()],
                inter_op_num_threads: inter,
                intra_op_num_threads: intra,
                ..OnnxConfig::default()
            }),
            ..BackendConfig::default()
        }
    }

    fn identity_model_config() -> ModelConfig {
        ModelConfig {
            model_path: IDENTITY_MODEL.to_string(),
            model_type: "identity".to_string(),
            confidence_threshold: None,
            preprocessing: Some(serde_json::json!({ "shape": [1, 3, 4, 4] })),
            postprocessing: None,
        }
    }

    #[test]
    fn maps_every_optimization_level() {
        assert!(matches!(
            graph_optimization_level(&OptimizationLevel::None),
            GraphOptimizationLevel::Disable
        ));
        assert!(matches!(
            graph_optimization_level(&OptimizationLevel::Basic),
            GraphOptimizationLevel::Level1
        ));
        assert!(matches!(
            graph_optimization_level(&OptimizationLevel::Extended),
            GraphOptimizationLevel::Level2
        ));
        assert!(matches!(
            graph_optimization_level(&OptimizationLevel::All),
            GraphOptimizationLevel::All
        ));
    }

    #[test]
    fn derives_options_from_backend_config() {
        let config = backend_config(OptimizationLevel::Extended, Some(2), Some(1));
        let options = SessionOptions::from_config(Some(&config));

        assert!(matches!(
            options.optimization_level,
            Some(GraphOptimizationLevel::Level2)
        ));
        assert_eq!(options.parallel_execution, Some(false));
        assert_eq!(options.intra_threads, Some(2));
        assert_eq!(options.inter_threads, Some(1));
    }

    #[test]
    fn leaves_unset_thread_counts_to_onnx_runtime() {
        let config = backend_config(OptimizationLevel::Basic, None, None);
        let options = SessionOptions::from_config(Some(&config));
        assert_eq!(options.intra_threads, None);
        assert_eq!(options.inter_threads, None);

        let mut without_onnx_config = config;
        without_onnx_config.onnx_config = None;
        let options = SessionOptions::from_config(Some(&without_onnx_config));
        assert_eq!(options.intra_threads, None);
        assert_eq!(options.inter_threads, None);
    }

    #[test]
    fn no_config_applies_no_options() {
        let options = SessionOptions::from_config(None);
        assert!(options.optimization_level.is_none());
        assert!(options.parallel_execution.is_none());
        assert!(options.intra_threads.is_none());
        assert!(options.inter_threads.is_none());
    }

    #[tokio::test]
    async fn loads_model_with_each_optimization_level_and_thread_counts() {
        let levels = [
            OptimizationLevel::None,
            OptimizationLevel::Basic,
            OptimizationLevel::Extended,
            OptimizationLevel::All,
        ];
        for level in levels {
            let label = format!("{:?}", level);
            let mut backend = OnnxRuntimeBackend::new();
            backend
                .initialize(&backend_config(level, Some(1), Some(1)))
                .await
                .unwrap();
            backend
                .load_model("identity", &identity_model_config())
                .await
                .unwrap_or_else(|e| panic!("load with {} failed: {}", label, e));
            assert_eq!(
                backend.get_loaded_models().await,
                vec!["identity".to_string()]
            );
        }
    }

    #[tokio::test]
    async fn loads_model_with_default_thread_counts() {
        let mut backend = OnnxRuntimeBackend::new();
        backend
            .initialize(&backend_config(OptimizationLevel::All, None, None))
            .await
            .unwrap();
        backend
            .load_model("identity", &identity_model_config())
            .await
            .unwrap();
    }

    /// Records applied options and can reject one by name.
    #[derive(Default)]
    struct RecordingTarget {
        applied: Vec<String>,
        reject: Option<&'static str>,
    }

    impl RecordingTarget {
        fn record(mut self, option: &str, value: String) -> Result<Self, String> {
            if self.reject == Some(option) {
                return Err("rejected by test target".to_string());
            }
            self.applied.push(format!("{}={}", option, value));
            Ok(self)
        }
    }

    impl SessionOptionTarget for RecordingTarget {
        fn set_optimization_level(self, level: GraphOptimizationLevel) -> Result<Self, String> {
            self.record(OPTION_OPTIMIZATION_LEVEL, format!("{:?}", level))
        }

        fn set_parallel_execution(self, parallel: bool) -> Result<Self, String> {
            self.record(OPTION_PARALLEL_EXECUTION, parallel.to_string())
        }

        fn set_intra_threads(self, threads: usize) -> Result<Self, String> {
            self.record(OPTION_INTRA_THREADS, threads.to_string())
        }

        fn set_inter_threads(self, threads: usize) -> Result<Self, String> {
            self.record(OPTION_INTER_THREADS, threads.to_string())
        }
    }

    #[test]
    fn applies_every_configured_option() {
        let config =
            backend_config_with_parallel(OptimizationLevel::Extended, true, Some(2), Some(3));
        let applied = SessionOptions::from_config(Some(&config))
            .apply(RecordingTarget::default())
            .unwrap()
            .applied;

        assert_eq!(
            applied,
            vec![
                "optimization level=Level2",
                "parallel execution=true",
                "intra-op thread count=2",
                "inter-op thread count=3",
            ]
        );
    }

    #[test]
    fn does_not_apply_unset_options() {
        let applied = SessionOptions::from_config(None)
            .apply(RecordingTarget::default())
            .unwrap()
            .applied;
        assert!(applied.is_empty());

        let config = backend_config(OptimizationLevel::All, None, None);
        let applied = SessionOptions::from_config(Some(&config))
            .apply(RecordingTarget::default())
            .unwrap()
            .applied;
        assert_eq!(
            applied,
            vec!["optimization level=All", "parallel execution=false"]
        );
    }

    #[test]
    fn rejected_option_fails_load_with_option_named() {
        let config = backend_config_with_parallel(OptimizationLevel::Basic, true, Some(1), Some(1));
        let options = SessionOptions::from_config(Some(&config));
        for option in [
            OPTION_OPTIMIZATION_LEVEL,
            OPTION_PARALLEL_EXECUTION,
            OPTION_INTRA_THREADS,
            OPTION_INTER_THREADS,
        ] {
            let target = RecordingTarget {
                reject: Some(option),
                ..RecordingTarget::default()
            };
            match options.apply(target) {
                Err(BackendError::ModelLoadFailed(message)) => {
                    assert!(
                        message.contains(option),
                        "{} missing from {}",
                        option,
                        message
                    )
                }
                Err(other) => panic!("unexpected error for {}: {}", option, other),
                Ok(_) => panic!("{} rejection was ignored", option),
            }
        }
    }

    #[tokio::test]
    async fn loads_model_with_parallel_execution() {
        let mut backend = OnnxRuntimeBackend::new();
        backend
            .initialize(&backend_config_with_parallel(
                OptimizationLevel::All,
                true,
                Some(1),
                Some(2),
            ))
            .await
            .unwrap();
        backend
            .load_model("identity", &identity_model_config())
            .await
            .unwrap();
    }

    #[tokio::test]
    async fn status_reports_effective_session_settings() {
        let mut backend = OnnxRuntimeBackend::new();
        backend
            .initialize(&backend_config_with_parallel(
                OptimizationLevel::Extended,
                true,
                Some(2),
                None,
            ))
            .await
            .unwrap();

        let settings = backend.get_status().await.session_settings;
        assert_eq!(settings[OPTION_OPTIMIZATION_LEVEL], "level2");
        assert_eq!(settings[OPTION_PARALLEL_EXECUTION], "true");
        assert_eq!(settings[OPTION_INTRA_THREADS], "2");
        assert_eq!(settings[OPTION_INTER_THREADS], "default");
    }
}
