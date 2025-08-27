use chrono::{DateTime, Utc, Local};
use opencv::{core::Size, prelude::*, videoio::VideoWriter};
use opencv::prelude::VideoWriterTrait;
use std::{error::Error, path::PathBuf, sync::Arc};
use tokio::sync::Mutex;
use tokio::fs;
use tracing::{info, warn};

use crate::video_ring_buffer::VideoBuffer;

/// Creates a formatted filename for the video based on event information
fn create_video_filename(
    formatted_timestamp: String,
    event_id: Option<u64>,
    event_type: Option<&str>,
) -> String {
    if let Some(event_id) = event_id {
        // Determine base name and extension
        let (base_name, extension) = if let Some(dot_idx) = formatted_timestamp.rfind('.') {
            let (base, ext) = formatted_timestamp.split_at(dot_idx);
            (base, ext)
        } else {
            (formatted_timestamp.as_str(), "")
        };

        // Get event type string once
        let event_type_str = event_type.unwrap_or("event");

        // Format the filename based on event type
        let formatted_name = if event_type_str == "alert" {
            format!("{}_alert_event_id_{}", base_name, event_id)
        } else if event_type_str.starts_with("analytics_disabled") {
            // Use the full event_type string which might include service type
            format!("{}_{}_timestamp_{}", base_name, event_type_str, event_id)
        } else {
            format!("{}_{}_id_{}", base_name, event_type_str, event_id)
        };

        // Add extension if it exists
        format!("{}{}", formatted_name, extension)
    } else {
        formatted_timestamp
    }
}

/// Sample frames evenly to achieve target duration and FPS
fn sample_frames<'a>(
    matching_frames: &[&'a crate::video_ring_buffer::TimestampedFrame],
    exact_frames_needed: usize,
    event_id_str: &str,
    duration_seconds: f64,
    video_fps: f64,
) -> Vec<&'a crate::video_ring_buffer::TimestampedFrame> {
    if matching_frames.len() > exact_frames_needed {
        info!("event_id={}, Sampling {} frames from {} available to achieve {}-second duration at {:.2} fps",
             event_id_str, exact_frames_needed, matching_frames.len(), duration_seconds, video_fps);

        // Select frames evenly distributed across the time range
        let step = (matching_frames.len() as f64) / (exact_frames_needed as f64);
        let mut selected_frames = Vec::with_capacity(exact_frames_needed);

        for i in 0..exact_frames_needed {
            let idx = (i as f64 * step) as usize;
            if idx < matching_frames.len() {
                selected_frames.push(matching_frames[idx]);
            }
        }

        selected_frames
    } else {
        info!("event_id={}, Using all {} available frames for {}-second duration at {:.2} fps",
             event_id_str, matching_frames.len(), duration_seconds, video_fps);
        matching_frames.to_vec()
    }
}

pub async fn write_buffered_video(
    buffer: Arc<Mutex<VideoBuffer>>,
    dest_path: PathBuf,
    filename_format: &str,
    video_format: &str,
    fps: f64,
    frame_size: Size,
    timestamp: Option<DateTime<Local>>,
    wait_seconds: usize,
    event_id: Option<u64>,
    event_type: Option<&str>,
) -> Result<bool, Box<dyn Error>> {
    let event_id_str = event_id.map(|id| id.to_string()).unwrap_or_else(|| "unknown".to_string());
    let formatted_timestamp = Utc::now().format(filename_format).to_string();
    info!("Creating filename with event_id={}, event_type={:?}", event_id_str, event_type);

    let file_name = create_video_filename(formatted_timestamp.clone(), event_id, event_type);
    // Get current date in UTC for folder naming
    let date_folder = Utc::now().format("%Y-%m-%d").to_string();
    let dated_dest_path = dest_path.join(date_folder);

    let file_path = dated_dest_path.join(&file_name);
    if !dated_dest_path.exists() {
        warn!("event_id={}, Directory does not exist: {:?}. Attempting to create it.", event_id_str, dated_dest_path);
        fs::create_dir_all(dated_dest_path.clone()).await.map_err(|e| Box::new(e) as Box<dyn Error>)?;
    }

    let fourcc_chars: Vec<char> = video_format.chars().collect();
    if fourcc_chars.len() != 4 {
        return Err("video_format must be exactly 4 characters".into());
    }

    let fourcc = VideoWriter::fourcc(
        fourcc_chars[0],
        fourcc_chars[1],
        fourcc_chars[2],
        fourcc_chars[3],
    )?;

    let mut frames_written = 0;
    let mut buffer_size_bytes = 0;
    let duration_seconds = wait_seconds as f64; // Define duration_seconds here for use in final logging
    let fps_for_logging = fps; // Store the FPS used for logging

    if let Some(ts) = timestamp {
        let start_time = ts;
        let end_time = start_time + chrono::Duration::seconds(wait_seconds as i64);
        let max_wait_attempts = 10; // Maximum number of attempts to wait for frames
        let mut attempt_count = 0;

        loop {
            let buf = buffer.lock().await;
            if let Some(latest_time) = buf.latest_frame_time() {
                if latest_time < end_time {
                    attempt_count += 1;
                    let seconds_remaining = end_time.signed_duration_since(latest_time).num_seconds();
                    info!(
                        "event_id={}, Waiting for frames: latest buffered frame at {}, need frames up to {} (seconds remaining: {}, attempt: {}/{})",
                        event_id_str,
                        latest_time.format("%Y-%m-%d %H:%M:%S"),
                        end_time.format("%Y-%m-%d %H:%M:%S"),
                        seconds_remaining,
                        attempt_count,
                        max_wait_attempts
                    );

                    // Exit if we've reached the maximum number of wait attempts
                    if attempt_count >= max_wait_attempts {
                        warn!("event_id={}, Exceeded maximum wait attempts ({}). Proceeding with available frames.",
                              event_id_str, max_wait_attempts);
                        break;
                    }

                    drop(buf);
                    tokio::time::sleep(std::time::Duration::from_secs(1)).await;
                    continue;
                } else {
                    info!(
                        "event_id={}, Collecting frames in range: {} to {} (inclusive)",
                        event_id_str,
                        start_time.format("%Y-%m-%d %H:%M:%S"),
                        end_time.format("%Y-%m-%d %H:%M:%S")
                    );

                    // Get frames that match our time range
                    let matching_frames: Vec<_> = buf.frames.iter()
                        .filter(|f| f.timestamp >= start_time && f.timestamp <= end_time)
                        .collect();

                    // Calculate actual FPS from the frames we collected
                    let actual_fps = calculate_actual_fps(&matching_frames, fps);

                    info!("event_id={}, Camera actual FPS: {:.2} (config FPS: {:.2})",
                          event_id_str, actual_fps, fps);

                    // Calculate number of frames needed for the target FPS
                    let exact_frames_needed = (duration_seconds * fps) as usize;

                    // Only create the writer if we have frames to write
                    if !matching_frames.is_empty() {
                        let mut writer = VideoWriter::new(
                            file_path.to_str().unwrap(),
                            fourcc,
                            fps, // Use configured FPS for consistency
                            frame_size,
                            true,
                        )?;

                        // Determine if we need to sample frames or use all available frames
                        let frames_to_write = sample_frames(&matching_frames, exact_frames_needed, &event_id_str, duration_seconds, fps);

                        // Write frames to video file and track metrics
                        let (written, size) = write_frames_to_video(frames_to_write, &mut writer, &event_id_str)?;
                        frames_written = written;
                        buffer_size_bytes = size;

                        writer.release()?;

                        info!("event_id={}, Buffered video written to {:?} ({} frames at {:.2} fps, total duration: {:.2} seconds, {} bytes)",
                              event_id_str, file_path, frames_written,
                              fps_for_logging, // Use the FPS we actually encoded with
                              duration_seconds, buffer_size_bytes);
                    } else {
                        warn!(
                            "event_id={}, No frames found matching the time range {} to {}. No video file created.",
                            event_id_str,
                            start_time.format("%Y-%m-%d %H:%M:%S"),
                            end_time.format("%Y-%m-%d %H:%M:%S")
                        );
                    }
                    break;
                }
            } else {
                attempt_count += 1;
                info!("event_id={}, Buffer is empty, waiting for frames... (attempt: {}/{})",
                      event_id_str, attempt_count, max_wait_attempts);

                // Exit if we've reached the maximum number of wait attempts
                if attempt_count >= max_wait_attempts {
                    warn!("event_id={}, Exceeded maximum wait attempts ({}). No frames available.",
                          event_id_str, max_wait_attempts);
                    break;
                }

                drop(buf);
                tokio::time::sleep(std::time::Duration::from_secs(1)).await;
                continue;
            }
        }
    } else {
        let buf = buffer.lock().await;

        // Only create the writer if the buffer is not empty
        if !buf.frames.is_empty() {
            let mut writer = create_video_writer(&file_path, fourcc, fps, frame_size)?;

            info!("event_id={}, No timestamp provided, writing entire buffer ({} frames).", event_id_str, buf.frames.len());
            // Write frames to video file and track metrics
            let (written, size) = write_frames_to_video(buf.frames.iter().collect(), &mut writer, &event_id_str)?;
            frames_written = written;
            buffer_size_bytes = size;

            writer.release()?;

            info!("event_id={}, Buffered video written to {:?} ({} frames at {:.2} fps, total duration: {:.2} seconds, {} bytes)",
                  event_id_str, file_path, frames_written,
                  fps, // Use the configured FPS for consistency
                  duration_seconds, buffer_size_bytes);
        } else {
            warn!("event_id={}, Buffer is empty. No video file created.", event_id_str);
        }
    }

    if frames_written == 0 {
        warn!("event_id={}, No frames available for the specified timestamp range.", event_id_str);
        return Ok(false);
    }

    info!("event_id={}, Buffered video written to {:?} ({} frames at {:.2} fps, total duration: {:.2} seconds, {} bytes)",
          event_id_str, file_path, frames_written,
          fps_for_logging, // Use the FPS we actually encoded with
          duration_seconds, buffer_size_bytes);
    Ok(true)
}

/// Calculate actual FPS from collected frames
fn calculate_actual_fps(frames: &Vec<&crate::video_ring_buffer::TimestampedFrame>, configured_fps: f64) -> f64 {
    if frames.len() > 1 {
        let first_time = frames[0].timestamp;
        let last_time = frames[frames.len() - 1].timestamp;
        let time_span_secs = last_time.signed_duration_since(first_time).num_milliseconds() as f64 / 1000.0;

        if time_span_secs > 0.0 {
            (frames.len() - 1) as f64 / time_span_secs
        } else {
            configured_fps // fallback to config fps if no time span
        }
    } else {
        configured_fps // fallback to config fps if insufficient frames
    }
}

/// Write frames to video file and track metrics
fn write_frames_to_video(
    frames: Vec<&crate::video_ring_buffer::TimestampedFrame>,
    writer: &mut VideoWriter,
    _event_id_str: &str, // Prefix with underscore to indicate intentionally unused
) -> Result<(usize, usize), Box<dyn Error>> {
    let mut frames_written = 0;
    let mut buffer_size_bytes = 0;

    for f in frames {
        writer.write(&f.frame)?;
        frames_written += 1;
        buffer_size_bytes += f.frame.total() as usize * f.frame.elem_size().unwrap_or(0);
    }

    Ok((frames_written, buffer_size_bytes))
}

/// Create a properly configured VideoWriter instance
fn create_video_writer(
    file_path: &PathBuf,
    fourcc: i32,
    fps: f64,
    frame_size: Size,
) -> Result<VideoWriter, Box<dyn Error>> {
    Ok(VideoWriter::new(
        file_path.to_str().unwrap(),
        fourcc,
        fps,
        frame_size,
        true,
    )?)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::video_ring_buffer::VideoBuffer;
    use opencv::core::{Mat, Size};
    use chrono::Local;
    use std::sync::Arc;
    use tokio::sync::Mutex;
    use std::path::PathBuf;

    #[tokio::test]
    async fn test_write_buffered_video_empty_buffer() {
        let buffer = Arc::new(Mutex::new(VideoBuffer::new(5)));
        let dest_path = PathBuf::from("/tmp/test_write_buffered_video_empty_buffer");
        let _ = tokio::fs::remove_dir_all(&dest_path).await;
        let result = write_buffered_video(
            buffer,
            dest_path,
            "%Y-%m-%d_%H%M%S_test.mkv",
            "XVID",
            10.0,
            Size::new(10, 10),
            None,
            1,
            Some(1),
            Some("test"),
        ).await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), false); // test for false when no frames
    }

    #[tokio::test]
    async fn test_write_buffered_video_with_frames() {
        let mut buffer = VideoBuffer::new(2);
        let mat = Mat::default();
        let now = Local::now();
        buffer.push(mat.clone(), now);
        buffer.push(mat.clone(), now);
        let buffer = Arc::new(Mutex::new(buffer));
        let dest_path = PathBuf::from("/tmp/test_write_buffered_video_with_frames");
        let _ = tokio::fs::remove_dir_all(&dest_path).await;
        let result = write_buffered_video(
            buffer,
            dest_path,
            "%Y-%m-%d_%H%M%S_test.mkv",
            "XVID",
            10.0,
            Size::new(10, 10),
            None,
            1,
            Some(2),
            Some("test"),
        ).await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), true); // test for true when frames exist
    }
}
