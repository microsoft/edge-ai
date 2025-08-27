use std::{env, error::Error, path::PathBuf, sync::Arc};
use tokio::sync::Mutex;
use tokio::fs;
use tracing::{info, warn, debug, error};
use chrono::Utc;
use opencv::core::Size;
use azure_iot_operations_mqtt::{
    MqttConnectionSettingsBuilder,
    session::{Session, SessionOptionsBuilder},
};
use uuid::Uuid;
use crate::{
    video_ring_buffer::{VideoBuffer, capture_rtsp_stream},
    mqtt_handler::receive_messages,
};

/// Create MQTT connection settings builder with custom handling for TLS configuration
fn create_mqtt_connection_settings_builder() -> Result<MqttConnectionSettingsBuilder, Box<dyn Error>> {
    // Check if TLS is enabled via environment variable

    let use_tls = env::var("AIO_MQTT_USE_TLS")
        .map(|v| v.to_lowercase() == "true")
        .unwrap_or(true); // Default to true if not specified

    // If TLS is disabled, build connection without authentication
    if !use_tls {
        info!("TLS disabled via AIO_MQTT_USE_TLS=false, building connection without authentication");

        // Temporarily unset TLS-related variables if they exist
        let original_tls = env::var("AIO_TLS_CA_FILE").ok();
        let original_sat = env::var("AIO_SAT_FILE").ok();

        env::remove_var("AIO_TLS_CA_FILE");
        env::remove_var("AIO_SAT_FILE");

        let builder = MqttConnectionSettingsBuilder::from_environment()
            .map_err(|e| Box::new(std::io::Error::new(std::io::ErrorKind::Other, e)) as Box<dyn Error>)?;

        // Restore original values if they were set
        if let Some(val) = original_tls {
            env::set_var("AIO_TLS_CA_FILE", val);
        }
        if let Some(val) = original_sat {
            env::set_var("AIO_SAT_FILE", val);
        }

        Ok(builder)
    } else {
        // Use the standard builder with TLS enabled
        info!("TLS enabled (AIO_MQTT_USE_TLS=true or not specified), building connection with authentication");
        MqttConnectionSettingsBuilder::from_environment()
            .map_err(|e| Box::new(std::io::Error::new(std::io::ErrorKind::Other, e)) as Box<dyn Error>)
    }
}

pub trait TimeParamWorker: Clone {
    fn get_time_params(&self, payload: &serde_json::Value) -> Result<VideoSegmentParams, Box<dyn std::error::Error>>;
}

#[derive(Debug)]
pub struct TimeParams {
    pub start_time: chrono::DateTime<chrono::Utc>,
    pub duration: f64,
}

#[derive(Debug)]
pub struct VideoSegmentParams {
    pub time_param: TimeParams,
    pub event_id: Option<u64>,
    pub event_type: Option<String>,
}

const DEFAULT_BUFFER_SECONDS: usize = 30;
const DEFAULT_FRAME_WIDTH: i32 = 640;
const DEFAULT_FRAME_HEIGHT: i32 = 480;
const DEFAULT_VIDEO_FORMAT: &str = "X264"; // or "MJPG", "XVID", "MP4V"
const DEFAULT_FILENAME_FORMAT: &str = "%Y-%m-%d_%H%M%S_segment.mkv";
const DEFAULT_VIDEO_FPS: f64 = 10.0;
const MAX_BUFFER_SECONDS: usize = 60;
const MAX_FRAME_WIDTH: i32 = 1920;
const MAX_FRAME_HEIGHT: i32 = 1080;
const MAX_VIDEO_FPS: f64 = 60.0;

pub async fn process_video_stream<W: TimeParamWorker + Send + Sync + 'static>(
    _worker_name: &str,
    worker: W,
    _input_topic: String,
) -> Result<(), Box<dyn Error>> {
    let rtsp_url = env::var("RTSP_URL").expect("RTSP_URL not set");
    let dest_path = PathBuf::from(env::var("MEDIA_CLOUD_SYNC_DIR").expect("MEDIA_CLOUD_SYNC_DIR not set"));
    ensure_directory_exists(&dest_path).await?;

    let buffer_seconds: usize = env::var("BUFFER_SECONDS")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(DEFAULT_BUFFER_SECONDS)
        .min(MAX_BUFFER_SECONDS);
    let frame_width: i32 = env::var("FRAME_WIDTH")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(DEFAULT_FRAME_WIDTH)
        .min(MAX_FRAME_WIDTH);
    let frame_height: i32 = env::var("FRAME_HEIGHT")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(DEFAULT_FRAME_HEIGHT)
        .min(MAX_FRAME_HEIGHT);
    let video_format = env::var("VIDEO_FORMAT").unwrap_or(DEFAULT_VIDEO_FORMAT.to_string());
    let filename_format = env::var("FILENAME_FORMAT").unwrap_or(DEFAULT_FILENAME_FORMAT.to_string());
    let fps: f64 = f64::min(
        env::var("VIDEO_FPS").ok().and_then(|v| v.parse().ok()).unwrap_or(DEFAULT_VIDEO_FPS),
        MAX_VIDEO_FPS,
    );

    let max_frames = buffer_seconds * fps as usize;
    let buffer = Arc::new(Mutex::new(VideoBuffer::new(max_frames)));
    let frame_size = Size::new(frame_width, frame_height);

    info!("Configured buffer_seconds={}, frame_width={}, frame_height={}, fps={}, max_frames={}", buffer_seconds, frame_width, frame_height, fps, max_frames);

    // Periodic logging of buffer size and estimated memory usage
    let buffer_clone = buffer.clone();
    tokio::spawn(async move {
        loop {
            let buf = buffer_clone.lock().await;
            let frame_count = buf.frames.len();
            // Estimate memory: width * height * 3 (RGB) * frame_count (bytes)
            let est_mem_mb = (frame_width as usize * frame_height as usize * 3 * frame_count) as f64 / (1024.0 * 1024.0);
            debug!("VideoBuffer: {} frames, estimated memory usage: {:.2} MiB", frame_count, est_mem_mb);
            drop(buf);
            tokio::time::sleep(std::time::Duration::from_secs(30)).await;
        }
    });

    info!("Starting video capture from RTSP stream: {}", rtsp_url);
    ffmpeg_next::init().unwrap();
    capture_rtsp_stream(rtsp_url, buffer.clone(), frame_size).await;

    let client_id = format!("{}-{}-{}",
        env::var("AIO_MQTT_CLIENT_ID").unwrap_or("media-capture-service".to_string()),
        Utc::now().timestamp(),
        Uuid::new_v4().to_string().split('-').next().unwrap_or("")
    );

    // Build MQTT connection settings with custom handling for empty TLS/SAT files
    let builder = create_mqtt_connection_settings_builder()?;
    let connection_settings = builder.client_id(&client_id).build().unwrap();
    info!("MQTT connection settings successfully built from environment.");

    let session_options = SessionOptionsBuilder::default()
        .connection_settings(connection_settings)
        .build()?;
    info!("Session options successfully built.");

    let session = Session::new(session_options)?;
    let client = session.create_managed_client();

    info!("Spawning task to receive messages.");

    let topics = get_trigger_topics();

    info!("Using {} trigger topics", topics.len());

    // Spawn a task for each topic
    for topic in topics {
        let client_clone = client.clone();
        let buffer_clone = buffer.clone();
        let dest_path_clone = dest_path.clone();
        let filename_format_clone = filename_format.clone();
        let video_format_clone = video_format.clone();
        let worker_clone = worker.clone();

        info!("Subscribing to topic: {}", topic);

        tokio::spawn(async move {
            receive_messages(
                client_clone,
                topic,
                buffer_clone,
                dest_path_clone,
                filename_format_clone,
                video_format_clone,
                fps,
                frame_size,
                worker_clone,
            ).await;
        });
    }

    session.run().await?;
    Ok(())
}

async fn ensure_directory_exists(dir: &PathBuf) -> Result<(), Box<dyn std::error::Error>> {
    if !dir.exists() {
        warn!("Directory does not exist: {:?}. Attempting to create it.", dir);
        fs::create_dir_all(dir.clone()).await.map_err(|e| Box::new(e) as Box<dyn std::error::Error>)?;
    }
    Ok(())
}

/// Parse the TRIGGER_TOPICS environment variable which contains a JSON array of topics
fn get_trigger_topics() -> Vec<String> {
    match env::var("TRIGGER_TOPICS") {
        Ok(topics_json) => {
            match serde_json::from_str::<Vec<String>>(&topics_json) {
                Ok(topics) => {
                    if topics.is_empty() {
                        info!("TRIGGER_TOPICS environment variable contains an empty array. Using default topic.");
                        vec!["alerts/+".to_string(), "analytics/+".to_string()]
                    } else {
                        info!("Loaded {} trigger topics from TRIGGER_TOPICS", topics.len());
                        topics
                    }
                },
                Err(e) => {
                    error!("Failed to parse TRIGGER_TOPICS as JSON array: {}. Using default topic.", e);
                    vec!["alerts/+".to_string(), "analytics/+".to_string()]
                }
            }
        },
        Err(_) => {
            info!("TRIGGER_TOPICS environment variable not set. Using default wildcard topic.");
            vec!["alerts/+".to_string(), "analytics/+".to_string()]
        }
    }
}

#[cfg(test)]
mod tests {
    // Only unit tests for trait logic or helpers defined in this module should be here.
    // Buffer and video writing logic are tested in their respective modules.
    use super::*;
    use serde_json::json;
    use chrono::TimeZone;

    #[derive(Clone)]
    struct DummyWorker;

    impl TimeParamWorker for DummyWorker {
        fn get_time_params(&self, _payload: &serde_json::Value) -> Result<VideoSegmentParams, Box<dyn std::error::Error>> {
            Ok(VideoSegmentParams {
                time_param: TimeParams {
                    start_time: chrono::Utc.timestamp_opt(1_600_000_000, 0).unwrap(),
                    duration: 5.0,
                },
                event_id: Some(42),
                event_type: Some("test".to_string()),
            })
        }
    }

    #[tokio::test]
    async fn test_time_param_worker_trait() {
        let worker = DummyWorker;
        let payload = json!({});
        let result = worker.get_time_params(&payload);
        assert!(result.is_ok());
        let params = result.unwrap();
        assert_eq!(params.event_id, Some(42));
        assert_eq!(params.time_param.duration, 5.0);
    }
}
