//! Message schema derivation and destination forwarding for POST response data.
//!
//! The SDK requires a [`MessageSchema`] to be reported at least once before any
//! [`Data`] can be forwarded to a data operation's configured destination(s).
//! [`SchemaCache`] tracks the last reported schema identity so the schema is only
//! re-reported when its content, format, or type changes, avoiding redundant schema
//! registry writes on every tick.

use azure_iot_operations_connector::base_connector::managed_azure_device_registry::DataOperationClient;
use azure_iot_operations_connector::data_processor::derived_json;
use azure_iot_operations_connector::{Data, MessageSchema, MessageSchemaBuilder};
use azure_iot_operations_services::schema_registry::{Format, SchemaType};
use sha2::{Digest, Sha256};

/// Tracks whether the schema derived on the most recent successful tick still
/// matches the last reported message schema.
#[derive(Debug, Default)]
pub struct SchemaCache {
    last_fingerprint: Option<[u8; 32]>,
}

impl SchemaCache {
    pub fn new() -> Self {
        Self::default()
    }

    fn needs_update(&self, schema: &MessageSchema) -> bool {
        self.last_fingerprint != Some(schema_fingerprint(schema))
    }

    fn record(&mut self, schema: &MessageSchema) {
        self.last_fingerprint = Some(schema_fingerprint(schema));
    }
}

fn schema_fingerprint(schema: &MessageSchema) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(schema.schema_content.as_bytes());
    hasher.update([0]);
    hasher.update(format!("{:?}", schema.format).as_bytes());
    hasher.update([0]);
    hasher.update(format!("{:?}", schema.schema_type).as_bytes());
    hasher.finalize().into()
}

/// Derives a [`MessageSchema`] for a response payload: a real JSON Schema when the
/// payload parses as JSON, otherwise a generic opaque schema describing an
/// arbitrary textual body of the given content type. The v1.0 contract accepts any
/// allow-listed textual response, not only JSON, so a fallback is required.
fn build_schema(payload: &[u8], content_type: &str) -> MessageSchema {
    let data = Data {
        payload: payload.to_vec(),
        content_type: content_type.to_string(),
        custom_user_data: Vec::new(),
        timestamp: None,
    };
    derived_json::create_schema(&data).unwrap_or_else(|_| opaque_schema(content_type))
}

fn opaque_schema(content_type: &str) -> MessageSchema {
    let schema_content = format!(r#"{{"type":"string","contentMediaType":"{content_type}"}}"#);
    MessageSchemaBuilder::default()
        .schema_content(schema_content)
        .format(Format::JsonSchemaDraft07)
        .schema_type(SchemaType::MessageSchema)
        .build()
        .expect("statically constructed opaque schema is always a valid MessageSchema")
}

/// Reports an updated message schema when the response content type has changed
/// since the last successful forward, then forwards the response payload to the
/// data operation's configured destination(s).
pub async fn forward_response(
    data_operation_client: &mut DataOperationClient,
    schema_cache: &mut SchemaCache,
    payload: Vec<u8>,
    content_type: String,
) -> Result<(), String> {
    let schema = build_schema(&payload, &content_type);
    if schema_cache.needs_update(&schema) {
        let schema_to_report = schema.clone();
        data_operation_client
            .report_message_schema_if_modified(move |_current| Some(schema_to_report.clone()))
            .await
            .map_err(|err| format!("failed to report message schema: {err}"))?;
        schema_cache.record(&schema);
    }

    let data = Data {
        payload,
        content_type,
        custom_user_data: Vec::new(),
        timestamp: None,
    };
    data_operation_client
        .forward_data(data)
        .await
        .map_err(|err| format!("failed to forward data to destination: {err}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn schema_cache_requires_update_on_first_use() {
        let cache = SchemaCache::new();
        let schema = build_schema(br#"{"value": 1}"#, "application/json");
        assert!(cache.needs_update(&schema));
    }

    #[test]
    fn schema_cache_skips_update_when_content_type_unchanged() {
        let mut cache = SchemaCache::new();
        let schema = build_schema(br#"{"value": 1}"#, "application/json");
        cache.record(&schema);
        assert!(!cache.needs_update(&schema));
    }

    #[test]
    fn schema_cache_requires_update_when_content_type_changes() {
        let mut cache = SchemaCache::new();
        let json_schema = build_schema(br#"{"value": 1}"#, "application/json");
        let text_schema = build_schema(b"plain text body", "text/plain");
        cache.record(&json_schema);
        assert!(cache.needs_update(&text_schema));
    }

    #[test]
    fn schema_cache_requires_update_when_payload_shape_changes() {
        let mut cache = SchemaCache::new();
        let first = build_schema(br#"{"value": 1}"#, "application/json");
        let second = build_schema(br#"{"value": "one"}"#, "application/json");
        cache.record(&first);
        assert!(cache.needs_update(&second));
    }

    #[test]
    fn builds_json_schema_for_json_payload() {
        let schema = build_schema(br#"{"value": 1}"#, "application/json");
        assert_eq!(schema.format, Format::JsonSchemaDraft07);
    }

    #[test]
    fn builds_opaque_schema_for_non_json_textual_payload() {
        let schema = build_schema(b"plain text body", "text/plain");
        assert!(schema.schema_content.contains("text/plain"));
    }
}
