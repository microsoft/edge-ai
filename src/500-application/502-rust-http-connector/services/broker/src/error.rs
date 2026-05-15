use crate::json_validator::validate_instance;
use jsonschema::{Draft, Validator};
use serde_json::Value;

pub fn parse_json_schema(schema_str: &str) -> Result<Value, String> {
    // Parse the schema string
    let schema: Value = serde_json::from_str(schema_str).map_err(|e| e.to_string())?;
    Ok(schema)
}

pub fn validate_json(schema: Value, instance: Value, device_id: &str) -> Result<String, String> {
    // Compile the schema and validate the instance
    let compiled = Validator::options()
        .with_draft(Draft::Draft7)
        .build(&schema)
        .map_err(|e| e.to_string())?;

    validate_instance(&compiled, instance, device_id)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn simple_schema() -> Value {
        serde_json::json!({
            "type": "object",
            "properties": {
                "temperature": { "type": "number" }
            },
            "required": ["temperature"]
        })
    }

    #[test]
    fn parse_json_schema_valid() {
        let schema = parse_json_schema(r#"{"type": "object"}"#);
        assert!(schema.is_ok());
        assert_eq!(schema.unwrap()["type"], "object");
    }

    #[test]
    fn parse_json_schema_invalid() {
        let result = parse_json_schema("not json");
        assert!(result.is_err());
    }

    #[test]
    fn validate_json_matching_instance() {
        let schema = simple_schema();
        let instance = serde_json::json!({"temperature": 42.5});
        let result = validate_json(schema, instance, "dev-1");
        assert_eq!(result.unwrap(), "Validation successful!");
    }

    #[test]
    fn validate_json_missing_required_field() {
        let schema = simple_schema();
        let instance = serde_json::json!({});
        let result = validate_json(schema, instance, "dev-1");
        assert!(result.is_err());
        let err_json: Value = serde_json::from_str(&result.unwrap_err()).unwrap();
        assert_eq!(err_json["deviceId"], "dev-1");
        assert_eq!(err_json["errorCode"], "004");
        assert!(err_json["errorMessage"].as_str().unwrap().contains("required"));
    }

    #[test]
    fn validate_json_wrong_type() {
        let schema = simple_schema();
        let instance = serde_json::json!({"temperature": "hot"});
        let result = validate_json(schema, instance, "sensor-5");
        assert!(result.is_err());
        let err_json: Value = serde_json::from_str(&result.unwrap_err()).unwrap();
        assert_eq!(err_json["deviceId"], "sensor-5");
        assert!(err_json["errorMessage"].as_str().unwrap().contains("type"));
    }
}
