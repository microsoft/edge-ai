//! WASM map operator that writes JSON messages to the AIO Distributed State Store.
//!
//! Extracts a key from a configurable JSON Pointer path within the message,
//! writes the full message payload to the state store under that key with a
//! configurable TTL, and passes the original message through unchanged.
//!
//! Configuration (via `ModuleConfiguration.properties`):
//! - `keyPath`    (required): JSON Pointer (RFC 6901) to the key field; e.g. `/id`, `/data/record_id`
//! - `ttlSeconds` (required): TTL in seconds; `0` = no expiration
//! - `keyPrefix`  (optional): Prefix prepended to the extracted key; default empty
//! - `onMissing`  (optional): `skip` (default) or `error` — behavior when keyPath not found

use std::sync::OnceLock;

use wasm_graph_sdk::logger::{self, Level};
use wasm_graph_sdk::macros::map_operator;
use wasm_graph_sdk::state_store;

const MODULE_NAME: &str = "msg-to-dss-key";

struct OperatorConfig {
    key_path: String,
    key_prefix: String,
    ttl_seconds: u64,
    error_on_missing: bool,
}

static CONFIG: OnceLock<OperatorConfig> = OnceLock::new();

/// Converts a JSON scalar value to a string suitable for use as a state store key.
/// Returns `None` for null, objects, and arrays — these are not valid key components.
fn value_to_key_string(value: &serde_json::Value) -> Option<String> {
    match value {
        serde_json::Value::String(s) => Some(s.clone()),
        serde_json::Value::Number(n) => Some(n.to_string()),
        serde_json::Value::Bool(b) => Some(b.to_string()),
        _ => None,
    }
}

fn msg_to_dss_key_init(configuration: ModuleConfiguration) -> bool {
    logger::log(Level::Info, MODULE_NAME, "Initializing operator");

    for (key, _) in &configuration.properties {
        logger::log(
            Level::Info,
            MODULE_NAME,
            &format!("Configuration property received: {}", key),
        );
    }

    // keyPath — REQUIRED, must be empty string or start with '/'
    let key_path = match configuration
        .properties
        .iter()
        .find(|(k, _)| k == "keyPath")
        .map(|(_, v)| v.clone())
    {
        Some(path) if !path.is_empty() && path.starts_with('/') => path,
        Some(other) => {
            logger::log(
                Level::Error,
                MODULE_NAME,
                &format!(
                    "Invalid keyPath '{}': must start with '/'. \
                     Use RFC 6901 JSON Pointer syntax, e.g. /id, /data/record_id, /items/0/id",
                    other
                ),
            );
            return false;
        }
        None => {
            logger::log(
                Level::Error,
                MODULE_NAME,
                "Missing required configuration: 'keyPath'. \
                 Provide a JSON Pointer path, e.g. /id or /data/record_id",
            );
            return false;
        }
    };

    // ttlSeconds — REQUIRED, must be parseable as u64
    let ttl_seconds = match configuration
        .properties
        .iter()
        .find(|(k, _)| k == "ttlSeconds")
        .map(|(_, v)| v.clone())
    {
        Some(val) => match val.parse::<u64>() {
            Ok(n) => n,
            Err(_) => {
                logger::log(
                    Level::Error,
                    MODULE_NAME,
                    &format!(
                        "Invalid ttlSeconds '{}': must be a non-negative integer. \
                         Use 0 for no expiration, or e.g. 3600 for one hour.",
                        val
                    ),
                );
                return false;
            }
        },
        None => {
            logger::log(
                Level::Error,
                MODULE_NAME,
                "Missing required configuration: 'ttlSeconds'. \
                 Provide the TTL in seconds (0 = no expiration).",
            );
            return false;
        }
    };

    // keyPrefix — OPTIONAL (default: empty string)
    let key_prefix = configuration
        .properties
        .iter()
        .find(|(k, _)| k == "keyPrefix")
        .map(|(_, v)| v.clone())
        .unwrap_or_default();

    // onMissing — OPTIONAL (default: "skip")
    let on_missing = configuration
        .properties
        .iter()
        .find(|(k, _)| k == "onMissing")
        .map(|(_, v)| v.clone())
        .unwrap_or_else(|| "skip".to_string());

    let error_on_missing = match on_missing.as_str() {
        "skip" => false,
        "error" => true,
        other => {
            logger::log(
                Level::Error,
                MODULE_NAME,
                &format!(
                    "Invalid onMissing value '{}': must be 'skip' or 'error'.",
                    other
                ),
            );
            return false;
        }
    };

    logger::log(
        Level::Info,
        MODULE_NAME,
        &format!(
            "Initialized: keyPath='{}', keyPrefix='{}', ttlSeconds={}, onMissing='{}'",
            key_path,
            key_prefix,
            ttl_seconds,
            if error_on_missing { "error" } else { "skip" }
        ),
    );

    let _ = CONFIG.set(OperatorConfig {
        key_path,
        key_prefix,
        ttl_seconds,
        error_on_missing,
    });

    true
}

#[map_operator(init = "msg_to_dss_key_init")]
fn msg_to_dss_key(input: DataModel) -> Result<DataModel, Error> {
    let config = CONFIG.get().ok_or_else(|| Error {
        message: "Operator not initialized".to_string(),
    })?;

    let DataModel::Message(ref message) = input else {
        return Ok(input);
    };

    let payload = match &message.payload {
        BufferOrBytes::Buffer(buffer) => buffer.read(),
        BufferOrBytes::Bytes(bytes) => bytes.clone(),
    };

    let json_str = match std::str::from_utf8(&payload) {
        Ok(s) => s,
        Err(_) => {
            logger::log(
                Level::Warn,
                MODULE_NAME,
                "Payload is not valid UTF-8 — skipping state store write, passing through",
            );
            return Ok(input);
        }
    };

    let parsed: serde_json::Value = match serde_json::from_str(json_str) {
        Ok(v) => v,
        Err(e) => {
            logger::log(
                Level::Warn,
                MODULE_NAME,
                &format!(
                    "Payload is not valid JSON ({}). Skipping state store write, passing through.",
                    e
                ),
            );
            return Ok(input);
        }
    };

    let key_value = match parsed.pointer(&config.key_path) {
        Some(value) => match value_to_key_string(value) {
            Some(s) => s,
            None => {
                let msg = format!(
                    "Value at keyPath '{}' is not a scalar (string/number/bool) — cannot use as key",
                    config.key_path
                );
                if config.error_on_missing {
                    return Err(Error { message: msg });
                }
                logger::log(Level::Warn, MODULE_NAME, &msg);
                return Ok(input);
            }
        },
        None => {
            let msg = format!(
                "keyPath '{}' not found in message",
                config.key_path
            );
            if config.error_on_missing {
                return Err(Error { message: msg });
            }
            logger::log(Level::Warn, MODULE_NAME, &msg);
            return Ok(input);
        }
    };

    let store_key = format!("{}{}", config.key_prefix, key_value);

    let options = state_store::SetOptions {
        conditions: state_store::SetConditions::Unconditional,
        expires: if config.ttl_seconds > 0 {
            Some(state_store::Duration {
                seconds: config.ttl_seconds,
                nanos: 0,
            })
        } else {
            None
        },
    };

    if let Err(e) = state_store::set(store_key.as_bytes(), &payload, None, None, options) {
        logger::log(
            Level::Error,
            MODULE_NAME,
            &format!(
                "State store write failed for key '{}': {:?} — passing through",
                store_key, e
            ),
        );
    }

    Ok(input)
}

#[cfg(test)]
mod tests {
    use super::*;

    // ─── value_to_key_string ────────────────────────────────────────────────

    #[test]
    fn test_value_to_key_string_string() {
        let v = serde_json::json!("abc123");
        assert_eq!(value_to_key_string(&v), Some("abc123".to_string()));
    }

    #[test]
    fn test_value_to_key_string_integer() {
        let v = serde_json::json!(42);
        assert_eq!(value_to_key_string(&v), Some("42".to_string()));
    }

    #[test]
    fn test_value_to_key_string_float() {
        let v = serde_json::json!(3.14);
        assert_eq!(value_to_key_string(&v), Some("3.14".to_string()));
    }

    #[test]
    fn test_value_to_key_string_bool_true() {
        let v = serde_json::json!(true);
        assert_eq!(value_to_key_string(&v), Some("true".to_string()));
    }

    #[test]
    fn test_value_to_key_string_bool_false() {
        let v = serde_json::json!(false);
        assert_eq!(value_to_key_string(&v), Some("false".to_string()));
    }

    #[test]
    fn test_value_to_key_string_null() {
        let v = serde_json::json!(null);
        assert_eq!(value_to_key_string(&v), None);
    }

    #[test]
    fn test_value_to_key_string_object() {
        let v = serde_json::json!({"a": 1});
        assert_eq!(value_to_key_string(&v), None);
    }

    #[test]
    fn test_value_to_key_string_array() {
        let v = serde_json::json!([1, 2, 3]);
        assert_eq!(value_to_key_string(&v), None);
    }

    // ─── JSON Pointer extraction ─────────────────────────────────────────────

    #[test]
    fn test_pointer_top_level_string() {
        let data = serde_json::json!({"id": "R-001"});
        let result = data.pointer("/id").and_then(value_to_key_string);
        assert_eq!(result, Some("R-001".to_string()));
    }

    #[test]
    fn test_pointer_top_level_number() {
        let data = serde_json::json!({"count": 42});
        let result = data.pointer("/count").and_then(value_to_key_string);
        assert_eq!(result, Some("42".to_string()));
    }

    #[test]
    fn test_pointer_nested_two_levels() {
        let data = serde_json::json!({"data": {"id": "nested-id"}});
        let result = data.pointer("/data/id").and_then(value_to_key_string);
        assert_eq!(result, Some("nested-id".to_string()));
    }

    #[test]
    fn test_pointer_array_first_element() {
        let data = serde_json::json!({"items": [{"id": "first"}, {"id": "second"}]});
        let result = data.pointer("/items/0/id").and_then(value_to_key_string);
        assert_eq!(result, Some("first".to_string()));
    }

    #[test]
    fn test_pointer_array_second_element() {
        let data = serde_json::json!({"items": [{"id": "first"}, {"id": "second"}]});
        let result = data.pointer("/items/1/id").and_then(value_to_key_string);
        assert_eq!(result, Some("second".to_string()));
    }

    #[test]
    fn test_pointer_deep_nested() {
        let data = serde_json::json!({"a": {"b": {"c": {"id": "deep"}}}});
        let result = data.pointer("/a/b/c/id").and_then(value_to_key_string);
        assert_eq!(result, Some("deep".to_string()));
    }

    #[test]
    fn test_pointer_missing_field() {
        let data = serde_json::json!({"name": "test"});
        let result = data.pointer("/nonexistent").and_then(value_to_key_string);
        assert_eq!(result, None);
    }

    #[test]
    fn test_pointer_partial_path_returns_none() {
        let data = serde_json::json!({"data": {"name": "test"}});
        let result = data.pointer("/data/id").and_then(value_to_key_string);
        assert_eq!(result, None);
    }

    #[test]
    fn test_pointer_array_out_of_bounds() {
        let data = serde_json::json!({"items": [{"id": "only"}]});
        let result = data.pointer("/items/5/id").and_then(value_to_key_string);
        assert_eq!(result, None);
    }

    #[test]
    fn test_pointer_object_at_path_returns_none() {
        let data = serde_json::json!({"meta": {"nested": {"object": true}}});
        let result = data.pointer("/meta/nested").and_then(value_to_key_string);
        assert_eq!(result, None);
    }

    // ─── Key construction ────────────────────────────────────────────────────

    #[test]
    fn test_key_construction_with_prefix() {
        let key = format!("{}{}", "device:", "001");
        assert_eq!(key, "device:001");
    }

    #[test]
    fn test_key_construction_no_prefix() {
        let key = format!("{}{}", "", "R-001");
        assert_eq!(key, "R-001");
    }

    #[test]
    fn test_key_construction_numeric_value() {
        let data = serde_json::json!({"sensor_id": 42});
        let extracted = data.pointer("/sensor_id").and_then(value_to_key_string).unwrap();
        let key = format!("{}{}", "sensor:", extracted);
        assert_eq!(key, "sensor:42");
    }

    #[test]
    fn test_key_construction_bool_value() {
        let data = serde_json::json!({"active": true});
        let extracted = data.pointer("/active").and_then(value_to_key_string).unwrap();
        let key = format!("{}{}", "status:", extracted);
        assert_eq!(key, "status:true");
    }
}
