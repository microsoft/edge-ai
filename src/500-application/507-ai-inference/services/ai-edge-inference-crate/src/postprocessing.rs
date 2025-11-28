//! Universal output postprocessing pipeline
//! Postprocessing utilities for AI inference
//! Based on universal approach for handling diverse model output types
//!
//! This module provides a unified postprocessing system that can automatically
//! handle different model output formats and convert them to standardized results.

use ndarray::{Array1, Array2, Array3, Array4};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use thiserror::Error;

use crate::types::Prediction;
use crate::model_config::{OutputConfiguration, PostprocessingConfiguration};
use crate::preprocessing::PreprocessedImage;

/// Errors that can occur during postprocessing
#[derive(Error, Debug)]
pub enum PostprocessingError {
    #[error("Invalid tensor shape: expected {expected:?}, got {actual:?}")]
    InvalidTensorShape { expected: Vec<usize>, actual: Vec<usize> },
    #[error("Unsupported output format: {0}")]
    UnsupportedOutputFormat(String),
    #[error("Configuration error: {0}")]
    ConfigError(String),
    #[error("Missing required parameter: {0}")]
    MissingParameter(String),
    #[error("Invalid parameter value: {0}")]
    InvalidParameter(String),
}

/// Universal postprocessor for different model types
#[derive(Debug, Clone)]
pub struct UniversalPostprocessor {
    /// Postprocessing type
    processor_type: PostprocessorType,
    /// Configuration parameters
    config: PostprocessingConfig,
}

/// Supported postprocessing types
#[derive(Debug, Clone)]
pub enum PostprocessorType {
    /// Object detection (YOLO, SSD, etc.)
    ObjectDetection(ObjectDetectionConfig),
    /// Image classification
    Classification(ClassificationConfig),
    /// Segmentation
    Segmentation(SegmentationConfig),
    /// Custom postprocessing
    Custom(CustomConfig),
}

/// Configuration for object detection postprocessing
#[derive(Debug, Clone)]
pub struct ObjectDetectionConfig {
    /// Confidence threshold for filtering detections
    pub confidence_threshold: f32,
    /// NMS (Non-Maximum Suppression) threshold
    pub nms_threshold: f32,
    /// Maximum number of detections to return
    pub max_detections: usize,
    /// Class labels
    pub class_labels: Vec<String>,
    /// Detection format (e.g., "yolov8", "yolov5", "ssd")
    pub detection_format: String,
    /// Number of classes
    pub num_classes: usize,
}

/// Configuration for image classification postprocessing
#[derive(Debug, Clone)]
pub struct ClassificationConfig {
    /// Confidence threshold for predictions
    pub confidence_threshold: f32,
    /// Maximum number of top predictions to return
    pub top_k: usize,
    /// Class labels
    pub class_labels: Vec<String>,
    /// Apply softmax to output logits
    pub apply_softmax: bool,
}

/// Configuration for segmentation postprocessing
#[derive(Debug, Clone)]
pub struct SegmentationConfig {
    /// Number of classes
    pub num_classes: usize,
    /// Apply argmax to get class predictions
    pub apply_argmax: bool,
    /// Class labels
    pub class_labels: Vec<String>,
}

/// Configuration for custom postprocessing
#[derive(Debug, Clone)]
pub struct CustomConfig {
    /// Custom parameters
    pub parameters: HashMap<String, serde_json::Value>,
}

/// General postprocessing configuration
#[derive(Debug, Clone)]
pub struct PostprocessingConfig {
    /// Output tensor specifications
    pub output_tensors: Vec<OutputTensorSpec>,
    /// Additional parameters
    pub parameters: HashMap<String, serde_json::Value>,
}

/// Specification for output tensor
#[derive(Debug, Clone)]
pub struct OutputTensorSpec {
    pub name: String,
    pub expected_shape: Vec<i64>,
    pub semantic_meaning: String,
}

/// Detection box representation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DetectionBox {
    pub x1: f32,
    pub y1: f32,
    pub x2: f32,
    pub y2: f32,
    pub confidence: f32,
    pub class_id: usize,
    pub class_name: String,
}

/// Segmentation mask
#[derive(Debug, Clone)]
pub struct SegmentationMask {
    pub mask: Array2<u8>,
    pub class_labels: Vec<String>,
}

impl UniversalPostprocessor {
    /// Create a new postprocessor from YAML configuration
    pub fn from_yaml_config(
        output_config: &OutputConfiguration,
        postprocessing_config: Option<&PostprocessingConfiguration>,
    ) -> Result<Self, PostprocessingError> {
        let processor_type = match output_config.postprocess_type.as_str() {
            "yolo" | "yolov8" | "yolov5" => {
                let config = ObjectDetectionConfig {
                    confidence_threshold: output_config.confidence_threshold.unwrap_or(0.5),
                    nms_threshold: output_config.nms_threshold.unwrap_or(0.4),
                    max_detections: output_config.max_detections.unwrap_or(100),
                    class_labels: output_config.class_labels.clone().unwrap_or_default(),
                    detection_format: output_config.postprocess_type.clone(),
                    num_classes: output_config.class_labels.as_ref().map(|l| l.len()).unwrap_or(80),
                };
                PostprocessorType::ObjectDetection(config)
            },

            "classification" => {
                let config = ClassificationConfig {
                    confidence_threshold: output_config.confidence_threshold.unwrap_or(0.1),
                    top_k: output_config.max_detections.unwrap_or(5),
                    class_labels: output_config.class_labels.clone().unwrap_or_default(),
                    apply_softmax: true,
                };
                PostprocessorType::Classification(config)
            },

            "segmentation" => {
                let config = SegmentationConfig {
                    num_classes: output_config.class_labels.as_ref().map(|l| l.len()).unwrap_or(1),
                    apply_argmax: true,
                    class_labels: output_config.class_labels.clone().unwrap_or_default(),
                };
                PostprocessorType::Segmentation(config)
            },

            _ => {
                let config = CustomConfig {
                    parameters: postprocessing_config
                        .and_then(|p| p.parameters.clone())
                        .map(|params| {
                            // Convert from serde_yaml::Value to serde_json::Value
                            let json_str = serde_yaml::to_string(&params).unwrap_or_default();
                            serde_json::from_str(&json_str).unwrap_or_default()
                        })
                        .unwrap_or_default(),
                };
                PostprocessorType::Custom(config)
            }
        };

        let config = PostprocessingConfig {
            output_tensors: output_config.tensors.iter().map(|t| OutputTensorSpec {
                name: t.name.clone(),
                expected_shape: t.shape.clone(),
                semantic_meaning: t.semantic.clone(),
            }).collect(),
            parameters: postprocessing_config
                .and_then(|p| p.parameters.clone())
                .map(|params| {
                    // Convert from serde_yaml::Value to serde_json::Value
                    let json_str = serde_yaml::to_string(&params).unwrap_or_default();
                    serde_json::from_str(&json_str).unwrap_or_default()
                })
                .unwrap_or_default(),
        };

        Ok(Self {
            processor_type,
            config,
        })
    }

    /// Process model outputs to standardized predictions
    pub fn process(
        &self,
        outputs: &[Array3<f32>],
        preprocessing_info: &PreprocessedImage,
    ) -> Result<Vec<Prediction>, PostprocessingError> {
        match &self.processor_type {
            PostprocessorType::ObjectDetection(config) => {
                self.process_object_detection(outputs, preprocessing_info, config)
            },
            PostprocessorType::Classification(config) => {
                self.process_classification(outputs, config)
            },
            PostprocessorType::Segmentation(config) => {
                self.process_segmentation(outputs, config)
            },
            PostprocessorType::Custom(config) => {
                self.process_custom(outputs, config)
            },
        }
    }

    /// Process object detection outputs
    fn process_object_detection(
        &self,
        outputs: &[Array3<f32>],
        preprocessing_info: &PreprocessedImage,
        config: &ObjectDetectionConfig,
    ) -> Result<Vec<Prediction>, PostprocessingError> {
        if outputs.is_empty() {
            return Ok(Vec::new());
        }

        let detections = match config.detection_format.as_str() {
            "yolov8" | "yolo" => self.process_yolov8_output(&outputs[0], config)?,
            "yolov5" => self.process_yolov5_output(&outputs[0], config)?,
            "ssd" => self.process_ssd_output(&outputs[0], config)?,
            _ => {
                return Err(PostprocessingError::UnsupportedOutputFormat(
                    format!("Unsupported detection format: {}", config.detection_format)
                ));
            }
        };

        // Convert coordinates back to original image space
        let converted_detections = self.convert_coordinates_to_original(
            detections,
            preprocessing_info,
        );

        // Apply NMS (Non-Maximum Suppression)
        let nms_detections = self.apply_nms(converted_detections, config.nms_threshold);

        // Convert to Prediction format
        let predictions: Vec<Prediction> = nms_detections
            .into_iter()
            .take(config.max_detections)
            .map(|det| Prediction {
                class: det.class_name,
                confidence: det.confidence,
                bbox: Some([det.x1, det.y1, det.x2, det.y2]),
                severity: Some("medium".to_string()), // Default severity
                metadata: HashMap::new(),
            })
            .collect();

        Ok(predictions)
    }

    /// Process YOLOv8 style output (1, num_boxes, 4+num_classes)
    fn process_yolov8_output(
        &self,
        output: &Array3<f32>,
        config: &ObjectDetectionConfig,
    ) -> Result<Vec<DetectionBox>, PostprocessingError> {
        let shape = output.shape();
        if shape.len() != 3 || shape[0] != 1 {
            return Err(PostprocessingError::InvalidTensorShape {
                expected: vec![1, 8400, 84], // Example for YOLOv8n
                actual: shape.to_vec(),
            });
        }

        let num_boxes = shape[1];
        let box_data_len = shape[2];

        if box_data_len < 4 + config.num_classes {
            return Err(PostprocessingError::ConfigError(
                format!("Output tensor size {} is too small for {} classes", box_data_len, config.num_classes)
            ));
        }

        let mut detections = Vec::new();

        for box_idx in 0..num_boxes {
            // Extract box coordinates (center_x, center_y, width, height)
            let cx = output[[0, box_idx, 0]];
            let cy = output[[0, box_idx, 1]];
            let w = output[[0, box_idx, 2]];
            let h = output[[0, box_idx, 3]];

            // Convert to corner format
            let x1 = cx - w / 2.0;
            let y1 = cy - h / 2.0;
            let x2 = cx + w / 2.0;
            let y2 = cy + h / 2.0;

            // Find class with highest confidence
            let mut max_conf = 0.0;
            let mut max_class = 0;

            for class_idx in 0..config.num_classes {
                let conf = output[[0, box_idx, 4 + class_idx]];
                if conf > max_conf {
                    max_conf = conf;
                    max_class = class_idx;
                }
            }

            // Filter by confidence threshold
            if max_conf >= config.confidence_threshold {
                let class_name = config.class_labels.get(max_class)
                    .cloned()
                    .unwrap_or_else(|| format!("class_{}", max_class));

                detections.push(DetectionBox {
                    x1,
                    y1,
                    x2,
                    y2,
                    confidence: max_conf,
                    class_id: max_class,
                    class_name,
                });
            }
        }

        Ok(detections)
    }

    /// Process YOLOv5 style output (similar but may have different format)
    fn process_yolov5_output(
        &self,
        output: &Array3<f32>,
        config: &ObjectDetectionConfig,
    ) -> Result<Vec<DetectionBox>, PostprocessingError> {
        // YOLOv5 format is similar to YOLOv8, can reuse the same logic
        self.process_yolov8_output(output, config)
    }

    /// Process SSD style output (different format)
    fn process_ssd_output(
        &self,
        _output: &Array3<f32>,
        _config: &ObjectDetectionConfig,
    ) -> Result<Vec<DetectionBox>, PostprocessingError> {
        // TODO: Implement SSD-specific postprocessing
        // SSD typically has separate outputs for boxes, scores, and classes
        Err(PostprocessingError::UnsupportedOutputFormat(
            "SSD postprocessing not yet implemented".to_string()
        ))
    }

    /// Process classification outputs
    fn process_classification(
        &self,
        outputs: &[Array3<f32>],
        config: &ClassificationConfig,
    ) -> Result<Vec<Prediction>, PostprocessingError> {
        if outputs.is_empty() {
            return Ok(Vec::new());
        }

        let output = &outputs[0];
        let shape = output.shape();

        if shape.len() < 2 {
            return Err(PostprocessingError::InvalidTensorShape {
                expected: vec![1, config.class_labels.len()],
                actual: shape.to_vec(),
            });
        }

        // Get the logits (convert to Vec<f32> to avoid dimension issues)
        let logits_vec = if shape.len() == 3 && shape[2] == 1 && shape[0] == 1 {
            // Shape is (1, num_classes, 1) - extract the middle dimension
            (0..shape[1]).map(|i| output[[0, i, 0]]).collect::<Vec<f32>>()
        } else if shape.len() == 2 && shape[0] == 1 {
            // Shape is (1, num_classes) - extract the second dimension
            (0..shape[1]).map(|i| output[[0, i, 0]]).collect::<Vec<f32>>()
        } else {
            return Err(PostprocessingError::InvalidTensorShape {
                expected: vec![1, config.class_labels.len().max(1000)], // Allow for common sizes
                actual: shape.to_vec(),
            });
        };

        // Apply softmax if requested
        let probabilities = if config.apply_softmax {
            self.apply_softmax_vec(&logits_vec)
        } else {
            logits_vec
        };

        // Get top-k predictions
        let mut predictions = Vec::new();
        let mut indexed_probs: Vec<(usize, f32)> = probabilities
            .iter()
            .enumerate()
            .map(|(i, &prob)| (i, prob))
            .collect();

        // Sort by confidence descending
        indexed_probs.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));

        // Take top-k above threshold
        for (class_idx, confidence) in indexed_probs.into_iter().take(config.top_k) {
            if confidence >= config.confidence_threshold {
                let class_name = config.class_labels.get(class_idx)
                    .cloned()
                    .unwrap_or_else(|| format!("class_{}", class_idx));

                predictions.push(Prediction {
                    class: class_name,
                    confidence,
                    bbox: None, // No bounding box for classification
                    severity: Some("info".to_string()), // Default severity
                    metadata: HashMap::new(),
                });
            }
        }

        Ok(predictions)
    }

    /// Process segmentation outputs
    fn process_segmentation(
        &self,
        outputs: &[Array3<f32>],
        config: &SegmentationConfig,
    ) -> Result<Vec<Prediction>, PostprocessingError> {
        if outputs.is_empty() {
            return Ok(Vec::new());
        }

        // For now, return a simple segmentation result
        // Full segmentation postprocessing would be more complex
        let prediction = Prediction {
            class: "segmentation".to_string(),
            confidence: 1.0,
            bbox: None,
            severity: Some("info".to_string()),
            metadata: {
                let mut meta = HashMap::new();
                meta.insert("output_type".to_string(), serde_json::Value::String("segmentation".to_string()));
                meta.insert("num_classes".to_string(), serde_json::Value::Number(config.num_classes.into()));
                meta
            },
        };

        Ok(vec![prediction])
    }

    /// Process custom outputs
    fn process_custom(
        &self,
        _outputs: &[Array3<f32>],
        _config: &CustomConfig,
    ) -> Result<Vec<Prediction>, PostprocessingError> {
        // Return a generic custom result
        let prediction = Prediction {
            class: "custom".to_string(),
            confidence: 1.0,
            bbox: None,
            severity: Some("info".to_string()),
            metadata: HashMap::new(),
        };

        Ok(vec![prediction])
    }

    /// Convert detection coordinates back to original image space
    fn convert_coordinates_to_original(
        &self,
        detections: Vec<DetectionBox>,
        preprocessing_info: &PreprocessedImage,
    ) -> Vec<DetectionBox> {
        let (scale_x, scale_y) = preprocessing_info.scale_factors;
        let (pad_left, pad_top, _, _) = preprocessing_info.padding;
        let (orig_w, orig_h) = preprocessing_info.original_size;

        detections
            .into_iter()
            .map(|mut det| {
                // Adjust for padding
                det.x1 -= pad_left as f32;
                det.y1 -= pad_top as f32;
                det.x2 -= pad_left as f32;
                det.y2 -= pad_top as f32;

                // Scale back to original size
                det.x1 /= scale_x;
                det.y1 /= scale_y;
                det.x2 /= scale_x;
                det.y2 /= scale_y;

                // Clamp to image bounds
                det.x1 = det.x1.max(0.0).min(orig_w as f32);
                det.y1 = det.y1.max(0.0).min(orig_h as f32);
                det.x2 = det.x2.max(0.0).min(orig_w as f32);
                det.y2 = det.y2.max(0.0).min(orig_h as f32);

                det
            })
            .collect()
    }

    /// Apply Non-Maximum Suppression to filter overlapping detections
    fn apply_nms(&self, mut detections: Vec<DetectionBox>, nms_threshold: f32) -> Vec<DetectionBox> {
        if detections.is_empty() {
            return detections;
        }

        // Sort by confidence descending
        detections.sort_by(|a, b| b.confidence.partial_cmp(&a.confidence).unwrap_or(std::cmp::Ordering::Equal));

        let mut keep = Vec::new();
        let mut suppressed = vec![false; detections.len()];

        for i in 0..detections.len() {
            if suppressed[i] {
                continue;
            }

            keep.push(detections[i].clone());

            for j in (i + 1)..detections.len() {
                if suppressed[j] {
                    continue;
                }

                // Only suppress detections of the same class
                if detections[i].class_id == detections[j].class_id {
                    let iou = self.calculate_iou(&detections[i], &detections[j]);
                    if iou > nms_threshold {
                        suppressed[j] = true;
                    }
                }
            }
        }

        keep
    }

    /// Calculate Intersection over Union (IoU) between two boxes
    fn calculate_iou(&self, box1: &DetectionBox, box2: &DetectionBox) -> f32 {
        let x1 = box1.x1.max(box2.x1);
        let y1 = box1.y1.max(box2.y1);
        let x2 = box1.x2.min(box2.x2);
        let y2 = box1.y2.min(box2.y2);

        if x2 <= x1 || y2 <= y1 {
            return 0.0;
        }

        let intersection = (x2 - x1) * (y2 - y1);
        let area1 = (box1.x2 - box1.x1) * (box1.y2 - box1.y1);
        let area2 = (box2.x2 - box2.x1) * (box2.y2 - box2.y1);
        let union = area1 + area2 - intersection;

        if union <= 0.0 {
            0.0
        } else {
            intersection / union
        }
    }

    /// Apply softmax activation to 2D array
    fn apply_softmax(&self, logits: &Array2<f32>) -> Array2<f32> {
        let max_val = logits.fold(f32::NEG_INFINITY, |acc, &x| acc.max(x));
        let exp_logits = logits.mapv(|x| (x - max_val).exp());
        let sum_exp = exp_logits.sum();
        exp_logits / sum_exp
    }

    /// Apply softmax activation to Vec<f32>
    fn apply_softmax_vec(&self, logits: &[f32]) -> Vec<f32> {
        let max_val = logits.iter().fold(f32::NEG_INFINITY, |acc, &x| acc.max(x));
        let exp_logits: Vec<f32> = logits.iter().map(|&x| (x - max_val).exp()).collect();
        let sum_exp: f32 = exp_logits.iter().sum();
        exp_logits.into_iter().map(|x| x / sum_exp).collect()
    }
}

/// Create preset postprocessors for common model types
pub mod presets {
    use super::*;

    /// YOLOv8 object detection postprocessor
    pub fn yolov8_coco() -> UniversalPostprocessor {
        let config = ObjectDetectionConfig {
            confidence_threshold: 0.5,
            nms_threshold: 0.4,
            max_detections: 100,
            class_labels: coco_labels(),
            detection_format: "yolov8".to_string(),
            num_classes: 80,
        };

        UniversalPostprocessor {
            processor_type: PostprocessorType::ObjectDetection(config),
            config: PostprocessingConfig {
                output_tensors: vec![OutputTensorSpec {
                    name: "output0".to_string(),
                    expected_shape: vec![1, 84, 8400],
                    semantic_meaning: "detections".to_string(),
                }],
                parameters: HashMap::new(),
            },
        }
    }

    /// ImageNet classification postprocessor
    pub fn imagenet_classification() -> UniversalPostprocessor {
        let config = ClassificationConfig {
            confidence_threshold: 0.1,
            top_k: 5,
            class_labels: Vec::new(), // Would load ImageNet labels in practice
            apply_softmax: true,
        };

        UniversalPostprocessor {
            processor_type: PostprocessorType::Classification(config),
            config: PostprocessingConfig {
                output_tensors: vec![OutputTensorSpec {
                    name: "output".to_string(),
                    expected_shape: vec![1, 1000],
                    semantic_meaning: "classification".to_string(),
                }],
                parameters: HashMap::new(),
            },
        }
    }

    /// COCO dataset class labels
    fn coco_labels() -> Vec<String> {
        vec![
            "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck", "boat",
            "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat",
            "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "backpack",
            "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball",
            "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket",
            "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple",
            "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair",
            "couch", "potted plant", "bed", "dining table", "toilet", "tv", "laptop", "mouse",
            "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink",
            "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush"
        ].into_iter().map(|s| s.to_string()).collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::Array3;

    #[test]
    fn test_yolov8_postprocessing() {
        let postprocessor = presets::yolov8_coco();

        // Create mock YOLOv8 output (1, 8400, 84)
        let mut output = Array3::<f32>::zeros((1, 8400, 84));

        // Add a fake detection
        output[[0, 0, 0]] = 320.0; // center_x
        output[[0, 0, 1]] = 240.0; // center_y
        output[[0, 0, 2]] = 100.0; // width
        output[[0, 0, 3]] = 80.0;  // height
        output[[0, 0, 4]] = 0.9;   // person class confidence

        // Mock preprocessing info
        let preprocessing_info = PreprocessedImage {
            tensor: Array4::zeros((1, 3, 640, 640)),
            original_size: (640, 480),
            tensor_shape: vec![1, 3, 640, 640],
            scale_factors: (1.0, 1.0),
            padding: (0, 80, 0, 80), // Letterbox padding
        };

        let outputs = vec![output];
        let predictions = postprocessor.process(&outputs, &preprocessing_info).unwrap();

        assert!(!predictions.is_empty());
        assert_eq!(predictions[0].class, "person");
        assert!(predictions[0].confidence > 0.8);
        assert!(predictions[0].bbox.is_some());
    }

    #[test]
    fn test_classification_postprocessing() {
        let postprocessor = presets::imagenet_classification();

        // Create mock classification output (1, 1000, 1)
        let mut output = Array3::<f32>::zeros((1, 1000, 1));
        output[[0, 285, 0]] = 5.0; // High logit for "Egyptian cat"
        output[[0, 281, 0]] = 3.0; // Medium logit for "tabby cat"

        let preprocessing_info = PreprocessedImage {
            tensor: Array4::zeros((1, 3, 224, 224)),
            original_size: (224, 224),
            tensor_shape: vec![1, 3, 224, 224],
            scale_factors: (1.0, 1.0),
            padding: (0, 0, 0, 0),
        };

        let outputs = vec![output];
        let predictions = postprocessor.process(&outputs, &preprocessing_info).unwrap();

        assert!(!predictions.is_empty());
        // The highest confidence prediction should be first
        assert!(predictions[0].confidence > predictions.get(1).map_or(0.0, |p| p.confidence));
    }
}
