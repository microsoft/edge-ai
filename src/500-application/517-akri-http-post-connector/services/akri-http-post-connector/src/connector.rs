//! Device Registry lifecycle orchestration for the Akri HTTP POST connector.
//!
//! Observes Device Endpoints, Assets, and Dataset data operations from the Azure
//! Device Registry, builds a bounded HTTP client per device endpoint (rebuilt on
//! credential/trust rotation), compiles projected configuration into immutable
//! [`config::ObservationPlan`]s, and executes scheduled bounded POST requests whose
//! responses are forwarded to the data operation's configured destination(s).

use std::path::{Path, PathBuf};
use std::sync::Arc;

use azure_iot_operations_connector::base_connector::managed_azure_device_registry::{
    AssetClient, AssetComponentClient, AssetStatusReporter, ClientNotification,
    DataOperationClient, DataOperationDefinition, DataOperationNotification,
    DataOperationStatusReporter, DeviceEndpointClient, DeviceEndpointClientCreationObservation,
    DeviceEndpointStatusReporter, RuntimeHealthEvent,
};
use azure_iot_operations_connector::AdrConfigError;
use tokio::sync::RwLock;
use tracing::{info, warn};

use crate::config::{self, ObservationPlan};
use crate::destination::{self, SchemaCache};
use crate::http::{self, EndpointCredentials};
use crate::policy;
use crate::proof;
use crate::scheduler::{self, GlobalConcurrency};
use crate::telemetry;

/// Per-device-endpoint HTTP client, credentials, and base request address, rebuilt
/// whenever the device endpoint's specification changes (covering credential and
/// trust-bundle rotation). `None` until the first valid specification is observed.
#[derive(Clone)]
struct EndpointState {
    client: reqwest::Client,
    credentials: EndpointCredentials,
    address: String,
}

type SharedEndpointState = Arc<RwLock<Option<EndpointState>>>;

impl EndpointState {
    fn build(
        device_endpoint_client: &DeviceEndpointClient,
        trust_bundle_dir: Option<&PathBuf>,
    ) -> Result<Self, String> {
        let specification = device_endpoint_client.specification();
        let inbound = specification.endpoints.inbound;
        let (credentials, identity) = http::load_credentials(&inbound.authentication)?;
        let client = http::build_client(trust_bundle_dir, identity)?;
        Ok(Self {
            client,
            credentials,
            address: inbound.address,
        })
    }
}

/// Tracks the currently accepted [`ObservationPlan`] for a single dataset data
/// operation and the tick interval derived from it, recreating the interval only
/// when the sampling interval actually changes.
struct TickState {
    plan: Option<ObservationPlan>,
    interval: tokio::time::Interval,
    has_plan: bool,
}

impl TickState {
    fn new() -> Self {
        Self {
            plan: None,
            interval: scheduler::interval_for(config::MIN_SAMPLING_INTERVAL_MS),
            has_plan: false,
        }
    }

    fn apply(&mut self, new_plan: ObservationPlan) {
        let sampling_interval_ms = new_plan.dataset.sampling_interval_ms;
        let needs_new_interval = self
            .plan
            .as_ref()
            .map(|plan| plan.dataset.sampling_interval_ms)
            != Some(sampling_interval_ms);
        if needs_new_interval {
            self.interval = scheduler::interval_for(sampling_interval_ms);
        }
        self.plan = Some(new_plan);
        self.has_plan = true;
    }

    /// Cancels scheduled work immediately: no further ticks execute until a new
    /// valid plan is compiled and applied.
    fn clear(&mut self) {
        self.plan = None;
        self.has_plan = false;
    }
}

/// Observes Device Endpoint creation notifications and spawns a supervision task per
/// device endpoint. Runs until the underlying observation channel ends.
///
/// `secrets_metadata_mount` and `secrets_mount` are the Akri connector-template
/// secrets mount paths used to resolve each dataset's `request.bodySecretAlias`
/// (see [`crate::secret_body`]).
pub async fn run(
    mut device_creation_observation: DeviceEndpointClientCreationObservation,
    trust_bundle_dir: Option<PathBuf>,
    concurrency: GlobalConcurrency,
    secrets_metadata_mount: PathBuf,
    secrets_mount: PathBuf,
) -> Result<(), String> {
    loop {
        let device_endpoint_client = device_creation_observation.recv_notification().await;
        tokio::spawn(run_device_endpoint(
            device_endpoint_client,
            trust_bundle_dir.clone(),
            concurrency.clone(),
            secrets_metadata_mount.clone(),
            secrets_mount.clone(),
        ));
    }
}

/// Supervises a single device endpoint: builds (and rebuilds, on update) the HTTP
/// client and credentials, reports device/endpoint status and health, and spawns a
/// task per asset created under it.
async fn run_device_endpoint(
    mut device_endpoint_client: DeviceEndpointClient,
    trust_bundle_dir: Option<PathBuf>,
    concurrency: GlobalConcurrency,
    secrets_metadata_mount: PathBuf,
    secrets_mount: PathBuf,
) {
    let reporter = device_endpoint_client.get_status_reporter();
    let endpoint_state: SharedEndpointState = Arc::new(RwLock::new(None));
    rebuild_endpoint_state(
        &device_endpoint_client,
        trust_bundle_dir.as_ref(),
        &endpoint_state,
        &reporter,
    )
    .await;

    loop {
        match device_endpoint_client.recv_notification().await {
            ClientNotification::Created(asset_client) => {
                tokio::spawn(run_asset(
                    asset_client,
                    Arc::clone(&endpoint_state),
                    concurrency.clone(),
                    secrets_metadata_mount.clone(),
                    secrets_mount.clone(),
                ));
            }
            ClientNotification::Updated => {
                info!("device endpoint specification updated; rebuilding HTTP client");
                rebuild_endpoint_state(
                    &device_endpoint_client,
                    trust_bundle_dir.as_ref(),
                    &endpoint_state,
                    &reporter,
                )
                .await;
            }
            ClientNotification::Deleted => {
                info!("device endpoint deleted; ending observation");
                return;
            }
        }
    }
}

/// Rebuilds the shared [`EndpointState`] from the device endpoint's current
/// specification, reporting device/endpoint status and a health event to reflect
/// whether the resulting client is usable.
async fn rebuild_endpoint_state(
    device_endpoint_client: &DeviceEndpointClient,
    trust_bundle_dir: Option<&PathBuf>,
    endpoint_state: &SharedEndpointState,
    reporter: &DeviceEndpointStatusReporter,
) {
    match EndpointState::build(device_endpoint_client, trust_bundle_dir) {
        Ok(state) => {
            *endpoint_state.write().await = Some(state);
            report_device_endpoint_status(reporter, telemetry::ok_status()).await;
        }
        Err(err) => {
            warn!(error = %err, "device endpoint credentials/trust configuration rejected");
            *endpoint_state.write().await = None;
            report_device_endpoint_status(reporter, telemetry::error_status(err)).await;
        }
    }
}

async fn report_device_endpoint_status(
    reporter: &DeviceEndpointStatusReporter,
    status: Result<(), AdrConfigError>,
) {
    let _ = reporter
        .report_device_status_if_modified(telemetry::report_if_changed(status.clone()))
        .await;
    let _ = reporter
        .report_endpoint_status_if_modified(telemetry::report_if_changed(status.clone()))
        .await;
    match status {
        Ok(()) => reporter.report_health_event(RuntimeHealthEvent::Available),
        Err(err) => reporter.report_health_event(RuntimeHealthEvent::Unavailable {
            message: err.message,
            reason_code: Some("ConfigurationError".to_string()),
        }),
    }
}

/// Supervises a single asset: spawns a task per dataset data operation created
/// under it, and reports asset status.
async fn run_asset(
    mut asset_client: AssetClient,
    endpoint_state: SharedEndpointState,
    concurrency: GlobalConcurrency,
    secrets_metadata_mount: PathBuf,
    secrets_mount: PathBuf,
) {
    let reporter = asset_client.get_status_reporter();
    report_asset_status(&reporter, telemetry::ok_status()).await;

    loop {
        match asset_client.recv_notification().await {
            ClientNotification::Created(AssetComponentClient::DataOperation((
                data_operation_client,
                _initial_status,
            ))) => {
                tokio::spawn(run_data_operation(
                    data_operation_client,
                    Arc::clone(&endpoint_state),
                    concurrency.clone(),
                    secrets_metadata_mount.clone(),
                    secrets_mount.clone(),
                ));
            }
            ClientNotification::Created(_) => {
                // Management actions and any future component kinds are out of scope
                // for the HTTP POST connector.
            }
            ClientNotification::Updated => {
                info!("asset specification updated in place");
                report_asset_status(&reporter, telemetry::ok_status()).await;
            }
            ClientNotification::Deleted => {
                info!("asset deleted; ending observation");
                return;
            }
        }
    }
}

async fn report_asset_status(reporter: &AssetStatusReporter, status: Result<(), AdrConfigError>) {
    let _ = reporter
        .report_status_if_modified(telemetry::report_if_changed(status))
        .await;
}

/// Supervises a single dataset data operation: compiles an [`ObservationPlan`] from
/// the current endpoint state and dataset configuration, atomically replaces the
/// active plan on valid updates, cancels scheduled work immediately on deletion, and
/// executes scheduled bounded POST requests inline within its own tick branch.
async fn run_data_operation(
    mut data_operation_client: DataOperationClient,
    endpoint_state: SharedEndpointState,
    concurrency: GlobalConcurrency,
    secrets_metadata_mount: PathBuf,
    secrets_mount: PathBuf,
) {
    let reporter = data_operation_client.get_status_reporter();
    let mut schema_cache = SchemaCache::new();
    let mut tick_state = TickState::new();

    match compile_and_store_plan(
        &data_operation_client,
        &endpoint_state,
        &mut tick_state,
        &secrets_metadata_mount,
        &secrets_mount,
    )
    .await
    {
        Ok(()) => report_dataset_status(&reporter, telemetry::ok_status()).await,
        Err(err) => {
            warn!(error = %err, "initial dataset configuration rejected; awaiting an update");
            report_dataset_status(&reporter, telemetry::error_status(err)).await;
        }
    }

    loop {
        tokio::select! {
            biased;
            notification = data_operation_client.recv_notification() => {
                match notification {
                    DataOperationNotification::Updated(Ok(()))
                    | DataOperationNotification::AssetUpdated(Ok(())) => {
                        match compile_and_store_plan(
                            &data_operation_client,
                            &endpoint_state,
                            &mut tick_state,
                            &secrets_metadata_mount,
                            &secrets_mount,
                        ).await {
                            Ok(()) => {
                                info!("observation plan replaced after update");
                                report_dataset_status(&reporter, telemetry::ok_status()).await;
                            }
                            Err(err) => {
                                warn!(error = %err, "updated dataset configuration rejected");
                                tick_state.clear();
                                report_dataset_status(&reporter, telemetry::error_status(err)).await;
                            }
                        }
                    }
                    DataOperationNotification::Updated(Err(err))
                    | DataOperationNotification::AssetUpdated(Err(err)) => {
                        warn!(error = ?err, "data operation update reported a config error");
                        tick_state.clear();
                    }
                    DataOperationNotification::Deleted => {
                        info!("data operation deleted; cancelling observation plan");
                        tick_state.clear();
                        return;
                    }
                }
            }
            _ = tick_state.interval.tick(), if tick_state.has_plan => {
                execute_tick(
                    &mut data_operation_client,
                    &tick_state.plan,
                    &endpoint_state,
                    &concurrency,
                    &mut schema_cache,
                    &reporter,
                )
                .await;
            }
        }
    }
}

async fn report_dataset_status(
    reporter: &DataOperationStatusReporter,
    status: Result<(), AdrConfigError>,
) {
    let _ = reporter
        .report_status_if_modified(telemetry::report_if_changed(status))
        .await;
}

/// Reads the current dataset configuration from the data operation's definition,
/// compiles a plan against the current endpoint state's resolved base address and
/// the connector-template secrets mount, and applies it to `tick_state` only if
/// compilation succeeds.
async fn compile_and_store_plan(
    data_operation_client: &DataOperationClient,
    endpoint_state: &SharedEndpointState,
    tick_state: &mut TickState,
    secrets_metadata_mount: &Path,
    secrets_mount: &Path,
) -> Result<(), String> {
    let DataOperationDefinition::Dataset(dataset) = data_operation_client.definition() else {
        return Err("data operation is not a Dataset".to_string());
    };
    let raw_dataset_configuration = dataset
        .dataset_configuration
        .as_deref()
        .ok_or_else(|| "dataset has no dataset_configuration".to_string())?;
    let data_source = dataset.data_source.as_deref();

    let base_address = {
        let guard = endpoint_state.read().await;
        let state = guard
            .as_ref()
            .ok_or_else(|| "device endpoint has no usable HTTP client yet".to_string())?;
        state.address.clone()
    };

    let plan = config::compile_plan(
        &base_address,
        data_source,
        raw_dataset_configuration,
        secrets_metadata_mount,
        secrets_mount,
    )?;
    proof::record(&plan.resolved_body);
    info!(endpoint_address = %plan.endpoint.address, "compiled observation plan");
    tick_state.apply(plan);
    Ok(())
}

/// Executes one scheduled tick: acquires a global concurrency permit, sends the
/// bounded POST request, forwards the response to the data operation's destination,
/// retrying the whole attempt once only when the dataset declares idempotent
/// semantics and destination forwarding was not yet attempted, then reports status
/// and a health event reflecting the outcome.
async fn execute_tick(
    data_operation_client: &mut DataOperationClient,
    plan: &Option<ObservationPlan>,
    endpoint_state: &SharedEndpointState,
    concurrency: &GlobalConcurrency,
    schema_cache: &mut SchemaCache,
    reporter: &DataOperationStatusReporter,
) {
    let Some(plan) = plan else {
        return;
    };
    let Some(state) = endpoint_state.read().await.clone() else {
        warn!("skipping tick; device endpoint has no usable HTTP client");
        return;
    };

    let _permit = concurrency.acquire().await;

    let mut destination_forward_attempted = false;
    let mut result = attempt_post_and_forward(
        data_operation_client,
        plan,
        &state,
        schema_cache,
        &mut destination_forward_attempted,
    )
    .await;

    if let Err(ref err) = result {
        if policy::retry_eligible(
            plan.dataset.request.idempotent,
            destination_forward_attempted,
        ) {
            warn!(error = %err, "POST attempt failed; retrying once for an idempotent request");
            result = attempt_post_and_forward(
                data_operation_client,
                plan,
                &state,
                schema_cache,
                &mut destination_forward_attempted,
            )
            .await;
        }
    }

    match result {
        Ok(()) => {
            report_dataset_status(reporter, telemetry::ok_status()).await;
            reporter.report_health_event(RuntimeHealthEvent::Available);
        }
        Err(err) => {
            warn!(error = %err, "POST attempt failed");
            report_dataset_status(reporter, telemetry::error_status(err.clone())).await;
            reporter.report_health_event(RuntimeHealthEvent::Unavailable {
                message: Some(err),
                reason_code: Some("PostExecutionError".to_string()),
            });
        }
    }
}

async fn attempt_post_and_forward(
    data_operation_client: &mut DataOperationClient,
    plan: &ObservationPlan,
    state: &EndpointState,
    schema_cache: &mut SchemaCache,
    destination_forward_attempted: &mut bool,
) -> Result<(), String> {
    let response = http::execute_post(
        &state.client,
        plan.endpoint.address.clone(),
        plan.resolved_body.clone(),
        &plan.dataset.request.content_type,
        &state.credentials,
    )
    .await?;

    *destination_forward_attempted = true;
    destination::forward_response(
        data_operation_client,
        schema_cache,
        response.body,
        response.content_type,
    )
    .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::{DatasetConfiguration, EndpointPolicy, RequestConfiguration};
    use url::Url;

    fn plan_with_interval(sampling_interval_ms: u32) -> ObservationPlan {
        ObservationPlan {
            endpoint: EndpointPolicy {
                address: Url::parse("http://127.0.0.1:8080/retrieval").unwrap(),
            },
            dataset: DatasetConfiguration {
                schema_version: config::DATASET_CONFIGURATION_SCHEMA_VERSION,
                request: RequestConfiguration {
                    body_secret_alias: "body-secret".to_string(),
                    content_type: "application/json".to_string(),
                    idempotent: false,
                },
                sampling_interval_ms,
            },
            resolved_body: "x".repeat(10_000),
        }
    }

    #[tokio::test]
    async fn tick_state_starts_without_a_plan() {
        let tick_state = TickState::new();
        assert!(!tick_state.has_plan);
        assert!(tick_state.plan.is_none());
    }

    #[tokio::test]
    async fn apply_replaces_the_active_plan_and_marks_has_plan() {
        let mut tick_state = TickState::new();
        tick_state.apply(plan_with_interval(500));
        assert!(tick_state.has_plan);
        assert_eq!(
            tick_state
                .plan
                .as_ref()
                .unwrap()
                .dataset
                .sampling_interval_ms,
            500
        );

        tick_state.apply(plan_with_interval(500));
        assert!(tick_state.has_plan);
    }

    #[tokio::test]
    async fn apply_reconstructs_the_interval_only_when_sampling_interval_changes() {
        let mut tick_state = TickState::new();
        tick_state.apply(plan_with_interval(500));
        let period_before = tick_state.interval.period();

        tick_state.apply(plan_with_interval(500));
        assert_eq!(tick_state.interval.period(), period_before);

        tick_state.apply(plan_with_interval(1_000));
        assert_ne!(tick_state.interval.period(), period_before);
        assert_eq!(
            tick_state.interval.period(),
            std::time::Duration::from_millis(1_000)
        );
    }

    #[tokio::test]
    async fn clear_cancels_scheduled_work_immediately() {
        let mut tick_state = TickState::new();
        tick_state.apply(plan_with_interval(500));
        assert!(tick_state.has_plan);

        tick_state.clear();
        assert!(!tick_state.has_plan);
        assert!(tick_state.plan.is_none());
    }
}
