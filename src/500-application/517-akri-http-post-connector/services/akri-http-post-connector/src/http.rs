//! Bounded, SSRF-conscious HTTP POST execution using rustls.
//!
//! Builds one [`reqwest::Client`] per device inbound endpoint (rebuilt whenever the
//! endpoint's authentication or trust settings change), disables redirects and
//! automatic proxy discovery, enforces explicit connect/total timeouts, and reads
//! response bodies up to [`policy::MAX_RESPONSE_BODY_BYTES`] regardless of what the
//! response's `Content-Length` header claims.

use std::path::{Path, PathBuf};

use azure_iot_operations_connector::base_connector::managed_azure_device_registry::Authentication;
use reqwest::{Client, ClientBuilder, Response};

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
pub fn build_client(
    trust_bundle_dir: Option<&PathBuf>,
    identity: Option<reqwest::Identity>,
) -> Result<Client, String> {
    let mut builder = ClientBuilder::new()
        .connect_timeout(policy::CONNECT_TIMEOUT)
        .timeout(policy::TOTAL_TIMEOUT)
        .redirect(reqwest::redirect::Policy::none())
        .no_proxy();

    if let Some(dir) = trust_bundle_dir {
        for cert in load_trust_bundle(dir)? {
            builder = builder.add_root_certificate(cert);
        }
    }
    if let Some(identity) = identity {
        builder = builder.identity(identity);
    }

    builder
        .build()
        .map_err(|err| format!("failed to build HTTP client: {err}"))
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

/// The outcome of a single POST execution: the validated response content type
/// (falling back to `application/octet-stream` for non-textual or missing values)
/// and its bounded, fully-read body.
pub struct PostResponse {
    pub content_type: String,
    pub body: Vec<u8>,
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
    credentials: &EndpointCredentials,
) -> Result<PostResponse, String> {
    let mut request = client
        .post(url)
        .header(reqwest::header::CONTENT_TYPE, content_type)
        .body(body);
    if let EndpointCredentials::BasicAuth { username, password } = credentials {
        request = request.basic_auth(username, Some(password));
    }

    let response = request
        .send()
        .await
        .map_err(|err| format!("POST request failed: {err}"))?
        .error_for_status()
        .map_err(|err| format!("POST response indicated failure: {err}"))?;

    let response_content_type = response
        .headers()
        .get(reqwest::header::CONTENT_TYPE)
        .and_then(|value| value.to_str().ok())
        .filter(|value| policy::is_textual_mime(value))
        .unwrap_or("application/octet-stream")
        .to_string();

    let body = read_bounded_body(response).await?;

    Ok(PostResponse {
        content_type: response_content_type,
        body,
    })
}

/// Reads a response body in chunks, stopping with an error before the accumulated
/// buffer would exceed [`policy::MAX_RESPONSE_BODY_BYTES`].
async fn read_bounded_body(mut response: Response) -> Result<Vec<u8>, String> {
    let mut buffer = Vec::new();
    while let Some(chunk) = response
        .chunk()
        .await
        .map_err(|err| format!("failed reading response body: {err}"))?
    {
        if buffer.len() + chunk.len() > policy::MAX_RESPONSE_BODY_BYTES {
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

    use tokio::io::{AsyncReadExt, AsyncWriteExt};
    use tokio::net::TcpListener;

    use super::*;

    /// Starts a minimal single-request HTTP/1.1 mock server that ignores the
    /// request and replies with `response`, then stops listening.
    async fn serve_once(response: &'static str) -> SocketAddr {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        tokio::spawn(async move {
            let (mut socket, _) = listener.accept().await.unwrap();
            let mut buf = [0u8; 4096];
            // Drain whatever the client sent; a real HTTP client will close the
            // write side once it has sent headers+body, we just need to read some.
            let _ = socket.read(&mut buf).await;
            let _: Result<(), Infallible> = Ok(());
            socket.write_all(response.as_bytes()).await.unwrap();
            socket.shutdown().await.unwrap();
        });
        addr
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
        // error_for_status() only rejects 4xx/5xx; a 302 with redirects disabled is
        // surfaced as a successful (non-followed) response rather than an error.
        let result = execute_post(
            &client,
            url,
            "body".to_string(),
            "text/plain",
            &EndpointCredentials::None,
        )
        .await;
        assert!(result.is_ok());
    }
}
