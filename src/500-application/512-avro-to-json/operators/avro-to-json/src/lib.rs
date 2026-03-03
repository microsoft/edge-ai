//! Avro to JSON transformation operator for Azure IoT Operations.
//!
//! Provides a stateless map operator that converts Apache Avro binary data to JSON.
//! Supports multiple Avro encoding formats:
//! - Detection of single-object encoding with embedded schema
//!   (schema lookup is not implemented; decoding is not supported)
//! - Schema-based decoding using a provided Avro schema
//!
//! This operator is designed to be generic and reusable across different Avro schemas.

use apache_avro::{from_avro_datum, types::Value as AvroValue, Schema};
use serde_json::{json, Value as JsonValue};
use std::sync::OnceLock;
use wasm_graph_sdk::logger::{self, Level};
use wasm_graph_sdk::macros::map_operator;

static AVRO_SCHEMA: OnceLock<Option<Schema>> = OnceLock::new();

/// Converts an Avro value to a JSON value recursively
fn avro_to_json(avro_value: &AvroValue) -> JsonValue {
    match avro_value {
        AvroValue::Null => JsonValue::Null,
        AvroValue::Boolean(b) => json!(b),
        AvroValue::Int(i) => json!(i),
        AvroValue::Long(l) => json!(l),
        AvroValue::Float(f) => json!(f),
        AvroValue::Double(d) => json!(d),
        AvroValue::Bytes(b) => {
            // Try to convert bytes to UTF-8 string, otherwise use base64
            match std::str::from_utf8(b) {
                Ok(s) => json!(s),
                Err(_) => {
                    // For binary data, encode as base64
                    let base64_encoded = base64_encode(b);
                    json!(base64_encoded)
                }
            }
        }
        AvroValue::String(s) => json!(s),
        AvroValue::Fixed(_, bytes) => {
            // Similar to Bytes - try UTF-8 first
            match std::str::from_utf8(bytes) {
                Ok(s) => json!(s),
                Err(_) => {
                    let base64_encoded = base64_encode(bytes);
                    json!(base64_encoded)
                }
            }
        }
        AvroValue::Enum(_, symbol) => json!(symbol),
        AvroValue::Union(_, boxed_value) => avro_to_json(boxed_value),
        AvroValue::Array(items) => {
            let json_items: Vec<JsonValue> = items.iter().map(avro_to_json).collect();
            json!(json_items)
        }
        AvroValue::Map(map) => {
            let json_map: serde_json::Map<String, JsonValue> = map
                .iter()
                .map(|(k, v)| (k.clone(), avro_to_json(v)))
                .collect();
            JsonValue::Object(json_map)
        }
        AvroValue::Record(fields) => {
            let json_map: serde_json::Map<String, JsonValue> = fields
                .iter()
                .map(|(k, v)| (k.clone(), avro_to_json(v)))
                .collect();
            JsonValue::Object(json_map)
        }
        AvroValue::Date(d) => json!(d),
        AvroValue::Decimal(decimal) => {
            // Decimal wraps big-endian two's-complement bytes (unscaled integer)
            // Without schema-level scale info here, render as unscaled integer
            let bytes: Vec<u8> = decimal.clone().try_into().unwrap_or_default();
            if bytes.is_empty() {
                json!("0")
            } else {
                let mut value: i128 = if bytes[0] & 0x80 != 0 { -1 } else { 0 };
                for &b in &bytes {
                    value = (value << 8) | b as i128;
                }
                json!(value.to_string())
            }
        }
        AvroValue::TimeMillis(t) => json!(t),
        AvroValue::TimeMicros(t) => json!(t),
        AvroValue::TimestampMillis(t) => json!(t),
        AvroValue::TimestampMicros(t) => json!(t),
        AvroValue::TimestampNanos(t) => json!(t),
        AvroValue::LocalTimestampMillis(t) => json!(t),
        AvroValue::LocalTimestampMicros(t) => json!(t),
        AvroValue::LocalTimestampNanos(t) => json!(t),
        AvroValue::Duration(d) => {
            json!({
                "months": u32::from(d.months()),
                "days": u32::from(d.days()),
                "millis": u32::from(d.millis())
            })
        }
        AvroValue::Uuid(u) => json!(u.to_string()),
        AvroValue::BigDecimal(bd) => {
            json!(format!("{}", bd))
        }
    }
}

/// Simple base64 encoding without external dependencies
fn base64_encode(bytes: &[u8]) -> String {
    const CHARS: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    let mut result = String::new();
    let mut i = 0;

    while i + 2 < bytes.len() {
        let b1 = bytes[i];
        let b2 = bytes[i + 1];
        let b3 = bytes[i + 2];

        result.push(CHARS[(b1 >> 2) as usize] as char);
        result.push(CHARS[(((b1 & 0x03) << 4) | (b2 >> 4)) as usize] as char);
        result.push(CHARS[(((b2 & 0x0f) << 2) | (b3 >> 6)) as usize] as char);
        result.push(CHARS[(b3 & 0x3f) as usize] as char);

        i += 3;
    }

    if i < bytes.len() {
        let b1 = bytes[i];
        result.push(CHARS[(b1 >> 2) as usize] as char);

        if i + 1 < bytes.len() {
            let b2 = bytes[i + 1];
            result.push(CHARS[(((b1 & 0x03) << 4) | (b2 >> 4)) as usize] as char);
            result.push(CHARS[((b2 & 0x0f) << 2) as usize] as char);
            result.push('=');
        } else {
            result.push(CHARS[((b1 & 0x03) << 4) as usize] as char);
            result.push('=');
            result.push('=');
        }
    }

    result
}

/// Attempts to parse Avro data with the provided schema
fn parse_with_schema(data: &[u8], schema: &Schema) -> Result<AvroValue, String> {
    from_avro_datum(schema, &mut &data[..], None)
        .map_err(|e| format!("Failed to parse Avro with schema: {}", e))
}

/// Attempts to detect and parse single-object encoded Avro
/// Single-object encoding: [C3 01] [8-byte schema fingerprint] [avro data]
fn try_parse_single_object(data: &[u8]) -> Option<Result<AvroValue, String>> {
    // Single-object encoded Avro starts with marker bytes [C3 01]
    if data.len() < 10 || data[0] != 0xC3 || data[1] != 0x01 {
        return None;
    }

    // Extract schema fingerprint (8 bytes after marker)
    let _fingerprint = &data[2..10];
    let _avro_data = &data[10..];

    logger::log(
        Level::Warn,
        "avro-to-json",
        "Detected single-object encoding but schema lookup is not implemented. \
         Consider providing schema via configuration.",
    );

    // Without a schema registry, we can't decode single-object encoding
    Some(Err(
        "Single-object encoding detected but schema resolution is not available. \
         Please provide schema via configuration or use a different encoding format."
            .to_string(),
    ))
}

/// Attempts to parse Object Container File format
/// OCF format includes schema in the file header
fn try_parse_container_file(data: &[u8]) -> Option<Result<AvroValue, String>> {
    // Object Container Files start with magic bytes: 'O', 'b', 'j', 0x01
    if data.len() < 4 || &data[0..4] != b"Obj\x01" {
        return None;
    }

    // Use apache-avro's built-in reader for container files
    use apache_avro::Reader;

    Some(
        Reader::new(&data[..])
            .map_err(|e| format!("Failed to parse Avro container file: {}", e))
            .and_then(|mut reader| {
                // Read first record from container
                reader
                    .next()
                    .ok_or_else(|| "No records in Avro container file".to_string())?
                    .map_err(|e| format!("Failed to read record: {}", e))
            }),
    )
}

/// Initialize the operator with optional schema configuration
fn avro_init(configuration: ModuleConfiguration) -> bool {
    logger::log(
        Level::Info,
        "avro-to-json",
        "Initializing Avro to JSON transformation operator",
    );

    // Log all received configuration properties at Info level (AIO convention)
    for (key, _) in &configuration.properties {
        logger::log(
            Level::Info,
            "avro-to-json",
            &format!("Configuration property received: {}", key),
        );
    }

    let schema_result = configuration
        .properties
        .iter()
        .find(|(k, _)| k == "avroSchema")
        .map(|(_, v)| {
            Schema::parse_str(v).map_err(|e| {
                logger::log(
                    Level::Error,
                    "avro-to-json",
                    &format!(
                        "Failed to parse provided Avro schema: {}. \
                         Ensure avroSchema is valid Avro schema JSON. \
                         Example: {{\"type\":\"record\",\"name\":\"Example\",\"fields\":[...]}}. \
                         See: https://avro.apache.org/docs/current/spec.html#schemas",
                        e
                    ),
                );
                e
            })
        });

    match schema_result {
        Some(Ok(schema)) => {
            logger::log(
                Level::Info,
                "avro-to-json",
                &format!("Loaded Avro schema: {}", schema.canonical_form()),
            );
            let _ = AVRO_SCHEMA.set(Some(schema));
        }
        Some(Err(_)) => {
            logger::log(
                Level::Error,
                "avro-to-json",
                "Cannot start: avroSchema configuration is invalid. \
                 Fix the schema or remove it to use auto-detection.",
            );
            return false;
        }
        None => {
            logger::log(
                Level::Info,
                "avro-to-json",
                "No schema provided - will attempt auto-detection from message format",
            );
            let _ = AVRO_SCHEMA.set(None);
        }
    }

    true
}

/// Map operator that converts Avro binary data to JSON
#[map_operator(init = "avro_init")]
fn transform(input: DataModel) -> Result<DataModel, Error> {
    let DataModel::Message(mut result) = input else {
        return Err(Error {
            message: "Unexpected input type".to_string(),
        });
    };

    let payload = match &result.payload {
        BufferOrBytes::Buffer(buffer) => buffer.read(),
        BufferOrBytes::Bytes(bytes) => bytes.clone(),
    };

    if payload.is_empty() {
        logger::log(
            Level::Warn,
            "avro-to-json",
            "Received empty payload - passing through",
        );
        return Ok(DataModel::Message(result));
    }

    // Try different parsing strategies in order of preference:
    // 1. If schema is configured, use it
    // 2. Try Object Container File format (has embedded schema)
    // 3. Try single-object encoding (requires schema registry - will log warning)
    // 4. If all strategies fail, return an error and log a warning

    let avro_value = if let Some(schema) = AVRO_SCHEMA.get().and_then(|s| s.as_ref()) {
        // Use configured schema
        match parse_with_schema(&payload, schema) {
            Ok(value) => {
                logger::log(
                    Level::Debug,
                    "avro-to-json",
                    "Successfully parsed Avro using configured schema",
                );
                Some(Ok(value))
            }
            Err(e) => {
                logger::log(
                    Level::Error,
                    "avro-to-json",
                    &format!("Failed to parse with configured schema: {}", e),
                );
                Some(Err(e))
            }
        }
    } else if let Some(result) = try_parse_container_file(&payload) {
        logger::log(
            Level::Debug,
            "avro-to-json",
            "Detected Object Container File format",
        );
        Some(result)
    } else if let Some(result) = try_parse_single_object(&payload) {
        Some(result)
    } else {
        // Could not determine format
        logger::log(
            Level::Error,
            "avro-to-json",
            "Could not detect Avro format. Supported formats: \
             (1) Object Container File (starts with magic bytes 'Obj\\x01'), \
             (2) Schema-based encoding (provide 'avroSchema' configuration). \
             Verify your Kafka producer is sending valid Avro data. \
             See: https://avro.apache.org/docs/current/spec.html",
        );
        None
    };

    match avro_value {
        Some(Ok(avro_value)) => {
            // Convert Avro to JSON
            let json_value = avro_to_json(&avro_value);

            // Serialize to JSON bytes
            match serde_json::to_vec(&json_value) {
                Ok(json_bytes) => {
                    logger::log(
                        Level::Debug,
                        "avro-to-json",
                        &format!("Successfully converted Avro to JSON ({} bytes)", json_bytes.len()),
                    );

                    result.payload = BufferOrBytes::Bytes(json_bytes);
                    Ok(DataModel::Message(result))
                }
                Err(e) => {
                    logger::log(
                        Level::Error,
                        "avro-to-json",
                        &format!("Failed to serialize JSON: {}", e),
                    );
                    Err(Error {
                        message: format!("JSON serialization error: {}", e),
                    })
                }
            }
        }
        Some(Err(e)) => {
            // Parsing failed
            Err(Error {
                message: format!("Avro parsing error: {}", e),
            })
        }
        None => {
            // Could not detect format - return error
            Err(Error {
                message: format!(
                    "Could not detect Avro format (payload size: {} bytes). \
                     Supported formats: (1) Object Container File (starts with magic bytes 'Obj\\x01'), \
                     (2) Schema-based encoding (provide 'avroSchema' configuration). \
                     Verify your Kafka producer is sending valid Avro data. \
                     First 10 bytes (hex): {:02X?}",
                    payload.len(),
                    &payload.iter().take(10).copied().collect::<Vec<u8>>()
                ),
            })
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use apache_avro::types::Value as AvroValue;

    // --- base64_encode tests ---

    #[test]
    fn base64_empty_input() {
        assert_eq!(base64_encode(b""), "");
    }

    #[test]
    fn base64_rfc4648_vectors() {
        // RFC 4648 Section 10 test vectors
        assert_eq!(base64_encode(b"f"), "Zg==");
        assert_eq!(base64_encode(b"fo"), "Zm8=");
        assert_eq!(base64_encode(b"foo"), "Zm9v");
        assert_eq!(base64_encode(b"foob"), "Zm9vYg==");
        assert_eq!(base64_encode(b"fooba"), "Zm9vYmE=");
        assert_eq!(base64_encode(b"foobar"), "Zm9vYmFy");
    }

    #[test]
    fn base64_binary_data() {
        assert_eq!(base64_encode(&[0x00, 0xFF, 0x80]), "AP+A");
    }

    // --- avro_to_json core variant tests ---

    #[test]
    fn avro_null_to_json() {
        assert_eq!(avro_to_json(&AvroValue::Null), serde_json::Value::Null);
    }

    #[test]
    fn avro_primitives_to_json() {
        assert_eq!(avro_to_json(&AvroValue::Boolean(true)), json!(true));
        assert_eq!(avro_to_json(&AvroValue::Int(42)), json!(42));
        assert_eq!(avro_to_json(&AvroValue::Long(123456789)), json!(123456789));
        assert_eq!(avro_to_json(&AvroValue::Float(3.14)), json!(3.14_f32));
        assert_eq!(avro_to_json(&AvroValue::Double(2.718)), json!(2.718));
    }

    #[test]
    fn avro_string_to_json() {
        assert_eq!(
            avro_to_json(&AvroValue::String("hello".to_string())),
            json!("hello")
        );
    }

    #[test]
    fn avro_bytes_utf8_to_json() {
        assert_eq!(
            avro_to_json(&AvroValue::Bytes(b"text".to_vec())),
            json!("text")
        );
    }

    #[test]
    fn avro_bytes_binary_to_json() {
        // Non-UTF8 bytes should base64 encode
        let binary = vec![0x00, 0xFF, 0x80];
        let result = avro_to_json(&AvroValue::Bytes(binary));
        assert_eq!(result, json!("AP+A"));
    }

    #[test]
    fn avro_record_to_json() {
        let record = AvroValue::Record(vec![
            ("name".to_string(), AvroValue::String("test".to_string())),
            ("count".to_string(), AvroValue::Int(42)),
        ]);
        let json = avro_to_json(&record);
        assert_eq!(json["name"], "test");
        assert_eq!(json["count"], 42);
    }

    #[test]
    fn avro_array_to_json() {
        let arr = AvroValue::Array(vec![AvroValue::Int(1), AvroValue::Int(2), AvroValue::Int(3)]);
        assert_eq!(avro_to_json(&arr), json!([1, 2, 3]));
    }

    #[test]
    fn avro_map_to_json() {
        let mut map = std::collections::HashMap::new();
        map.insert("key".to_string(), AvroValue::String("value".to_string()));
        let result = avro_to_json(&AvroValue::Map(map));
        assert_eq!(result["key"], "value");
    }

    #[test]
    fn avro_union_null_to_json() {
        let union_val = AvroValue::Union(0, Box::new(AvroValue::Null));
        assert_eq!(avro_to_json(&union_val), serde_json::Value::Null);
    }

    #[test]
    fn avro_union_string_to_json() {
        let union_val = AvroValue::Union(1, Box::new(AvroValue::String("data".to_string())));
        assert_eq!(avro_to_json(&union_val), json!("data"));
    }

    #[test]
    fn avro_enum_to_json() {
        let enum_val = AvroValue::Enum(0, "ACTIVE".to_string());
        assert_eq!(avro_to_json(&enum_val), json!("ACTIVE"));
    }

    #[test]
    fn avro_uuid_to_json() {
        let uuid = uuid::Uuid::parse_str("550e8400-e29b-41d4-a716-446655440000").unwrap();
        assert_eq!(
            avro_to_json(&AvroValue::Uuid(uuid)),
            json!("550e8400-e29b-41d4-a716-446655440000")
        );
    }

    #[test]
    fn avro_timestamp_types_to_json() {
        assert_eq!(avro_to_json(&AvroValue::Date(19000)), json!(19000));
        assert_eq!(avro_to_json(&AvroValue::TimeMillis(43200000)), json!(43200000));
        assert_eq!(avro_to_json(&AvroValue::TimeMicros(43200000000)), json!(43200000000_i64));
        assert_eq!(avro_to_json(&AvroValue::TimestampMillis(1700000000000)), json!(1700000000000_i64));
        assert_eq!(avro_to_json(&AvroValue::TimestampMicros(1700000000000000)), json!(1700000000000000_i64));
    }

    // --- Regression tests for R01 (Decimal) and R02 (Duration) ---

    #[test]
    fn avro_decimal_to_json_positive() {
        // Decimal(42) = big-endian bytes [0x2A]
        let decimal = apache_avro::Decimal::from(vec![0x2A]);
        assert_eq!(avro_to_json(&AvroValue::Decimal(decimal)), json!("42"));
    }

    #[test]
    fn avro_decimal_to_json_negative() {
        // Decimal(-1) = big-endian two's complement [0xFF]
        let decimal = apache_avro::Decimal::from(vec![0xFF]);
        assert_eq!(avro_to_json(&AvroValue::Decimal(decimal)), json!("-1"));
    }

    #[test]
    fn avro_decimal_to_json_zero() {
        let decimal = apache_avro::Decimal::from(vec![0x00]);
        assert_eq!(avro_to_json(&AvroValue::Decimal(decimal)), json!("0"));
    }

    #[test]
    fn avro_decimal_empty_bytes() {
        let decimal = apache_avro::Decimal::from(Vec::<u8>::new());
        assert_eq!(avro_to_json(&AvroValue::Decimal(decimal)), json!("0"));
    }

    #[test]
    fn avro_decimal_exceeds_json_safe_integer() {
        // 2^53 + 1 = 9007199254740993, exceeds JSON safe integer range
        // Big-endian bytes: 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01
        let decimal = apache_avro::Decimal::from(vec![0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]);
        assert_eq!(
            avro_to_json(&AvroValue::Decimal(decimal)),
            json!("9007199254740993")
        );
    }

    #[test]
    fn avro_decimal_max_i128() {
        // i128::MAX = 170141183460469231731687303715884105727
        // 16 bytes: 0x7F followed by fifteen 0xFF bytes
        let decimal = apache_avro::Decimal::from(vec![
            0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        ]);
        assert_eq!(
            avro_to_json(&AvroValue::Decimal(decimal)),
            json!("170141183460469231731687303715884105727")
        );
    }

    #[test]
    fn avro_decimal_min_i128() {
        // i128::MIN = -170141183460469231731687303715884105728
        // 16 bytes: 0x80 followed by fifteen 0x00 bytes
        let decimal = apache_avro::Decimal::from(vec![
            0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        ]);
        assert_eq!(
            avro_to_json(&AvroValue::Decimal(decimal)),
            json!("-170141183460469231731687303715884105728")
        );
    }

    #[test]
    fn avro_duration_to_json() {
        let duration = apache_avro::Duration::new(
            apache_avro::Months::new(12),
            apache_avro::Days::new(30),
            apache_avro::Millis::new(5000),
        );
        let result = avro_to_json(&AvroValue::Duration(duration));
        assert_eq!(result["months"], 12);
        assert_eq!(result["days"], 30);
        assert_eq!(result["millis"], 5000);
    }

    #[test]
    fn avro_duration_zero_values() {
        let duration = apache_avro::Duration::new(
            apache_avro::Months::new(0),
            apache_avro::Days::new(0),
            apache_avro::Millis::new(0),
        );
        let result = avro_to_json(&AvroValue::Duration(duration));
        assert_eq!(result, json!({"months": 0, "days": 0, "millis": 0}));
    }

    #[test]
    fn avro_bigdecimal_to_json() {
        use apache_avro::BigDecimal;
        use std::str::FromStr;

        let bd = BigDecimal::from_str("123.456").unwrap();
        let result = avro_to_json(&AvroValue::BigDecimal(bd));
        assert_eq!(result, json!("123.456"));
    }

    #[test]
    fn avro_bigdecimal_large_value() {
        use apache_avro::BigDecimal;
        use std::str::FromStr;

        let bd = BigDecimal::from_str("999999999999999999.123456789").unwrap();
        let result = avro_to_json(&AvroValue::BigDecimal(bd));
        assert_eq!(result, json!("999999999999999999.123456789"));
    }

    #[test]
    fn avro_bigdecimal_negative() {
        use apache_avro::BigDecimal;
        use std::str::FromStr;

        let bd = BigDecimal::from_str("-42.5").unwrap();
        let result = avro_to_json(&AvroValue::BigDecimal(bd));
        assert_eq!(result, json!("-42.5"));
    }
}
