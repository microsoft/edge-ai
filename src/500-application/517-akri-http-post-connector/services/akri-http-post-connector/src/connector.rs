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
use tokio::sync::{watch, RwLock};
use tokio::task::JoinSet;
use tokio_util::sync::CancellationToken;
use tracing::{info, warn};

use crate::config::{self, ObservationPlan};
use crate::destination::{self, SchemaCache};
use crate::http::{self, EndpointCredentials};
use crate::policy;
use crate::proof;
use crate::scheduler::{self, GlobalConcurrency};
use crate::secret_body;
use crate::telemetry;

/// Per-device-endpoint HTTP client, credentials, and base request address, rebuilt
/// whenever the device endpoint's specification changes (covering credential and
/// trust-bundle rotation). `None` until the first valid specification is observed.
#[derive(Clone)]
struct EndpointState {
    client: reqwest::Client,
    credentials: EndpointCredentials,
    address: reqwest::Url,
}

struct EndpointStore {
    state: RwLock<Option<EndpointState>>,
    generation: watch::Sender<u64>,
}

type SharedEndpointState = Arc<EndpointStore>;

const CHILD_SHUTDOWN_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(5);

impl EndpointStore {
    fn new() -> Self {
        let (generation, _) = watch::channel(0);
        Self {
            state: RwLock::new(None),
            generation,
        }
    }

    async fn replace(&self, state: Option<EndpointState>) {
        *self.state.write().await = state;
        self.generation.send_modify(|generation| *generation += 1);
    }

    async fn snapshot(&self) -> Option<EndpointState> {
        self.state.read().await.clone()
    }

    fn subscribe(&self) -> watch::Receiver<u64> {
        self.generation.subscribe()
    }
}

enum WorkerOutcome {
    Response(http::PostResponse),
    Failed(telemetry::FailureReason),
    Cancelled,
}

struct ResolvedRequest {
    state: EndpointState,
    url: reqwest::Url,
    body: String,
}

impl EndpointState {
    async fn build(
        device_endpoint_client: &DeviceEndpointClient,
        trust_bundle_dir: Option<&PathBuf>,
    ) -> Result<Self, String> {
        let specification = device_endpoint_client.specification();
        let inbound = specification.endpoints.inbound;
        let address = config::parse_endpoint_address(&inbound.address)?;
        let (client, credentials) =
            http::build_endpoint_client(&address, &inbound.authentication, trust_bundle_dir)?;
        Ok(Self {
            client,
            credentials,
            address,
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
    let mut endpoint_tasks = JoinSet::new();
    loop {
        tokio::select! {
            device_endpoint_client = device_creation_observation.recv_notification() => {
                endpoint_tasks.spawn(run_device_endpoint(
                    device_endpoint_client,
                    trust_bundle_dir.clone(),
                    concurrency.clone(),
                    secrets_metadata_mount.clone(),
                    secrets_mount.clone(),
                    CancellationToken::new(),
                ));
            }
            result = endpoint_tasks.join_next(), if !endpoint_tasks.is_empty() => {
                report_task_result("device endpoint", result);
            }
        }
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
    cancellation: CancellationToken,
) {
    let reporter = device_endpoint_client.get_status_reporter();
    let endpoint_state: SharedEndpointState = Arc::new(EndpointStore::new());
    rebuild_endpoint_state(
        &device_endpoint_client,
        trust_bundle_dir.as_ref(),
        &endpoint_state,
        &reporter,
    )
    .await;

    let mut asset_tasks = JoinSet::new();
    loop {
        tokio::select! {
            biased;
            _ = cancellation.cancelled() => break,
            notification = device_endpoint_client.recv_notification() => {
                match notification {
                    ClientNotification::Created(asset_client) => {
                        asset_tasks.spawn(run_asset(
                            asset_client,
                            Arc::clone(&endpoint_state),
                            concurrency.clone(),
                            secrets_metadata_mount.clone(),
                            secrets_mount.clone(),
                            cancellation.child_token(),
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
                        break;
                    }
                }
            }
            result = asset_tasks.join_next(), if !asset_tasks.is_empty() => {
                report_task_result("asset", result);
            }
        }
    }

    cancellation.cancel();
    shutdown_tasks(&mut asset_tasks).await;
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
    match EndpointState::build(device_endpoint_client, trust_bundle_dir).await {
        Ok(state) => {
            endpoint_state.replace(Some(state)).await;
            report_device_endpoint_status(reporter, telemetry::ok_status()).await;
        }
        Err(_) => {
            let reason = "EndpointConfigurationRejected";
            warn!(reason, "device endpoint configuration rejected");
            endpoint_state.replace(None).await;
            report_device_endpoint_status(reporter, telemetry::error_status(reason)).await;
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
    cancellation: CancellationToken,
) {
    let reporter = asset_client.get_status_reporter();
    report_asset_status(&reporter, telemetry::ok_status()).await;

    let mut data_operation_tasks = JoinSet::new();
    loop {
        tokio::select! {
            biased;
            _ = cancellation.cancelled() => break,
            notification = asset_client.recv_notification() => {
                match notification {
                    ClientNotification::Created(AssetComponentClient::DataOperation((
                        data_operation_client,
                        _initial_status,
                    ))) => {
                        data_operation_tasks.spawn(run_data_operation(
                            data_operation_client,
                            Arc::clone(&endpoint_state),
                            concurrency.clone(),
                            secrets_metadata_mount.clone(),
                            secrets_mount.clone(),
                            cancellation.child_token(),
                        ));
                    }
                    ClientNotification::Created(_) => {}
                    ClientNotification::Updated => {
                        info!("asset specification updated in place");
                        report_asset_status(&reporter, telemetry::ok_status()).await;
                    }
                    ClientNotification::Deleted => {
                        info!("asset deleted; ending observation");
                        break;
                    }
                }
            }
            result = data_operation_tasks.join_next(), if !data_operation_tasks.is_empty() => {
                report_task_result("data operation", result);
            }
        }
    }

    cancellation.cancel();
    shutdown_tasks(&mut data_operation_tasks).await;
}

async fn report_asset_status(reporter: &AssetStatusReporter, status: Result<(), AdrConfigError>) {
    let _ = reporter
        .report_status_if_modified(telemetry::report_if_changed(status))
        .await;
}

/// Supervises one dataset while retaining exclusive ownership of its SDK client.
async fn run_data_operation(
    mut data_operation_client: DataOperationClient,
    endpoint_state: SharedEndpointState,
    concurrency: GlobalConcurrency,
    secrets_metadata_mount: PathBuf,
    secrets_mount: PathBuf,
    cancellation: CancellationToken,
) {
    let mut reporter = data_operation_client.get_status_reporter();
    let mut schema_cache = SchemaCache::new();
    let mut tick_state = TickState::new();
    let mut endpoint_updates = endpoint_state.subscribe();
    let mut worker_tasks = JoinSet::new();
    let mut worker_cancellation = None;

    match compile_and_store_plan(&data_operation_client, &mut tick_state) {
        Ok(()) => report_dataset_status(&reporter, telemetry::ok_status()).await,
        Err(_) => {
            warn!(
                reason = telemetry::FailureReason::ConfigurationRejected.code(),
                "initial dataset configuration rejected; awaiting an update"
            );
            report_dataset_unavailable(&reporter, telemetry::FailureReason::ConfigurationRejected)
                .await;
        }
    }

    loop {
        tokio::select! {
            biased;
            _ = cancellation.cancelled() => {
                tick_state.clear();
                cancel_worker(&mut worker_tasks, &mut worker_cancellation).await;
                return;
            }
            changed = endpoint_updates.changed() => {
                if changed.is_ok() {
                    cancel_worker(&mut worker_tasks, &mut worker_cancellation).await;
                }
            }
            notification = data_operation_client.recv_notification() => {
                cancel_worker(&mut worker_tasks, &mut worker_cancellation).await;
                if matches!(
                    notification,
                    DataOperationNotification::Updated(_)
                        | DataOperationNotification::AssetUpdated(_)
                ) {
                    reporter.pause_and_refresh_health_version();
                }
                match notification {
                    DataOperationNotification::Updated(Ok(()))
                    | DataOperationNotification::AssetUpdated(Ok(())) => {
                        match compile_and_store_plan(&data_operation_client, &mut tick_state) {
                            Ok(()) => {
                                info!("observation plan replaced after update");
                                report_dataset_status(&reporter, telemetry::ok_status()).await;
                            }
                            Err(_) => {
                                warn!(reason = telemetry::FailureReason::ConfigurationRejected.code(), "updated dataset configuration rejected");
                                tick_state.clear();
                                report_dataset_unavailable(
                                    &reporter,
                                    telemetry::FailureReason::ConfigurationRejected,
                                ).await;
                            }
                        }
                    }
                    DataOperationNotification::Updated(Err(_))
                    | DataOperationNotification::AssetUpdated(Err(_)) => {
                        warn!(reason = telemetry::FailureReason::ConfigurationRejected.code(), "data operation update reported a configuration error");
                        tick_state.clear();
                        report_dataset_unavailable(
                            &reporter,
                            telemetry::FailureReason::ConfigurationRejected,
                        ).await;
                    }
                    DataOperationNotification::Deleted => {
                        info!("data operation deleted; cancelling observation plan");
                        tick_state.clear();
                        return;
                    }
                }
            }
            result = worker_tasks.join_next(), if !worker_tasks.is_empty() => {
                worker_cancellation = None;
                match result {
                    Some(Ok(outcome)) => {
                        handle_worker_outcome(
                            outcome,
                            &mut data_operation_client,
                            &mut schema_cache,
                            &reporter,
                            &cancellation,
                        ).await;
                    }
                    Some(Err(err)) => warn!(error = %err, "dataset worker failed"),
                    None => {}
                }
            }
            _ = tick_state.interval.tick(), if tick_state.has_plan && worker_tasks.is_empty() => {
                let worker_token = cancellation.child_token();
                worker_cancellation = Some(worker_token.clone());
                worker_tasks.spawn(execute_worker(
                    tick_state.plan.clone().expect("has_plan requires a plan"),
                    Arc::clone(&endpoint_state),
                    concurrency.clone(),
                    secrets_metadata_mount.clone(),
                    secrets_mount.clone(),
                    worker_token,
                ));
            }
        }
    }
}

fn report_task_result(task_kind: &str, result: Option<Result<(), tokio::task::JoinError>>) {
    if let Some(Err(err)) = result {
        warn!(task_kind, error = %err, "connector supervision task failed");
    }
}

async fn shutdown_tasks(tasks: &mut JoinSet<()>) {
    let timeout = tokio::time::sleep(CHILD_SHUTDOWN_TIMEOUT);
    tokio::pin!(timeout);

    while !tasks.is_empty() {
        tokio::select! {
            result = tasks.join_next() => report_task_result("child", result),
            _ = &mut timeout => {
                tasks.abort_all();
                while let Some(result) = tasks.join_next().await {
                    report_task_result("aborted child", Some(result));
                }
                return;
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

async fn report_dataset_unavailable(
    reporter: &DataOperationStatusReporter,
    reason: telemetry::FailureReason,
) {
    if reason.invalidates_runtime_configuration() {
        report_dataset_status(reporter, telemetry::error_status(reason.code())).await;
    }
    reporter.report_health_event(RuntimeHealthEvent::Unavailable {
        message: Some(reason.code().to_string()),
        reason_code: Some(reason.code().to_string()),
    });
}

/// Reads and validates immutable dataset intent and applies it atomically.
fn compile_and_store_plan(
    data_operation_client: &DataOperationClient,
    tick_state: &mut TickState,
) -> Result<(), String> {
    let DataOperationDefinition::Dataset(dataset) = data_operation_client.definition() else {
        return Err("data operation is not a Dataset".to_string());
    };
    let raw_dataset_configuration = dataset
        .dataset_configuration
        .as_deref()
        .ok_or_else(|| "dataset has no dataset_configuration".to_string())?;
    let data_source = dataset.data_source.as_deref();

    let plan = config::compile_plan(data_source, raw_dataset_configuration)?;
    info!("compiled observation plan");
    tick_state.apply(plan);
    Ok(())
}

async fn execute_worker(
    plan: ObservationPlan,
    endpoint_state: SharedEndpointState,
    concurrency: GlobalConcurrency,
    secrets_metadata_mount: PathBuf,
    secrets_mount: PathBuf,
    cancellation: CancellationToken,
) -> WorkerOutcome {
    let _permit = tokio::select! {
        biased;
        _ = cancellation.cancelled() => return WorkerOutcome::Cancelled,
        permit = concurrency.acquire() => permit,
    };
    let request = match resolve_request(
        &plan,
        &endpoint_state,
        &secrets_metadata_mount,
        &secrets_mount,
        &cancellation,
    )
    .await
    {
        Ok(request) => request,
        Err(outcome) => return outcome,
    };

    let mut result = execute_post(&plan, &request, &cancellation).await;
    if matches!(
        result,
        WorkerOutcome::Failed(telemetry::FailureReason::RequestFailed)
    ) && policy::retry_eligible(plan.dataset.request.idempotent, false)
    {
        result = execute_post(&plan, &request, &cancellation).await;
    }
    result
}

async fn resolve_request(
    plan: &ObservationPlan,
    endpoint_state: &SharedEndpointState,
    secrets_metadata_mount: &Path,
    secrets_mount: &Path,
    cancellation: &CancellationToken,
) -> Result<ResolvedRequest, WorkerOutcome> {
    let state = tokio::select! {
        biased;
        _ = cancellation.cancelled() => return Err(WorkerOutcome::Cancelled),
        state = endpoint_state.snapshot() => state,
    }
    .ok_or(WorkerOutcome::Failed(
        telemetry::FailureReason::EndpointUnavailable,
    ))?;
    let url = policy::resolve_request_url(&state.address, plan.data_source.as_deref())
        .map_err(|_| WorkerOutcome::Failed(telemetry::FailureReason::InvalidEndpoint))?;
    let body = tokio::select! {
        biased;
        _ = cancellation.cancelled() => return Err(WorkerOutcome::Cancelled),
        body = secret_body::resolve_body(
            secrets_metadata_mount,
            secrets_mount,
            &plan.dataset.request.body_secret_alias,
        ) => body.map_err(|_| WorkerOutcome::Failed(telemetry::FailureReason::BodyUnavailable))?,
    };
    proof::record(&body);
    Ok(ResolvedRequest { state, url, body })
}

async fn execute_post(
    plan: &ObservationPlan,
    request: &ResolvedRequest,
    cancellation: &CancellationToken,
) -> WorkerOutcome {
    tokio::select! {
        biased;
        _ = cancellation.cancelled() => WorkerOutcome::Cancelled,
        result = http::execute_post(
            &request.state.client,
            request.url.clone(),
            request.body.clone(),
            &plan.dataset.request.content_type,
            &request.state.credentials,
        ) => match result {
            Ok(response) => WorkerOutcome::Response(response),
            Err(_) => WorkerOutcome::Failed(telemetry::FailureReason::RequestFailed),
        },
    }
}

async fn handle_worker_outcome(
    outcome: WorkerOutcome,
    data_operation_client: &mut DataOperationClient,
    schema_cache: &mut SchemaCache,
    reporter: &DataOperationStatusReporter,
    cancellation: &CancellationToken,
) {
    let result = match outcome {
        WorkerOutcome::Response(response) => tokio::select! {
            biased;
            _ = cancellation.cancelled() => return,
            result = destination::forward_response(
                data_operation_client,
                schema_cache,
                response.body,
                response.content_type,
            ) => result.map_err(|_| telemetry::FailureReason::ForwardingFailed),
        },
        WorkerOutcome::Failed(failure) => Err(failure),
        WorkerOutcome::Cancelled => return,
    };

    match result {
        Ok(()) => {
            report_dataset_status(reporter, telemetry::ok_status()).await;
            reporter.report_health_event(RuntimeHealthEvent::Available);
        }
        Err(failure) => {
            warn!(reason = failure.code(), "POST attempt failed");
            report_dataset_unavailable(reporter, failure).await;
        }
    }
}

async fn cancel_worker(
    workers: &mut JoinSet<WorkerOutcome>,
    cancellation: &mut Option<CancellationToken>,
) {
    if let Some(cancellation) = cancellation.take() {
        cancellation.cancel();
    }
    let timeout = tokio::time::sleep(CHILD_SHUTDOWN_TIMEOUT);
    tokio::pin!(timeout);
    while !workers.is_empty() {
        tokio::select! {
            _ = workers.join_next() => {}
            _ = &mut timeout => {
                workers.abort_all();
                while workers.join_next().await.is_some() {}
                return;
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::{DatasetConfiguration, RequestConfiguration};
    use std::sync::atomic::{AtomicU64, Ordering};

    struct TestMount {
        metadata_dir: PathBuf,
        secrets_dir: PathBuf,
    }

    impl TestMount {
        fn new(body: &str) -> Self {
            static COUNTER: AtomicU64 = AtomicU64::new(0);
            let unique = COUNTER.fetch_add(1, Ordering::Relaxed);
            let base = std::env::temp_dir().join(format!(
                "akri-http-post-connector-worker-test-{}-{unique}",
                std::process::id()
            ));
            let metadata_dir = base.join("metadata");
            let secrets_dir = base.join("secrets");
            std::fs::create_dir_all(&metadata_dir).unwrap();
            std::fs::create_dir_all(&secrets_dir).unwrap();
            std::fs::write(metadata_dir.join("body-secret"), "content").unwrap();
            std::fs::write(secrets_dir.join("content"), body).unwrap();
            Self {
                metadata_dir,
                secrets_dir,
            }
        }

        fn replace_body(&self, body: &str) {
            std::fs::write(self.secrets_dir.join("content"), body).unwrap();
        }
    }

    impl Drop for TestMount {
        fn drop(&mut self) {
            if let Some(base) = self.metadata_dir.parent() {
                let _ = std::fs::remove_dir_all(base);
            }
        }
    }

    fn endpoint_state(address: &str) -> EndpointState {
        EndpointState {
            client: reqwest::Client::builder().no_proxy().build().unwrap(),
            credentials: EndpointCredentials::None,
            address: reqwest::Url::parse(address).unwrap(),
        }
    }

    fn plan_with_interval(sampling_interval_ms: u32) -> ObservationPlan {
        ObservationPlan {
            data_source: Some("/retrieval".to_string()),
            dataset: DatasetConfiguration {
                request: RequestConfiguration {
                    body_secret_alias: "body-secret".to_string(),
                    content_type: "application/json".to_string(),
                    idempotent: false,
                },
                sampling_interval_ms,
            },
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

    #[tokio::test]
    async fn cancellation_preempts_worker_waiting_for_permit() {
        let mount = TestMount::new("first");
        let endpoint_store = Arc::new(EndpointStore::new());
        endpoint_store
            .replace(Some(endpoint_state("http://127.0.0.1:8080")))
            .await;
        let cancellation = CancellationToken::new();
        let worker = tokio::spawn(execute_worker(
            plan_with_interval(500),
            endpoint_store,
            GlobalConcurrency::new(0),
            mount.metadata_dir.clone(),
            mount.secrets_dir.clone(),
            cancellation.clone(),
        ));

        tokio::task::yield_now().await;
        cancellation.cancel();
        let outcome = tokio::time::timeout(std::time::Duration::from_secs(1), worker)
            .await
            .unwrap()
            .unwrap();
        assert!(matches!(outcome, WorkerOutcome::Cancelled));
    }

    #[tokio::test]
    async fn request_resolution_uses_current_endpoint_and_body() {
        let mount = TestMount::new("first");
        let endpoint_store = Arc::new(EndpointStore::new());
        endpoint_store
            .replace(Some(endpoint_state("http://127.0.0.1:8080/base")))
            .await;
        let plan = plan_with_interval(500);
        let cancellation = CancellationToken::new();

        let first = match resolve_request(
            &plan,
            &endpoint_store,
            &mount.metadata_dir,
            &mount.secrets_dir,
            &cancellation,
        )
        .await
        {
            Ok(request) => request,
            Err(_) => panic!("initial request resolution should succeed"),
        };

        mount.replace_body("second");
        endpoint_store
            .replace(Some(endpoint_state("http://127.0.0.1:9090/base")))
            .await;
        let second = match resolve_request(
            &plan,
            &endpoint_store,
            &mount.metadata_dir,
            &mount.secrets_dir,
            &cancellation,
        )
        .await
        {
            Ok(request) => request,
            Err(_) => panic!("rotated request resolution should succeed"),
        };

        assert_eq!(first.url.as_str(), "http://127.0.0.1:8080/retrieval");
        assert_eq!(first.body, "first");
        assert_eq!(second.url.as_str(), "http://127.0.0.1:9090/retrieval");
        assert_eq!(second.body, "second");
    }

    #[tokio::test]
    async fn shutdown_tasks_waits_for_cancelled_children() {
        let cancellation = CancellationToken::new();
        let mut tasks = JoinSet::new();
        let child_cancellation = cancellation.child_token();
        tasks.spawn(async move {
            child_cancellation.cancelled().await;
        });

        cancellation.cancel();
        shutdown_tasks(&mut tasks).await;
        assert!(tasks.is_empty());
    }
}
