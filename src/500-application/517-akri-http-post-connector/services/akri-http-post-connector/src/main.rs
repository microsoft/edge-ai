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
mod telemetry;

use anyhow::{Context, Result};
use azure_iot_operations_connector::base_connector::{BaseConnector, OptionsBuilder};
use azure_iot_operations_connector::deployment_artifacts::connector::ConnectorArtifacts;
use azure_iot_operations_protocol::application::ApplicationContextBuilder;
use tracing_subscriber::{fmt, prelude::*, EnvFilter};

/// Maximum number of POST requests allowed in flight at once across every data
/// operation owned by this connector instance.
const GLOBAL_CONCURRENCY_LIMIT: usize = 8;

fn init_logging() -> Result<()> {
    let filter = EnvFilter::try_from_default_env().or_else(|_| EnvFilter::try_new("info"))?;
    let _ = tracing_subscriber::registry()
        .with(filter)
        .with(fmt::layer().with_target(true))
        .try_init();
    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    init_logging()?;

    let connector_artifacts = ConnectorArtifacts::new_from_deployment()
        .map_err(|err| anyhow::anyhow!(err.to_string()))
        .context("failed to load connector artifacts")?;
    // Extracted before `connector_artifacts` is consumed by `BaseConnector::new` below.
    let trust_bundle_dir = connector_artifacts
        .device_endpoint_trust_bundle_mount
        .clone();
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
