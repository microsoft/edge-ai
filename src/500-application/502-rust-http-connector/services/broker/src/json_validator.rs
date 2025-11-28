use crate::error_handler::ErrorAlert;
use jsonschema::Validator;
use serde_json::Value;

pub fn validate_instance(
    compiled: &Validator,
    instance: Value,
    device_id: &str,
) -> Result<String, String> {
    if compiled.is_valid(&instance) {
        Ok("Validation successful!".to_string())
    } else {
        let errors = compiled.iter_errors(&instance);
        let error_messages: Vec<String> = errors
            .map(|error| {
                format!(
                    "JSON schema validation error: {}. Instance path: {}.",
                    error, error.instance_path
                )
            })
            .collect();
        let alert = ErrorAlert::generate_alert(
            device_id.to_string(),
            "004".to_string(),
            error_messages.join("; "),
        );
        Err(alert)
    }
}
