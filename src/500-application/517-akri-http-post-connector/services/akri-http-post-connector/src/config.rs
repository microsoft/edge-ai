//! Parsing and validation for the `EdgeAi.HttpPost` dataset configuration contract
//! and inbound endpoint address.
//!
//! Field names mirror the `datasetConfigurationSchema` published in
//! `connector-metadata/connector-metadata.json` (`request.bodySecretAlias`,
//! `request.contentType`, `request.idempotent`, `samplingIntervalMs`).
//! `request.bodySecretAlias` is resolved to request body
//! content via [`crate::secret_body::resolve_body`]; see that module and
//! `docs/request-body-secret.md` for the resolution contract and its manual
//! `kubectl create secret generic` prerequisite.

use std::collections::BTreeMap;

use reqwest::header::{HeaderMap, HeaderName, HeaderValue};
use serde::Deserialize;
use url::Url;

use crate::policy;

/// Maximum accepted request body length in bytes, enforced against the content
/// resolved from `request.bodySecretAlias`. This is a ceiling only; the contract
/// requires supporting bodies of at least 10,000 characters, it does not impose a
/// per-request minimum.
pub const MAX_REQUEST_BODY_BYTES: usize = 262_144;

/// Maximum accepted length of `request.bodySecretAlias`, matching the Kubernetes
/// object-name convention this alias is expected to follow.
pub const MAX_BODY_SECRET_ALIAS_LEN: usize = 253;

/// Minimum accepted sampling interval, matching `datasetConfigurationSchema`.
pub const MIN_SAMPLING_INTERVAL_MS: u32 = 100;

const MAX_CUSTOM_HEADERS: usize = 32;
const MAX_CUSTOM_HEADER_NAME_BYTES: usize = 128;
const MAX_CUSTOM_HEADER_VALUE_BYTES: usize = 4_096;

// These headers control credentials, message framing, content typing, or trace
// propagation and must remain owned by the connector or HTTP transport.
const RESERVED_HEADER_NAMES: [&str; 10] = [
    "authorization",
    "proxy-authorization",
    "host",
    "content-length",
    "transfer-encoding",
    "connection",
    "content-type",
    "traceparent",
    "tracestate",
    "baggage",
];

/// Projected dataset configuration, parsed from the Device Registry dataset's
/// `dataset_configuration` JSON.
#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DatasetConfiguration {
    pub request: RequestConfiguration,
    pub sampling_interval_ms: u32,
}

/// The request body's secret alias, content type, and retry policy owned by the
/// dataset configuration. `body_secret_alias` names a secret resolved via
/// [`secret_body::resolve_body`]; it is never an inline request body.
#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RequestConfiguration {
    pub body_secret_alias: String,
    pub content_type: String,
    #[serde(default)]
    pub headers: BTreeMap<String, String>,
    /// Whether this POST request is safe to retry once after a failed send.
    /// Defaults to `false`, matching the contract's default single-attempt
    /// semantics for non-idempotent requests.
    #[serde(default)]
    pub idempotent: bool,
}

/// Immutable validated dataset intent. Mutable endpoint and secret state is
/// resolved immediately before each request execution.
#[derive(Debug, Clone)]
pub struct ObservationPlan {
    pub data_source: Option<String>,
    pub dataset: DatasetConfiguration,
}

/// Parses the raw `dataset_configuration` JSON string into a [`DatasetConfiguration`].
pub fn parse_dataset_configuration(raw: &str) -> Result<DatasetConfiguration, String> {
    serde_json::from_str(raw).map_err(|err| format!("invalid dataset configuration JSON: {err}"))
}

/// Validates a parsed [`DatasetConfiguration`] against the connector contract:
/// textual content type, `body_secret_alias` format, and sampling interval floor.
/// Request body size is checked whenever the alias is resolved.
pub fn validate_dataset_configuration(config: &DatasetConfiguration) -> Result<(), String> {
    if config.request.content_type.trim().is_empty() {
        return Err("request.contentType must not be empty".to_string());
    }
    if !policy::is_textual_mime(&config.request.content_type) {
        return Err(format!(
            "request.contentType '{}' is not an accepted textual MIME type",
            config.request.content_type
        ));
    }
    validate_body_secret_alias(&config.request.body_secret_alias)?;
    build_custom_headers(&config.request.headers)?;
    if config.sampling_interval_ms < MIN_SAMPLING_INTERVAL_MS {
        return Err(format!(
            "samplingIntervalMs {} is below the minimum of {}",
            config.sampling_interval_ms, MIN_SAMPLING_INTERVAL_MS
        ));
    }
    Ok(())
}

/// Builds custom request headers after validating their names and values.
pub fn build_custom_headers(headers: &BTreeMap<String, String>) -> Result<HeaderMap, String> {
    if headers.len() > MAX_CUSTOM_HEADERS {
        return Err(format!(
            "request.headers contains {} entries, exceeding the maximum of {MAX_CUSTOM_HEADERS}",
            headers.len()
        ));
    }

    let mut validated = HeaderMap::with_capacity(headers.len());
    for (name, value) in headers {
        if name.len() > MAX_CUSTOM_HEADER_NAME_BYTES {
            return Err(format!(
                "request.headers name exceeds the {MAX_CUSTOM_HEADER_NAME_BYTES} byte ceiling"
            ));
        }
        let header_name = HeaderName::from_bytes(name.as_bytes())
            .map_err(|err| format!("request.headers contains invalid name '{name}': {err}"))?;
        if RESERVED_HEADER_NAMES.contains(&header_name.as_str()) {
            return Err(format!(
                "request.headers must not override reserved header '{name}'"
            ));
        }
        if validated.contains_key(&header_name) {
            return Err(format!(
                "request.headers contains duplicate case-insensitive name '{name}'"
            ));
        }
        if value.len() > MAX_CUSTOM_HEADER_VALUE_BYTES {
            return Err(format!(
                "request.headers value for '{name}' exceeds the {MAX_CUSTOM_HEADER_VALUE_BYTES} byte ceiling"
            ));
        }
        let header_value = HeaderValue::from_str(value)
            .map_err(|err| format!("request.headers contains invalid value for '{name}': {err}"))?;
        validated.insert(header_name, header_value);
    }
    Ok(validated)
}

/// Validates `request.bodySecretAlias`: non-empty, at most
/// [`MAX_BODY_SECRET_ALIAS_LEN`] characters, restricted to
/// `[A-Za-z0-9_.-]`, and not `.` or `..` (which would be meaningless or unsafe
/// path segments once joined onto the secrets metadata mount in
/// [`secret_body::resolve_body`]).
fn validate_body_secret_alias(alias: &str) -> Result<(), String> {
    if alias.is_empty() {
        return Err("request.bodySecretAlias must not be empty".to_string());
    }
    if alias.len() > MAX_BODY_SECRET_ALIAS_LEN {
        return Err(format!(
            "request.bodySecretAlias length {} exceeds the {} character ceiling",
            alias.len(),
            MAX_BODY_SECRET_ALIAS_LEN
        ));
    }
    if alias == "." || alias == ".." {
        return Err("request.bodySecretAlias must not be '.' or '..'".to_string());
    }
    let is_safe = alias
        .chars()
        .all(|ch| ch.is_ascii_alphanumeric() || matches!(ch, '_' | '.' | '-'));
    if !is_safe {
        return Err(format!(
            "request.bodySecretAlias '{alias}' contains characters outside [A-Za-z0-9_.-]"
        ));
    }
    Ok(())
}

/// Parses and validates a base inbound endpoint address string. Requires an `http`
/// or `https` scheme and a non-empty host. Same-origin enforcement against the
/// dataset's relative path happens at execution via
/// [`policy::resolve_request_url`].
pub fn parse_endpoint_address(address: &str) -> Result<Url, String> {
    let url = Url::parse(address).map_err(|err| format!("invalid endpoint address: {err}"))?;
    if url.scheme() != "http" && url.scheme() != "https" {
        return Err(format!(
            "endpoint address scheme '{}' is not http or https",
            url.scheme()
        ));
    }
    if !url.username().is_empty() || url.password().is_some() {
        return Err("endpoint address must not include userinfo".to_string());
    }
    match url.host_str() {
        Some(host) if !host.is_empty() => Ok(url),
        _ => Err("endpoint address must include a non-empty host".to_string()),
    }
}

/// Parses and validates the immutable dataset configuration and relative data
/// source retained between ticks.
pub fn compile_plan(
    data_source: Option<&str>,
    raw_dataset_configuration: &str,
) -> Result<ObservationPlan, String> {
    policy::validate_data_source(data_source)?;
    let dataset = parse_dataset_configuration(raw_dataset_configuration)?;
    validate_dataset_configuration(&dataset)?;
    Ok(ObservationPlan {
        data_source: data_source.map(str::to_string),
        dataset,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn valid_dataset_json() -> String {
        r#"{
            "request": {
                "bodySecretAlias": "body-secret",
                "contentType": "application/json",
                "headers": { "X-Requested-With": "XMLHttpRequest" }
            },
            "samplingIntervalMs": 1000
        }"#
        .to_string()
    }

    #[test]
    fn parses_valid_dataset_configuration() {
        let config = parse_dataset_configuration(&valid_dataset_json()).unwrap();
        validate_dataset_configuration(&config).unwrap();
        assert_eq!(config.request.body_secret_alias, "body-secret");
        assert_eq!(
            config.request.headers.get("X-Requested-With"),
            Some(&"XMLHttpRequest".to_string())
        );
        assert_eq!(config.sampling_interval_ms, 1000);
    }

    #[test]
    fn rejects_configuration_with_inline_body_field() {
        let raw = r#"{
            "request": { "body": "hello world", "contentType": "application/json" },
            "samplingIntervalMs": 1000
        }"#;
        assert!(parse_dataset_configuration(raw).is_err());
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
    fn rejects_empty_body_secret_alias() {
        let raw = valid_dataset_json().replace("\"body-secret\"", "\"\"");
        let config = parse_dataset_configuration(&raw).unwrap();
        assert!(validate_dataset_configuration(&config).is_err());
    }

    #[test]
    fn rejects_body_secret_alias_over_length_ceiling() {
        let oversized_alias = "a".repeat(MAX_BODY_SECRET_ALIAS_LEN + 1);
        let raw =
            valid_dataset_json().replace("\"body-secret\"", &format!("\"{oversized_alias}\""));
        let config = parse_dataset_configuration(&raw).unwrap();
        assert!(validate_dataset_configuration(&config).is_err());
    }

    #[test]
    fn rejects_body_secret_alias_containing_a_path_separator() {
        let raw = valid_dataset_json().replace("\"body-secret\"", "\"../escape\"");
        let config = parse_dataset_configuration(&raw).unwrap();
        assert!(validate_dataset_configuration(&config).is_err());
    }

    #[test]
    fn rejects_body_secret_alias_equal_to_dot_dot() {
        let raw = valid_dataset_json().replace("\"body-secret\"", "\"..\"");
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
    fn rejects_all_reserved_custom_headers_case_insensitively() {
        for name in RESERVED_HEADER_NAMES {
            let headers = BTreeMap::from([(name.to_ascii_uppercase(), "value".to_string())]);
            assert!(build_custom_headers(&headers).is_err(), "accepted {name}");
        }
    }

    #[test]
    fn rejects_custom_header_value_containing_newline() {
        let raw = valid_dataset_json().replace(
            "\"XMLHttpRequest\"",
            "\"XMLHttpRequest\\r\\nInjected: value\"",
        );
        let config = parse_dataset_configuration(&raw).unwrap();
        assert!(validate_dataset_configuration(&config).is_err());
    }

    #[test]
    fn accepts_customer_managed_routing_header() {
        let headers = BTreeMap::from([(
            "X-Envoy-Original-Dst-Host".to_string(),
            "internal.example".to_string(),
        )]);
        assert!(build_custom_headers(&headers).is_ok());
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
        let plan = compile_plan(None, &valid_dataset_json()).unwrap();
        assert_eq!(plan.dataset.request.body_secret_alias, "body-secret");
        assert!(plan.data_source.is_none());
    }

    #[test]
    fn compile_plan_retains_relative_data_source() {
        let plan = compile_plan(Some("/api/v1/query"), &valid_dataset_json()).unwrap();
        assert_eq!(plan.data_source.as_deref(), Some("/api/v1/query"));
    }

    #[test]
    fn compile_plan_fails_when_data_source_is_absolute() {
        assert!(compile_plan(Some("https://other.local/steal"), &valid_dataset_json()).is_err());
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
