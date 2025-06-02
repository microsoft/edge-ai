use serde::{Serialize, Deserialize};
use chrono::{DateTime, Utc};

#[derive(Debug, Serialize, Deserialize)]
pub struct ErrorAlert {
    #[serde(rename = "deviceId")]
    device_id: String,
    #[serde(rename = "readingTime")]
    reading_time: DateTime<Utc>,
    #[serde(rename = "errorCode")]
    error_code: String,
    #[serde(rename = "errorMessage")]
    error_message: String,
}

impl ErrorAlert {
    pub fn new(device_id: String, error_code: String, error_message: String) -> Self {
        Self {
            device_id,
            reading_time: Utc::now(),
            error_code,
            error_message,
        }
    }

    pub fn generate_alert(device_id: String, error_code: String, error_message: String) -> String {
        let error_alert = ErrorAlert::new(device_id, error_code, error_message);
        serde_json::to_string(&error_alert).unwrap()
    }
}
