//! Parsing and validation for the `EdgeAi.HttpPost` v1.0 dataset configuration
//! contract and inbound endpoint address.
//!
//! Field names mirror the `datasetConfigurationSchema` published in
//! `connector-metadata/connector-metadata.json` (`schemaVersion`, `request.body`,
//! `request.contentType`, `request.idempotent`, `samplingIntervalMs`).

use serde::Deserialize;
use url::Url;

use crate::policy;

/// Dataset configuration schema version accepted by this connector (v1.0 contract).
pub const DATASET_CONFIGURATION_SCHEMA_VERSION: u32 = 1;

/// Maximum accepted request body length in bytes. This is a ceiling only; the
/// contract requires supporting bodies of at least 10,000 characters, it does not
/// impose a per-request minimum.
pub const MAX_REQUEST_BODY_BYTES: usize = 262_144;

/// Minimum accepted sampling interval, matching `datasetConfigurationSchema`.
pub const MIN_SAMPLING_INTERVAL_MS: u32 = 100;

/// Projected dataset configuration, parsed from the Device Registry dataset's
/// `dataset_configuration` JSON.
#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DatasetConfiguration {
    pub schema_version: u32,
    pub request: RequestConfiguration,
    pub sampling_interval_ms: u32,
}

/// The request body, content type, and retry policy owned by the dataset
/// configuration.
#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RequestConfiguration {
    pub body: String,
    pub content_type: String,
    /// Whether this POST request is safe to retry once after a failed send.
    /// Defaults to `false`, matching the contract's default single-attempt
    /// semantics for non-idempotent requests.
    #[serde(default)]
    pub idempotent: bool,
}

/// A validated inbound endpoint address, restricted to `http`/`https` with a
/// non-empty host, and resolved against the dataset's relative `data_source` path
/// (see [`policy::resolve_request_url`]). Does not perform SSRF host-allowlisting
/// beyond same-origin enforcement.
#[derive(Debug, Clone)]
pub struct EndpointPolicy {
    pub address: Url,
}

/// An immutable, fully validated plan combining a resolved request address with an
/// accepted dataset configuration. Only produced by [`compile_plan`] after all
/// validation succeeds.
#[derive(Debug, Clone)]
pub struct ObservationPlan {
    pub endpoint: EndpointPolicy,
    pub dataset: DatasetConfiguration,
}

/// Parses the raw `dataset_configuration` JSON string into a [`DatasetConfiguration`].
pub fn parse_dataset_configuration(raw: &str) -> Result<DatasetConfiguration, String> {
    serde_json::from_str(raw).map_err(|err| format!("invalid dataset configuration JSON: {err}"))
}

/// Validates a parsed [`DatasetConfiguration`] against the v1.0 contract: schema
/// version, textual content type, request body byte ceiling, and sampling interval
/// floor.
pub fn validate_dataset_configuration(config: &DatasetConfiguration) -> Result<(), String> {
    if config.schema_version != DATASET_CONFIGURATION_SCHEMA_VERSION {
        return Err(format!(
            "unsupported dataset configuration schemaVersion {} (expected {})",
            config.schema_version, DATASET_CONFIGURATION_SCHEMA_VERSION
        ));
    }
    if config.request.content_type.trim().is_empty() {
        return Err("request.contentType must not be empty".to_string());
    }
    if !policy::is_textual_mime(&config.request.content_type) {
        return Err(format!(
            "request.contentType '{}' is not an accepted textual MIME type",
            config.request.content_type
        ));
    }
    if config.request.body.len() > MAX_REQUEST_BODY_BYTES {
        return Err(format!(
            "request.body length {} bytes exceeds the {} byte ceiling",
            config.request.body.len(),
            MAX_REQUEST_BODY_BYTES
        ));
    }
    if config.sampling_interval_ms < MIN_SAMPLING_INTERVAL_MS {
        return Err(format!(
            "samplingIntervalMs {} is below the minimum of {}",
            config.sampling_interval_ms, MIN_SAMPLING_INTERVAL_MS
        ));
    }
    Ok(())
}

/// Parses and validates a base inbound endpoint address string. Requires an `http`
/// or `https` scheme and a non-empty host. Same-origin enforcement against a
/// dataset's relative path happens in [`compile_plan`] via
/// [`policy::resolve_request_url`].
pub fn parse_endpoint_address(address: &str) -> Result<Url, String> {
    let url = Url::parse(address).map_err(|err| format!("invalid endpoint address: {err}"))?;
    if url.scheme() != "http" && url.scheme() != "https" {
        return Err(format!(
            "endpoint address scheme '{}' is not http or https",
            url.scheme()
        ));
    }
    match url.host_str() {
        Some(host) if !host.is_empty() => Ok(url),
        _ => Err("endpoint address must include a non-empty host".to_string()),
    }
}

/// Parses and validates a base endpoint address, an optional relative dataset
/// `data_source` path, and a raw dataset configuration together, producing an
/// immutable [`ObservationPlan`] only if all three succeed.
pub fn compile_plan(
    endpoint_address: &str,
    data_source: Option<&str>,
    raw_dataset_configuration: &str,
) -> Result<ObservationPlan, String> {
    let base_address = parse_endpoint_address(endpoint_address)?;
    let resolved_address = policy::resolve_request_url(&base_address, data_source)?;
    let dataset = parse_dataset_configuration(raw_dataset_configuration)?;
    validate_dataset_configuration(&dataset)?;
    Ok(ObservationPlan {
        endpoint: EndpointPolicy {
            address: resolved_address,
        },
        dataset,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn valid_dataset_json() -> String {
        r#"{
            "schemaVersion": 1,
            "request": { "body": "hello world", "contentType": "application/json" },
            "samplingIntervalMs": 1000
        }"#
        .to_string()
    }

    #[test]
    fn parses_valid_dataset_configuration() {
        let config = parse_dataset_configuration(&valid_dataset_json()).unwrap();
        validate_dataset_configuration(&config).unwrap();
        assert_eq!(config.schema_version, 1);
        assert_eq!(config.request.body, "hello world");
        assert_eq!(config.sampling_interval_ms, 1000);
    }

    #[test]
    fn rejects_wrong_schema_version() {
        let raw = valid_dataset_json().replace("\"schemaVersion\": 1", "\"schemaVersion\": 2");
        let config = parse_dataset_configuration(&raw).unwrap();
        assert!(validate_dataset_configuration(&config).is_err());
    }

    #[test]
    fn rejects_empty_content_type() {
        let raw = valid_dataset_json().replace("\"application/json\"", "\"\"");
        let config = parse_dataset_configuration(&raw).unwrap();
        assert!(validate_dataset_configuration(&config).is_err());
    }

    #[test]
    fn rejects_binary_content_type() {
        let raw =
            valid_dataset_json().replace("\"application/json\"", "\"application/octet-stream\"");
        let config = parse_dataset_configuration(&raw).unwrap();
        assert!(validate_dataset_configuration(&config).is_err());
    }

    #[test]
    fn accepts_text_wildcard_content_type_with_parameters() {
        let raw =
            valid_dataset_json().replace("\"application/json\"", "\"text/plain; charset=utf-8\"");
        let config = parse_dataset_configuration(&raw).unwrap();
        validate_dataset_configuration(&config).unwrap();
    }

    #[test]
    fn rejects_body_over_byte_ceiling() {
        let oversized_body = "a".repeat(MAX_REQUEST_BODY_BYTES + 1);
        let raw = valid_dataset_json().replace("\"hello world\"", &format!("\"{oversized_body}\""));
        let config = parse_dataset_configuration(&raw).unwrap();
        assert!(validate_dataset_configuration(&config).is_err());
    }

    #[test]
    fn rejects_sampling_interval_below_minimum() {
        let raw = valid_dataset_json()
            .replace("\"samplingIntervalMs\": 1000", "\"samplingIntervalMs\": 1");
        let config = parse_dataset_configuration(&raw).unwrap();
        assert!(validate_dataset_configuration(&config).is_err());
    }

    #[test]
    fn rejects_malformed_json() {
        assert!(parse_dataset_configuration("not json").is_err());
    }

    #[test]
    fn parses_valid_http_and_https_endpoint_addresses() {
        assert!(parse_endpoint_address("http://example.local:8080/path").is_ok());
        assert!(parse_endpoint_address("https://example.local/path").is_ok());
    }

    #[test]
    fn rejects_non_http_scheme() {
        assert!(parse_endpoint_address("ftp://example.local/path").is_err());
    }

    #[test]
    fn rejects_address_without_host() {
        // The `url` crate rejects an empty host for special schemes (http/https) at
        // parse time itself, before this function's own host_str() check runs.
        assert!(parse_endpoint_address("http://").is_err());
    }

    #[test]
    fn rejects_unparseable_address() {
        assert!(parse_endpoint_address("not a url").is_err());
    }

    #[test]
    fn compile_plan_succeeds_for_valid_inputs() {
        let plan = compile_plan("https://example.local/path", None, &valid_dataset_json()).unwrap();
        assert_eq!(plan.endpoint.address.scheme(), "https");
        assert_eq!(plan.dataset.request.body, "hello world");
    }

    #[test]
    fn compile_plan_resolves_relative_data_source() {
        let plan = compile_plan(
            "https://example.local/base",
            Some("/api/v1/query"),
            &valid_dataset_json(),
        )
        .unwrap();
        assert_eq!(
            plan.endpoint.address.as_str(),
            "https://example.local/api/v1/query"
        );
    }

    #[test]
    fn compile_plan_fails_when_endpoint_invalid() {
        assert!(compile_plan("not a url", None, &valid_dataset_json()).is_err());
    }

    #[test]
    fn compile_plan_fails_when_data_source_changes_origin() {
        assert!(compile_plan(
            "https://example.local/base",
            Some("https://other.local/steal"),
            &valid_dataset_json()
        )
        .is_err());
    }

    #[test]
    fn compile_plan_fails_when_dataset_invalid() {
        let raw = valid_dataset_json().replace("\"schemaVersion\": 1", "\"schemaVersion\": 9");
        assert!(compile_plan("https://example.local/path", None, &raw).is_err());
    }

    #[test]
    fn defaults_idempotent_to_false_when_absent() {
        let config = parse_dataset_configuration(&valid_dataset_json()).unwrap();
        assert!(!config.request.idempotent);
    }

    #[test]
    fn parses_explicit_idempotent_flag() {
        let raw = valid_dataset_json().replace(
            "\"contentType\": \"application/json\"",
            "\"contentType\": \"application/json\", \"idempotent\": true",
        );
        let config = parse_dataset_configuration(&raw).unwrap();
        assert!(config.request.idempotent);
    }
}
