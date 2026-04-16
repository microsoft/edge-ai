use std::str;

use anyhow::{anyhow, Result};
use serde_json::Value;
use uuid::Uuid;

#[derive(Debug, Clone, Copy)]
pub enum CorrelationSource {
    Payload,
    Generated(CorrelationFallbackReason),
}

#[derive(Debug, Clone, Copy)]
pub enum CorrelationFallbackReason {
    EmptyPayload,
    InvalidUtf8,
    InvalidJson,
    MissingField,
    UnsupportedType,
}

#[derive(Debug, Clone)]
pub struct CorrelationId {
    pub value: String,
    pub source: CorrelationSource,
}

impl CorrelationId {
    pub fn generated(reason: CorrelationFallbackReason) -> Self {
        Self {
            value: Uuid::new_v4().to_string(),
            source: CorrelationSource::Generated(reason),
        }
    }

    pub fn from_payload(value: String) -> Self {
        Self {
            value,
            source: CorrelationSource::Payload,
        }
    }

    pub fn is_generated(&self) -> bool {
        matches!(self.source, CorrelationSource::Generated(_))
    }

    pub fn fallback_reason(&self) -> Option<&'static str> {
        match self.source {
            CorrelationSource::Generated(reason) => Some(reason.as_str()),
            CorrelationSource::Payload => None,
        }
    }
}

impl CorrelationFallbackReason {
    pub fn as_str(self) -> &'static str {
        match self {
            CorrelationFallbackReason::EmptyPayload => "empty_payload",
            CorrelationFallbackReason::InvalidUtf8 => "invalid_utf8",
            CorrelationFallbackReason::InvalidJson => "invalid_json",
            CorrelationFallbackReason::MissingField => "missing_field",
            CorrelationFallbackReason::UnsupportedType => "unsupported_type",
        }
    }
}

pub fn correlation_id_from_payload(
    payload: &[u8],
    field: &str,
    allow_generated: bool,
) -> Result<CorrelationId> {
    if payload.is_empty() {
        return maybe_generate(allow_generated, CorrelationFallbackReason::EmptyPayload);
    }

    let text = match str::from_utf8(payload) {
        Ok(value) => value,
        Err(_) => return maybe_generate(allow_generated, CorrelationFallbackReason::InvalidUtf8),
    };

    let trimmed_field = field.trim();
    if trimmed_field.is_empty() {
        return Err(anyhow!("correlation field name cannot be empty"));
    }

    let segments = trimmed_field
        .split('.')
        .filter(|segment| !segment.is_empty())
        .collect::<Vec<_>>();

    let json = match serde_json::from_str::<Value>(text) {
        Ok(value) => value,
        Err(_) => return maybe_generate(allow_generated, CorrelationFallbackReason::InvalidJson),
    };

    if let Some(value) = locate_value(&json, &segments) {
        if value.is_null() {
            return maybe_generate(allow_generated, CorrelationFallbackReason::MissingField);
        }

        if let Some(str_value) = value.as_str() {
            return Ok(CorrelationId::from_payload(str_value.to_owned()));
        }

        if let Some(bool_value) = value.as_bool() {
            return Ok(CorrelationId::from_payload(bool_value.to_string()));
        }

        if let Some(num) = value.as_i64() {
            return Ok(CorrelationId::from_payload(num.to_string()));
        }

        if let Some(num) = value.as_u64() {
            return Ok(CorrelationId::from_payload(num.to_string()));
        }

        if let Some(num) = value.as_f64() {
            return Ok(CorrelationId::from_payload(num.to_string()));
        }

        return maybe_generate(allow_generated, CorrelationFallbackReason::UnsupportedType);
    }

    maybe_generate(allow_generated, CorrelationFallbackReason::MissingField)
}

fn locate_value<'a>(value: &'a Value, path: &[&str]) -> Option<&'a Value> {
    if path.is_empty() {
        return None;
    }

    let mut current = value;
    for segment in path {
        current = current.get(segment)?;
    }
    Some(current)
}

fn maybe_generate(
    allow_generated: bool,
    reason: CorrelationFallbackReason,
) -> Result<CorrelationId> {
    if allow_generated {
        Ok(CorrelationId::generated(reason))
    } else {
        Err(anyhow!(
            "correlation ID unavailable and generation disabled ({})",
            reason.as_str()
        ))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn from_payload_sets_source_and_value() {
        let id = CorrelationId::from_payload("abc-123".to_owned());
        assert_eq!(id.value, "abc-123");
        assert!(!id.is_generated());
        assert!(id.fallback_reason().is_none());
    }

    #[test]
    fn generated_sets_source_and_reason() {
        let id = CorrelationId::generated(CorrelationFallbackReason::EmptyPayload);
        assert!(id.is_generated());
        assert_eq!(id.fallback_reason(), Some("empty_payload"));
        assert!(!id.value.is_empty());
    }

    #[test]
    fn fallback_reason_strings() {
        assert_eq!(CorrelationFallbackReason::EmptyPayload.as_str(), "empty_payload");
        assert_eq!(CorrelationFallbackReason::InvalidUtf8.as_str(), "invalid_utf8");
        assert_eq!(CorrelationFallbackReason::InvalidJson.as_str(), "invalid_json");
        assert_eq!(CorrelationFallbackReason::MissingField.as_str(), "missing_field");
        assert_eq!(CorrelationFallbackReason::UnsupportedType.as_str(), "unsupported_type");
    }

    #[test]
    fn empty_payload_generates_id() {
        let result = correlation_id_from_payload(b"", "id", true).unwrap();
        assert!(result.is_generated());
        assert_eq!(result.fallback_reason(), Some("empty_payload"));
    }

    #[test]
    fn empty_payload_errors_when_generation_disabled() {
        let err = correlation_id_from_payload(b"", "id", false).unwrap_err();
        assert!(err.to_string().contains("empty_payload"));
    }

    #[test]
    fn invalid_utf8_generates_id() {
        let payload: &[u8] = &[0xFF, 0xFE, 0xFD];
        let result = correlation_id_from_payload(payload, "id", true).unwrap();
        assert!(result.is_generated());
        assert_eq!(result.fallback_reason(), Some("invalid_utf8"));
    }

    #[test]
    fn invalid_utf8_errors_when_generation_disabled() {
        let payload: &[u8] = &[0xFF, 0xFE];
        let err = correlation_id_from_payload(payload, "id", false).unwrap_err();
        assert!(err.to_string().contains("invalid_utf8"));
    }

    #[test]
    fn empty_field_name_returns_error() {
        let payload = br#"{"id":"abc"}"#;
        let err = correlation_id_from_payload(payload, "", true).unwrap_err();
        assert!(err.to_string().contains("correlation field name cannot be empty"));
    }

    #[test]
    fn whitespace_only_field_name_returns_error() {
        let payload = br#"{"id":"abc"}"#;
        let err = correlation_id_from_payload(payload, "  ", true).unwrap_err();
        assert!(err.to_string().contains("correlation field name cannot be empty"));
    }

    #[test]
    fn invalid_json_generates_id() {
        let payload = b"not-json";
        let result = correlation_id_from_payload(payload, "id", true).unwrap();
        assert!(result.is_generated());
        assert_eq!(result.fallback_reason(), Some("invalid_json"));
    }

    #[test]
    fn invalid_json_errors_when_generation_disabled() {
        let payload = b"not-json";
        let err = correlation_id_from_payload(payload, "id", false).unwrap_err();
        assert!(err.to_string().contains("invalid_json"));
    }

    #[test]
    fn missing_field_generates_id() {
        let payload = br#"{"other":"value"}"#;
        let result = correlation_id_from_payload(payload, "id", true).unwrap();
        assert!(result.is_generated());
        assert_eq!(result.fallback_reason(), Some("missing_field"));
    }

    #[test]
    fn null_field_generates_id() {
        let payload = br#"{"id":null}"#;
        let result = correlation_id_from_payload(payload, "id", true).unwrap();
        assert!(result.is_generated());
        assert_eq!(result.fallback_reason(), Some("missing_field"));
    }

    #[test]
    fn extracts_string_value() {
        let payload = br#"{"id":"trace-42"}"#;
        let result = correlation_id_from_payload(payload, "id", true).unwrap();
        assert!(!result.is_generated());
        assert_eq!(result.value, "trace-42");
    }

    #[test]
    fn extracts_bool_value() {
        let payload = br#"{"flag":true}"#;
        let result = correlation_id_from_payload(payload, "flag", true).unwrap();
        assert!(!result.is_generated());
        assert_eq!(result.value, "true");
    }

    #[test]
    fn extracts_integer_value() {
        let payload = br#"{"seq":99}"#;
        let result = correlation_id_from_payload(payload, "seq", true).unwrap();
        assert!(!result.is_generated());
        assert_eq!(result.value, "99");
    }

    #[test]
    fn extracts_float_value() {
        let payload = br#"{"temp":23.5}"#;
        let result = correlation_id_from_payload(payload, "temp", true).unwrap();
        assert!(!result.is_generated());
        assert_eq!(result.value, "23.5");
    }

    #[test]
    fn unsupported_type_array_generates_id() {
        let payload = br#"{"data":[1,2,3]}"#;
        let result = correlation_id_from_payload(payload, "data", true).unwrap();
        assert!(result.is_generated());
        assert_eq!(result.fallback_reason(), Some("unsupported_type"));
    }

    #[test]
    fn unsupported_type_object_generates_id() {
        let payload = br#"{"data":{"nested":"obj"}}"#;
        let result = correlation_id_from_payload(payload, "data", true).unwrap();
        assert!(result.is_generated());
        assert_eq!(result.fallback_reason(), Some("unsupported_type"));
    }

    #[test]
    fn nested_field_path() {
        let payload = br#"{"meta":{"trace":{"id":"deep-123"}}}"#;
        let result = correlation_id_from_payload(payload, "meta.trace.id", true).unwrap();
        assert!(!result.is_generated());
        assert_eq!(result.value, "deep-123");
    }

    #[test]
    fn nested_field_missing_intermediate() {
        let payload = br#"{"meta":{}}"#;
        let result = correlation_id_from_payload(payload, "meta.trace.id", true).unwrap();
        assert!(result.is_generated());
        assert_eq!(result.fallback_reason(), Some("missing_field"));
    }

    #[test]
    fn locate_value_empty_path_returns_none() {
        let json: Value = serde_json::from_str(r#"{"a":1}"#).unwrap();
        assert!(locate_value(&json, &[]).is_none());
    }

    #[test]
    fn locate_value_single_segment() {
        let json: Value = serde_json::from_str(r#"{"key":"val"}"#).unwrap();
        let found = locate_value(&json, &["key"]).unwrap();
        assert_eq!(found.as_str(), Some("val"));
    }

    #[test]
    fn locate_value_multi_segment() {
        let json: Value = serde_json::from_str(r#"{"a":{"b":{"c":42}}}"#).unwrap();
        let found = locate_value(&json, &["a", "b", "c"]).unwrap();
        assert_eq!(found.as_i64(), Some(42));
    }
}
