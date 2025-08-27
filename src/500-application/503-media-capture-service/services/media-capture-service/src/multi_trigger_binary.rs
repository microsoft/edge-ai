use tracing_subscriber::{EnvFilter};
use tracing::{info, span, Level};
use media_capture_service::{MultiTriggerWorker, process_video_stream};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize tracing subscriber
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .with_ansi(true)
        .init();

    // Create a tracing span for the main function
    let main_span = span!(Level::INFO, "multi_trigger_main");
    let _enter = main_span.enter();

    info!("Starting multi-trigger service");
    info!("This binary supports multiple message formats based on topic patterns");

    // Create a new MultiTriggerWorker (it no longer needs the topic at construction time)
    let worker = MultiTriggerWorker::new();

    // Pass an empty input_topic so that process_video_stream will use the TRIGGER_TOPICS env var
    let result = process_video_stream("multi-trigger", worker, "".to_string()).await;

    match result {
        Ok(_) => {
            info!("multi-trigger service completed successfully");
            Ok(())
        }
        Err(e) => {
            tracing::error!("multi-trigger service failed: {:?}", e);
            Err(e)
        }
    }
}
