use chrono::{DateTime, Duration, Local};

use opencv::{
    core::{Mat, Size},
    imgproc,
};
use opencv::prelude::MatTraitConst;
use std::{collections::VecDeque, path::Path, sync::Arc, env, time::Duration as StdDuration};
use tokio::sync::Mutex;
use tracing::{error, info, trace, warn};
use ffmpeg_next as ffmpeg;
use tokio::task;


pub struct TimestampedFrame {
    pub frame: Mat,
    pub timestamp: DateTime<Local>,
}

pub struct VideoBuffer {
    pub frames: VecDeque<TimestampedFrame>,
    pub max_frames: usize,
}

impl VideoBuffer {
    pub fn new(max_frames: usize) -> Self {
        Self {
            frames: VecDeque::with_capacity(max_frames),
            max_frames,
        }
    }

    pub fn push(&mut self, frame: Mat, timestamp: DateTime<Local>) {
        // If buffer is full, remove the oldest frame to make room for the new one
        if self.frames.len() == self.max_frames {
            self.frames.pop_front();
        }
        self.frames.push_back(TimestampedFrame { frame, timestamp });
    }

    pub fn get_frames(&self) -> Vec<Mat> {
        self.frames.iter().map(|tf| tf.frame.clone()).collect()
    }

    pub fn get_frames_since(&self, timestamp: DateTime<Local>) -> Vec<Mat> {
        self.frames
            .iter()
            .filter(|f| f.timestamp >= timestamp)
            .map(|f| f.frame.clone())
            .collect()
    }

    pub fn latest_frame_time(&self) -> Option<DateTime<Local>> {
        self.frames.back().map(|f| f.timestamp)
    }
    
    /// Removes frames older than the specified age in seconds.
    /// 
    /// Prevents memory growth when frames are added slower than expected
    /// or when max_frames is large.
    /// 
    /// Returns the number of frames removed.
    pub fn cleanup_old_frames(&mut self, max_age_seconds: i64) -> usize {
        let now = Local::now();
        let oldest_allowed = now - chrono::Duration::seconds(max_age_seconds);
        
        let initial_count = self.frames.len();
        
        // Remove frames older than max_age_seconds
        self.frames.retain(|frame| frame.timestamp >= oldest_allowed);
        
        let removed_count = initial_count - self.frames.len();
        if removed_count > 0 {
            info!("Cleaned up {} frames older than {} seconds", removed_count, max_age_seconds);
        }
        
        removed_count
    }
}

// Memory management constants
const DEFAULT_MAX_OLD_FRAMES_AGE_SECS: &str = "300"; // 5 minutes
const DEFAULT_BUFFER_CLEANUP_INTERVAL_SECS: &str = "60"; // 1 minute

// Helper to get env var with default
fn get_env_or_default(key: &str, default: &str) -> String {
    env::var(key).unwrap_or_else(|_| {
        trace!("Using default value for {}: {}", key, default);
        default.to_string()
    })
}

// Helper to get env var as numeric value with default
fn get_env_as_u64(key: &str, default: &str) -> u64 {
    get_env_or_default(key, default).parse::<u64>().unwrap_or_else(|_| {
        warn!("Failed to parse {} as u64, using default: {}", key, default);
        default.parse::<u64>().unwrap_or(0)
    })
}

pub async fn capture_rtsp_stream(rtsp_url: String, buffer: Arc<Mutex<VideoBuffer>>, frame_size: Size) {
    // Spawn a task to periodically clean up old frames
    let buffer_clone = buffer.clone();
    tokio::spawn(async move {
        let cleanup_interval_secs = get_env_as_u64("BUFFER_CLEANUP_INTERVAL_SECS", DEFAULT_BUFFER_CLEANUP_INTERVAL_SECS);
        let max_old_frames_age_secs = get_env_as_u64("MAX_OLD_FRAMES_AGE_SECS", DEFAULT_MAX_OLD_FRAMES_AGE_SECS) as i64;
        
        info!("Starting periodic buffer cleanup task (interval: {}s, max age: {}s)", 
              cleanup_interval_secs, max_old_frames_age_secs);
              
        loop {
            tokio::time::sleep(StdDuration::from_secs(cleanup_interval_secs)).await;
            
            let mut buf = buffer_clone.lock().await;
            let initial_count = buf.frames.len();
            let removed = buf.cleanup_old_frames(max_old_frames_age_secs);
            
            if removed > 0 {
                info!("Periodic cleanup: removed {} old frames, {} frames remaining", 
                      removed, initial_count - removed);
            } else {
                trace!("Periodic cleanup: no old frames to remove, {} frames in buffer", initial_count);
            }
        }
    });

    task::spawn_blocking(move || {
        info!("Initializing FFmpeg...");
        
        // Set FFmpeg log level to only show fatal errors, suppressing the H.264 decoding warnings
        ffmpeg::log::set_level(ffmpeg::log::Level::Fatal);
        std::env::set_var("OPENCV_FFMPEG_LOGLEVEL", "0"); // 0 = AV_LOG_QUIET
        std::env::set_var("AV_LOG_LEVEL", "0");
        
        if let Err(e) = ffmpeg::init() {
            error!("FFmpeg initialization failed: {:?}", e);
            return;
        }
        info!("FFmpeg initialized successfully.");

        // Continuous reconnection loop
        loop {
            info!("Connecting to RTSP stream: {}", rtsp_url);
            match connect_and_process_stream(&rtsp_url, &buffer, frame_size) {
                Ok(_) => info!("RTSP stream processing completed normally."),
                Err(e) => error!("RTSP stream processing failed: {}. Will retry in 5 seconds...", e),
            }
            
            // Wait before attempting to reconnect
            std::thread::sleep(std::time::Duration::from_secs(5));
            info!("Attempting to reconnect to RTSP stream...");
        }
    });
}

fn connect_and_process_stream(
    rtsp_url: &str, 
    buffer: &Arc<Mutex<VideoBuffer>>, 
    frame_size: Size
) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    // Set analyzeduration and probesize options for RTSP
    let mut options = ffmpeg::Dictionary::new();
    options.set("analyzeduration", "10000000");
    options.set("probesize", "5000000");
    options.set("stimeout", "10000000"); // 10 seconds socket timeout
    options.set("rtsp_transport", "tcp"); // Use TCP for RTSP transport
    options.set("max_delay", "5000000"); // 5 seconds max delay
    options.set("buffer_size", "8192000"); // Increase buffer size to handle jitter
    options.set("max_interleave_delta", "0"); // Handle non-monotonic timestamps
    options.set("flags", "low_delay"); // Enable low delay mode
    options.set("error_concealment", "1"); // Enable error concealment
    // options.set("fflags", "nobuffer"); // Disable buffering for low latency
    // options.set("flush_packets", "1"); // Flush packets immediately

    info!("Opening RTSP stream: {}", rtsp_url);
    let p = Path::new(rtsp_url);
    let mut ictx = match ffmpeg::format::input_with_dictionary(&p, options) {
        Ok(ctx) => {
            info!("RTSP stream opened successfully with custom options.");
            ctx
        },
        Err(e) => {
            error!("Failed to open RTSP stream: {:?}", e);
            return Err(format!("Failed to open RTSP stream: {:?}", e).into());
        }
    };
    
    // Log all stream info for debugging
    for (i, stream) in ictx.streams().enumerate() {
        info!(
            "Stream {}: id={:?}, type={:?}, disposition={:?}, time_base={:?}, avg_frame_rate={:?}",
            i,
            stream.id(),
            stream.parameters().medium(),
            stream.disposition(),
            stream.time_base(),
            stream.avg_frame_rate()
        );
    }

    info!("Selecting best video stream...");
    let input = match ictx.streams().best(ffmpeg::media::Type::Video) {
        Some(stream) => {
            info!("Best video stream selected: index={}", stream.index());
            stream
        },
        None => {
            error!("No video stream found in RTSP feed");
            return Err("No video stream found in RTSP feed".into());
        }
    };

    let video_stream_index = input.index();
    let time_base = input.time_base();
    info!("Video stream index: {}, time_base: {:?}", video_stream_index, time_base);

    let context_decoder = match ffmpeg::codec::context::Context::from_parameters(input.parameters()) {
        Ok(ctx) => {
            info!("Decoder context created successfully.");
            ctx
        },
        Err(e) => {
            error!("Failed to create decoder context: {:?}", e);
            return Err(format!("Failed to create decoder context: {:?}", e).into());
        }
    };
    let mut decoder = match context_decoder.decoder().video() {
        Ok(dec) => {
            info!("Video decoder created successfully.");
            dec
        },
        Err(e) => {
            error!("Failed to create video decoder: {:?}", e);
            return Err(format!("Failed to create video decoder: {:?}", e).into());
        }
    };

    let mut packet_count = 0;
    let mut frame_count = 0;

    for (stream, packet) in ictx.packets() {
        if stream.index() == video_stream_index {
            packet_count += 1;
            trace!("Processing packet #{}", packet_count);

            if let Err(e) = decoder.send_packet(&packet) {
                error!("Error sending packet to decoder: {:?}", e);
                continue;
            }
            let mut decoded_frame = ffmpeg::util::frame::Video::empty();
            let stream_start_time = Local::now(); // Capture this once, before the decoding loop starts
            while decoder.receive_frame(&mut decoded_frame).is_ok() {
                frame_count += 1;
                // Get accurate timestamp
                let pts = decoded_frame.pts();
                let timestamp_sec = pts.map(|p| p as f64 * f64::from(time_base));
                // Approximate frame time using local system time + relative timestamp
                let frame_time = timestamp_sec.map(|ts| {
                    let frame_dt: DateTime<Local> = stream_start_time + Duration::milliseconds((ts * 1000.0) as i64);
                    frame_dt.format("%Y-%m-%d %H:%M:%S").to_string()
                }).unwrap_or_else(|| "N/A".to_string());

                let now = Local::now().format("%Y-%m-%d %H:%M:%S").to_string();

                trace!(
                    "Decoded frame #{}: pts={:?}, timestamp_sec={:?}, local_time={}, frame_time={}",
                    frame_count,
                    pts,
                    timestamp_sec,
                    now,
                    frame_time
                );

                // Convert ffmpeg frame to OpenCV Mat
                let mat = match ffmpeg_frame_to_mat(&decoded_frame) {
                    Ok(m) => {
                        // Check if the converted Mat is valid
                        if m.empty() || m.cols() <= 0 || m.rows() <= 0 {
                            trace!("Frame #{} was successfully converted but appears invalid, skipping", frame_count);
                            continue;
                        }
                        trace!("Frame #{} successfully converted to Mat (size: {}x{})", frame_count, m.cols(), m.rows());
                        m
                    },
                    Err(e) => {
                        error!("Failed to convert frame to Mat: {:?}", e);
                        continue;
                    }
                };

                // Resize frame
                let mut resized = Mat::default();
                if let Err(e) = imgproc::resize(&mat, &mut resized, frame_size, 0.0, 0.0, imgproc::INTER_LINEAR) {
                    error!("Failed to resize frame: {:?}", e);
                    continue;
                } else {
                    trace!("Frame #{} resized to {:?}", frame_count, frame_size);
                }

                // Get the current timestamp outside the lock
                let frame_timestamp = Local::now();
                
                // Minimize lock duration by using a block scope
                {
                    // Take the lock only for the push operation
                    let mut buf = buffer.blocking_lock();
                    let before = buf.frames.len();
                    buf.push(resized, frame_timestamp);
                    let after = buf.frames.len();
                    
                    // Log if buffer size changed significantly - potential memory issue indicator
                    if after > before + 10 {
                        warn!("Buffer grew unusually fast: {} -> {} frames", before, after);
                    } else {
                        trace!("Frame #{} pushed to buffer (size before: {}, after: {})", frame_count, before, after);
                    }
                    
                    // Lock is released here at end of scope
                }
            }
        }
    }
    info!("RTSP capture finished. Total packets: {}, total frames: {}", packet_count, frame_count);
    
    Ok(())
}

// Helper function to convert ffmpeg frame to OpenCV Mat
fn ffmpeg_frame_to_mat(frame: &ffmpeg::util::frame::Video) -> opencv::Result<Mat> {
    let width = frame.width();
    let height = frame.height();

    let mut rgb_frame = ffmpeg::util::frame::video::Video::empty();
    let mut scaler = ffmpeg::software::scaling::Context::get(
        frame.format(),
        width,
        height,
        ffmpeg::format::Pixel::RGB24,
        width,
        height,
        ffmpeg::software::scaling::Flags::BILINEAR,
    ).map_err(|e| opencv::Error::new(0, format!("Scaler creation failed: {:?}", e)))?;

    scaler.run(frame, &mut rgb_frame)
        .map_err(|e| opencv::Error::new(0, format!("Scaling failed: {:?}", e)))?;

    let data = rgb_frame.data(0);
    let mat_temp = Mat::from_slice(data)?;
    let mat = mat_temp.reshape(3, height as i32)?;
    let mut mat_bgr = Mat::default();
    imgproc::cvt_color(&mat, &mut mat_bgr, imgproc::COLOR_RGB2BGR, 0)?;
    Ok(mat_bgr)
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Local;
    use opencv::core::Mat;

    #[test]
    fn test_push_and_get_frames() {
        let mut buffer = VideoBuffer::new(2);
        let mat = Mat::default();
        let now = Local::now();
        buffer.push(mat.clone(), now);
        buffer.push(mat.clone(), now);
        assert_eq!(buffer.get_frames().len(), 2);
        buffer.push(mat.clone(), now);
        assert_eq!(buffer.get_frames().len(), 2); // Oldest should be dropped
    }

    #[test]
    fn test_get_frames_since() {
        let mut buffer = VideoBuffer::new(3);
        let mat = Mat::default();
        let t1 = Local::now();
        let t2 = t1 + chrono::Duration::seconds(1);
        let t3 = t2 + chrono::Duration::seconds(1);
        buffer.push(mat.clone(), t1);
        buffer.push(mat.clone(), t2);
        buffer.push(mat.clone(), t3);
        let frames = buffer.get_frames_since(t2);
        assert_eq!(frames.len(), 2);
    }

    #[test]
    fn test_latest_frame_time() {
        let mut buffer = VideoBuffer::new(2);
        let mat = Mat::default();
        let t1 = Local::now();
        buffer.push(mat.clone(), t1);
        assert_eq!(buffer.latest_frame_time().unwrap(), t1);
    }

    #[test]
    fn test_cleanup_old_frames() {
        let mut buffer = VideoBuffer::new(3);
        let mat = Mat::default();
        
        // Create timestamps with more significant time differences
        let now = Local::now();
        let t_old = now - chrono::Duration::seconds(5); // 5 seconds in the past
        let t_recent1 = now - chrono::Duration::seconds(1); // 1 second in the past
        let t_recent2 = now; // Current time
        
        // Add frames with those timestamps
        buffer.push(mat.clone(), t_old);     // This one should be removed when we clean up frames older than 2 seconds
        buffer.push(mat.clone(), t_recent1); // These should be kept
        buffer.push(mat.clone(), t_recent2); // These should be kept
        
        // Verify initial buffer state
        assert_eq!(buffer.frames.len(), 3);
        
        // Clean up frames older than 2 seconds
        let removed_count = buffer.cleanup_old_frames(2);
        
        // Verify one frame was removed and two remain
        assert_eq!(removed_count, 1, "Expected 1 frame to be removed");
        assert_eq!(buffer.frames.len(), 2, "Expected 2 frames to remain");
    }

    #[test]
    fn test_buffer_capacity_limit() {
        let mut buffer = VideoBuffer::new(10);
        let mat = Mat::default();
        let now = Local::now();
        
        // Fill the buffer completely
        for _ in 0..10 {
            buffer.push(mat.clone(), now);
        }
        
        assert_eq!(buffer.frames.len(), 10, "Buffer should be at maximum capacity");
        
        // One more push should still maintain the max size by removing the oldest frame
        buffer.push(mat.clone(), now);
        assert_eq!(buffer.frames.len(), 10, "Buffer should remain at maximum capacity");
    }
    
    #[test]
    fn test_get_env_or_default() {
        // Test with non-existent env var
        let result = get_env_or_default("NON_EXISTENT_VAR", "default_value");
        assert_eq!(result, "default_value");
    }
}
