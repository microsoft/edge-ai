//! Message schema derivation and destination forwarding for POST response data.
//!
//! The SDK requires a [`MessageSchema`] to be reported at least once before any
//! [`Data`] can be forwarded to a data operation's configured destination(s).
//! [`SchemaCache`] tracks the last reported response content type so the schema is
//! only re-derived and re-reported when it actually changes, avoiding redundant
//! schema registry writes on every tick.

use azure_iot_operations_connector::base_connector::managed_azure_device_registry::DataOperationClient;
use azure_iot_operations_connector::data_processor::derived_json;
use azure_iot_operations_connector::{Data, MessageSchema, MessageSchemaBuilder};
use azure_iot_operations_services::schema_registry::{Format, SchemaType};

/// Tracks whether the response content type observed on the most recent successful
/// tick still matches the last reported message schema.
#[derive(Debug, Default)]
pub struct SchemaCache {
    last_content_type: Option<String>,
}

impl SchemaCache {
    pub fn new() -> Self {
        Self::default()
    }

    fn needs_update(&self, content_type: &str) -> bool {
        self.last_content_type.as_deref() != Some(content_type)
    }

    fn record(&mut self, content_type: &str) {
        self.last_content_type = Some(content_type.to_string());
    }
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
    if schema_cache.needs_update(&content_type) {
        let schema = build_schema(&payload, &content_type);
        data_operation_client
            .report_message_schema_if_modified(move |_current| Some(schema.clone()))
            .await
            .map_err(|err| format!("failed to report message schema: {err}"))?;
        schema_cache.record(&content_type);
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
        assert!(cache.needs_update("application/json"));
    }

    #[test]
    fn schema_cache_skips_update_when_content_type_unchanged() {
        let mut cache = SchemaCache::new();
        cache.record("application/json");
        assert!(!cache.needs_update("application/json"));
    }

    #[test]
    fn schema_cache_requires_update_when_content_type_changes() {
        let mut cache = SchemaCache::new();
        cache.record("application/json");
        assert!(cache.needs_update("text/plain"));
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
