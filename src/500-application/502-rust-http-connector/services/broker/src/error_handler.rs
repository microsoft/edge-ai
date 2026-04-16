use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

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

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::Value;

    #[test]
    fn new_populates_fields() {
        let alert = ErrorAlert::new(
            "device-1".to_string(),
            "ERR001".to_string(),
            "something broke".to_string(),
        );
        assert_eq!(alert.device_id, "device-1");
        assert_eq!(alert.error_code, "ERR001");
        assert_eq!(alert.error_message, "something broke");
    }

    #[test]
    fn generate_alert_produces_valid_json_with_camel_case_keys() {
        let json_str =
            ErrorAlert::generate_alert("dev-2".to_string(), "004".to_string(), "bad".to_string());
        let v: Value = serde_json::from_str(&json_str).expect("valid JSON");
        assert_eq!(v["deviceId"], "dev-2");
        assert_eq!(v["errorCode"], "004");
        assert_eq!(v["errorMessage"], "bad");
        assert!(v["readingTime"].is_string());
    }

    #[test]
    fn reading_time_is_iso8601() {
        let json_str = ErrorAlert::generate_alert(
            "d".to_string(),
            "c".to_string(),
            "m".to_string(),
        );
        let v: Value = serde_json::from_str(&json_str).unwrap();
        let ts = v["readingTime"].as_str().unwrap();
        ts.parse::<DateTime<Utc>>().expect("valid ISO 8601 timestamp");
    }

    #[test]
    fn roundtrip_deserialize() {
        let json_str = ErrorAlert::generate_alert(
            "dev-3".to_string(),
            "005".to_string(),
            "msg".to_string(),
        );
        let alert: ErrorAlert = serde_json::from_str(&json_str).expect("deserializes");
        assert_eq!(alert.device_id, "dev-3");
        assert_eq!(alert.error_code, "005");
        assert_eq!(alert.error_message, "msg");
    }
}
