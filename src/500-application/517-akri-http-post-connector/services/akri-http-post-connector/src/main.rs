//! Akri HTTP POST Connector entrypoint.
//!
//! Wires a `BaseConnector` to the Azure Device Registry, observes Device Endpoints,
//! Assets, and Dataset data operations, and executes scheduled bounded HTTP POST
//! requests whose responses are forwarded to each data operation's configured
//! destination.

mod config;
mod connector;
mod destination;
mod http;
mod policy;
mod proof;
mod scheduler;
mod secret_body;
mod telemetry;

use anyhow::{Context, Result};
use azure_iot_operations_connector::base_connector::{BaseConnector, OptionsBuilder};
use azure_iot_operations_connector::deployment_artifacts::connector::ConnectorArtifacts;
use azure_iot_operations_protocol::application::ApplicationContextBuilder;

/// Maximum number of POST requests allowed in flight at once across every data
/// operation owned by this connector instance.
const GLOBAL_CONCURRENCY_LIMIT: usize = 8;

#[tokio::main]
async fn main() -> Result<()> {
    let connector_artifacts = ConnectorArtifacts::new_from_deployment()
        .map_err(|err| anyhow::anyhow!(err.to_string()))
        .context("failed to load connector artifacts")?;
    let configured_log_level = connector_artifacts
        .connector_configuration
        .diagnostics
        .as_ref()
        .map(|diagnostics| diagnostics.logs.level.as_str());
    let _telemetry_guard = telemetry::init("akri-http-post-connector", configured_log_level)
        .map_err(anyhow::Error::msg)
        .context("failed to initialize telemetry")?;
    // Extracted before `connector_artifacts` is consumed by `BaseConnector::new` below.
    let trust_bundle_dir = connector_artifacts.connector_trust_settings_mount.clone();
    // Both secrets mount paths resolve `request.bodySecretAlias` (see `secret_body`);
    // either being absent is a startup configuration error, not a per-request one.
    let connector_secrets_metadata_mount = connector_artifacts
        .connector_secrets_metadata_mount
        .clone()
        .ok_or_else(|| {
            anyhow::anyhow!(
                "CONNECTOR_SECRETS_METADATA_MOUNT_PATH is required to resolve request.bodySecretAlias"
            )
        })?;
    let connector_secrets_mount = std::env::var("CONNECTOR_SECRETS_MOUNT_PATH")
        .map(std::path::PathBuf::from)
        .map_err(|_| {
            anyhow::anyhow!(
                "CONNECTOR_SECRETS_MOUNT_PATH is required to resolve request.bodySecretAlias"
            )
        })?;
    let application_context = ApplicationContextBuilder::default()
        .build()
        .context("failed to build application context")?;
    let base_connector_options = OptionsBuilder::default()
        .build()
        .context("failed to build base connector options")?;
    let base_connector = BaseConnector::new(
        application_context,
        connector_artifacts,
        base_connector_options,
    )
    .map_err(anyhow::Error::msg)
    .context("failed to construct base connector")?;

    // The device endpoint creation observation must be created before `run(self)`
    // consumes the connector, since it borrows the connector to register itself.
    let device_creation_observation = base_connector
        .create_device_endpoint_client_create_observation()
        .map_err(anyhow::Error::msg)
        .context("failed to create device endpoint observation")?;
    let concurrency = scheduler::GlobalConcurrency::new(GLOBAL_CONCURRENCY_LIMIT);
    let observation_task = tokio::spawn(connector::run(
        device_creation_observation,
        trust_bundle_dir,
        concurrency,
        connector_secrets_metadata_mount,
        connector_secrets_mount,
    ));

    tokio::select! {
        result = observation_task => {
            result
                .context("observation task panicked")?
                .map_err(anyhow::Error::msg)
                .context("observation loop ended")?;
        }
        result = base_connector.run() => {
            result
                .map_err(|err| anyhow::anyhow!(err.to_string()))
                .context("base connector runtime ended")?;
        }
    }

    Ok(())
}
