//! WASM map operator providing DateTime functions for AIO dataflow graphs.
//!
//! A single mode-driven map operator that derives new timestamp fields and writes
//! them back into the JSON payload by JSON Pointer, returning the full message so
//! the graph continues. All conversions are UTC-only and deterministic: no wall
//! clock is read. For current/ingestion-time conversions, `inputSource =
//! messageTimestamp` reads the message hybrid logical clock (HLC) wall-clock
//! component. That value comes from the publisher's optional `__ts` MQTT user
//! property (the data flow assigns it when absent), so treat it as deterministic
//! event-time rather than a guaranteed broker-stamped ingestion clock.
//!
//! Modes (`mode`):
//! - `parse`    — RFC 3339 string (or host timestamp) -> epoch number (`epochUnit`)
//! - `format`   — epoch number (or host timestamp) -> formatted UTC string (`format`)
//! - `reformat` — timestamp string (`inputFormat` or RFC 3339) -> restyled string (`format`)
//! - `duration` — two timestamps (`inputPath`, `inputPath2`) -> numeric diff (`unit`)
//! - `parts`    — timestamp -> object of requested `parts`
//!
//! Configuration (via `ModuleConfiguration.properties`, flat camelCase strings):
//! - `mode`        (required): `parse` | `format` | `reformat` | `duration` | `parts`
//! - `inputSource` (optional): `payload` (default, uses `inputPath`) | `messageTimestamp`
//! - `inputPath`   (required when `inputSource = payload`): JSON Pointer to the source field
//! - `inputPath2`  (required for `duration`): JSON Pointer to the second timestamp
//! - `outputPath`  (required): JSON Pointer where the result is written
//! - `inputFormat` (optional): strftime parse layout when input is not RFC 3339
//! - `format`      (required for `format`/`reformat`): strftime output layout
//! - `unit`        (optional): duration unit `ms` (default) | `seconds` | `minutes` | `hours`
//! - `epochUnit`   (optional): epoch granularity `ms` (default) | `seconds`
//! - `parts`       (required for `parts`): comma list of year,month,day,hour,minute,second,weekday,ordinal
//! - `onMissing`   (optional): `skip` (default, passthrough) | `error`

use std::sync::OnceLock;

use chrono::{DateTime, Datelike, NaiveDateTime, Timelike, Utc};
use serde_json::{Map, Value};
use wasm_graph_sdk::logger::{self, Level};
use wasm_graph_sdk::macros::map_operator;

const MODULE_NAME: &str = "datetime";

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Mode {
    Parse,
    Format,
    Reformat,
    Duration,
    Parts,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum InputSource {
    Payload,
    MessageTimestamp,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum OnMissing {
    Skip,
    Error,
}

#[derive(Debug)]
struct OperatorConfig {
    mode: Mode,
    input_source: InputSource,
    input_path: String,
    input_path2: Option<String>,
    output_path: String,
    input_format: Option<String>,
    format: Option<String>,
    unit: String,
    epoch_unit: String,
    parts: Vec<String>,
    on_missing: OnMissing,
}

static CONFIG: OnceLock<OperatorConfig> = OnceLock::new();

#[map_operator(init = "datetime_init")]
fn datetime(input: DataModel) -> Result<DataModel, Error> {
    let config = CONFIG.get().ok_or_else(|| Error {
        message: "datetime operator not initialized".to_string(),
    })?;

    let DataModel::Message(mut output) = input else {
        return Ok(input);
    };

    let payload = match &output.payload {
        BufferOrBytes::Buffer(buffer) => buffer.read(),
        BufferOrBytes::Bytes(bytes) => bytes.clone(),
    };

    let json_str = match std::str::from_utf8(&payload) {
        Ok(text) => text,
        Err(_) => {
            return passthrough_or_error(config, output, "payload is not valid UTF-8".to_string());
        }
    };

    let mut value: Value = match serde_json::from_str(json_str) {
        Ok(parsed) => parsed,
        Err(e) => {
            return passthrough_or_error(config, output, format!("payload is not valid JSON: {e}"));
        }
    };

    let host_timestamp = DateTime::from_timestamp(
        output.timestamp.timestamp.secs as i64,
        output.timestamp.timestamp.nanos,
    );

    match apply_mode(config, &mut value, host_timestamp) {
        Ok(()) => {
            let bytes = serde_json::to_vec(&value).map_err(|e| Error {
                message: format!("serialize failed: {e}"),
            })?;
            output.payload = BufferOrBytes::Bytes(bytes);
            Ok(DataModel::Message(output))
        }
        Err(message) => passthrough_or_error(config, output, message),
    }
}

fn datetime_init(configuration: ModuleConfiguration) -> bool {
    logger::log(Level::Info, MODULE_NAME, "Initializing operator");

    match parse_config(&configuration.properties) {
        Ok(config) => {
            logger::log(
                Level::Info,
                MODULE_NAME,
                &format!("Initialized: mode={:?}", config.mode),
            );
            CONFIG.set(config).is_ok()
        }
        Err(message) => {
            logger::log(Level::Error, MODULE_NAME, &message);
            false
        }
    }
}

/// Returns the message unchanged when `onMissing = skip` (logging a warning), or
/// propagates the failure as an `Error` when `onMissing = error`.
fn passthrough_or_error(
    config: &OperatorConfig,
    output: Message,
    message: String,
) -> Result<DataModel, Error> {
    if matches!(config.on_missing, OnMissing::Error) {
        return Err(Error { message });
    }
    logger::log(
        Level::Warn,
        MODULE_NAME,
        &format!("{message} — passing through"),
    );
    Ok(DataModel::Message(output))
}

/// Parses and validates operator configuration from key-value properties.
/// Returns `Ok(OperatorConfig)` on success, or `Err(message)` describing the failure.
fn parse_config(properties: &[(String, String)]) -> Result<OperatorConfig, String> {
    let get = |key: &str| {
        properties
            .iter()
            .find(|(k, _)| k == key)
            .map(|(_, v)| v.clone())
    };

    let mode = match get("mode") {
        Some(value) => match value.as_str() {
            "parse" => Mode::Parse,
            "format" => Mode::Format,
            "reformat" => Mode::Reformat,
            "duration" => Mode::Duration,
            "parts" => Mode::Parts,
            other => {
                return Err(format!(
                    "Invalid mode '{other}': must be one of parse|format|reformat|duration|parts."
                ));
            }
        },
        None => {
            return Err("Missing required configuration: 'mode'. \
                 Provide one of parse|format|reformat|duration|parts."
                .to_string());
        }
    };

    let input_source = match get("inputSource") {
        Some(value) => match value.as_str() {
            "payload" => InputSource::Payload,
            "messageTimestamp" => InputSource::MessageTimestamp,
            other => {
                return Err(format!(
                    "Invalid inputSource '{other}': must be 'payload' or 'messageTimestamp'."
                ));
            }
        },
        None => InputSource::Payload,
    };

    let input_path = match get("inputPath") {
        Some(path) if path.starts_with('/') => path,
        Some(other) => {
            return Err(format!(
                "Invalid inputPath '{other}': must start with '/' (RFC 6901 JSON Pointer)."
            ));
        }
        None => {
            if matches!(input_source, InputSource::Payload) {
                return Err("Missing required configuration: 'inputPath'. \
                     Provide a JSON Pointer, e.g. /event_timestamp, when inputSource=payload."
                    .to_string());
            }
            String::new()
        }
    };

    let input_path2 = match get("inputPath2") {
        Some(path) if path.starts_with('/') => Some(path),
        Some(other) => {
            return Err(format!(
                "Invalid inputPath2 '{other}': must start with '/' (RFC 6901 JSON Pointer)."
            ));
        }
        None => None,
    };
    if matches!(mode, Mode::Duration) && input_path2.is_none() {
        return Err("Missing required configuration: 'inputPath2'. \
             Duration mode requires a second JSON Pointer timestamp."
            .to_string());
    }

    let output_path = match get("outputPath") {
        Some(path) if path.starts_with('/') => path,
        Some(other) => {
            return Err(format!(
                "Invalid outputPath '{other}': must start with '/' (RFC 6901 JSON Pointer)."
            ));
        }
        None => {
            return Err("Missing required configuration: 'outputPath'. \
                 Provide a JSON Pointer where the result is written."
                .to_string());
        }
    };

    let input_format = get("inputFormat").filter(|value| !value.is_empty());

    let format = get("format").filter(|value| !value.is_empty());
    if matches!(mode, Mode::Format | Mode::Reformat) && format.is_none() {
        return Err("Missing required configuration: 'format'. \
             Provide a strftime layout for format/reformat modes, e.g. %Y-%m-%dT%H:%M:%S%.3fZ."
            .to_string());
    }

    let unit = match get("unit") {
        Some(value) => match value.as_str() {
            "ms" | "seconds" | "minutes" | "hours" => value,
            other => {
                return Err(format!(
                    "Invalid unit '{other}': must be one of ms|seconds|minutes|hours."
                ));
            }
        },
        None => "ms".to_string(),
    };

    let epoch_unit = match get("epochUnit") {
        Some(value) => match value.as_str() {
            "ms" | "seconds" => value,
            other => {
                return Err(format!(
                    "Invalid epochUnit '{other}': must be 'ms' or 'seconds'."
                ));
            }
        },
        None => "ms".to_string(),
    };

    let parts = match get("parts") {
        Some(value) => {
            let list: Vec<String> = value
                .split(',')
                .map(|entry| entry.trim().to_string())
                .filter(|entry| !entry.is_empty())
                .collect();
            for part in &list {
                if !is_known_part(part) {
                    return Err(format!(
                        "Invalid parts entry '{part}': allowed values are \
                         year,month,day,hour,minute,second,weekday,ordinal."
                    ));
                }
            }
            list
        }
        None => Vec::new(),
    };
    if matches!(mode, Mode::Parts) && parts.is_empty() {
        return Err("Missing required configuration: 'parts'. \
             Provide a comma list, e.g. year,month,day."
            .to_string());
    }

    let on_missing = match get("onMissing") {
        Some(value) => match value.as_str() {
            "skip" => OnMissing::Skip,
            "error" => OnMissing::Error,
            other => {
                return Err(format!(
                    "Invalid onMissing value '{other}': must be 'skip' or 'error'."
                ));
            }
        },
        None => OnMissing::Skip,
    };

    Ok(OperatorConfig {
        mode,
        input_source,
        input_path,
        input_path2,
        output_path,
        input_format,
        format,
        unit,
        epoch_unit,
        parts,
        on_missing,
    })
}

/// Computes the configured mode result and writes it into `value` at `outputPath`.
/// Returns `Err(message)` when the source field is missing or malformed.
fn apply_mode(
    config: &OperatorConfig,
    value: &mut Value,
    host_timestamp: Option<DateTime<Utc>>,
) -> Result<(), String> {
    let result = match config.mode {
        Mode::Parse => {
            let dt = resolve_datetime(config, value, host_timestamp)?;
            Value::from(to_epoch(&dt, &config.epoch_unit))
        }
        Mode::Format => {
            let fmt = config
                .format
                .as_deref()
                .ok_or_else(|| "format mode requires 'format'".to_string())?;
            match config.input_source {
                InputSource::MessageTimestamp => {
                    let dt = host_timestamp
                        .ok_or_else(|| "messageTimestamp source is unavailable".to_string())?;
                    Value::from(dt.format(fmt).to_string())
                }
                InputSource::Payload => {
                    let epoch = epoch_at_path(value, &config.input_path)?;
                    Value::from(from_epoch(epoch, &config.epoch_unit, fmt)?)
                }
            }
        }
        Mode::Reformat => {
            let fmt = config
                .format
                .as_deref()
                .ok_or_else(|| "reformat mode requires 'format'".to_string())?;
            match config.input_source {
                InputSource::MessageTimestamp => {
                    let dt = host_timestamp
                        .ok_or_else(|| "messageTimestamp source is unavailable".to_string())?;
                    Value::from(dt.format(fmt).to_string())
                }
                InputSource::Payload => {
                    let text = string_at_path(value, &config.input_path)?;
                    Value::from(reformat(&text, config.input_format.as_deref(), fmt)?)
                }
            }
        }
        Mode::Duration => {
            let start = match config.input_source {
                InputSource::MessageTimestamp => host_timestamp
                    .ok_or_else(|| "messageTimestamp source is unavailable".to_string())?,
                InputSource::Payload => {
                    datetime_from_path(value, &config.input_path, config.input_format.as_deref())?
                }
            };
            let path2 = config
                .input_path2
                .as_deref()
                .ok_or_else(|| "duration mode requires 'inputPath2'".to_string())?;
            let end = datetime_from_path(value, path2, config.input_format.as_deref())?;
            Value::from(duration_in_unit(&start, &end, &config.unit))
        }
        Mode::Parts => {
            let dt = resolve_datetime(config, value, host_timestamp)?;
            parts_object(&dt, &config.parts)
        }
    };

    json_pointer_set(value, &config.output_path, result)
}

/// Resolves the source `DateTime` for string-based modes from the payload field or
/// the host timestamp.
fn resolve_datetime(
    config: &OperatorConfig,
    value: &Value,
    host_timestamp: Option<DateTime<Utc>>,
) -> Result<DateTime<Utc>, String> {
    match config.input_source {
        InputSource::MessageTimestamp => {
            host_timestamp.ok_or_else(|| "messageTimestamp source is unavailable".to_string())
        }
        InputSource::Payload => {
            datetime_from_path(value, &config.input_path, config.input_format.as_deref())
        }
    }
}

/// Reads an integer epoch value at `path` from the payload.
fn epoch_at_path(value: &Value, path: &str) -> Result<i64, String> {
    let field = value
        .pointer(path)
        .ok_or_else(|| format!("inputPath '{path}' not found in message"))?;
    field
        .as_i64()
        .ok_or_else(|| format!("value at inputPath '{path}' is not an integer epoch"))
}

/// Reads a string value at `path` from the payload.
fn string_at_path(value: &Value, path: &str) -> Result<String, String> {
    let field = value
        .pointer(path)
        .ok_or_else(|| format!("path '{path}' not found in message"))?;
    field
        .as_str()
        .map(str::to_string)
        .ok_or_else(|| format!("value at path '{path}' is not a string timestamp"))
}

/// Reads a string timestamp at `path` and parses it via `input_format` or RFC 3339.
fn datetime_from_path(
    value: &Value,
    path: &str,
    input_format: Option<&str>,
) -> Result<DateTime<Utc>, String> {
    let field = value
        .pointer(path)
        .ok_or_else(|| format!("path '{path}' not found in message"))?;
    let text = field
        .as_str()
        .ok_or_else(|| format!("value at path '{path}' is not a string timestamp"))?;
    parse_string_datetime(text, input_format)
}

/// Parses a UTC `DateTime` from a string using a strftime `input_format` or RFC 3339.
fn parse_string_datetime(input: &str, input_format: Option<&str>) -> Result<DateTime<Utc>, String> {
    match input_format {
        Some(fmt) => {
            let naive = NaiveDateTime::parse_from_str(input, fmt)
                .map_err(|e| format!("failed to parse '{input}' with format '{fmt}': {e}"))?;
            Ok(DateTime::<Utc>::from_naive_utc_and_offset(naive, Utc))
        }
        None => DateTime::parse_from_rfc3339(input)
            .map(|dt| dt.with_timezone(&Utc))
            .map_err(|e| format!("failed to parse RFC 3339 timestamp '{input}': {e}")),
    }
}

/// Converts a UTC `DateTime` to an epoch value in the requested unit.
fn to_epoch(dt: &DateTime<Utc>, epoch_unit: &str) -> i64 {
    if epoch_unit == "seconds" {
        dt.timestamp()
    } else {
        dt.timestamp_millis()
    }
}

/// Converts an epoch value in the requested unit to a UTC `DateTime`.
fn epoch_to_datetime(epoch: i64, epoch_unit: &str) -> Result<DateTime<Utc>, String> {
    let dt = if epoch_unit == "seconds" {
        DateTime::from_timestamp(epoch, 0)
    } else {
        DateTime::from_timestamp_millis(epoch)
    };
    dt.ok_or_else(|| format!("epoch value {epoch} ({epoch_unit}) is out of range"))
}

/// Formats an epoch value in the requested unit as a UTC string with `fmt`.
fn from_epoch(epoch: i64, epoch_unit: &str, fmt: &str) -> Result<String, String> {
    let dt = epoch_to_datetime(epoch, epoch_unit)?;
    Ok(dt.format(fmt).to_string())
}

/// Parses `input` (via `input_format` or RFC 3339) and re-renders it with `out_format`.
fn reformat(input: &str, input_format: Option<&str>, out_format: &str) -> Result<String, String> {
    let dt = parse_string_datetime(input, input_format)?;
    Ok(dt.format(out_format).to_string())
}

/// Returns the difference `start - end` expressed in the requested unit.
fn duration_in_unit(start: &DateTime<Utc>, end: &DateTime<Utc>, unit: &str) -> i64 {
    let delta = start.signed_duration_since(*end);
    match unit {
        "seconds" => delta.num_seconds(),
        "minutes" => delta.num_minutes(),
        "hours" => delta.num_hours(),
        _ => delta.num_milliseconds(),
    }
}

/// Returns whether `part` names a supported calendar/clock component.
fn is_known_part(part: &str) -> bool {
    matches!(
        part,
        "year" | "month" | "day" | "hour" | "minute" | "second" | "weekday" | "ordinal"
    )
}

/// Builds a JSON object of the requested `parts` from a UTC `DateTime`.
fn parts_object(dt: &DateTime<Utc>, parts: &[String]) -> Value {
    let mut object = Map::new();
    for part in parts {
        let component = match part.as_str() {
            "year" => Value::from(dt.year()),
            "month" => Value::from(dt.month()),
            "day" => Value::from(dt.day()),
            "hour" => Value::from(dt.hour()),
            "minute" => Value::from(dt.minute()),
            "second" => Value::from(dt.second()),
            "weekday" => Value::from(dt.weekday().to_string()),
            "ordinal" => Value::from(dt.ordinal()),
            _ => continue,
        };
        object.insert(part.clone(), component);
    }
    Value::Object(object)
}

/// Sets `new_value` at `pointer` (RFC 6901), creating intermediate objects as needed.
fn json_pointer_set(root: &mut Value, pointer: &str, new_value: Value) -> Result<(), String> {
    if pointer.is_empty() {
        *root = new_value;
        return Ok(());
    }
    if !pointer.starts_with('/') {
        return Err(format!(
            "Invalid outputPath '{pointer}': must start with '/'."
        ));
    }

    let tokens: Vec<String> = pointer[1..]
        .split('/')
        .map(|token| token.replace("~1", "/").replace("~0", "~"))
        .collect();

    let last = tokens.len() - 1;
    let mut current = root;
    for token in &tokens[..last] {
        current = match current {
            Value::Object(map) => map
                .entry(token.clone())
                .or_insert_with(|| Value::Object(Map::new())),
            Value::Array(array) => {
                let index = token.parse::<usize>().map_err(|_| {
                    format!("Invalid array index '{token}' in JSON Pointer '{pointer}'.")
                })?;
                array.get_mut(index).ok_or_else(|| {
                    format!("Array index {index} out of bounds in JSON Pointer '{pointer}'.")
                })?
            }
            _ => {
                return Err(format!(
                    "Cannot traverse '{token}': parent is not an object or array in JSON Pointer '{pointer}'."
                ));
            }
        };
    }

    let leaf = &tokens[last];
    match current {
        Value::Object(map) => {
            map.insert(leaf.clone(), new_value);
            Ok(())
        }
        Value::Array(array) => {
            let index = leaf.parse::<usize>().map_err(|_| {
                format!("Invalid array index '{leaf}' in JSON Pointer '{pointer}'.")
            })?;
            if index >= array.len() {
                return Err(format!(
                    "Array index {index} out of bounds in JSON Pointer '{pointer}'."
                ));
            }
            array[index] = new_value;
            Ok(())
        }
        _ => Err(format!(
            "Cannot set value: parent is not an object or array in JSON Pointer '{pointer}'."
        )),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn props(pairs: &[(&str, &str)]) -> Vec<(String, String)> {
        pairs
            .iter()
            .map(|(k, v)| (k.to_string(), v.to_string()))
            .collect()
    }

    fn utc(text: &str) -> DateTime<Utc> {
        DateTime::parse_from_rfc3339(text)
            .expect("valid RFC 3339 fixture")
            .with_timezone(&Utc)
    }

    // ─── parse_config: success ───────────────────────────────────────────────

    #[test]
    fn given_minimal_parse_mode_when_parse_config_then_applies_defaults() {
        let config = parse_config(&props(&[
            ("mode", "parse"),
            ("inputPath", "/ts"),
            ("outputPath", "/epoch"),
        ]))
        .expect("config should be valid");

        assert_eq!(config.mode, Mode::Parse, "mode should be Parse");
        assert_eq!(config.epoch_unit, "ms", "epochUnit should default to ms");
        assert_eq!(config.unit, "ms", "unit should default to ms");
        assert_eq!(
            config.input_source,
            InputSource::Payload,
            "inputSource should default to payload"
        );
        assert_eq!(
            config.on_missing,
            OnMissing::Skip,
            "onMissing should default to skip"
        );
    }

    #[test]
    fn given_message_timestamp_source_when_parse_config_then_input_path_optional() {
        let config = parse_config(&props(&[
            ("mode", "parse"),
            ("inputSource", "messageTimestamp"),
            ("outputPath", "/epoch"),
        ]))
        .expect("config without inputPath should be valid for messageTimestamp");

        assert_eq!(
            config.input_source,
            InputSource::MessageTimestamp,
            "inputSource should be messageTimestamp"
        );
        assert!(
            config.input_path.is_empty(),
            "inputPath should be empty when omitted with messageTimestamp"
        );
    }

    // ─── parse_config: validation errors ─────────────────────────────────────

    #[test]
    fn given_no_mode_when_parse_config_then_errors() {
        let error = parse_config(&props(&[("outputPath", "/x")])).unwrap_err();
        assert!(
            error.contains("'mode'"),
            "error should mention mode: {error}"
        );
    }

    #[test]
    fn given_invalid_mode_when_parse_config_then_errors() {
        let error = parse_config(&props(&[("mode", "bogus"), ("outputPath", "/x")])).unwrap_err();
        assert!(
            error.contains("Invalid mode"),
            "error should reject the mode: {error}"
        );
    }

    #[test]
    fn given_payload_source_without_input_path_when_parse_config_then_errors() {
        let error = parse_config(&props(&[("mode", "parse"), ("outputPath", "/x")])).unwrap_err();
        assert!(
            error.contains("'inputPath'"),
            "error should require inputPath: {error}"
        );
    }

    #[test]
    fn given_input_path_without_leading_slash_when_parse_config_then_errors() {
        let error = parse_config(&props(&[
            ("mode", "parse"),
            ("inputPath", "ts"),
            ("outputPath", "/x"),
        ]))
        .unwrap_err();
        assert!(
            error.contains("Invalid inputPath"),
            "error should reject non-pointer inputPath: {error}"
        );
    }

    #[test]
    fn given_no_output_path_when_parse_config_then_errors() {
        let error = parse_config(&props(&[("mode", "parse"), ("inputPath", "/ts")])).unwrap_err();
        assert!(
            error.contains("'outputPath'"),
            "error should require outputPath: {error}"
        );
    }

    #[test]
    fn given_duration_mode_without_input_path2_when_parse_config_then_errors() {
        let error = parse_config(&props(&[
            ("mode", "duration"),
            ("inputPath", "/a"),
            ("outputPath", "/d"),
        ]))
        .unwrap_err();
        assert!(
            error.contains("'inputPath2'"),
            "error should require inputPath2 for duration: {error}"
        );
    }

    #[test]
    fn given_format_mode_without_format_when_parse_config_then_errors() {
        let error = parse_config(&props(&[
            ("mode", "format"),
            ("inputPath", "/epoch"),
            ("outputPath", "/display"),
        ]))
        .unwrap_err();
        assert!(
            error.contains("'format'"),
            "error should require format for format mode: {error}"
        );
    }

    #[test]
    fn given_invalid_unit_when_parse_config_then_errors() {
        let error = parse_config(&props(&[
            ("mode", "duration"),
            ("inputPath", "/a"),
            ("inputPath2", "/b"),
            ("outputPath", "/d"),
            ("unit", "weeks"),
        ]))
        .unwrap_err();
        assert!(
            error.contains("Invalid unit"),
            "error should reject the unit: {error}"
        );
    }

    #[test]
    fn given_invalid_epoch_unit_when_parse_config_then_errors() {
        let error = parse_config(&props(&[
            ("mode", "parse"),
            ("inputPath", "/ts"),
            ("outputPath", "/epoch"),
            ("epochUnit", "micros"),
        ]))
        .unwrap_err();
        assert!(
            error.contains("Invalid epochUnit"),
            "error should reject the epochUnit: {error}"
        );
    }

    #[test]
    fn given_parts_mode_without_parts_when_parse_config_then_errors() {
        let error = parse_config(&props(&[
            ("mode", "parts"),
            ("inputPath", "/ts"),
            ("outputPath", "/parts"),
        ]))
        .unwrap_err();
        assert!(
            error.contains("'parts'"),
            "error should require parts for parts mode: {error}"
        );
    }

    #[test]
    fn given_unknown_part_when_parse_config_then_errors() {
        let error = parse_config(&props(&[
            ("mode", "parts"),
            ("inputPath", "/ts"),
            ("outputPath", "/parts"),
            ("parts", "year,century"),
        ]))
        .unwrap_err();
        assert!(
            error.contains("Invalid parts entry"),
            "error should reject the unknown part: {error}"
        );
    }

    #[test]
    fn given_invalid_on_missing_when_parse_config_then_errors() {
        let error = parse_config(&props(&[
            ("mode", "parse"),
            ("inputPath", "/ts"),
            ("outputPath", "/epoch"),
            ("onMissing", "halt"),
        ]))
        .unwrap_err();
        assert!(
            error.contains("Invalid onMissing"),
            "error should reject the onMissing value: {error}"
        );
    }

    // ─── epoch round-trip ────────────────────────────────────────────────────

    #[test]
    fn given_utc_datetime_when_to_and_from_epoch_ms_then_round_trips() {
        let dt = utc("2021-01-01T00:00:00Z");
        let epoch = to_epoch(&dt, "ms");
        assert_eq!(epoch, 1_609_459_200_000, "epoch ms should match");

        let rendered = from_epoch(epoch, "ms", "%Y-%m-%dT%H:%M:%SZ").expect("epoch in range");
        assert_eq!(
            rendered, "2021-01-01T00:00:00Z",
            "round-trip should restore the timestamp"
        );
    }

    #[test]
    fn given_utc_datetime_when_to_epoch_seconds_then_returns_seconds() {
        let dt = utc("2021-01-01T00:00:00Z");
        assert_eq!(
            to_epoch(&dt, "seconds"),
            1_609_459_200,
            "epoch seconds should match"
        );
    }

    #[test]
    fn given_epoch_seconds_when_from_epoch_then_formats_utc() {
        let rendered = from_epoch(0, "seconds", "%Y-%m-%dT%H:%M:%SZ").expect("epoch in range");
        assert_eq!(
            rendered, "1970-01-01T00:00:00Z",
            "epoch 0 should be the unix epoch"
        );
    }

    // ─── reformat ────────────────────────────────────────────────────────────

    #[test]
    fn given_rfc3339_when_reformat_then_restyles() {
        let rendered =
            reformat("2021-03-15T08:30:00Z", None, "%Y-%m-%d %H:%M").expect("valid RFC 3339 input");
        assert_eq!(
            rendered, "2021-03-15 08:30",
            "reformat should restyle the timestamp"
        );
    }

    #[test]
    fn given_custom_input_format_when_reformat_then_parses_and_restyles() {
        let rendered = reformat("2021-03-15 08:30", Some("%Y-%m-%d %H:%M"), "%Y/%m/%d")
            .expect("valid custom-format input");
        assert_eq!(rendered, "2021/03/15", "reformat should honor inputFormat");
    }

    // ─── duration ────────────────────────────────────────────────────────────

    #[test]
    fn given_one_hour_apart_when_duration_in_unit_then_converts_each_unit() {
        let start = utc("2021-01-01T01:00:00Z");
        let end = utc("2021-01-01T00:00:00Z");

        assert_eq!(duration_in_unit(&start, &end, "ms"), 3_600_000, "ms diff");
        assert_eq!(
            duration_in_unit(&start, &end, "seconds"),
            3_600,
            "seconds diff"
        );
        assert_eq!(
            duration_in_unit(&start, &end, "minutes"),
            60,
            "minutes diff"
        );
        assert_eq!(duration_in_unit(&start, &end, "hours"), 1, "hours diff");
    }

    // ─── parts ───────────────────────────────────────────────────────────────

    #[test]
    fn given_timestamp_when_parts_object_then_extracts_requested_components() {
        let dt = utc("2021-03-15T08:30:45Z");
        let parts = vec![
            "year".to_string(),
            "month".to_string(),
            "day".to_string(),
            "weekday".to_string(),
            "ordinal".to_string(),
        ];
        let object = parts_object(&dt, &parts);

        assert_eq!(object["year"], Value::from(2021), "year component");
        assert_eq!(object["month"], Value::from(3), "month component");
        assert_eq!(object["day"], Value::from(15), "day component");
        assert_eq!(object["weekday"], Value::from("Mon"), "weekday component");
        assert_eq!(object["ordinal"], Value::from(74), "ordinal component");
    }

    // ─── json_pointer_set ────────────────────────────────────────────────────

    #[test]
    fn given_top_level_pointer_when_set_then_writes_value() {
        let mut root = serde_json::json!({});
        json_pointer_set(&mut root, "/epoch", Value::from(42)).expect("set should succeed");
        assert_eq!(
            root["epoch"],
            Value::from(42),
            "top-level value should be written"
        );
    }

    #[test]
    fn given_nested_pointer_when_set_then_creates_intermediate_objects() {
        let mut root = serde_json::json!({});
        json_pointer_set(&mut root, "/a/b/c", Value::from("deep")).expect("set should succeed");
        assert_eq!(
            root["a"]["b"]["c"],
            Value::from("deep"),
            "nested value should be written"
        );
    }

    #[test]
    fn given_existing_fields_when_set_then_preserves_them() {
        let mut root = serde_json::json!({"keep": 1});
        json_pointer_set(&mut root, "/added", Value::from(2)).expect("set should succeed");
        assert_eq!(
            root["keep"],
            Value::from(1),
            "existing field should be preserved"
        );
        assert_eq!(root["added"], Value::from(2), "new field should be added");
    }

    #[test]
    fn given_pointer_without_leading_slash_when_set_then_errors() {
        let mut root = serde_json::json!({});
        let error = json_pointer_set(&mut root, "epoch", Value::from(1)).unwrap_err();
        assert!(
            error.contains("must start with '/'"),
            "error should reject non-pointer output path: {error}"
        );
    }
}
