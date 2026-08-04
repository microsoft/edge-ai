//! Tick scheduling and global concurrency bounding for dataset POST execution.

use std::sync::Arc;
use std::time::Duration;

use tokio::sync::{Semaphore, SemaphorePermit};
use tokio::time::{Interval, MissedTickBehavior};

/// Builds a tick interval for a dataset's `sampling_interval_ms`, configured to
/// delay (rather than burst) missed ticks. `Interval`'s period cannot be changed in
/// place; callers must construct a new interval whenever the sampling interval
/// changes and replace their loop-owned instance with it.
///
/// Delaying missed ticks naturally coalesces scheduled work: if a tick's POST
/// execution takes longer than the sampling interval, the next tick fires one
/// interval after the previous tick completed rather than firing immediately to
/// "catch up" on a backlog.
pub fn interval_for(sampling_interval_ms: u32) -> Interval {
    let mut interval =
        tokio::time::interval(Duration::from_millis(u64::from(sampling_interval_ms)));
    interval.set_missed_tick_behavior(MissedTickBehavior::Delay);
    interval
}

/// A shared, cloneable handle bounding the total number of in-flight POST
/// executions across every data operation owned by this connector instance.
#[derive(Debug, Clone)]
pub struct GlobalConcurrency {
    semaphore: Arc<Semaphore>,
}

impl GlobalConcurrency {
    /// Creates a new bound allowing up to `permits` concurrent POST executions.
    pub fn new(permits: usize) -> Self {
        Self {
            semaphore: Arc::new(Semaphore::new(permits)),
        }
    }

    /// Waits for and acquires a permit, backpressuring the calling task until one
    /// is available. The returned permit releases its slot on drop.
    pub async fn acquire(&self) -> SemaphorePermit<'_> {
        // The semaphore is never closed, so acquiring can only be interrupted by the
        // permits themselves being exhausted, never by a closed-semaphore error.
        self.semaphore
            .acquire()
            .await
            .expect("connector-owned semaphore is never closed")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn interval_for_constructs_without_panicking() {
        let _interval = interval_for(100);
    }

    #[tokio::test]
    async fn global_concurrency_bounds_in_flight_permits() {
        let concurrency = GlobalConcurrency::new(1);
        let first = concurrency.acquire().await;
        assert_eq!(concurrency.semaphore.available_permits(), 0);
        drop(first);
        assert_eq!(concurrency.semaphore.available_permits(), 1);
    }
}
