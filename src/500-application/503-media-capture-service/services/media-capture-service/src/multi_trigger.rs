use chrono;
use serde_json;
use tracing::info;

use crate::video_processor::{TimeParams, VideoSegmentParams, TimeParamWorker};

const DEFAULT_CAPTURE_DURATION: f64 = 10.0;
const DEFAULT_VIDEO_FEED_DELAY_SECONDS: i64 = 5; // Default delay for timestamp adjustment
const TIMESTAMP_FORMAT: &str = "%Y-%m-%dT%H:%M:%S%.3fZ"; // ISO 8601 format with milliseconds

/// A worker that can handle different message formats based on the topic pattern
#[derive(Clone)]
pub struct MultiTriggerWorker;

impl MultiTriggerWorker {
    pub fn new() -> Self {
        Self
    }

    /// Determine which type of message we're dealing with based on the topic pattern
    fn get_message_type(&self, topic: &str) -> MessageType {
        // Normalize the topic to lowercase for robust matching
        let t = topic.to_lowercase();

        // Treat any topic containing "alert" (e.g., "alerts/trigger", ".../alert/true") as an Alert
        if t.contains("alert") && t.contains("trigger") {
            return MessageType::Alert;
        }

        // Support both "analytics_disabled" and "analytics/disabled" styles
        if t.contains("analytics_disabled") || (t.contains("analytics") && t.contains("disabled")) {
            return MessageType::AnalyticsDisabled;
        }

        // Fallback
        MessageType::Unknown
    }
}

/// The type of message based on the topic pattern
enum MessageType {
    Alert,
    AnalyticsDisabled,
    Unknown,
}

/// Helper function for Alert messages
fn calculate_alert_params(
    payload: &serde_json::Value,
) -> Result<VideoSegmentParams, Box<dyn std::error::Error>> {
    let devices = payload["attributes"]["devices"]
        .as_array()
        .ok_or("Missing or invalid devices array")?;

    // Looking for device_data with type = ALERT_DLQC
    let timestamp = devices.iter().find_map(|device| {
        device["device_data"].as_object().and_then(|device_data| {
            if device_data.get("type")?.as_str()? == "ALERT_DLQC" {
                // DCAM uses epoch milliseconds format
                let epoch_ms = device_data.get("timestamp")?.as_i64()?;
                Some(epoch_ms)
            } else {
                None
            }
        })
    }).ok_or("Missing or invalid 'timestamp' field in alert payload with type ALERT_DLQC")?;

    info!("Extracted event timestamp: {:?}", timestamp);

    // Extract event_id from the payload
    let event_id = devices.iter().find_map(|device| {
        device["device_data"].get("event_id").and_then(|v| v.as_u64())
    });

    // Get environment variables
    let capture_duration: f64 = std::env::var("CAPTURE_DURATION_SECONDS")
        .ok()
        .and_then(|val| val.parse::<f64>().ok())
        .unwrap_or(DEFAULT_CAPTURE_DURATION);

    // Get the video feed delay seconds - this is to account for delay between event detection and video frames
    let video_feed_delay_secs: i64 = std::env::var("VIDEO_FEED_DELAY_SECONDS")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(DEFAULT_VIDEO_FEED_DELAY_SECONDS);

    info!("Using video_feed_delay_seconds: {}", video_feed_delay_secs);

    // Calculate the video segment parameters
    calculate_video_segment_params(
        timestamp,
        event_id,
        Some("alert".to_string()),
        capture_duration,
        video_feed_delay_secs
    )
}

/// Helper function for AnalyticsDisabled messages
fn calculate_analytics_disabled_params(
    payload: &serde_json::Value,
) -> Result<VideoSegmentParams, Box<dyn std::error::Error>> {
    // Extract the timestamp - using same approach as original analytics_disabled_trigger.rs
    let timestamp = payload["timestamp"]
        .as_i64()
        .ok_or("Missing or invalid 'timestamp' field in Analytics_Disabled payload")?;

    info!("Extracted Analytics_Disabled event timestamp: {:?}", timestamp);

    // Extract analytics_type - try both fields, like the original implementation
    let analytics_type = payload["analytics_type"]
        .as_str()
        .unwrap_or_else(|| payload["analyticsType"]
            .as_str()
            .unwrap_or_else(|| payload["type"]
                .as_str()
                .unwrap_or("unknown")));

    // Get environment variables for duration and video feed delay - use the correct env var name
    let capture_duration = std::env::var("CAPTURE_DURATION_SECONDS")
        .ok()
        .and_then(|v| v.parse::<f64>().ok())
        .unwrap_or(DEFAULT_CAPTURE_DURATION);

    let video_feed_delay_secs = std::env::var("VIDEO_FEED_DELAY_SECONDS")
        .ok()
        .and_then(|v| v.parse::<i64>().ok())
        .unwrap_or(DEFAULT_VIDEO_FEED_DELAY_SECONDS);

    info!("Using video_feed_delay_seconds: {}", video_feed_delay_secs);

    // For Analytics_Disabled events, we can use the timestamp as a unique identifier
    let event_id = Some(timestamp as u64);

    let service_type = analytics_type
        .to_string()
        .replace(" ", "_")
        .to_lowercase();

    let event_type = Some(format!("analytics_disabled_{}", service_type));

    calculate_video_segment_params(
        timestamp,
        event_id,
        event_type,
        capture_duration,
        video_feed_delay_secs
    )
}

/// Helper function for unknown message formats - uses a best-effort approach
fn calculate_unknown_params(
    payload: &serde_json::Value,
) -> Result<VideoSegmentParams, Box<dyn std::error::Error>> {
    // Try to find a timestamp field at various locations
    let timestamp = if let Some(timestamp_str) = payload["timestamp"].as_str() {
        chrono::DateTime::parse_from_str(timestamp_str, TIMESTAMP_FORMAT)
            .map(|dt| dt.timestamp_millis())
            .or_else(|_| {
                chrono::DateTime::parse_from_str(timestamp_str, "%Y-%m-%dT%H:%M:%SZ")
                    .map(|dt| dt.timestamp_millis())
            })
            .unwrap_or_else(|_| chrono::Utc::now().timestamp_millis())
    } else if let Some(timestamp_val) = payload["timestamp"].as_i64() {
        timestamp_val
    } else {
        // Default to current time if no timestamp found
        chrono::Utc::now().timestamp_millis()
    };

    // Get environment variables for duration and video feed delay
    let capture_duration = std::env::var("CAPTURE_DURATION")
        .ok()
        .and_then(|v| v.parse::<f64>().ok())
        .unwrap_or(DEFAULT_CAPTURE_DURATION);

    let video_feed_delay_secs = std::env::var("VIDEO_FEED_DELAY_SECONDS")
        .ok()
        .and_then(|v| v.parse::<i64>().ok())
        .unwrap_or(DEFAULT_VIDEO_FEED_DELAY_SECONDS);

    calculate_video_segment_params(
        timestamp,
        Some(timestamp as u64),
        Some("unknown".to_string()),
        capture_duration,
        video_feed_delay_secs
    )
}

/// Helper function that calculates video segment parameters based on event timestamp
fn calculate_video_segment_params(
    timestamp: i64,
    event_id: Option<u64>,
    event_type: Option<String>,
    capture_duration: f64,
    video_feed_delay_secs: i64
) -> Result<VideoSegmentParams, Box<dyn std::error::Error>> {
    // Calculate total capture duration including the delay compensation
    // For example, with 10s capture_duration and 5s delay:
    // Total duration becomes 15s (5s for delay + 10s for capture around the event)
    let total_duration = capture_duration + (video_feed_delay_secs as f64);

    // Calculate start time: We want to go back (delay + half_duration) before the event timestamp
    let half_normal_duration_ms = ((capture_duration / 2.0) * 1000.0) as i64;
    let delay_ms = video_feed_delay_secs * 1000;

    // Start time: Go back by (delay + half_duration) before the timestamp
    let start_time = timestamp - delay_ms - half_normal_duration_ms;

    info!("Original timestamp: {}", timestamp);
    info!("Delay compensation: {}ms, Half duration: {}ms", delay_ms, half_normal_duration_ms);
    info!("Calculated start time: {} (total lookback: {}ms)",
          start_time, delay_ms + half_normal_duration_ms);

    let datetime_start_time = chrono::DateTime::<chrono::Utc>::from_timestamp_millis(start_time)
        .ok_or_else(|| "Failed to convert start_time to datetime")?;

    // Create the TimeParam struct with the total duration (delay + capture_duration)
    let time_param = TimeParams {
        start_time: datetime_start_time,
        duration: total_duration,
    };

    // This will result in capturing:
    // 1. Video from (timestamp - delay - half_capture_duration) to (timestamp + half_capture_duration)
    // 2. For typical values (5s delay, 10s normal duration):
    //    - Start: (timestamp - 5s - 5s) = 10s before the event timestamp
    //    - End: (timestamp + 5s) = 5s after the event timestamp
    //    - Total duration: 15s (5s for delay + 5s before event + 5s after event)

    Ok(VideoSegmentParams { time_param, event_id, event_type })
}

impl TimeParamWorker for MultiTriggerWorker {
    fn get_time_params(&self, payload: &serde_json::Value) -> Result<VideoSegmentParams, Box<dyn std::error::Error>> {
        // Extract the topic from the payload (which was inserted by mqtt_handler.rs)
        let topic = payload["__mqtt_topic"].as_str().unwrap_or("");

        let message_type = self.get_message_type(topic);

        // Log which message type we detected
        info!("Processing message with detected type: {:?} for topic: {}",
               std::mem::discriminant(&message_type),
               topic);

        // Delegate to the appropriate handler based on message type
        match message_type {
            MessageType::Alert => calculate_alert_params(payload),
            MessageType::AnalyticsDisabled => calculate_analytics_disabled_params(payload),
            MessageType::Unknown => calculate_unknown_params(payload),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    use std::env;

    #[test]
    fn test_message_type_detection() {
        let worker = MultiTriggerWorker::new();

        assert!(matches!(worker.get_message_type("some/topic/alert/true"), MessageType::Alert));
        assert!(matches!(worker.get_message_type("some/topic/analytics_disabled"), MessageType::AnalyticsDisabled));
        assert!(matches!(worker.get_message_type("some/other/topic"), MessageType::Unknown));
    }

    #[test]
    fn test_calculate_alert_params() {
        // Set up environment variables
        env::set_var("CAPTURE_DURATION_SECONDS", "10.0");
        env::set_var("VIDEO_FEED_DELAY_SECONDS", "5");

        // Create a mock payload for ALERT_DLQC
        let payload = json!({
            "attributes": {
                "devices": [
                    {
                        "device_data": {
                            "type": "ALERT_DLQC",
                            "timestamp": 1727214960000i64,
                            "event_id": 12345
                        }
                    }
                ]
            }
        });

        // Call the calculate_alert_params function
        let result = calculate_alert_params(&payload);
        assert!(result.is_ok());

        let params = result.unwrap();

        // Verify event_id is extracted correctly
        assert_eq!(params.event_id, Some(12345));

        // Verify event_type
        assert_eq!(params.event_type, Some("alert".to_string()));

        // Verify duration is now the total duration (capture_duration + delay)
        assert_eq!(params.time_param.duration, 15.0);

        // Expected timestamp calculation:
        // 1. Original timestamp: 1727214960000
        // 2. Start time calculation: timestamp - delay_ms - half_duration_ms
        //    = 1727214960000 - (5 * 1000) - (5 * 1000) = 1727214950000
        // 3. This gives us 10s before the original timestamp, which means:
        //    - 5s to account for the delay
        //    - 5s before the actual event
        //    - And we'll capture for 15s total (including 5s after the event)
        let expected_start_time = chrono::DateTime::<chrono::Utc>::from_timestamp_millis(1727214950000)
            .expect("Invalid timestamp");

        assert_eq!(params.time_param.start_time, expected_start_time);
    }

    #[test]
    fn test_missing_devices_array() {
        let payload = json!({
            "attributes": {}
        });

        let result = calculate_alert_params(&payload);
        assert!(result.is_err());
        assert_eq!(
            result.unwrap_err().to_string(),
            "Missing or invalid devices array"
        );
    }

    #[test]
    fn test_missing_timestamp_in_alert() {
        let payload = json!({
            "attributes": {
                "devices": [
                    {
                        "device_data": {
                            "type": "ALERT_DLQC"
                        }
                    }
                ]
            }
        });

        let result = calculate_alert_params(&payload);
        assert!(result.is_err());
        assert_eq!(
            result.unwrap_err().to_string(),
            "Missing or invalid 'timestamp' field in alert payload with type ALERT_DLQC"
        );
    }

    #[test]
    fn test_calculate_analytics_disabled_params() {
        // Set up environment variables
        env::set_var("CAPTURE_DURATION_SECONDS", "10.0");
        env::set_var("VIDEO_FEED_DELAY_SECONDS", "5");

        // Create a mock payload for analytics_disabled
        let payload = json!({
            "timestamp": 1727214960000i64,
            "analytics_type": "motion_detection"
        });

        // Call the calculate_analytics_disabled_params function
        let result = calculate_analytics_disabled_params(&payload);
        assert!(result.is_ok());

        let params = result.unwrap();

        // Verify event_id is created from timestamp
        assert_eq!(params.event_id, Some(1727214960000));

        // Verify event_type contains analytics type
        assert_eq!(params.event_type, Some("analytics_disabled_motion_detection".to_string()));

        // Verify duration is now the total duration (capture_duration + delay)
        assert_eq!(params.time_param.duration, 15.0);

        // Expected timestamp calculation:
        // 1. Original timestamp: 1727214960000
        // 2. Start time calculation: timestamp - delay_ms - half_duration_ms
        //    = 1727214960000 - (5 * 1000) - (5 * 1000) = 1727214950000
        // 3. This gives us 10s before the original timestamp, which means:
        //    - 5s to account for the delay
        //    - 5s before the actual event
        //    - And we'll capture for 15s total (including 5s after the event)
        let expected_start_time = chrono::DateTime::<chrono::Utc>::from_timestamp_millis(1727214950000)
            .expect("Invalid timestamp");

        assert_eq!(params.time_param.start_time, expected_start_time);
    }

    #[test]
    fn test_missing_timestamp_in_analytics_disabled() {
        let payload = json!({
            "analytics_type": "smart_man_on_site"
        });

        let result = calculate_analytics_disabled_params(&payload);
        assert!(result.is_err());
        assert_eq!(
            result.unwrap_err().to_string(),
            "Missing or invalid 'timestamp' field in Analytics_Disabled payload"
        );
    }

    #[test]
    fn test_calculate_unknown_params() {
        // Set up environment variables
        env::set_var("CAPTURE_DURATION", "10.0");
        env::set_var("VIDEO_FEED_DELAY_SECONDS", "5");

        // Create a mock payload with a string timestamp
        let payload = json!({
            "timestamp": "2025-07-16T10:15:30.123Z"
        });

        // Call the calculate_unknown_params function
        let result = calculate_unknown_params(&payload);
        assert!(result.is_ok());

        let params = result.unwrap();

        // Verify event_type
        assert_eq!(params.event_type, Some("unknown".to_string()));

        // Verify duration is now the total duration (capture_duration + delay)
        assert_eq!(params.time_param.duration, 15.0);
    }

    #[test]
    fn test_end_to_end_worker_flow() {
        // Set up environment variables
        env::set_var("CAPTURE_DURATION_SECONDS", "10.0");
        env::set_var("VIDEO_FEED_DELAY_SECONDS", "5");

        // Create mock payloads with topic
        let alert_payload = json!({
            "__mqtt_topic": "some/topic/alert/true",
            "attributes": {
                "devices": [
                    {
                        "device_data": {
                            "type": "ALERT_DLQC",
                            "timestamp": 1727214960000i64,
                            "event_id": 12345
                        }
                    }
                ]
            }
        });

        let analytics_disabled_payload = json!({
            "__mqtt_topic": "some/topic/analytics_disabled",
            "timestamp": 1727214960000i64,
            "analytics_type": "smart_man"
        });

        let worker = MultiTriggerWorker::new();

        // Test alert flow
        let alert_result = worker.get_time_params(&alert_payload);
        assert!(alert_result.is_ok());
        let alert_params = alert_result.unwrap();
        assert_eq!(alert_params.event_type, Some("alert".to_string()));

        // Test analytics disabled flow
        let analytics_result = worker.get_time_params(&analytics_disabled_payload);
        assert!(analytics_result.is_ok());
        let analytics_params = analytics_result.unwrap();
        assert_eq!(analytics_params.event_type.unwrap().contains("analytics_disabled"), true);
    }
}
