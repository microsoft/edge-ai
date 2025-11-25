use std::sync::Arc;

use anyhow::{anyhow, Result};
use tokio::{
    io::{AsyncReadExt, AsyncWriteExt},
    net::{TcpListener, TcpStream},
    sync::oneshot,
    task::JoinHandle,
};
use tracing::{info, warn};

use crate::config::HealthConfig;

pub struct HealthServer {
    shutdown_tx: Option<oneshot::Sender<()>>,
    handle: JoinHandle<Result<()>>,
}

impl HealthServer {
    pub async fn spawn(config: HealthConfig) -> Result<Self> {
        let listener = TcpListener::bind(config.bind_addr).await.map_err(|err| {
            anyhow!(
                "failed to bind health endpoint on {}: {err}",
                config.bind_addr
            )
        })?;

        info!(
            address = %config.bind_addr,
            liveness_path = %config.liveness_path,
            readiness_path = %config.readiness_path,
            "HTTP health endpoint listening"
        );

        let (shutdown_tx, shutdown_rx) = oneshot::channel();
        let shared_config = Arc::new(config);
        let server_config = shared_config.clone();

        let handle = tokio::spawn(async move { run(listener, server_config, shutdown_rx).await });

        Ok(Self {
            shutdown_tx: Some(shutdown_tx),
            handle,
        })
    }

    pub async fn shutdown(mut self) -> Result<()> {
        if let Some(tx) = self.shutdown_tx.take() {
            let _ = tx.send(());
        }

        match self.handle.await {
            Ok(result) => result,
            Err(err) if err.is_cancelled() => Ok(()),
            Err(err) => Err(anyhow!("health server task failed: {err}")),
        }
    }
}

async fn run(
    listener: TcpListener,
    config: Arc<HealthConfig>,
    mut shutdown: oneshot::Receiver<()>,
) -> Result<()> {
    loop {
        tokio::select! {
            accept_result = listener.accept() => {
                match accept_result {
                    Ok((stream, peer)) => {
                        let cfg = config.clone();
                        tokio::spawn(async move {
                            if let Err(err) = handle_connection(stream, cfg).await {
                                warn!(target = "health", peer = %peer, "health check request failed: {err:?}");
                            }
                        });
                    }
                    Err(err) => {
                        warn!(target = "health", "failed to accept health connection: {err:?}");
                    }
                }
            }
            _ = &mut shutdown => {
                info!("Shutting down HTTP health endpoint");
                break;
            }
        }
    }

    Ok(())
}

async fn handle_connection(stream: TcpStream, config: Arc<HealthConfig>) -> Result<()> {
    let mut stream = stream;
    let mut buffer = [0u8; 1024];
    let bytes_read = stream.read(&mut buffer).await?;
    if bytes_read == 0 {
        return Ok(());
    }

    let request = String::from_utf8_lossy(&buffer[..bytes_read]);
    let mut parts = request
        .lines()
        .next()
        .unwrap_or_default()
        .split_whitespace();
    let method = parts.next().unwrap_or("");
    let path = parts.next().unwrap_or("/");
    let path = path.split('?').next().unwrap_or(path);

    if method != "GET" && method != "HEAD" {
        write_response(&mut stream, 405, b"method not allowed", method == "HEAD").await?;
        return Ok(());
    }

    let (status, body) = if path == config.liveness_path || path == "/" {
        (200, b"ok".as_slice())
    } else if path == config.readiness_path {
        (200, b"ready".as_slice())
    } else {
        (404, b"not found".as_slice())
    };

    write_response(&mut stream, status, body, method == "HEAD").await?;
    Ok(())
}

async fn write_response(
    stream: &mut TcpStream,
    status: u16,
    body: &[u8],
    head_request: bool,
) -> Result<()> {
    let status_line = match status {
        200 => "HTTP/1.1 200 OK",
        404 => "HTTP/1.1 404 Not Found",
        405 => "HTTP/1.1 405 Method Not Allowed",
        _ => "HTTP/1.1 500 Internal Server Error",
    };

    let response_header = format!(
        "{status_line}\r\ncontent-type: text/plain; charset=utf-8\r\ncontent-length: {}\r\nconnection: close\r\n\r\n",
        body.len()
    );

    stream.write_all(response_header.as_bytes()).await?;

    if !head_request {
        stream.write_all(body).await?;
    }

    stream.shutdown().await?;
    Ok(())
}
