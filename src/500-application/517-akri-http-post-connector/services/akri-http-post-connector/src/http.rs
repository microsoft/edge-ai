//! Bounded, SSRF-conscious HTTP POST execution using rustls.
//!
//! Builds one [`reqwest::Client`] per device inbound endpoint (rebuilt whenever the
//! endpoint's authentication or trust settings change), disables redirects and
//! automatic proxy discovery, enforces explicit connect/total timeouts, and reads
//! response bodies up to [`policy::MAX_RESPONSE_BODY_BYTES`] regardless of what the
//! response's `Content-Length` header claims.

use std::collections::BTreeMap;
use std::error::Error as _;
use std::path::{Path, PathBuf};

use azure_iot_operations_connector::base_connector::managed_azure_device_registry::Authentication;
use opentelemetry::propagation::Injector;
use reqwest::{Client, ClientBuilder, Response};
use tracing::{debug, field, Instrument, Span};
use tracing_opentelemetry::OpenTelemetrySpanExt;

use crate::policy;

/// Endpoint-scoped credentials resolved from the device's projected [`Authentication`].
/// A client certificate is applied at client-build time; HTTP Basic Auth is applied
/// per-request since reqwest has no client-level default for it.
#[derive(Debug, Clone)]
pub enum EndpointCredentials {
    /// No client credentials; the request relies solely on transport security.
    None,
    /// Present a client certificate and key during the TLS handshake.
    ClientCertificate,
    /// Send an HTTP Basic Authorization header with every request.
    BasicAuth { username: String, password: String },
}

impl EndpointCredentials {
    fn is_authenticated(&self) -> bool {
        !matches!(self, Self::None)
    }

    pub(crate) fn kind(&self) -> &'static str {
        match self {
            Self::None => "none",
            Self::ClientCertificate => "client_certificate",
            Self::BasicAuth { .. } => "basic_auth",
        }
    }
}

/// Loads endpoint credentials from the device's projected authentication mode,
/// reading certificate/key/credential files from their Akri-projected mount paths.
/// Returns the credential descriptor plus, for [`Authentication::Certificate`], the
/// PEM identity bytes to install on the HTTP client.
pub fn load_credentials(
    authentication: &Authentication,
) -> Result<(EndpointCredentials, Option<reqwest::Identity>), String> {
    match authentication {
        Authentication::Anonymous => Ok((EndpointCredentials::None, None)),
        Authentication::Certificate {
            certificate_path,
            intermediate_certificates_path,
            key_path,
        } => {
            let mut pem = read_file(certificate_path)?;
            if let Some(intermediate_path) = intermediate_certificates_path {
                pem.extend(read_file(intermediate_path)?);
            }
            if let Some(key_path) = key_path {
                pem.extend(read_file(key_path)?);
            }
            let identity = reqwest::Identity::from_pem(&pem)
                .map_err(|err| format!("invalid client certificate/key PEM: {err}"))?;
            Ok((EndpointCredentials::ClientCertificate, Some(identity)))
        }
        Authentication::UsernamePassword {
            username_path,
            password_path,
        } => {
            let username = read_file_to_string(username_path)?;
            let password = read_file_to_string(password_path)?;
            Ok((EndpointCredentials::BasicAuth { username, password }, None))
        }
    }
}

fn read_file(path: &Path) -> Result<Vec<u8>, String> {
    std::fs::read(path).map_err(|err| format!("failed to read '{}': {err}", path.display()))
}

fn read_file_to_string(path: &Path) -> Result<String, String> {
    let contents = read_file(path)?;
    String::from_utf8(contents)
        .map(|value| value.trim().to_string())
        .map_err(|err| format!("'{}' is not valid UTF-8: {err}", path.display()))
}

/// Builds a rustls-backed HTTP client for a single device inbound endpoint, with
/// redirects and proxy discovery disabled, explicit connect/total timeouts, an
/// optional client identity, and an optional directory of PEM trust-bundle CA
/// certificates layered on top of the platform's built-in trust roots.
fn build_client(
    trust_bundle_dir: Option<&PathBuf>,
    identity: Option<reqwest::Identity>,
) -> Result<Client, String> {
    debug!(
        custom_trust_bundle = trust_bundle_dir.is_some(),
        client_identity = identity.is_some(),
        redirects_enabled = false,
        proxy_enabled = false,
        "configuring endpoint HTTP client"
    );
    let mut builder = ClientBuilder::new()
        .connect_timeout(policy::CONNECT_TIMEOUT)
        .timeout(policy::TOTAL_TIMEOUT)
        .redirect(reqwest::redirect::Policy::none())
        .no_proxy();

    if let Some(dir) = trust_bundle_dir {
        let certs = load_trust_bundle(dir).inspect_err(|_| {
            debug!("endpoint trust bundle loading failed");
        })?;
        debug!(
            certificate_count = certs.len(),
            "loaded endpoint trust bundle"
        );
        if certs.is_empty() {
            return Err("endpoint trust bundle must contain at least one certificate".to_string());
        }
        builder = builder.tls_built_in_root_certs(false);
        for cert in certs {
            builder = builder.add_root_certificate(cert);
        }
    }
    if let Some(identity) = identity {
        builder = builder.identity(identity);
    }
    builder
        .build()
        .inspect(|_| {
            debug!("endpoint HTTP client configured");
        })
        .map_err(|err| {
            debug!("endpoint HTTP client configuration failed");
            format!("failed to build HTTP client: {err}")
        })
}

/// Validates an endpoint before returning its HTTP client and request credentials.
pub fn build_endpoint_client(
    endpoint: &reqwest::Url,
    authentication: &Authentication,
    trust_bundle_dir: Option<&PathBuf>,
) -> Result<(Client, EndpointCredentials), String> {
    debug!(
        scheme = endpoint.scheme(),
        port = endpoint.port_or_known_default().unwrap_or_default(),
        custom_trust_bundle = trust_bundle_dir.is_some(),
        "validating endpoint HTTP configuration"
    );
    validate_endpoint_url(endpoint).inspect_err(|_| {
        debug!("endpoint URL validation failed");
    })?;
    debug!("endpoint URL validation completed");
    let (credentials, identity) = load_credentials(authentication).inspect_err(|_| {
        debug!("endpoint credential loading failed");
    })?;
    debug!(
        credential_kind = credentials.kind(),
        "endpoint credentials loaded"
    );
    validate_transport(endpoint, &credentials).inspect_err(|_| {
        debug!("endpoint transport validation failed");
    })?;
    debug!("endpoint transport validation completed");

    let client = build_client(trust_bundle_dir, identity)?;
    Ok((client, credentials))
}

fn validate_endpoint_url(endpoint: &reqwest::Url) -> Result<(), String> {
    if !endpoint.username().is_empty() || endpoint.password().is_some() {
        return Err("endpoint URL userinfo is not permitted".to_string());
    }
    endpoint
        .host_str()
        .ok_or_else(|| "endpoint URL host is missing".to_string())?;
    Ok(())
}

fn validate_transport(
    endpoint: &reqwest::Url,
    credentials: &EndpointCredentials,
) -> Result<(), String> {
    if endpoint.scheme() == "http" && credentials.is_authenticated() {
        return Err("endpoint credentials require HTTPS".to_string());
    }
    Ok(())
}

fn load_trust_bundle(dir: &Path) -> Result<Vec<reqwest::Certificate>, String> {
    let entries = std::fs::read_dir(dir).map_err(|err| {
        format!(
            "failed to read trust bundle directory '{}': {err}",
            dir.display()
        )
    })?;
    let mut certs = Vec::new();
    for entry in entries {
        let entry = entry.map_err(|err| format!("failed to read trust bundle entry: {err}"))?;
        let path = entry.path();
        if !path.is_file() {
            continue;
        }
        let bytes = read_file(&path)?;
        let cert = reqwest::Certificate::from_pem(&bytes).map_err(|err| {
            format!(
                "invalid trust bundle certificate '{}': {err}",
                path.display()
            )
        })?;
        certs.push(cert);
    }
    Ok(certs)
}

fn request_target(url: &reqwest::Url) -> String {
    let host = match url.host() {
        Some(url::Host::Ipv6(address)) => format!("[{address}]"),
        Some(host) => host.to_string(),
        None => "unknown".to_string(),
    };
    let port = url.port_or_known_default().unwrap_or_default();
    format!("{}://{host}:{port}", url.scheme())
}

fn request_error_category(error: &reqwest::Error) -> &'static str {
    if error.is_timeout() {
        "timeout"
    } else if error.is_connect() {
        "connect"
    } else if error.is_body() {
        "body"
    } else if error.is_decode() {
        "decode"
    } else if error.is_redirect() {
        "redirect"
    } else if error.is_status() {
        "status"
    } else if error.is_builder() {
        "builder"
    } else {
        "request"
    }
}

fn format_request_error(context: &str, target: &str, error: reqwest::Error) -> String {
    let category = request_error_category(&error);
    let error = error.without_url();
    let mut message = format!("{context}: category={category} target={target}: {error}");
    let mut source = error.source();
    while let Some(cause) = source {
        message.push_str(": caused by: ");
        message.push_str(&cause.to_string());
        source = cause.source();
    }
    message
}

/// The outcome of a single POST execution: the validated response content type
/// (falling back to `application/octet-stream` for non-textual or missing values)
/// and its bounded, fully-read body.
pub struct PostResponse {
    pub content_type: String,
    pub body: Vec<u8>,
}

struct HeaderInjector<'a>(&'a mut reqwest::header::HeaderMap);

impl Injector for HeaderInjector<'_> {
    fn set(&mut self, key: &str, value: String) {
        let Ok(name) = reqwest::header::HeaderName::from_bytes(key.as_bytes()) else {
            return;
        };
        let Ok(value) = reqwest::header::HeaderValue::from_str(&value) else {
            return;
        };
        self.0.insert(name, value);
    }
}

/// Sends a single bounded POST request for the given resolved request URL, request
/// body, and content type, applying HTTP Basic Auth credentials when configured.
/// Validates the response content type and reads at most
/// [`policy::MAX_RESPONSE_BODY_BYTES`] of response body, aborting the read as soon
/// as that ceiling would be exceeded rather than trusting `Content-Length`.
pub async fn execute_post(
    client: &Client,
    url: reqwest::Url,
    body: String,
    content_type: &str,
    headers: &BTreeMap<String, String>,
    credentials: &EndpointCredentials,
) -> Result<PostResponse, String> {
    if url.scheme() != "https" && credentials.is_authenticated() {
        return Err("endpoint credentials require HTTPS".to_string());
    }
    let target = request_target(&url);
    let server_address = url.host_str().unwrap_or("unknown").to_string();
    let server_port = url.port_or_known_default().unwrap_or_default();
    let span = tracing::info_span!(
        "http.client.request",
        otel.kind = "client",
        http.request.method = "POST",
        server.address = %server_address,
        server.port = server_port,
        http.response.status_code = field::Empty,
        error.type = field::Empty,
    );

    async move {
        debug!(
            scheme = url.scheme(),
            port = server_port,
            credential_kind = credentials.kind(),
            "preparing POST request"
        );
        let custom_headers = crate::config::build_custom_headers(headers)?;
        let mut request = client
            .post(url)
            .header(reqwest::header::CONTENT_TYPE, content_type)
            .headers(custom_headers)
            .body(body);
        if let EndpointCredentials::BasicAuth { username, password } = credentials {
            request = request.basic_auth(username, Some(password));
        }
        let mut request = request.build().map_err(|error| {
            debug!(
                error_category = request_error_category(&error),
                "POST request construction failed"
            );
            format_request_error("failed to build POST request", &target, error)
        })?;
        debug!("POST request built");
        let context = Span::current().context();
        opentelemetry::global::get_text_map_propagator(|propagator| {
            propagator.inject_context(&context, &mut HeaderInjector(request.headers_mut()));
        });
        debug!("trace context injected into POST request");

        debug!("dispatching POST request");
        let response = client.execute(request).await.map_err(|error| {
            Span::current().record("error.type", "request_failed");
            debug!(
                error_category = request_error_category(&error),
                "POST request dispatch failed"
            );
            format_request_error("POST request failed", &target, error)
        })?;
        let status = response.status();
        debug!(
            status_code = status.as_u16(),
            authentication_challenge = response
                .headers()
                .contains_key(reqwest::header::WWW_AUTHENTICATE),
            content_type_present = response
                .headers()
                .contains_key(reqwest::header::CONTENT_TYPE),
            "POST response headers received"
        );
        Span::current().record("http.response.status_code", status.as_u16());
        if !status.is_success() {
            Span::current().record("error.type", "unsuccessful_status");
            debug!(
                status_code = status.as_u16(),
                "POST response rejected before body processing"
            );
            return Err(format!("POST response status was not successful: {status}"));
        }

        let response_content_type = response
            .headers()
            .get(reqwest::header::CONTENT_TYPE)
            .and_then(|value| value.to_str().ok())
            .filter(|value| policy::is_textual_mime(value))
            .unwrap_or("application/octet-stream")
            .to_string();
        debug!(
            textual_content_type = response_content_type != "application/octet-stream",
            "POST response content type classified"
        );

        let body = read_bounded_body(response).await?;
        debug!(
            response_body_bytes = body.len(),
            "POST response body read completed"
        );

        Ok(PostResponse {
            content_type: response_content_type,
            body,
        })
    }
    .instrument(span)
    .await
}

/// Reads a response body in chunks, stopping with an error before the accumulated
/// buffer would exceed [`policy::MAX_RESPONSE_BODY_BYTES`].
async fn read_bounded_body(mut response: Response) -> Result<Vec<u8>, String> {
    debug!(
        response_body_byte_ceiling = policy::MAX_RESPONSE_BODY_BYTES,
        "reading bounded POST response body"
    );
    let mut buffer = Vec::new();
    while let Some(chunk) = response.chunk().await.map_err(|error| {
        debug!(
            error_category = request_error_category(&error),
            "POST response body read failed"
        );
        format!("failed reading response body: {}", error.without_url())
    })? {
        if buffer.len() + chunk.len() > policy::MAX_RESPONSE_BODY_BYTES {
            debug!("POST response body exceeded configured byte ceiling");
            return Err(format!(
                "response body exceeded the {} byte ceiling",
                policy::MAX_RESPONSE_BODY_BYTES
            ));
        }
        buffer.extend_from_slice(&chunk);
    }
    Ok(buffer)
}

#[cfg(test)]
mod tests {
    use std::convert::Infallible;
    use std::net::SocketAddr;
    use std::sync::OnceLock;

    use tokio::io::{AsyncReadExt, AsyncWriteExt};
    use tokio::net::TcpListener;
    use tokio::sync::oneshot;
    use tracing::Instrument;

    use super::*;

    static TELEMETRY: OnceLock<crate::telemetry::TelemetryGuard> = OnceLock::new();

    /// Starts a minimal single-request HTTP/1.1 mock server that ignores the
    /// request and replies with `response`, then stops listening.
    async fn serve_once(response: &'static str) -> SocketAddr {
        serve_once_capturing(response).await.0
    }

    async fn serve_once_capturing(
        response: &'static str,
    ) -> (SocketAddr, oneshot::Receiver<Vec<u8>>) {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        let (request_tx, request_rx) = oneshot::channel();
        tokio::spawn(async move {
            let (mut socket, _) = listener.accept().await.unwrap();
            let mut buf = [0u8; 4096];
            // Drain whatever the client sent; a real HTTP client will close the
            // write side once it has sent headers+body, we just need to read some.
            let bytes_read = socket.read(&mut buf).await.unwrap();
            let _ = request_tx.send(buf[..bytes_read].to_vec());
            let _: Result<(), Infallible> = Ok(());
            socket.write_all(response.as_bytes()).await.unwrap();
            socket.shutdown().await.unwrap();
        });
        (addr, request_rx)
    }

    #[tokio::test]
    async fn executes_post_and_reads_textual_response_body() {
        let addr = serve_once(
            "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 5\r\nConnection: close\r\n\r\nhello",
        )
        .await;
        let client = build_client(None, None).unwrap();
        let url = reqwest::Url::parse(&format!("http://{addr}/path")).unwrap();
        let response = execute_post(
            &client,
            url,
            "body".to_string(),
            "text/plain",
            &Default::default(),
            &EndpointCredentials::None,
        )
        .await
        .unwrap();
        assert_eq!(response.content_type, "text/plain");
        assert_eq!(response.body, b"hello");
    }

    #[tokio::test]
    async fn falls_back_to_octet_stream_for_non_textual_response_content_type() {
        let addr = serve_once(
            "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: 3\r\nConnection: close\r\n\r\nabc",
        )
        .await;
        let client = build_client(None, None).unwrap();
        let url = reqwest::Url::parse(&format!("http://{addr}/path")).unwrap();
        let response = execute_post(
            &client,
            url,
            "body".to_string(),
            "text/plain",
            &Default::default(),
            &EndpointCredentials::None,
        )
        .await
        .unwrap();
        assert_eq!(response.content_type, "application/octet-stream");
    }

    #[tokio::test]
    async fn rejects_response_body_over_the_byte_ceiling() {
        let oversized = "a".repeat(policy::MAX_RESPONSE_BODY_BYTES + 1);
        let response = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
            oversized.len(),
            oversized
        );
        let response: &'static str = Box::leak(response.into_boxed_str());
        let addr = serve_once(response).await;
        let client = build_client(None, None).unwrap();
        let url = reqwest::Url::parse(&format!("http://{addr}/path")).unwrap();
        let result = execute_post(
            &client,
            url,
            "body".to_string(),
            "text/plain",
            &Default::default(),
            &EndpointCredentials::None,
        )
        .await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn does_not_follow_redirects() {
        let addr = serve_once(
            "HTTP/1.1 302 Found\r\nLocation: http://127.0.0.1:9/elsewhere\r\nContent-Length: 0\r\nConnection: close\r\n\r\n",
        )
        .await;
        let client = build_client(None, None).unwrap();
        let url = reqwest::Url::parse(&format!("http://{addr}/path")).unwrap();
        let result = execute_post(
            &client,
            url,
            "body".to_string(),
            "text/plain",
            &Default::default(),
            &EndpointCredentials::None,
        )
        .await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn sends_allowed_custom_request_header() {
        let (addr, request_rx) = serve_once_capturing(
            "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok",
        )
        .await;
        let client = build_client(None, None).unwrap();
        let url = reqwest::Url::parse(&format!("http://{addr}/path")).unwrap();
        let headers =
            BTreeMap::from([("X-Requested-With".to_string(), "XMLHttpRequest".to_string())]);

        execute_post(
            &client,
            url,
            "body".to_string(),
            "application/json",
            &headers,
            &EndpointCredentials::None,
        )
        .await
        .unwrap();

        let request = String::from_utf8(request_rx.await.unwrap()).unwrap();
        assert!(request
            .to_ascii_lowercase()
            .contains("\r\nx-requested-with: xmlhttprequest\r\n"));
    }

    #[tokio::test]
    async fn injects_traceparent_without_url_path_attributes() {
        TELEMETRY.get_or_init(|| crate::telemetry::init("http-post-test", None).unwrap());
        let (addr, request_rx) = serve_once_capturing(
            "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok",
        )
        .await;
        let client = build_client(None, None).unwrap();
        let url = reqwest::Url::parse(&format!("http://{addr}/private?secret=value")).unwrap();
        let parent = tracing::info_span!("test.parent");

        execute_post(
            &client,
            url,
            "body".to_string(),
            "text/plain",
            &Default::default(),
            &EndpointCredentials::None,
        )
        .instrument(parent)
        .await
        .unwrap();

        let request = String::from_utf8(request_rx.await.unwrap()).unwrap();
        assert!(request.to_ascii_lowercase().contains("\r\ntraceparent: "));
    }
}
