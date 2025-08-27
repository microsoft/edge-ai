use azure_iot_operations_mqtt::control_packet::QoS;
use azure_iot_operations_mqtt::interface::{ManagedClient, MqttPubSub, PubReceiver};
use azure_iot_operations_mqtt::session::SessionManagedClient;
use chrono::{Duration, Local};
use opencv::core::Size;
use serde_json;
use std::{path::PathBuf, sync::Arc};
use tokio::sync::Mutex;
use tracing::{error, info, warn};

use crate::video_processor::TimeParamWorker;
use crate::video_ring_buffer::VideoBuffer;
use crate::video_writer::write_buffered_video;

pub async fn receive_messages<W: TimeParamWorker + Send + Sync + 'static>(
    client: SessionManagedClient,
    input_topic: String,
    buffer: Arc<Mutex<VideoBuffer>>,
    dest_path: PathBuf,
    filename_format: String,
    video_format: String,
    fps: f64,
    frame_size: Size,
    worker: W,
) {
    info!("Destination path: {:?}", dest_path);
    let mut receiver = match client.create_filtered_pub_receiver(&input_topic) {
        Ok(receiver) => receiver,
        Err(e) => {
            error!("Failed to create filtered pub receiver for topic {}: {:?}", input_topic, e);
            return;
        }
    };

    info!("Subscribing to topic: {}", input_topic);
    if let Err(e) = client.subscribe(input_topic.clone(), QoS::AtLeastOnce).await {
        error!("Failed to subscribe to topic {}: {:?}", input_topic, e);
        return;
    }
    info!("Successfully subscribed to topic: {}", input_topic);

    while let Some(msg) = receiver.recv().await {
        info!("Message received on topic {}: {:?}", input_topic, msg.payload);

        let payload: serde_json::Value = match serde_json::from_slice(&msg.payload) {
            Ok(val) => val,
            Err(e) => {
                error!("Failed to parse MQTT payload: {:?}", e);
                continue;
            }
        };
        
        // Create a new JSON value with the topic included
        let mut payload_with_topic = payload.clone();
        if let serde_json::Value::Object(ref mut map) = payload_with_topic {
            map.insert("__mqtt_topic".to_string(), serde_json::Value::String(input_topic.clone()));
        }
        
        // Process the message with the enhanced payload
        process_message(&payload_with_topic, worker.clone(), buffer.clone(), dest_path.clone(), 
            &filename_format, &video_format, fps, frame_size).await;
    }
}

// Helper function to process a message with a worker
async fn process_message<W: TimeParamWorker + Send + Sync + 'static>(
    payload: &serde_json::Value,
    worker: W,
    buffer: Arc<Mutex<VideoBuffer>>,
    dest_path: PathBuf,
    filename_format: &str,
    video_format: &str,
    fps: f64,
    frame_size: Size,
) {
    let params_with_id = match worker.get_time_params(payload) {
        Ok(tp) => tp,
        Err(e) => {
            error!("Failed to extract time parameters from payload: {:?}", e);
            return;
        }
    };
    
    let time_param = params_with_id.time_param;
    let event_id = params_with_id.event_id.clone();
    let event_type = params_with_id.event_type.clone();
    let event_id_str = event_id.map(|id| id.to_string()).unwrap_or_else(|| "unknown".to_string());

    let start_range = time_param.start_time.with_timezone(&Local);
    let duration = Duration::seconds(time_param.duration as i64);
    let end_range = start_range + duration;

    info!(
        "event_id={}, Writing buffered video from {} to {} (total duration: {} seconds)",
        event_id_str,
        start_range.format("%Y-%m-%d %H:%M:%S"),
        end_range.format("%Y-%m-%d %H:%M:%S"),
        time_param.duration,
    );

    let wait_seconds = (end_range - start_range).num_seconds().max(0) as usize;

    let result = write_buffered_video(
        buffer,
        dest_path,
        filename_format,
        video_format,
        fps,
        frame_size,
        Some(start_range),
        wait_seconds,
        event_id.clone(),
        event_type.as_deref(),
    )
    .await;

    match result {
        Err(e) => {
            error!("event_id={}, Failed to write buffered video: {:?}", event_id_str, e);
        }
        Ok(false) => {
            warn!("event_id={}, No frames were written for the requested range. No video file created.", event_id_str);
        }
        Ok(true) => {
            info!("event_id={}, Buffered video segment written successfully.", event_id_str);
        }
    }
}