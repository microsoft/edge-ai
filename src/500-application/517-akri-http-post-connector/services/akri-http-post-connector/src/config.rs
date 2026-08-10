//! Parsing and validation for the `EdgeAi.HttpPost` dataset configuration contract
//! and inbound endpoint address.
//!
//! Field names mirror the `datasetConfigurationSchema` published in
//! `connector-metadata/connector-metadata.json` (`schemaVersion`,
//! `request.bodySecretAlias`, `request.contentType`, `request.idempotent`,
//! `samplingIntervalMs`). `request.bodySecretAlias` is resolved to request body
//! content via [`crate::secret_body::resolve_body`]; see that module and
//! `docs/request-body-secret.md` for the resolution contract and its manual
//! `kubectl create secret generic` prerequisite.

use std::path::Path;

use serde::Deserialize;
use url::Url;

use crate::policy;
use crate::secret_body;

/// Dataset configuration schema version accepted by this connector (v2 contract).
pub const DATASET_CONFIGURATION_SCHEMA_VERSION: u32 = 2;

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

/// Projected dataset configuration, parsed from the Device Registry dataset's
/// `dataset_configuration` JSON.
#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DatasetConfiguration {
    pub schema_version: u32,
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

/// An immutable, fully validated plan combining a resolved request address, an
/// accepted dataset configuration, and the request body content resolved from
/// `dataset.request.body_secret_alias`. Only produced by [`compile_plan`] after all
/// validation and secret resolution succeed.
#[derive(Debug, Clone)]
pub struct ObservationPlan {
    pub endpoint: EndpointPolicy,
    pub dataset: DatasetConfiguration,
    pub resolved_body: String,
}

/// Parses the raw `dataset_configuration` JSON string into a [`DatasetConfiguration`].
pub fn parse_dataset_configuration(raw: &str) -> Result<DatasetConfiguration, String> {
    serde_json::from_str(raw).map_err(|err| format!("invalid dataset configuration JSON: {err}"))
}

/// Validates a parsed [`DatasetConfiguration`] against the v2 contract: schema
/// version, textual content type, `body_secret_alias` format, and sampling
/// interval floor. Does not resolve or size-check the request body itself; that
/// happens against the resolved secret content in [`compile_plan`].
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
    validate_body_secret_alias(&config.request.body_secret_alias)?;
    if config.sampling_interval_ms < MIN_SAMPLING_INTERVAL_MS {
        return Err(format!(
            "samplingIntervalMs {} is below the minimum of {}",
            config.sampling_interval_ms, MIN_SAMPLING_INTERVAL_MS
        ));
    }
    Ok(())
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
/// `data_source` path, and a raw dataset configuration together, then resolves
/// `request.bodySecretAlias` to its request body content via
/// [`secret_body::resolve_body`] against `secrets_metadata_mount` and
/// `secrets_mount`, producing an immutable [`ObservationPlan`] only if all steps
/// succeed.
pub fn compile_plan(
    endpoint_address: &str,
    data_source: Option<&str>,
    raw_dataset_configuration: &str,
    secrets_metadata_mount: &Path,
    secrets_mount: &Path,
) -> Result<ObservationPlan, String> {
    let base_address = parse_endpoint_address(endpoint_address)?;
    let resolved_address = policy::resolve_request_url(&base_address, data_source)?;
    let dataset = parse_dataset_configuration(raw_dataset_configuration)?;
    validate_dataset_configuration(&dataset)?;
    let resolved_body = secret_body::resolve_body(
        secrets_metadata_mount,
        secrets_mount,
        &dataset.request.body_secret_alias,
    )?;
    Ok(ObservationPlan {
        endpoint: EndpointPolicy {
            address: resolved_address,
        },
        dataset,
        resolved_body,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;
    use std::sync::atomic::{AtomicU64, Ordering};

    /// A throwaway secrets-metadata-mount / secrets-mount pair with a single
    /// alias resolved to `body`, for exercising `compile_plan`'s secret
    /// resolution step without a live Akri operator. Built with `std::fs`/
    /// `std::env` only, matching this crate's constraint of not adding a new
    /// Cargo dependency for test scaffolding.
    struct SecretMount {
        metadata_dir: PathBuf,
        secrets_dir: PathBuf,
    }

    impl SecretMount {
        fn new(alias: &str, body: &str) -> Self {
            static COUNTER: AtomicU64 = AtomicU64::new(0);
            let unique = COUNTER.fetch_add(1, Ordering::Relaxed);
            let base = std::env::temp_dir().join(format!(
                "akri-http-post-connector-config-test-{}-{unique}",
                std::process::id()
            ));
            let metadata_dir = base.join("metadata");
            let secrets_dir = base.join("secrets");
            std::fs::create_dir_all(&metadata_dir).unwrap();
            std::fs::create_dir_all(&secrets_dir).unwrap();
            std::fs::write(metadata_dir.join(alias), "content").unwrap();
            std::fs::write(secrets_dir.join("content"), body).unwrap();
            Self {
                metadata_dir,
                secrets_dir,
            }
        }
    }

    impl Drop for SecretMount {
        fn drop(&mut self) {
            if let Some(base) = self.metadata_dir.parent() {
                let _ = std::fs::remove_dir_all(base);
            }
        }
    }

    fn valid_dataset_json() -> String {
        r#"{
            "schemaVersion": 2,
            "request": { "bodySecretAlias": "body-secret", "contentType": "application/json" },
            "samplingIntervalMs": 1000
        }"#
        .to_string()
    }

    #[test]
    fn parses_valid_dataset_configuration() {
        let config = parse_dataset_configuration(&valid_dataset_json()).unwrap();
        validate_dataset_configuration(&config).unwrap();
        assert_eq!(config.schema_version, DATASET_CONFIGURATION_SCHEMA_VERSION);
        assert_eq!(config.request.body_secret_alias, "body-secret");
        assert_eq!(config.sampling_interval_ms, 1000);
    }

    #[test]
    fn rejects_v1_schema_version() {
        let raw = valid_dataset_json().replace("\"schemaVersion\": 2", "\"schemaVersion\": 1");
        let config = parse_dataset_configuration(&raw).unwrap();
        assert!(validate_dataset_configuration(&config).is_err());
    }

    #[test]
    fn rejects_v1_configuration_with_inline_body_field() {
        let raw = r#"{
            "schemaVersion": 1,
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
        let mount = SecretMount::new("body-secret", "hello world");
        let plan = compile_plan(
            "https://example.local/path",
            None,
            &valid_dataset_json(),
            &mount.metadata_dir,
            &mount.secrets_dir,
        )
        .unwrap();
        assert_eq!(plan.endpoint.address.scheme(), "https");
        assert_eq!(plan.dataset.request.body_secret_alias, "body-secret");
        assert_eq!(plan.resolved_body, "hello world");
    }

    #[test]
    fn compile_plan_resolves_relative_data_source() {
        let mount = SecretMount::new("body-secret", "hello world");
        let plan = compile_plan(
            "https://example.local/base",
            Some("/api/v1/query"),
            &valid_dataset_json(),
            &mount.metadata_dir,
            &mount.secrets_dir,
        )
        .unwrap();
        assert_eq!(
            plan.endpoint.address.as_str(),
            "https://example.local/api/v1/query"
        );
    }

    #[test]
    fn compile_plan_fails_when_endpoint_invalid() {
        let unused_mount = Path::new("/nonexistent-mount");
        assert!(compile_plan(
            "not a url",
            None,
            &valid_dataset_json(),
            unused_mount,
            unused_mount
        )
        .is_err());
    }

    #[test]
    fn compile_plan_fails_when_data_source_changes_origin() {
        let unused_mount = Path::new("/nonexistent-mount");
        assert!(compile_plan(
            "https://example.local/base",
            Some("https://other.local/steal"),
            &valid_dataset_json(),
            unused_mount,
            unused_mount
        )
        .is_err());
    }

    #[test]
    fn compile_plan_fails_when_dataset_invalid() {
        let unused_mount = Path::new("/nonexistent-mount");
        let raw = valid_dataset_json().replace("\"schemaVersion\": 2", "\"schemaVersion\": 9");
        assert!(compile_plan(
            "https://example.local/path",
            None,
            &raw,
            unused_mount,
            unused_mount
        )
        .is_err());
    }

    #[test]
    fn compile_plan_fails_when_secret_alias_unresolvable() {
        let unresolvable_mount = Path::new("/nonexistent-mount");
        assert!(compile_plan(
            "https://example.local/path",
            None,
            &valid_dataset_json(),
            unresolvable_mount,
            unresolvable_mount
        )
        .is_err());
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
