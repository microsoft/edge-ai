use std::num::NonZeroU32;
use std::sync::Arc;
use std::sync::atomic::{AtomicU64, Ordering};

use governor::{Quota, RateLimiter as GovRateLimiter, clock::DefaultClock, state::{InMemoryState, NotKeyed}};
use tokio::sync::Semaphore;
use tracing::{debug, warn};

/// Inference rate limiter combining concurrency bounds with token-bucket rate control.
///
/// Acquire a permit via [`InferenceRateLimiter::acquire`] before running inference.
/// The returned [`InferencePermit`] releases the semaphore slot on drop.
pub struct InferenceRateLimiter {
    semaphore: Arc<Semaphore>,
    max_concurrent: usize,
    rate_limiter: Option<Arc<GovRateLimiter<NotKeyed, InMemoryState, DefaultClock>>>,
    queue_capacity: usize,
    is_drop_on_backpressure: bool,

    // Metrics
    dropped_count: AtomicU64,
    rate_limited_count: AtomicU64,
}

/// RAII guard that releases a semaphore permit on drop.
pub struct InferencePermit {
    _permit: tokio::sync::OwnedSemaphorePermit,
}

/// Snapshot of rate-limiter metrics for Prometheus export.
#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct RateLimiterMetrics {
    pub dropped_total: u64,
    pub rate_limited_total: u64,
    pub concurrent_active: u32,
    pub max_concurrent: u32,
    pub queue_capacity: usize,
}

impl InferenceRateLimiter {
    /// Build a new rate limiter.
    ///
    /// * `max_concurrent` — semaphore permits (bounds parallel inference tasks)
    /// * `rate_per_second` — token-bucket rate; 0.0 disables rate limiting
    /// * `queue_capacity` — bounded channel capacity for backpressure signaling
    /// * `is_drop_on_backpressure` — `true` to drop excess messages, `false` to block
    pub fn new(
        max_concurrent: usize,
        rate_per_second: f64,
        queue_capacity: usize,
        is_drop_on_backpressure: bool,
    ) -> Self {
        let rate_limiter = if rate_per_second > 0.0 {
            let per_second = NonZeroU32::new(rate_per_second.ceil() as u32)
                .unwrap_or(NonZeroU32::new(1).unwrap());
            Some(Arc::new(GovRateLimiter::direct(Quota::per_second(per_second))))
        } else {
            None
        };

        Self {
            semaphore: Arc::new(Semaphore::new(max_concurrent)),
            max_concurrent,
            rate_limiter,
            queue_capacity,
            is_drop_on_backpressure,
            dropped_count: AtomicU64::new(0),
            rate_limited_count: AtomicU64::new(0),
        }
    }

    /// Acquire a concurrency permit, optionally waiting for the rate-limiter token.
    ///
    /// Returns `Some(permit)` on success or `None` when the caller should drop the message
    /// (only possible when `is_drop_on_backpressure` is true and the semaphore has no permits).
    pub async fn acquire(&self) -> Option<InferencePermit> {
        // Rate-limit first (lightweight, no semaphore contention yet)
        if let Some(rl) = &self.rate_limiter {
            if rl.check().is_err() {
                self.rate_limited_count.fetch_add(1, Ordering::Relaxed);
                debug!("Rate limiter engaged — waiting for token");
                rl.until_ready().await;
            }
        }

        // Acquire semaphore permit
        if self.is_drop_on_backpressure {
            match Arc::clone(&self.semaphore).try_acquire_owned() {
                Ok(permit) => Some(InferencePermit { _permit: permit }),
                Err(_) => {
                    self.dropped_count.fetch_add(1, Ordering::Relaxed);
                    warn!("Backpressure: dropping message — all {} inference slots occupied", self.semaphore.available_permits());
                    None
                }
            }
        } else {
            let permit = Arc::clone(&self.semaphore)
                .acquire_owned()
                .await
                .expect("semaphore is never closed");
            Some(InferencePermit { _permit: permit })
        }
    }

    /// Current metrics snapshot.
    pub fn metrics(&self) -> RateLimiterMetrics {
        let active = self.concurrent_active() as u32;
        RateLimiterMetrics {
            dropped_total: self.dropped_count.load(Ordering::Relaxed),
            rate_limited_total: self.rate_limited_count.load(Ordering::Relaxed),
            concurrent_active: active,
            max_concurrent: self.max_concurrent as u32,
            queue_capacity: self.queue_capacity,
        }
    }

    /// Number of inference tasks currently holding a permit.
    fn concurrent_active(&self) -> usize {
        self.max_concurrent - self.semaphore.available_permits()
    }

    pub fn queue_capacity(&self) -> usize {
        self.queue_capacity
    }

    pub fn is_drop_on_backpressure(&self) -> bool {
        self.is_drop_on_backpressure
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn acquire_within_limit_succeeds() {
        let rl = InferenceRateLimiter::new(2, 0.0, 16, false);
        let p1 = rl.acquire().await;
        let p2 = rl.acquire().await;
        assert!(p1.is_some());
        assert!(p2.is_some());
    }

    #[tokio::test]
    async fn drop_on_backpressure_returns_none() {
        let rl = InferenceRateLimiter::new(1, 0.0, 16, true);
        let _p1 = rl.acquire().await.expect("first permit should succeed");
        let p2 = rl.acquire().await;
        assert!(p2.is_none(), "second permit should be dropped");
        assert_eq!(rl.metrics().dropped_total, 1);
    }
}
