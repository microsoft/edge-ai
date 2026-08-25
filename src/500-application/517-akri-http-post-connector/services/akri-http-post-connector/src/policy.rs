//! Security and resource-limit policy shared by the HTTP request/response
//! pipeline: textual MIME allow-listing, same-origin URL resolution, and
//! bounded retry eligibility.

use std::collections::HashSet;
use std::net::IpAddr;
use std::sync::OnceLock;
use std::time::Duration;

use ipnet::IpNet;
use url::Url;

const ALLOWED_HOSTS_VAR: &str = "HTTP_POST_ALLOWED_HOSTS";
const ALLOWED_CIDRS_VAR: &str = "HTTP_POST_ALLOWED_CIDRS";
const ALLOW_ANONYMOUS_HTTP_VAR: &str = "HTTP_POST_ALLOW_ANONYMOUS_HTTP";

/// Endpoint authority rules loaded once at connector startup.
#[derive(Clone, Debug)]
pub struct EndpointPolicy {
    allowed_hosts: HashSet<String>,
    allowed_networks: Vec<IpNet>,
    allow_anonymous_http: bool,
}

impl EndpointPolicy {
    /// Loads the endpoint allow rules from the process environment.
    pub fn from_env() -> Result<Self, String> {
        let allowed_hosts =
            parse_allowed_hosts(&std::env::var(ALLOWED_HOSTS_VAR).map_err(|_| {
                format!("{ALLOWED_HOSTS_VAR} is required and must contain approved endpoint hosts")
            })?)?;
        let allowed_networks =
            parse_allowed_networks(&std::env::var(ALLOWED_CIDRS_VAR).map_err(|_| {
                format!("{ALLOWED_CIDRS_VAR} is required and must contain approved endpoint CIDRs")
            })?)?;
        let allow_anonymous_http = std::env::var(ALLOW_ANONYMOUS_HTTP_VAR)
            .map(|value| value.eq_ignore_ascii_case("true"))
            .unwrap_or(false);

        Ok(Self {
            allowed_hosts,
            allowed_networks,
            allow_anonymous_http,
        })
    }

    /// Returns whether anonymous HTTP endpoints are enabled for development.
    pub fn allows_anonymous_http(&self) -> bool {
        self.allow_anonymous_http
    }

    /// Rejects endpoint URL authority that cannot be safely emitted or resolved.
    pub fn validate_url(&self, url: &Url) -> Result<(), String> {
        if !url.username().is_empty() || url.password().is_some() {
            return Err("endpoint URL userinfo is not permitted".to_string());
        }
        let host = url
            .host_str()
            .ok_or_else(|| "endpoint URL host is missing".to_string())?
            .to_ascii_lowercase();
        if host.parse::<IpAddr>().is_err() && !self.allowed_hosts.contains(&host) {
            return Err("endpoint host is not approved".to_string());
        }
        Ok(())
    }

    /// Requires every resolved address to be safe and within an approved CIDR.
    pub fn validate_addresses(&self, addresses: &[IpAddr]) -> Result<(), String> {
        if addresses.is_empty() {
            return Err("endpoint DNS resolution returned no addresses".to_string());
        }
        if addresses.iter().any(is_denied_address) {
            return Err("endpoint resolved to a denied address class".to_string());
        }
        if addresses.iter().any(|address| {
            !self
                .allowed_networks
                .iter()
                .any(|network| network.contains(address))
        }) {
            return Err("endpoint resolved outside approved CIDRs".to_string());
        }
        Ok(())
    }
}

/// Maximum accepted response body length in bytes, mirroring the request body
/// ceiling enforced on dataset configuration in [`crate::config`].
pub const MAX_RESPONSE_BODY_BYTES: usize = 262_144;

/// Connection establishment timeout applied to every outbound POST request.
pub const CONNECT_TIMEOUT: Duration = Duration::from_secs(10);

/// Total request timeout, covering connect, send, and response read.
pub const TOTAL_TIMEOUT: Duration = Duration::from_secs(30);

fn parse_allowed_hosts(value: &str) -> Result<HashSet<String>, String> {
    let hosts: HashSet<String> = value
        .split(',')
        .map(str::trim)
        .filter(|host| !host.is_empty())
        .map(|host| host.trim_end_matches('.').to_ascii_lowercase())
        .collect();
    if hosts.is_empty() {
        return Err(format!("{ALLOWED_HOSTS_VAR} must not be empty"));
    }
    if hosts.iter().any(|host| {
        host.parse::<IpAddr>().is_ok() || host.contains('/') || host.contains(':') || host == "*"
    }) {
        return Err(format!(
            "{ALLOWED_HOSTS_VAR} must contain exact DNS hostnames only"
        ));
    }
    Ok(hosts)
}

fn parse_allowed_networks(value: &str) -> Result<Vec<IpNet>, String> {
    let networks: Result<Vec<IpNet>, _> = value
        .split(',')
        .map(str::trim)
        .filter(|network| !network.is_empty())
        .map(str::parse)
        .collect();
    let networks = networks.map_err(|_| format!("{ALLOWED_CIDRS_VAR} contains an invalid CIDR"))?;
    if networks.is_empty() {
        return Err(format!("{ALLOWED_CIDRS_VAR} must not be empty"));
    }
    Ok(networks)
}

fn is_denied_address(address: &IpAddr) -> bool {
    match address {
        IpAddr::V4(address) => {
            address.is_unspecified()
                || address.is_loopback()
                || address.is_link_local()
                || address.is_multicast()
                || address.is_broadcast()
        }
        IpAddr::V6(address) => {
            address.is_unspecified()
                || address.is_loopback()
                || address.is_unicast_link_local()
                || address.is_multicast()
        }
    }
}

fn textual_mime_types() -> &'static HashSet<&'static str> {
    static TEXTUAL_MIME_TYPES: OnceLock<HashSet<&'static str>> = OnceLock::new();
    TEXTUAL_MIME_TYPES.get_or_init(|| {
        [
            "application/json",
            "application/xml",
            "application/x-www-form-urlencoded",
            "text/plain",
            "text/csv",
            "text/xml",
            "text/html",
        ]
        .into_iter()
        .collect()
    })
}

/// Returns whether `content_type` (ignoring parameters such as `; charset=utf-8`) is
/// an allow-listed textual MIME type, or any `text/*` subtype.
pub fn is_textual_mime(content_type: &str) -> bool {
    let base = content_type
        .split(';')
        .next()
        .unwrap_or("")
        .trim()
        .to_ascii_lowercase();
    base.starts_with("text/") || textual_mime_types().contains(base.as_str())
}

/// Resolves the absolute request URL for a dataset by joining the endpoint's base
/// address with the dataset's relative `data_source` path. Rejects any `data_source`
/// value that would change the resolved scheme, host, or port, so an asset cannot
/// redirect a request to an unintended origin (a protocol-relative or absolute
/// `data_source` value is an SSRF vector otherwise).
pub fn resolve_request_url(base: &Url, data_source: Option<&str>) -> Result<Url, String> {
    let Some(data_source) = data_source else {
        return Ok(base.clone());
    };
    let resolved = base
        .join(data_source)
        .map_err(|err| format!("invalid data_source path '{data_source}': {err}"))?;
    if resolved.scheme() != base.scheme()
        || resolved.host_str() != base.host_str()
        || resolved.port_or_known_default() != base.port_or_known_default()
    {
        return Err(format!(
            "data_source '{data_source}' must resolve to the same origin as the endpoint address"
        ));
    }
    Ok(resolved)
}

/// Validates that a retained data source is a URL-reference that cannot change
/// endpoint authority when resolved during request execution.
pub fn validate_data_source(data_source: Option<&str>) -> Result<(), String> {
    let validation_base =
        Url::parse("https://validation.invalid/").expect("static validation URL is valid");
    resolve_request_url(&validation_base, data_source).map(|_| ())
}

/// Returns whether a failed POST attempt is eligible for a single same-tick retry.
/// Retries are only permitted when the dataset configuration explicitly declares the
/// request idempotent, and never once destination forwarding has been attempted,
/// since replaying a POST after a forwarding failure could duplicate side effects.
pub fn retry_eligible(idempotent: bool, destination_forward_attempted: bool) -> bool {
    idempotent && !destination_forward_attempted
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_allow_listed_and_text_wildcard_mime_types() {
        assert!(is_textual_mime("application/json"));
        assert!(is_textual_mime("text/plain; charset=utf-8"));
        assert!(is_textual_mime("TEXT/CSV"));
    }

    #[test]
    fn rejects_binary_mime_types() {
        assert!(!is_textual_mime("application/octet-stream"));
        assert!(!is_textual_mime("image/png"));
        assert!(!is_textual_mime(""));
    }

    #[test]
    fn resolves_relative_data_source_against_base() {
        let base = Url::parse("https://example.local/base").unwrap();
        let resolved = resolve_request_url(&base, Some("/api/v1/query")).unwrap();
        assert_eq!(resolved.as_str(), "https://example.local/api/v1/query");
    }

    #[test]
    fn returns_base_when_no_data_source_configured() {
        let base = Url::parse("https://example.local/base").unwrap();
        let resolved = resolve_request_url(&base, None).unwrap();
        assert_eq!(resolved, base);
    }

    #[test]
    fn rejects_protocol_relative_data_source_that_changes_host() {
        let base = Url::parse("https://example.local/base").unwrap();
        assert!(resolve_request_url(&base, Some("//evil.example/steal")).is_err());
    }

    #[test]
    fn rejects_absolute_data_source_pointing_at_a_different_origin() {
        let base = Url::parse("https://example.local/base").unwrap();
        assert!(resolve_request_url(&base, Some("http://example.local/downgrade")).is_err());
        assert!(resolve_request_url(&base, Some("https://other.local/steal")).is_err());
    }

    #[test]
    fn validates_only_relative_data_sources() {
        assert!(validate_data_source(Some("/api/v1/query")).is_ok());
        assert!(validate_data_source(Some("https://other.local/query")).is_err());
        assert!(validate_data_source(Some("//other.local/query")).is_err());
    }

    #[test]
    fn retry_is_eligible_only_when_idempotent_and_not_yet_forwarded() {
        assert!(retry_eligible(true, false));
        assert!(!retry_eligible(true, true));
        assert!(!retry_eligible(false, false));
        assert!(!retry_eligible(false, true));
    }
}
