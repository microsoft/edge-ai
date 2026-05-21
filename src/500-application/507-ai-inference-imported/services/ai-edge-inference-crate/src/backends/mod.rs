#[cfg(feature = "candle")]
pub mod candle;

#[cfg(feature = "onnx-runtime")]
pub mod onnx;

// Re-export backend implementations
#[cfg(feature = "candle")]
pub use candle::CandleBackend;

#[cfg(feature = "onnx-runtime")]
pub use onnx::OnnxRuntimeBackend;