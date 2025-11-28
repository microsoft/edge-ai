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
