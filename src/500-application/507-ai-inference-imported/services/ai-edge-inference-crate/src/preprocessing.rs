//! Preprocessing utilities for AI inference
//! Based on universal approach for handling diverse model input requirements
//!
//! This module provides a unified preprocessing system that can automatically
//! handle different model input formats, sizes, normalization strategies, etc.
//! allowing for truly universal model deployment.

use image::{DynamicImage, ImageError};
use ndarray::Array4;
use serde::{Deserialize, Serialize};
use thiserror::Error;

/// Errors that can occur during preprocessing
#[derive(Error, Debug)]
pub enum PreprocessingError {
    #[error("Image processing error: {0}")]
    ImageError(#[from] ImageError),
    #[error("Invalid configuration: {0}")]
    InvalidConfig(String),
    #[error("Unsupported format: {0}")]
    UnsupportedFormat(String),
    #[error("Dimension mismatch: expected {expected:?}, got {actual:?}")]
    DimensionMismatch { expected: Vec<i64>, actual: Vec<usize> },
}

/// Universal image preprocessor that handles different model requirements
#[derive(Debug, Clone)]
pub struct UniversalImagePreprocessor {
    /// Target dimensions for the model
    target_size: (u32, u32),
    /// Resize strategy to use
    resize_strategy: ResizeStrategy,
    /// Normalization configuration
    normalization: NormalizationConfig,
    /// Input format (NCHW or NHWC)
    format: InputFormat,
    /// Additional preprocessing steps
    steps: Vec<PreprocessingStep>,
}

/// Resize strategies for handling different aspect ratios
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ResizeStrategy {
    /// Letterbox resize - maintains aspect ratio, adds padding
    Letterbox { fill_color: [u8; 3] },
    /// Center crop - crops from center to target aspect ratio
    CenterCrop,
    /// Stretch - distorts image to exact target size
    Stretch,
    /// Pad to square and then resize
    PadSquare { fill_color: [u8; 3] },
}

/// Normalization configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NormalizationConfig {
    /// Mean values per channel
    pub mean: Vec<f32>,
    /// Standard deviation values per channel
    pub std: Vec<f32>,
    /// Scale to [0,1] before applying mean/std
    pub scale_to_unit: bool,
}

/// Input tensor format
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum InputFormat {
    /// Batch, Channel, Height, Width (PyTorch style)
    NCHW,
    /// Batch, Height, Width, Channel (TensorFlow style)
    NHWC,
}

/// Individual preprocessing step
pub use crate::model_config::PreprocessingStep;

/// Result of preprocessing operation
#[derive(Debug)]
pub struct PreprocessedImage {
    /// The preprocessed tensor data as f32 values
    pub tensor: Array4<f32>,
    /// Original image dimensions
    pub original_size: (u32, u32),
    /// Final tensor dimensions
    pub tensor_shape: Vec<usize>,
    /// Scaling factors applied (for post-processing coordinate conversion)
    pub scale_factors: (f32, f32),
    /// Padding applied (left, top, right, bottom)
    pub padding: (u32, u32, u32, u32),
}

impl Default for NormalizationConfig {
    fn default() -> Self {
        Self {
            mean: vec![0.0, 0.0, 0.0],
            std: vec![1.0, 1.0, 1.0],
            scale_to_unit: true,
        }
    }
}

impl UniversalImagePreprocessor {
    /// Create a new preprocessor with configuration
    pub fn new(
        target_size: (u32, u32),
        resize_strategy: ResizeStrategy,
        normalization: NormalizationConfig,
        format: InputFormat,
    ) -> Self {
        Self {
            target_size,
            resize_strategy,
            normalization,
            format,
            steps: Vec::new(),
        }
    }

    /// Create a preprocessor from YAML configuration
    pub fn from_yaml_config(
        input_config: &crate::model_config::InputConfiguration,
        preprocessing_config: Option<&crate::model_config::PreprocessingConfiguration>,
    ) -> Result<Self, PreprocessingError> {
        // Parse target size from input shape [N, C, H, W] or [N, H, W, C]
        let target_size = if input_config.shape.len() >= 3 {
            let (h, w) = match input_config.format.as_str() {
                "NCHW" => {
                    if input_config.shape.len() == 4 {
                        (input_config.shape[2] as u32, input_config.shape[3] as u32)
                    } else {
                        return Err(PreprocessingError::InvalidConfig(
                            "NCHW format requires 4D shape".to_string()
                        ));
                    }
                },
                "NHWC" => {
                    if input_config.shape.len() == 4 {
                        (input_config.shape[1] as u32, input_config.shape[2] as u32)
                    } else {
                        return Err(PreprocessingError::InvalidConfig(
                            "NHWC format requires 4D shape".to_string()
                        ));
                    }
                },
                _ => return Err(PreprocessingError::UnsupportedFormat(
                    format!("Unsupported input format: {}", input_config.format)
                )),
            };
            (h, w)
        } else {
            return Err(PreprocessingError::InvalidConfig(
                "Input shape must have at least 3 dimensions".to_string()
            ));
        };

        // Parse resize strategy
        let resize_strategy = if let Some(preproc) = preprocessing_config {
            match preproc.resize_strategy.as_str() {
                "letterbox" => ResizeStrategy::Letterbox { fill_color: [114, 114, 114] },
                "crop" | "center_crop" => ResizeStrategy::CenterCrop,
                "stretch" => ResizeStrategy::Stretch,
                "pad_square" => ResizeStrategy::PadSquare { fill_color: [114, 114, 114] },
                _ => ResizeStrategy::Letterbox { fill_color: [114, 114, 114] },
            }
        } else {
            ResizeStrategy::Letterbox { fill_color: [114, 114, 114] }
        };

        // Parse normalization
        let normalization = if let Some(preproc) = preprocessing_config {
            if let Some(norm_config) = &preproc.normalization {
                NormalizationConfig {
                    mean: norm_config.mean.clone(),
                    std: norm_config.std.clone(),
                    scale_to_unit: norm_config.scale_to_unit,
                }
            } else {
                NormalizationConfig::default()
            }
        } else {
            NormalizationConfig::default()
        };

        // Parse input format
        let format = match input_config.format.as_str() {
            "NCHW" => InputFormat::NCHW,
            "NHWC" => InputFormat::NHWC,
            _ => return Err(PreprocessingError::UnsupportedFormat(
                format!("Unsupported format: {}", input_config.format)
            )),
        };

        let mut preprocessor = Self::new(target_size, resize_strategy, normalization, format);

        // Add additional steps if specified
        if let Some(preproc) = preprocessing_config {
            if let Some(steps) = &preproc.steps {
                preprocessor.steps = steps.clone();
            }
        }

        Ok(preprocessor)
    }

    /// Process an image according to the configuration
    pub fn process(&self, image: DynamicImage) -> Result<PreprocessedImage, PreprocessingError> {
        let original_size = (image.width(), image.height());

        // Step 1: Apply resize strategy
        let (resized_image, scale_factors, padding) = self.apply_resize_strategy(image)?;

        // Step 2: Apply additional preprocessing steps
        let processed_image = self.apply_preprocessing_steps(resized_image)?;

        // Step 3: Convert to tensor format
        let tensor = self.image_to_tensor(processed_image)?;

        // Step 4: Apply normalization
        let normalized_tensor = self.apply_normalization(tensor)?;

        Ok(PreprocessedImage {
            tensor: normalized_tensor,
            original_size,
            tensor_shape: vec![1, 3, self.target_size.1 as usize, self.target_size.0 as usize],
            scale_factors,
            padding,
        })
    }

    /// Apply the configured resize strategy
    fn apply_resize_strategy(
        &self,
        image: DynamicImage,
    ) -> Result<(DynamicImage, (f32, f32), (u32, u32, u32, u32)), PreprocessingError> {
        let (orig_w, orig_h) = (image.width(), image.height());
        let (target_w, target_h) = self.target_size;

        match &self.resize_strategy {
            ResizeStrategy::Letterbox { fill_color } => {
                // Calculate scaling to fit within target while maintaining aspect ratio
                let scale = f32::min(target_w as f32 / orig_w as f32, target_h as f32 / orig_h as f32);
                let new_w = (orig_w as f32 * scale) as u32;
                let new_h = (orig_h as f32 * scale) as u32;

                // Resize image
                let resized = image.resize_exact(new_w, new_h, image::imageops::FilterType::Lanczos3);

                // Calculate padding
                let pad_w = target_w - new_w;
                let pad_h = target_h - new_h;
                let (pad_left, pad_right) = (pad_w / 2, pad_w - pad_w / 2);
                let (pad_top, pad_bottom) = (pad_h / 2, pad_h - pad_h / 2);

                // Create padded image
                let mut canvas = image::ImageBuffer::from_pixel(
                    target_w,
                    target_h,
                    image::Rgb(*fill_color)
                );

                image::imageops::overlay(&mut canvas, &resized.to_rgb8(), pad_left as i64, pad_top as i64);

                let padded_image = DynamicImage::ImageRgb8(canvas);

                Ok((padded_image, (scale, scale), (pad_left, pad_top, pad_right, pad_bottom)))
            },

            ResizeStrategy::CenterCrop => {
                // Calculate crop dimensions to maintain target aspect ratio
                let target_ratio = target_w as f32 / target_h as f32;
                let orig_ratio = orig_w as f32 / orig_h as f32;

                let (crop_w, crop_h) = if orig_ratio > target_ratio {
                    // Image is wider - crop width
                    let crop_w = (orig_h as f32 * target_ratio) as u32;
                    (crop_w, orig_h)
                } else {
                    // Image is taller - crop height
                    let crop_h = (orig_w as f32 / target_ratio) as u32;
                    (orig_w, crop_h)
                };

                // Center crop
                let crop_x = (orig_w - crop_w) / 2;
                let crop_y = (orig_h - crop_h) / 2;
                let cropped = image.crop_imm(crop_x, crop_y, crop_w, crop_h);

                // Resize to target
                let resized = cropped.resize_exact(target_w, target_h, image::imageops::FilterType::Lanczos3);

                let scale_x = target_w as f32 / crop_w as f32;
                let scale_y = target_h as f32 / crop_h as f32;

                Ok((resized, (scale_x, scale_y), (0, 0, 0, 0)))
            },

            ResizeStrategy::Stretch => {
                // Simple resize to exact target dimensions
                let resized = image.resize_exact(target_w, target_h, image::imageops::FilterType::Lanczos3);
                let scale_x = target_w as f32 / orig_w as f32;
                let scale_y = target_h as f32 / orig_h as f32;

                Ok((resized, (scale_x, scale_y), (0, 0, 0, 0)))
            },

            ResizeStrategy::PadSquare { fill_color } => {
                // First pad to square, then resize
                let max_dim = u32::max(orig_w, orig_h);
                let pad_w = max_dim - orig_w;
                let pad_h = max_dim - orig_h;

                let mut canvas = image::ImageBuffer::from_pixel(
                    max_dim,
                    max_dim,
                    image::Rgb(*fill_color)
                );

                image::imageops::overlay(&mut canvas, &image.to_rgb8(), (pad_w / 2) as i64, (pad_h / 2) as i64);
                let squared = DynamicImage::ImageRgb8(canvas);

                // Now resize to target
                let resized = squared.resize_exact(target_w, target_h, image::imageops::FilterType::Lanczos3);
                let scale = target_w as f32 / max_dim as f32;

                Ok((resized, (scale, scale), (pad_w / 2, pad_h / 2, pad_w / 2, pad_h / 2)))
            },
        }
    }

    /// Apply additional preprocessing steps
    fn apply_preprocessing_steps(&self, mut image: DynamicImage) -> Result<DynamicImage, PreprocessingError> {
        for step in &self.steps {
            image = self.apply_preprocessing_step(image, step)?;
        }
        Ok(image)
    }

    /// Apply a single preprocessing step
    fn apply_preprocessing_step(
        &self,
        image: DynamicImage,
        step: &PreprocessingStep,
    ) -> Result<DynamicImage, PreprocessingError> {
        match step.step_type.as_str() {
            "contrast_enhancement" => {
                if let Some(factor_value) = step.parameters.get("factor") {
                    let factor = match factor_value {
                        serde_yaml::Value::Number(n) => n.as_f64()
                            .ok_or_else(|| PreprocessingError::InvalidConfig("Factor must be a number".to_string()))?
                            as f32,
                        _ => return Err(PreprocessingError::InvalidConfig("Factor must be a number".to_string())),
                    };

                    // Simple contrast enhancement
                    let mut img_buffer = image.to_rgb8();
                    for pixel in img_buffer.pixels_mut() {
                        for channel in &mut pixel.0 {
                            let enhanced = ((*channel as f32 - 128.0) * factor + 128.0).clamp(0.0, 255.0) as u8;
                            *channel = enhanced;
                        }
                    }
                    Ok(DynamicImage::ImageRgb8(img_buffer))
                } else {
                    Err(PreprocessingError::InvalidConfig("Contrast enhancement requires 'factor' parameter".to_string()))
                }
            },

            "denoising" => {
                // Simple blur for denoising
                if let Some(strength_value) = step.parameters.get("strength") {
                    let strength = match strength_value {
                        serde_yaml::Value::Number(n) => n.as_f64()
                            .ok_or_else(|| PreprocessingError::InvalidConfig("Strength must be a number".to_string()))?
                            as f32,
                        _ => return Err(PreprocessingError::InvalidConfig("Strength must be a number".to_string())),
                    };

                    let sigma = strength * 2.0;
                    Ok(image.blur(sigma))
                } else {
                    Ok(image.blur(1.0)) // Default denoising
                }
            },

            "center_crop" => {
                if let Some(size_value) = step.parameters.get("size") {
                    // Handle serde_yaml::Value conversion to array
                    let size_array = match size_value {
                        serde_yaml::Value::Sequence(seq) => seq,
                        _ => return Err(PreprocessingError::InvalidConfig("Size must be an array".to_string())),
                    };

                    if size_array.len() != 2 {
                        return Err(PreprocessingError::InvalidConfig("Size array must have 2 elements".to_string()));
                    }

                    let crop_w = match &size_array[0] {
                        serde_yaml::Value::Number(n) => n.as_u64()
                            .ok_or_else(|| PreprocessingError::InvalidConfig("Width must be a positive number".to_string()))?
                            as u32,
                        _ => return Err(PreprocessingError::InvalidConfig("Width must be a number".to_string())),
                    };

                    let crop_h = match &size_array[1] {
                        serde_yaml::Value::Number(n) => n.as_u64()
                            .ok_or_else(|| PreprocessingError::InvalidConfig("Height must be a positive number".to_string()))?
                            as u32,
                        _ => return Err(PreprocessingError::InvalidConfig("Height must be a number".to_string())),
                    };

                    let (orig_w, orig_h) = (image.width(), image.height());
                    let crop_x = (orig_w - crop_w) / 2;
                    let crop_y = (orig_h - crop_h) / 2;

                    Ok(image.crop_imm(crop_x, crop_y, crop_w, crop_h))
                } else {
                    Err(PreprocessingError::InvalidConfig("Center crop requires 'size' parameter".to_string()))
                }
            },

            _ => {
                tracing::warn!("Unknown preprocessing step: {}", step.step_type);
                Ok(image) // Skip unknown steps
            }
        }
    }

    /// Convert image to tensor format
    fn image_to_tensor(&self, image: DynamicImage) -> Result<Array4<f32>, PreprocessingError> {
        let rgb_image = image.to_rgb8();
        let (width, height) = rgb_image.dimensions();

        match self.format {
            InputFormat::NCHW => {
                // [N, C, H, W] format
                let mut tensor = Array4::<f32>::zeros((1, 3, height as usize, width as usize));

                for (y, row) in rgb_image.rows().enumerate() {
                    for (x, pixel) in row.enumerate() {
                        tensor[[0, 0, y, x]] = pixel.0[0] as f32; // R
                        tensor[[0, 1, y, x]] = pixel.0[1] as f32; // G
                        tensor[[0, 2, y, x]] = pixel.0[2] as f32; // B
                    }
                }

                Ok(tensor)
            },

            InputFormat::NHWC => {
                // [N, H, W, C] format
                let mut tensor = Array4::<f32>::zeros((1, height as usize, width as usize, 3));

                for (y, row) in rgb_image.rows().enumerate() {
                    for (x, pixel) in row.enumerate() {
                        tensor[[0, y, x, 0]] = pixel.0[0] as f32; // R
                        tensor[[0, y, x, 1]] = pixel.0[1] as f32; // G
                        tensor[[0, y, x, 2]] = pixel.0[2] as f32; // B
                    }
                }

                Ok(tensor)
            },
        }
    }

    /// Apply normalization to tensor
    fn apply_normalization(&self, mut tensor: Array4<f32>) -> Result<Array4<f32>, PreprocessingError> {
        let num_channels = match self.format {
            InputFormat::NCHW => tensor.shape()[1],
            InputFormat::NHWC => tensor.shape()[3],
        };

        if self.normalization.mean.len() != num_channels || self.normalization.std.len() != num_channels {
            return Err(PreprocessingError::InvalidConfig(
                format!("Normalization arrays must have {} elements for {} channels",
                    num_channels, num_channels)
            ));
        }

        match self.format {
            InputFormat::NCHW => {
                for c in 0..num_channels {
                    let mut channel = tensor.slice_mut(ndarray::s![0, c, .., ..]);

                    // Scale to [0,1] if requested
                    if self.normalization.scale_to_unit {
                        channel.mapv_inplace(|x| x / 255.0);
                    }

                    // Apply mean and std normalization
                    let mean = self.normalization.mean[c];
                    let std = self.normalization.std[c];
                    channel.mapv_inplace(|x| (x - mean) / std);
                }
            },

            InputFormat::NHWC => {
                for c in 0..num_channels {
                    let mut channel = tensor.slice_mut(ndarray::s![0, .., .., c]);

                    // Scale to [0,1] if requested
                    if self.normalization.scale_to_unit {
                        channel.mapv_inplace(|x| x / 255.0);
                    }

                    // Apply mean and std normalization
                    let mean = self.normalization.mean[c];
                    let std = self.normalization.std[c];
                    channel.mapv_inplace(|x| (x - mean) / std);
                }
            },
        }

        Ok(tensor)
    }
}

/// Create common preprocessor configurations for popular model types
pub mod presets {
    use super::*;

    /// YOLOv8 preprocessing (letterbox, RGB, 640x640)
    pub fn yolov8() -> UniversalImagePreprocessor {
        UniversalImagePreprocessor::new(
            (640, 640),
            ResizeStrategy::Letterbox { fill_color: [114, 114, 114] },
            NormalizationConfig {
                mean: vec![0.0, 0.0, 0.0],
                std: vec![1.0, 1.0, 1.0],
                scale_to_unit: true,
            },
            InputFormat::NCHW,
        )
    }

    /// MobileNetV2 ImageNet preprocessing (crop, RGB, 224x224)
    pub fn mobilenetv2_imagenet() -> UniversalImagePreprocessor {
        UniversalImagePreprocessor::new(
            (224, 224),
            ResizeStrategy::CenterCrop,
            NormalizationConfig {
                mean: vec![0.485, 0.456, 0.406],
                std: vec![0.229, 0.224, 0.225],
                scale_to_unit: true,
            },
            InputFormat::NCHW,
        )
    }

    /// ResNet preprocessing (crop, RGB, 224x224)
    pub fn resnet_imagenet() -> UniversalImagePreprocessor {
        UniversalImagePreprocessor::new(
            (224, 224),
            ResizeStrategy::CenterCrop,
            NormalizationConfig {
                mean: vec![0.485, 0.456, 0.406],
                std: vec![0.229, 0.224, 0.225],
                scale_to_unit: true,
            },
            InputFormat::NCHW,
        )
    }

    /// EfficientNet preprocessing (crop, RGB, variable size)
    pub fn efficientnet(input_size: u32) -> UniversalImagePreprocessor {
        UniversalImagePreprocessor::new(
            (input_size, input_size),
            ResizeStrategy::CenterCrop,
            NormalizationConfig {
                mean: vec![0.485, 0.456, 0.406],
                std: vec![0.229, 0.224, 0.225],
                scale_to_unit: true,
            },
            InputFormat::NCHW,
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use image::{Rgb, RgbImage};

    fn create_test_image(width: u32, height: u32) -> DynamicImage {
        let img_buffer = RgbImage::from_fn(width, height, |x, y| {
            if (x + y) % 2 == 0 {
                Rgb([255, 0, 0]) // Red
            } else {
                Rgb([0, 255, 0]) // Green
            }
        });
        DynamicImage::ImageRgb8(img_buffer)
    }

    #[test]
    fn test_letterbox_resize() {
        let preprocessor = presets::yolov8();
        let test_image = create_test_image(800, 600); // 4:3 aspect ratio

        let result = preprocessor.process(test_image).unwrap();

        // Should be letterboxed to 640x640 with padding
        assert_eq!(result.tensor.shape(), &[1, 3, 640, 640]);
        assert!(result.padding.0 > 0 || result.padding.1 > 0); // Should have some padding
    }

    #[test]
    fn test_center_crop_resize() {
        let preprocessor = presets::mobilenetv2_imagenet();
        let test_image = create_test_image(800, 600);

        let result = preprocessor.process(test_image).unwrap();

        // Should be cropped and resized to 224x224
        assert_eq!(result.tensor.shape(), &[1, 3, 224, 224]);
        assert_eq!(result.padding, (0, 0, 0, 0)); // No padding for crop
    }

    #[test]
    fn test_normalization() {
        let preprocessor = presets::mobilenetv2_imagenet();
        let test_image = create_test_image(224, 224);

        let result = preprocessor.process(test_image).unwrap();

        // Values should be normalized (not in 0-255 range)
        let sample_value = result.tensor[[0, 0, 0, 0]];
        assert!(sample_value < 10.0 && sample_value > -10.0); // Should be in normalized range
    }
}
