use std::time::{Duration, Instant};
use azure_iot_operations_mqtt::session::SessionConnectionMonitor;
use tracing::{event, Level};

pub async fn uptime_monitor(monitor: SessionConnectionMonitor) {
    let mut total_uptime = Duration::default();
    loop {
        event!(Level::INFO, "Waiting for connection...");
        monitor.connected().await;
        event!(Level::INFO, "Connected! Beginning uptime monitoring...");
        let connect_time = Instant::now();
        monitor.disconnected().await;
        let disconnect_time = Instant::now();
        let uptime = disconnect_time - connect_time;
        event!(Level::INFO, "Disconnected after {:?}", uptime);
        total_uptime += uptime;
        event!(Level::INFO, "Total uptime: {:?}", total_uptime);
    }
}
