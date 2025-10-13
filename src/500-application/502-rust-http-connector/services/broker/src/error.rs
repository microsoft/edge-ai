use crate::json_validator::validate_instance;
use jsonschema::{Draft, JSONSchema};
use serde_json::Value;

pub fn parse_json_schema(schema_str: &str) -> Result<Value, String> {
    // Parse the schema string
    let schema: Value = serde_json::from_str(schema_str).map_err(|e| e.to_string())?;
    Ok(schema)
}

pub fn validate_json(schema: Value, instance: Value, device_id: &str) -> Result<String, String> {
    // Compile the schema and validate the instance
    let compiled = JSONSchema::options()
        .with_draft(Draft::Draft7)
        .compile(&schema)
        .map_err(|e| e.to_string())?;

    validate_instance(&compiled, instance, device_id)
}
