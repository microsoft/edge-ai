use jsonschema::{JSONSchema};
use serde_json::Value;
use crate::error_handler::{ErrorAlert};

pub fn validate_instance(compiled: &JSONSchema, instance: Value, device_id: &str) -> Result<String, String> {
    let result = compiled.validate(&instance);
    if let Err(errors) = result {
        let mut error_messages = Vec::new();
        for error in errors {
            error_messages.push(format!("JSON schema validation error: {}. Instance path: {}.", error, error.instance_path));
        }
        let alert = ErrorAlert::generate_alert(
            device_id.to_string(),
            "004".to_string(),
            error_messages.join("; ")
        );
        Err(alert)
    } else {
        Ok("Validation successful!".to_string())
    }
}
