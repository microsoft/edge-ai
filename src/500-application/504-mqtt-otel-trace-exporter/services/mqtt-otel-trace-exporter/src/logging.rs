use anyhow::{anyhow, Result};
use tracing_subscriber::{fmt, prelude::*, EnvFilter};

use crate::config::LoggingConfig;

pub fn init(config: &LoggingConfig) -> Result<()> {
    let filter = EnvFilter::try_from_default_env()
        .or_else(|_| EnvFilter::try_new(config.level.as_str()))
        .map_err(|err| anyhow!("invalid log level '{}': {}", config.level, err))?;

    let _ = tracing_subscriber::registry()
        .with(filter)
        .with(fmt::layer().with_target(true).with_thread_ids(true))
        .try_init();

    Ok(())
}
