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

#[cfg(test)]
mod tests {
    use super::*;
    use jsonschema::Draft;

    fn build_validator(schema_json: &serde_json::Value) -> Validator {
        Validator::options()
            .with_draft(Draft::Draft7)
            .build(schema_json)
            .unwrap()
    }

    #[test]
    fn valid_instance_returns_ok() {
        let schema = serde_json::json!({"type": "object"});
        let compiled = build_validator(&schema);
        let result = validate_instance(&compiled, serde_json::json!({}), "d1");
        assert_eq!(result.unwrap(), "Validation successful!");
    }

    #[test]
    fn invalid_instance_returns_error_alert_json() {
        let schema = serde_json::json!({
            "type": "object",
            "properties": { "x": { "type": "number" } },
            "required": ["x"]
        });
        let compiled = build_validator(&schema);
        let result = validate_instance(&compiled, serde_json::json!({}), "sensor-7");
        assert!(result.is_err());
        let alert: serde_json::Value = serde_json::from_str(&result.unwrap_err()).unwrap();
        assert_eq!(alert["deviceId"], "sensor-7");
        assert_eq!(alert["errorCode"], "004");
        assert!(alert["errorMessage"].as_str().unwrap().contains("required"));
    }

    #[test]
    fn multiple_errors_joined_with_semicolon() {
        let schema = serde_json::json!({
            "type": "object",
            "properties": {
                "a": { "type": "number" },
                "b": { "type": "number" }
            },
            "required": ["a", "b"]
        });
        let compiled = build_validator(&schema);
        let result = validate_instance(
            &compiled,
            serde_json::json!({"a": "wrong", "b": "wrong"}),
            "d2",
        );
        let msg = serde_json::from_str::<serde_json::Value>(&result.unwrap_err())
            .unwrap()["errorMessage"]
            .as_str()
            .unwrap()
            .to_string();
        assert!(msg.contains("; "), "multiple errors should be semicolon-separated");
    }

    #[test]
    fn error_message_includes_instance_path() {
        let schema = serde_json::json!({
            "type": "object",
            "properties": { "val": { "type": "integer" } }
        });
        let compiled = build_validator(&schema);
        let result = validate_instance(
            &compiled,
            serde_json::json!({"val": "text"}),
            "d3",
        );
        let msg = serde_json::from_str::<serde_json::Value>(&result.unwrap_err())
            .unwrap()["errorMessage"]
            .as_str()
            .unwrap()
            .to_string();
        assert!(msg.contains("Instance path:"));
    }
}
