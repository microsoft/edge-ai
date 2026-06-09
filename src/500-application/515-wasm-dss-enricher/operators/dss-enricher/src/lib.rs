//! WASM map operator that enriches messages with data from the AIO Distributed State Store.
//!
//! Extracts a lookup key from a configurable JSON Pointer path in the incoming message,
//! reads the corresponding record from the DSS, and merges selected fields into the
//! outgoing message.
//!
//! Configuration (via `ModuleConfiguration.properties`):
//! - `keyPath`    (required): JSON Pointer (RFC 6901) to the key field
//! - `keyPrefix`  (optional): Prefix prepended to the extracted key; default empty
//! - `outputPath` (optional): Path where enriched data is injected; empty = root merge
//! - `fields`     (optional): Comma-separated fields to extract; `*` = all; default `*`
//! - `onMissing`  (optional): `skip` (default), `error`, or `default`
//! - `onError`    (optional): `skip` (default) or `error`

use std::sync::OnceLock;

use wasm_graph_sdk::logger::{self, Level};
use wasm_graph_sdk::macros::map_operator;
use wasm_graph_sdk::state_store;

const MODULE_NAME: &str = "dss-enricher";

#[derive(Debug, Clone, PartialEq)]
enum OnMissing {
    Skip,
    Error,
    Default,
}

#[derive(Debug, Clone, PartialEq)]
enum OnError {
    Skip,
    Error,
}

#[derive(Debug)]
enum FieldSelection {
    All,
    Named(Vec<String>),
}

#[derive(Debug)]
struct OperatorConfig {
    key_path: String,
    key_prefix: String,
    output_path: Option<String>,
    fields: FieldSelection,
    on_missing: OnMissing,
    on_error: OnError,
}

static CONFIG: OnceLock<OperatorConfig> = OnceLock::new();

/// Converts a JSON scalar value to a string suitable for use as a state store key.
/// Returns `None` for null, objects, and arrays.
fn value_to_key_string(value: &serde_json::Value) -> Option<String> {
    match value {
        serde_json::Value::String(s) => Some(s.clone()),
        serde_json::Value::Number(n) => Some(n.to_string()),
        serde_json::Value::Bool(b) => Some(b.to_string()),
        _ => None,
    }
}

/// Extracts selected fields from a stored JSON object based on field configuration.
fn extract_fields(
    stored: &serde_json::Value,
    fields: &FieldSelection,
) -> serde_json::Value {
    match fields {
        FieldSelection::All => stored.clone(),
        FieldSelection::Named(names) => {
            let mut result = serde_json::Map::new();
            if let Some(obj) = stored.as_object() {
                for name in names {
                    if let Some(value) = obj.get(name) {
                        result.insert(name.clone(), value.clone());
                    }
                }
            }
            serde_json::Value::Object(result)
        }
    }
}

/// Merges enrichment data into the message at the configured output path.
fn merge_into_message(
    message: &mut serde_json::Value,
    enrichment: serde_json::Value,
    output_path: &Option<String>,
) {
    match output_path {
        Some(path) => {
            // Inject under the specified path
            if let Some(obj) = message.as_object_mut() {
                obj.insert(path.clone(), enrichment);
            }
        }
        None => {
            // Merge at root level — stored fields are added alongside source fields
            if let (Some(msg_obj), Some(enrich_obj)) =
                (message.as_object_mut(), enrichment.as_object())
            {
                for (k, v) in enrich_obj {
                    // Source fields take precedence — do not overwrite
                    if !msg_obj.contains_key(k) {
                        msg_obj.insert(k.clone(), v.clone());
                    }
                }
            }
        }
    }
}

/// Parses and validates operator configuration from key-value properties.
fn parse_config(properties: &[(String, String)]) -> Result<OperatorConfig, String> {
    // keyPath — REQUIRED
    let key_path = match properties
        .iter()
        .find(|(k, _)| k == "keyPath")
        .map(|(_, v)| v.clone())
    {
        Some(path) if !path.is_empty() && path.starts_with('/') => path,
        Some(other) => {
            return Err(format!(
                "Invalid keyPath '{}': must start with '/'. \
                 Use RFC 6901 JSON Pointer syntax, e.g. /id, /data/entityId",
                other
            ));
        }
        None => {
            return Err(
                "Missing required configuration: 'keyPath'. \
                 Provide a JSON Pointer path to the lookup key field."
                    .to_string(),
            );
        }
    };

    // keyPrefix — OPTIONAL
    let key_prefix = properties
        .iter()
        .find(|(k, _)| k == "keyPrefix")
        .map(|(_, v)| v.clone())
        .unwrap_or_default();

    // outputPath — OPTIONAL
    let output_path = properties
        .iter()
        .find(|(k, _)| k == "outputPath")
        .map(|(_, v)| v.clone())
        .filter(|v| !v.is_empty());

    // fields — OPTIONAL (default: *)
    let fields = match properties
        .iter()
        .find(|(k, _)| k == "fields")
        .map(|(_, v)| v.clone())
    {
        Some(f) if f == "*" || f.is_empty() => FieldSelection::All,
        Some(f) => {
            let names: Vec<String> = f.split(',').map(|s| s.trim().to_string()).collect();
            if names.iter().any(|n| n.is_empty()) {
                return Err(format!(
                    "Invalid fields '{}': contains empty field name after splitting on comma",
                    f
                ));
            }
            FieldSelection::Named(names)
        }
        None => FieldSelection::All,
    };

    // onMissing — OPTIONAL (default: skip)
    let on_missing = match properties
        .iter()
        .find(|(k, _)| k == "onMissing")
        .map(|(_, v)| v.clone())
        .unwrap_or_else(|| "skip".to_string())
        .as_str()
    {
        "skip" => OnMissing::Skip,
        "error" => OnMissing::Error,
        "default" => OnMissing::Default,
        other => {
            return Err(format!(
                "Invalid onMissing value '{}': must be 'skip', 'error', or 'default'.",
                other
            ));
        }
    };

    // onError — OPTIONAL (default: skip)
    let on_error = match properties
        .iter()
        .find(|(k, _)| k == "onError")
        .map(|(_, v)| v.clone())
        .unwrap_or_else(|| "skip".to_string())
        .as_str()
    {
        "skip" => OnError::Skip,
        "error" => OnError::Error,
        other => {
            return Err(format!(
                "Invalid onError value '{}': must be 'skip' or 'error'.",
                other
            ));
        }
    };

    Ok(OperatorConfig {
        key_path,
        key_prefix,
        output_path,
        fields,
        on_missing,
        on_error,
    })
}

fn dss_enricher_init(configuration: ModuleConfiguration) -> bool {
    logger::log(Level::Info, MODULE_NAME, "Initializing operator");

    for (key, _) in &configuration.properties {
        logger::log(
            Level::Info,
            MODULE_NAME,
            &format!("Configuration property received: {}", key),
        );
    }

    match parse_config(&configuration.properties) {
        Ok(config) => {
            logger::log(
                Level::Info,
                MODULE_NAME,
                &format!(
                    "Initialized: keyPath='{}', keyPrefix='{}', outputPath={:?}, \
                     fields={:?}, onMissing={:?}, onError={:?}",
                    config.key_path,
                    config.key_prefix,
                    config.output_path,
                    config.fields,
                    config.on_missing,
                    config.on_error,
                ),
            );
            let _ = CONFIG.set(config);
            true
        }
        Err(msg) => {
            logger::log(Level::Error, MODULE_NAME, &msg);
            false
        }
    }
}

#[map_operator(init = "dss_enricher_init")]
fn dss_enricher(input: DataModel) -> Result<DataModel, Error> {
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

    // Parse incoming message
    let json_str = match std::str::from_utf8(&payload) {
        Ok(s) => s,
        Err(_) => {
            logger::log(
                Level::Warn,
                MODULE_NAME,
                "Payload is not valid UTF-8 — passing through unchanged",
            );
            return Ok(input);
        }
    };

    let mut parsed: serde_json::Value = match serde_json::from_str(json_str) {
        Ok(v) => v,
        Err(e) => {
            logger::log(
                Level::Warn,
                MODULE_NAME,
                &format!("Payload is not valid JSON ({}). Passing through unchanged.", e),
            );
            return Ok(input);
        }
    };

    // Extract the lookup key value using JSON Pointer
    let key_value = match parsed.pointer(&config.key_path) {
        Some(value) => match value_to_key_string(value) {
            Some(s) => s,
            None => {
                let msg = format!(
                    "Value at keyPath '{}' is not a scalar (string/number/bool) — cannot use as key",
                    config.key_path
                );
                match config.on_missing {
                    OnMissing::Error => return Err(Error { message: msg }),
                    _ => {
                        logger::log(Level::Warn, MODULE_NAME, &msg);
                        return Ok(input);
                    }
                }
            }
        },
        None => {
            let msg = format!("keyPath '{}' not found in message", config.key_path);
            match config.on_missing {
                OnMissing::Error => return Err(Error { message: msg }),
                _ => {
                    logger::log(Level::Warn, MODULE_NAME, &msg);
                    return Ok(input);
                }
            }
        }
    };

    // Construct the full DSS key
    let store_key = format!("{}{}", config.key_prefix, key_value);

    // Read from state store
    let stored_value = match state_store::get(store_key.as_bytes(), None) {
        Ok(resp) => match resp.response {
            Some(bytes) => {
                match std::str::from_utf8(&bytes) {
                    Ok(s) => match serde_json::from_str::<serde_json::Value>(s) {
                        Ok(v) => Some(v),
                        Err(e) => {
                            let msg = format!(
                                "Stored value for key '{}' is not valid JSON: {}",
                                store_key, e
                            );
                            match config.on_error {
                                OnError::Error => return Err(Error { message: msg }),
                                OnError::Skip => {
                                    logger::log(Level::Warn, MODULE_NAME, &msg);
                                    None
                                }
                            }
                        }
                    },
                    Err(e) => {
                        let msg = format!(
                            "Stored value for key '{}' is not valid UTF-8: {}",
                            store_key, e
                        );
                        match config.on_error {
                            OnError::Error => return Err(Error { message: msg }),
                            OnError::Skip => {
                                logger::log(Level::Warn, MODULE_NAME, &msg);
                                None
                            }
                        }
                    }
                }
            }
            None => {
                // Key not found in state store
                let msg = format!("Key '{}' not found in state store", store_key);
                match config.on_missing {
                    OnMissing::Error => return Err(Error { message: msg }),
                    OnMissing::Default => {
                        logger::log(Level::Info, MODULE_NAME, &msg);
                        Some(serde_json::Value::Object(serde_json::Map::new()))
                    }
                    OnMissing::Skip => {
                        logger::log(Level::Info, MODULE_NAME, &msg);
                        None
                    }
                }
            }
        },
        Err(e) => {
            let msg = format!(
                "State store read failed for key '{}': {:?}",
                store_key, e
            );
            match config.on_error {
                OnError::Error => return Err(Error { message: msg }),
                OnError::Skip => {
                    logger::log(Level::Warn, MODULE_NAME, &msg);
                    None
                }
            }
        }
    };

    // If we have stored data, extract fields and merge into message
    if let Some(stored) = stored_value {
        let enrichment = extract_fields(&stored, &config.fields);
        merge_into_message(&mut parsed, enrichment, &config.output_path);

        // Serialize enriched message
        let enriched_bytes = serde_json::to_vec(&parsed).map_err(|e| Error {
            message: format!("Failed to serialize enriched message: {}", e),
        })?;

        let DataModel::Message(mut output) = input else {
            unreachable!("input was already matched as DataModel::Message");
        };
        output.payload = BufferOrBytes::Bytes(enriched_bytes);
        return Ok(DataModel::Message(output));
    }

    // No enrichment performed — return original message unchanged
    Ok(input)
}

#[cfg(test)]
mod tests {
    use super::*;

    // ─── value_to_key_string ─────────────────────────────────────────────

    #[test]
    fn test_value_to_key_string_string() {
        let v = serde_json::json!("abc-123");
        assert_eq!(value_to_key_string(&v), Some("abc-123".to_string()));
    }

    #[test]
    fn test_value_to_key_string_number() {
        let v = serde_json::json!(42);
        assert_eq!(value_to_key_string(&v), Some("42".to_string()));
    }

    #[test]
    fn test_value_to_key_string_bool() {
        let v = serde_json::json!(true);
        assert_eq!(value_to_key_string(&v), Some("true".to_string()));
    }

    #[test]
    fn test_value_to_key_string_null_returns_none() {
        let v = serde_json::Value::Null;
        assert_eq!(value_to_key_string(&v), None);
    }

    #[test]
    fn test_value_to_key_string_object_returns_none() {
        let v = serde_json::json!({"a": 1});
        assert_eq!(value_to_key_string(&v), None);
    }

    #[test]
    fn test_value_to_key_string_array_returns_none() {
        let v = serde_json::json!([1, 2]);
        assert_eq!(value_to_key_string(&v), None);
    }

    // ─── extract_fields ──────────────────────────────────────────────────

    #[test]
    fn test_extract_fields_all() {
        let stored = serde_json::json!({"a": 1, "b": "two", "c": true});
        let result = extract_fields(&stored, &FieldSelection::All);
        assert_eq!(result, stored);
    }

    #[test]
    fn test_extract_fields_named_subset() {
        let stored = serde_json::json!({"a": 1, "b": "two", "c": true});
        let fields = FieldSelection::Named(vec!["a".to_string(), "c".to_string()]);
        let result = extract_fields(&stored, &fields);
        assert_eq!(result, serde_json::json!({"a": 1, "c": true}));
    }

    #[test]
    fn test_extract_fields_named_missing_field() {
        let stored = serde_json::json!({"a": 1});
        let fields = FieldSelection::Named(vec!["a".to_string(), "missing".to_string()]);
        let result = extract_fields(&stored, &fields);
        assert_eq!(result, serde_json::json!({"a": 1}));
    }

    // ─── merge_into_message ──────────────────────────────────────────────

    #[test]
    fn test_merge_at_root_no_overwrite() {
        let mut msg = serde_json::json!({"id": "x", "temp": 22});
        let enrichment = serde_json::json!({"location": "lab", "id": "SHOULD_NOT_OVERWRITE"});
        merge_into_message(&mut msg, enrichment, &None);
        assert_eq!(msg, serde_json::json!({"id": "x", "temp": 22, "location": "lab"}));
    }

    #[test]
    fn test_merge_at_output_path() {
        let mut msg = serde_json::json!({"id": "x", "temp": 22});
        let enrichment = serde_json::json!({"location": "lab"});
        merge_into_message(&mut msg, enrichment.clone(), &Some("context".to_string()));
        assert_eq!(
            msg,
            serde_json::json!({"id": "x", "temp": 22, "context": {"location": "lab"}})
        );
    }

    // ─── parse_config ────────────────────────────────────────────────────

    #[test]
    fn test_parse_config_minimal_valid() {
        let props = vec![("keyPath".to_string(), "/id".to_string())];
        let config = parse_config(&props).unwrap();
        assert_eq!(config.key_path, "/id");
        assert_eq!(config.key_prefix, "");
        assert_eq!(config.output_path, None);
        assert_eq!(config.on_missing, OnMissing::Skip);
        assert_eq!(config.on_error, OnError::Skip);
    }

    #[test]
    fn test_parse_config_full() {
        let props = vec![
            ("keyPath".to_string(), "/data/ref".to_string()),
            ("keyPrefix".to_string(), "entity:".to_string()),
            ("outputPath".to_string(), "enriched".to_string()),
            ("fields".to_string(), "name,category".to_string()),
            ("onMissing".to_string(), "error".to_string()),
            ("onError".to_string(), "error".to_string()),
        ];
        let config = parse_config(&props).unwrap();
        assert_eq!(config.key_path, "/data/ref");
        assert_eq!(config.key_prefix, "entity:");
        assert_eq!(config.output_path, Some("enriched".to_string()));
        assert_eq!(config.on_missing, OnMissing::Error);
        assert_eq!(config.on_error, OnError::Error);
    }

    #[test]
    fn test_parse_config_missing_key_path() {
        let props = vec![("keyPrefix".to_string(), "x:".to_string())];
        let result = parse_config(&props);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Missing required configuration: 'keyPath'"));
    }

    #[test]
    fn test_parse_config_invalid_key_path_no_slash() {
        let props = vec![("keyPath".to_string(), "noslash".to_string())];
        let result = parse_config(&props);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("must start with '/'"));
    }

    #[test]
    fn test_parse_config_invalid_on_missing() {
        let props = vec![
            ("keyPath".to_string(), "/id".to_string()),
            ("onMissing".to_string(), "invalid".to_string()),
        ];
        let result = parse_config(&props);
        assert!(result.is_err());
    }

    #[test]
    fn test_parse_config_on_missing_default() {
        let props = vec![
            ("keyPath".to_string(), "/id".to_string()),
            ("onMissing".to_string(), "default".to_string()),
        ];
        let config = parse_config(&props).unwrap();
        assert_eq!(config.on_missing, OnMissing::Default);
    }
}
