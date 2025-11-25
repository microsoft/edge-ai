mod config;
mod correlation;
mod health;
mod logging;
mod mqtt_client;
#[path = "tracing.rs"]
mod telemetry;

use anyhow::Result;

#[tokio::main]
async fn main() -> Result<()> {
    let config = config::AppConfig::load()?;
    logging::init(&config.logging)?;
    if config.mqtt.tls_auto_enabled {
        tracing::warn!(
            "MQTT TLS was automatically enabled because certificate material is configured"
        );
    }
    let telemetry = telemetry::init(&config.telemetry).await?;
    let health_server = match health::HealthServer::spawn(config.health.clone()).await {
        Ok(server) => server,
        Err(err) => {
            telemetry.shutdown().await?;
            return Err(err);
        }
    };

    let mqtt_result = mqtt_client::run(config).await;
    let telemetry_result = telemetry.shutdown().await;
    let health_result = health_server.shutdown().await;

    if let Err(err) = mqtt_result {
        telemetry_result?;
        health_result?;
        return Err(err);
    }

    telemetry_result?;
    health_result?;
    Ok(())
}
