//! Continuous recording mode: records fixed-length segments from an RTSP
//! stream into the cloud sync directory, where ACSA uploads them to Blob
//! Storage.
//!
//! Segments are written to
//! `{MEDIA_CLOUD_SYNC_DIR}/{camera_id}/{YYYY}/{MM}/{DD}/{HH}/segment_{start}_{camera_id}.{ext}`
//! with a JSON metadata sidecar, which is the layout the video query API lists
//! by prefix.
//!
//! ffmpeg writes each segment to a staging directory outside the synced
//! directory, on the same filesystem, and the finished segment is renamed into
//! place. ACSA therefore never sees, or uploads, an incomplete file.
//!
//! While ffmpeg writes a segment, the recorder refreshes a lease file next to
//! it. Cleanup removes an incomplete segment only when its lease has stopped
//! being refreshed, because ffmpeg can buffer output and leave an active file
//! unmodified for minutes.

use crate::{acsa_writer::AcsaWriter, camera_id::camera_id_from_env};
use chrono::{DateTime, Utc};
use std::{
    env,
    error::Error,
    future::Future,
    ops::RangeInclusive,
    path::{Path, PathBuf},
    pin::Pin,
    process::Stdio,
    sync::{Arc, Mutex},
    time::Duration,
};
use tokio::{
    fs,
    io::{AsyncBufReadExt, BufReader},
    process::Command,
    task::JoinHandle,
    time::interval,
};
use tracing::{debug, error, info, warn};

const SEGMENT_PREFIX: &str = "segment_";
const METADATA_EXTENSION: &str = "json";
/// Suffix for a segment that ffmpeg is still writing. The file is renamed to
/// its final name only after ffmpeg succeeds.
const PARTIAL_EXTENSION: &str = "partial";
/// Extra time allowed beyond the segment length for ffmpeg to connect and
/// finalize the file before the process is killed.
const FFMPEG_GRACE: Duration = Duration::from_secs(60);
const RETRY_DELAY: Duration = Duration::from_secs(5);
/// Video container extensions that continuous recording can produce, so
/// retention applies after `OUTPUT_FORMAT` changes.
const VIDEO_EXTENSIONS: [&str; 2] = ["mp4", "mkv"];
/// Suffix of the lease file a recorder refreshes while it writes a partial
/// segment, independent of when ffmpeg flushes media to disk.
const LEASE_EXTENSION: &str = "lease";
/// How often an active recorder refreshes its lease.
const LEASE_REFRESH: Duration = Duration::from_secs(10);
/// A lease not refreshed for this long belongs to a recorder that stopped.
const PARTIAL_IDLE_LIMIT: Duration = Duration::from_secs(120);
/// Recordings shorter than this are treated as failed.
const MIN_SEGMENT_DURATION: Duration = Duration::from_secs(1);
/// Recordings within this tolerance of the requested length aren't reported as short.
const SHORT_SEGMENT_TOLERANCE: Duration = Duration::from_secs(1);
const FFPROBE_TIMEOUT: Duration = Duration::from_secs(30);

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum OutputFormat {
    Mp4,
    Mkv,
}

impl OutputFormat {
    pub fn parse(value: &str) -> Result<Self, String> {
        match value.to_ascii_lowercase().as_str() {
            "mp4" => Ok(Self::Mp4),
            "mkv" => Ok(Self::Mkv),
            _ => Err("OUTPUT_FORMAT must be mp4 or mkv".to_string()),
        }
    }

    pub fn extension(self) -> &'static str {
        match self {
            Self::Mp4 => "mp4",
            Self::Mkv => "mkv",
        }
    }

    fn muxer(self) -> &'static str {
        match self {
            Self::Mp4 => "mp4",
            Self::Mkv => "matroska",
        }
    }
}

/// Settings for [`ContinuousRecorder`].
pub struct ContinuousRecorderConfig {
    pub camera_id: String,
    pub rtsp_url: String,
    pub segment_duration: Duration,
    pub output_base_path: PathBuf,
    /// Directory for in-progress segments. Must be outside `output_base_path`
    /// and on the same filesystem so the final rename is atomic.
    pub staging_path: PathBuf,
    pub location: String,
    /// Local segments older than this are deleted; `None` disables cleanup.
    pub retention: Option<Duration>,
    pub cleanup_interval: Duration,
    pub output_format: OutputFormat,
}

pub struct ContinuousRecorder {
    config: ContinuousRecorderConfig,
    /// Partial segment ffmpeg is writing now, which cleanup never removes.
    active: Arc<Mutex<Option<PathBuf>>>,
}

fn required_env(name: &str) -> Result<String, String> {
    match env::var(name) {
        Ok(value) if !value.is_empty() => Ok(value),
        _ => Err(format!("{name} must be set for continuous recording")),
    }
}

fn env_u64(name: &str, default: u64, range: RangeInclusive<u64>) -> Result<u64, String> {
    let value = match env::var(name) {
        Ok(raw) if !raw.is_empty() => raw
            .parse::<u64>()
            .map_err(|_| format!("{name} must be a whole number"))?,
        _ => default,
    };
    if range.contains(&value) {
        Ok(value)
    } else {
        Err(format!(
            "{name} must be between {} and {}",
            range.start(),
            range.end()
        ))
    }
}

/// Replaces URL user information (`user:password@`) with `***@` so ffmpeg
/// diagnostics that echo the input URL don't leak camera credentials.
pub fn redact_url_credentials(text: &str) -> String {
    let mut redacted = String::with_capacity(text.len());
    let mut rest = text;
    while let Some(index) = rest.find("://") {
        let (head, tail) = rest.split_at(index + 3);
        redacted.push_str(head);
        let authority_end = tail
            .find(|c: char| c == '/' || c.is_whitespace() || c == '"' || c == '\'')
            .unwrap_or(tail.len());
        let authority = &tail[..authority_end];
        match authority.rfind('@') {
            Some(at) => {
                redacted.push_str("***");
                redacted.push_str(&authority[at..]);
            }
            None => redacted.push_str(authority),
        }
        rest = &tail[authority_end..];
    }
    redacted.push_str(rest);
    redacted
}

impl ContinuousRecorder {
    pub fn new(config: ContinuousRecorderConfig) -> Self {
        Self {
            config,
            active: Arc::new(Mutex::new(None)),
        }
    }

    /// Builds the recorder from environment variables. `CAMERA_ID`,
    /// `RTSP_URL`, and `MEDIA_CLOUD_SYNC_DIR` are required.
    pub fn from_environment() -> Result<Self, Box<dyn Error>> {
        let camera_id =
            camera_id_from_env()?.ok_or("CAMERA_ID must be set for continuous recording")?;
        let rtsp_url = required_env("RTSP_URL")?;
        let output_base_path = PathBuf::from(required_env("MEDIA_CLOUD_SYNC_DIR")?);
        let staging_path = match env::var("MEDIA_STAGING_DIR") {
            Ok(value) if !value.is_empty() => PathBuf::from(value),
            _ => default_staging_path(&output_base_path)?,
        };
        let location = env::var("CAMERA_LOCATION").unwrap_or_else(|_| "unknown".to_string());
        let segment_seconds = env_u64("CONTINUOUS_SEGMENT_DURATION_SECONDS", 300, 10..=3600)?;
        let retention_hours = env_u64("LOCAL_RETENTION_HOURS", 24, 0..=8760)?;
        let cleanup_minutes = env_u64("CLEANUP_INTERVAL_MINUTES", 60, 1..=1440)?;
        let output_format =
            OutputFormat::parse(&env::var("OUTPUT_FORMAT").unwrap_or_else(|_| "mp4".to_string()))?;

        info!(
            "Continuous recording: camera={camera_id}, location={location}, \
             segment={segment_seconds}s, format={}, local retention={retention_hours}h \
             (0 disables cleanup), cleanup interval={cleanup_minutes}m",
            output_format.extension()
        );

        Ok(Self::new(ContinuousRecorderConfig {
            camera_id,
            rtsp_url,
            segment_duration: Duration::from_secs(segment_seconds),
            output_base_path,
            staging_path,
            location,
            retention: (retention_hours > 0).then(|| Duration::from_secs(retention_hours * 3600)),
            cleanup_interval: Duration::from_secs(cleanup_minutes * 60),
            output_format,
        }))
    }

    pub fn camera_id(&self) -> &str {
        &self.config.camera_id
    }

    pub fn location(&self) -> &str {
        &self.config.location
    }

    /// Records segments back to back until the process stops. A failed
    /// segment is logged and retried after a short delay.
    pub async fn record_loop(&self) -> Result<(), Box<dyn Error>> {
        info!(
            "Starting continuous recording for camera {} with {}s segments",
            self.config.camera_id,
            self.config.segment_duration.as_secs()
        );

        fs::create_dir_all(&self.config.output_base_path).await?;
        fs::create_dir_all(&self.config.staging_path).await?;
        ensure_same_filesystem(&self.config.staging_path, &self.config.output_base_path)?;
        info!(
            "Staging in-progress segments in {}",
            self.config.staging_path.display()
        );

        // Partial files whose lease went stale belong to a recorder that
        // stopped; a running recorder keeps its lease fresh
        let staging_camera_path = self.config.staging_path.join(&self.config.camera_id);
        match remove_stale_partial_segments(&staging_camera_path, PARTIAL_IDLE_LIMIT, None).await {
            Ok(0) => {}
            Ok(count) => warn!("Removed {count} abandoned incomplete segments"),
            Err(e) => warn!("Failed to remove abandoned incomplete segments: {e}"),
        }

        self.start_cleanup_task(self.config.retention);

        loop {
            match self.record_segment().await {
                Ok(path) => debug!("Recorded segment {}", path.display()),
                Err(e) => {
                    error!(
                        "Failed to record segment for {}: {}",
                        self.config.camera_id, e
                    );
                    tokio::time::sleep(RETRY_DELAY).await;
                }
            }
        }
    }

    async fn record_segment(&self) -> Result<PathBuf, Box<dyn Error>> {
        let partial = staging_partial_path(
            &self.config.staging_path,
            &self.config.camera_id,
            self.config.output_format,
            &Utc::now(),
        );
        if let Some(parent) = partial.parent() {
            fs::create_dir_all(parent).await?;
        }

        // Hold the lease and mark the segment active before ffmpeg creates it
        let _lease = Lease::acquire(&partial, LEASE_REFRESH).await?;
        let _active = ActiveSegment::mark(&self.active, &partial);

        let window = match self.capture(&partial).await {
            Ok(window) => window,
            Err(e) => {
                let _ = fs::remove_file(&partial).await;
                return Err(e);
            }
        };
        if window.short {
            warn!(
                "Segment for {} contains {:.1}s of the requested {}s",
                self.config.camera_id,
                (window.end - window.start).num_milliseconds() as f64 / 1000.0,
                self.config.segment_duration.as_secs()
            );
        }

        // Name the segment after the start of the footage it contains
        let output = segment_path(
            &self.config.output_base_path,
            &self.config.camera_id,
            self.config.output_format,
            &window.start,
        );
        if let Some(parent) = output.parent() {
            fs::create_dir_all(parent).await?;
        }
        fs::rename(&partial, &output).await?;

        AcsaWriter::write_segment_with_metadata(
            &output,
            &self.config.camera_id,
            &self.config.location,
            window.start,
            window.end,
        )
        .await?;

        info!(
            "Recorded {} ({:.2} MB) for upload by ACSA",
            output.display(),
            fs::metadata(&output).await?.len() as f64 / 1_048_576.0
        );
        Ok(output)
    }

    /// Records into `partial` and returns the time window its footage covers.
    async fn capture(&self, partial: &Path) -> Result<CaptureWindow, Box<dyn Error>> {
        let input = [
            "-rtsp_transport".to_string(),
            "tcp".to_string(),
            // RTSP socket I/O timeout in microseconds
            "-timeout".to_string(),
            "10000000".to_string(),
            "-i".to_string(),
            self.config.rtsp_url.clone(),
        ];
        let footage_start = run_ffmpeg_capture(
            &input,
            self.config.segment_duration,
            self.config.output_format,
            partial,
        )
        .await?;
        let finished_at = Utc::now();
        let recorded = probe_duration(partial).await?;
        Ok(capture_window(
            footage_start,
            finished_at,
            recorded,
            self.config.segment_duration,
        )?)
    }

    /// Periodically removes abandoned partial files and, when retention is
    /// set, expired segments.
    fn start_cleanup_task(&self, retention: Option<Duration>) {
        let camera_path = self.config.output_base_path.join(&self.config.camera_id);
        let staging_camera_path = self.config.staging_path.join(&self.config.camera_id);
        let cleanup_interval = self.config.cleanup_interval;
        let camera_id = self.config.camera_id.clone();
        let active = Arc::clone(&self.active);
        let retention =
            retention.map(|r| chrono::Duration::from_std(r).unwrap_or(chrono::Duration::MAX));

        tokio::spawn(async move {
            let mut timer = interval(cleanup_interval);
            loop {
                timer.tick().await;
                let current = active.lock().ok().and_then(|guard| guard.clone());
                if let Err(e) = remove_stale_partial_segments(
                    &staging_camera_path,
                    PARTIAL_IDLE_LIMIT,
                    current.as_deref(),
                )
                .await
                {
                    warn!("Partial segment cleanup failed for camera {camera_id}: {e}");
                }
                let Some(retention) = retention else {
                    continue;
                };
                let cutoff = Utc::now() - retention;
                match cleanup_segments(&camera_path, cutoff).await {
                    Ok(0) => debug!("No expired segments for camera {camera_id}"),
                    Ok(count) => {
                        info!("Deleted {count} expired segment files for camera {camera_id}")
                    }
                    Err(e) => warn!("Segment cleanup failed for camera {camera_id}: {e}"),
                }
            }
        });
    }
}

/// Returns the segment file path for `timestamp`.
pub fn segment_path(
    base_path: &Path,
    camera_id: &str,
    format: OutputFormat,
    timestamp: &DateTime<Utc>,
) -> PathBuf {
    base_path
        .join(camera_id)
        .join(timestamp.format("%Y").to_string())
        .join(timestamp.format("%m").to_string())
        .join(timestamp.format("%d").to_string())
        .join(timestamp.format("%H").to_string())
        .join(format!(
            "{SEGMENT_PREFIX}{}_{camera_id}.{}",
            timestamp.format("%Y-%m-%dT%H:%M:%SZ"),
            format.extension()
        ))
}

/// Time range covered by a recorded segment.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CaptureWindow {
    pub start: DateTime<Utc>,
    pub end: DateTime<Utc>,
    /// The footage is shorter than the requested segment length.
    pub short: bool,
}

/// Derives the footage window from the measured recording length, starting at
/// `footage_start` estimated from ffmpeg progress. Connection time before the
/// first frame, a stalled stream, and file finalization are therefore
/// excluded. Without an estimate, the window ends when ffmpeg finished.
pub fn capture_window(
    footage_start: Option<DateTime<Utc>>,
    finished_at: DateTime<Utc>,
    recorded: Duration,
    requested: Duration,
) -> Result<CaptureWindow, String> {
    if recorded < MIN_SEGMENT_DURATION {
        return Err(format!(
            "recording contains {:.1}s of video, below the {}s minimum",
            recorded.as_secs_f64(),
            MIN_SEGMENT_DURATION.as_secs()
        ));
    }
    let length = chrono::Duration::from_std(recorded).map_err(|e| e.to_string())?;
    let start = footage_start.unwrap_or(finished_at - length);
    Ok(CaptureWindow {
        start,
        end: (start + length).min(finished_at),
        short: recorded + SHORT_SEGMENT_TOLERANCE < requested,
    })
}

/// Estimates when the recorded footage started from ffmpeg `-progress` output.
///
/// Each report of encoded output time `t` seen at wall-clock time `w` implies
/// the footage started no later than `w - t`, because a frame can't be encoded
/// before it arrives. The smallest such value is kept. While a live stream
/// flows it stays close to the first frame's arrival; reports during a stall,
/// or the encoder flush when ffmpeg exits, yield later values and are ignored.
#[derive(Debug, Default)]
pub struct ProgressTracker {
    footage_start: Option<DateTime<Utc>>,
}

impl ProgressTracker {
    /// Records one `-progress` line seen at `now`.
    pub fn observe(&mut self, line: &str, now: DateTime<Utc>) {
        let Some(value) = line.trim().strip_prefix("out_time_us=") else {
            return;
        };
        let Ok(micros) = value.parse::<i64>() else {
            return;
        };
        if micros <= 0 {
            return;
        }
        let candidate = now - chrono::Duration::microseconds(micros);
        if self.footage_start.is_none_or(|start| candidate < start) {
            self.footage_start = Some(candidate);
        }
    }

    pub fn footage_start(&self) -> Option<DateTime<Utc>> {
        self.footage_start
    }
}

/// Runs ffmpeg with `input` arguments, writes at most `duration` of
/// re-encoded media to `output`, and returns the estimated footage start.
pub async fn run_ffmpeg_capture(
    input: &[String],
    duration: Duration,
    format: OutputFormat,
    output: &Path,
) -> Result<Option<DateTime<Utc>>, Box<dyn Error>> {
    let duration_arg = duration.as_secs().to_string();
    let output_str = output.to_str().ok_or("Segment path is not valid UTF-8")?;

    let mut command = Command::new("ffmpeg");
    command
        .args(["-hide_banner", "-loglevel", "error", "-nostats"])
        .args(["-progress", "pipe:1", "-stats_period", "0.5"])
        .args(input)
        .args(["-t", &duration_arg])
        // Downscale to 360p and favor encoding speed to bound CPU and memory use.
        // Zero-latency tuning keeps encoder output, and so progress reports, in
        // step with frame arrival for the footage start estimate.
        .args(["-vf", "scale=-2:360"])
        .args(["-c:v", "libx264", "-preset", "ultrafast"])
        .args(["-tune", "zerolatency", "-crf", "28"])
        .args(["-g", "30", "-sc_threshold", "0"])
        .args(["-c:a", "aac", "-b:a", "64k"])
        .args(["-f", format.muxer()]);
    if format == OutputFormat::Mp4 {
        command.args(["-movflags", "+faststart"]);
    }
    command
        .args(["-y", output_str])
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .kill_on_drop(true);

    let mut child = command.spawn()?;
    let stdout = child
        .stdout
        .take()
        .ok_or("ffmpeg progress output is unavailable")?;
    let progress = tokio::spawn(async move {
        let mut tracker = ProgressTracker::default();
        let mut lines = BufReader::new(stdout).lines();
        while let Ok(Some(line)) = lines.next_line().await {
            tracker.observe(&line, Utc::now());
        }
        tracker.footage_start()
    });

    let limit = duration + FFMPEG_GRACE;
    let result = match tokio::time::timeout(limit, child.wait_with_output()).await {
        Ok(result) => result?,
        Err(_) => {
            progress.abort();
            return Err(format!(
                "ffmpeg did not finish within {}s and was stopped",
                limit.as_secs()
            )
            .into());
        }
    };
    let footage_start = progress.await.unwrap_or(None);

    if !result.status.success() {
        let stderr = redact_url_credentials(&String::from_utf8_lossy(&result.stderr));
        let last_line = stderr.lines().next_back().unwrap_or("no error output");
        return Err(format!("ffmpeg exited with {}: {}", result.status, last_line).into());
    }
    Ok(footage_start)
}

/// Lease file refreshed while ffmpeg writes a partial segment. Dropping the
/// lease stops the refresh and removes the file.
pub struct Lease {
    path: PathBuf,
    refresher: JoinHandle<()>,
}

impl Lease {
    /// Creates the lease for `partial` and refreshes it every `refresh`.
    pub async fn acquire(partial: &Path, refresh: Duration) -> std::io::Result<Self> {
        let path = lease_path(partial);
        fs::write(&path, lease_contents()).await?;
        let refreshed = path.clone();
        let refresher = tokio::spawn(async move {
            let mut timer = interval(refresh);
            timer.tick().await;
            loop {
                timer.tick().await;
                if let Err(e) = fs::write(&refreshed, lease_contents()).await {
                    warn!("Failed to refresh lease {}: {e}", refreshed.display());
                }
            }
        });
        Ok(Self { path, refresher })
    }
}

impl Drop for Lease {
    fn drop(&mut self) {
        self.refresher.abort();
        let _ = std::fs::remove_file(&self.path);
    }
}

fn lease_contents() -> String {
    format!(
        "pid={} refreshed={}\n",
        std::process::id(),
        Utc::now().to_rfc3339()
    )
}

/// Returns the lease file path for a partial segment.
pub fn lease_path(partial: &Path) -> PathBuf {
    let mut name = partial.as_os_str().to_owned();
    name.push(".");
    name.push(LEASE_EXTENSION);
    PathBuf::from(name)
}

/// Marks a partial segment as the one being recorded until dropped.
struct ActiveSegment<'a> {
    slot: &'a Mutex<Option<PathBuf>>,
}

impl<'a> ActiveSegment<'a> {
    fn mark(slot: &'a Mutex<Option<PathBuf>>, partial: &Path) -> Self {
        if let Ok(mut current) = slot.lock() {
            *current = Some(partial.to_path_buf());
        }
        Self { slot }
    }
}

impl Drop for ActiveSegment<'_> {
    fn drop(&mut self) {
        if let Ok(mut current) = self.slot.lock() {
            *current = None;
        }
    }
}

/// Parses the `format=duration` value printed by `ffprobe`.
pub fn parse_probe_duration(output: &str) -> Result<Duration, String> {
    let value = output.trim();
    let seconds: f64 = value.parse().map_err(|_| {
        format!("recording contains no measurable media (ffprobe duration {value:?})")
    })?;
    if !seconds.is_finite() || seconds < 0.0 {
        return Err(format!("ffprobe reported an invalid duration ({value})"));
    }
    Ok(Duration::from_secs_f64(seconds))
}

/// Measures the media duration of `path` with `ffprobe`.
async fn probe_duration(path: &Path) -> Result<Duration, Box<dyn Error>> {
    let mut command = Command::new("ffprobe");
    command
        .args(["-v", "error", "-show_entries", "format=duration"])
        .args(["-of", "default=noprint_wrappers=1:nokey=1"])
        .arg(path)
        .stdin(Stdio::null())
        .stderr(Stdio::piped())
        .kill_on_drop(true);
    let output = tokio::time::timeout(FFPROBE_TIMEOUT, command.output())
        .await
        .map_err(|_| "ffprobe timed out")??;
    if !output.status.success() {
        return Err(format!(
            "ffprobe exited with {}: {}",
            output.status,
            String::from_utf8_lossy(&output.stderr).trim()
        )
        .into());
    }
    Ok(parse_probe_duration(&String::from_utf8_lossy(
        &output.stdout,
    ))?)
}

/// Default staging directory: a hidden sibling of the synced directory, such
/// as `/cloud-sync/.media-staging` for `/cloud-sync/media`, so it stays on the
/// same volume but outside the ACSA ingest subvolume.
pub fn default_staging_path(sync_dir: &Path) -> Result<PathBuf, String> {
    let name = sync_dir
        .file_name()
        .and_then(|name| name.to_str())
        .ok_or("MEDIA_CLOUD_SYNC_DIR must name a directory below the volume mount")?;
    let parent = sync_dir
        .parent()
        .filter(|parent| !parent.as_os_str().is_empty())
        .ok_or("MEDIA_CLOUD_SYNC_DIR must name a directory below the volume mount")?;
    Ok(parent.join(format!(".{name}-staging")))
}

/// Fails unless `staging` and `sync_dir` are on the same filesystem and
/// `staging` isn't inside `sync_dir`, so finished segments can be renamed
/// atomically into a directory that ACSA uploads from.
pub fn ensure_same_filesystem(staging: &Path, sync_dir: &Path) -> Result<(), String> {
    use std::os::unix::fs::MetadataExt;
    if staging.starts_with(sync_dir) {
        return Err(format!(
            "staging directory {} must be outside {}",
            staging.display(),
            sync_dir.display()
        ));
    }
    let device = |path: &Path| {
        std::fs::metadata(path)
            .map(|metadata| metadata.dev())
            .map_err(|e| format!("cannot read {}: {e}", path.display()))
    };
    if device(staging)? != device(sync_dir)? {
        return Err(format!(
            "staging directory {} must be on the same volume as {}",
            staging.display(),
            sync_dir.display()
        ));
    }
    Ok(())
}

/// Returns the in-progress path for a segment starting at `timestamp`.
pub fn staging_partial_path(
    staging_path: &Path,
    camera_id: &str,
    format: OutputFormat,
    timestamp: &DateTime<Utc>,
) -> PathBuf {
    let file_name = segment_path(Path::new(""), camera_id, format, timestamp)
        .file_name()
        .map(PathBuf::from)
        .unwrap_or_default();
    partial_path(&staging_path.join(camera_id).join(file_name))
}

/// Returns the path ffmpeg writes to before the segment is complete.
pub fn partial_path(output: &Path) -> PathBuf {
    let mut name = output.as_os_str().to_owned();
    name.push(".");
    name.push(PARTIAL_EXTENSION);
    PathBuf::from(name)
}

/// Deletes continuous segment videos in any supported format, metadata
/// sidecars, and incomplete segments under `camera_path` that were last
/// modified before `cutoff`, then removes empty directories. Triggered clips
/// aren't touched because they don't use the `segment_` prefix.
pub async fn cleanup_segments(
    camera_path: &Path,
    cutoff: DateTime<Utc>,
) -> Result<usize, std::io::Error> {
    let matches = |path: &Path| {
        has_segment_extension(path, &VIDEO_EXTENSIONS)
            || has_segment_extension(path, &[METADATA_EXTENSION, PARTIAL_EXTENSION])
    };
    cleanup_tree(camera_path, cutoff, &matches).await
}

/// Deletes incomplete segments in `staging_camera_path` whose recorder
/// stopped, along with their leases, and returns how many segments it removed.
///
/// A partial segment is kept while its lease was refreshed within
/// `idle_limit`, regardless of when ffmpeg last wrote media to it. A partial
/// segment without a lease is judged by its own modification time. `active`
/// is never removed. Leases whose segment is gone are removed once stale.
pub async fn remove_stale_partial_segments(
    staging_camera_path: &Path,
    idle_limit: Duration,
    active: Option<&Path>,
) -> Result<usize, std::io::Error> {
    if !fs::try_exists(staging_camera_path).await? {
        return Ok(0);
    }
    let cutoff =
        Utc::now() - chrono::Duration::from_std(idle_limit).unwrap_or(chrono::Duration::MAX);

    let mut removed = 0;
    let mut entries = fs::read_dir(staging_camera_path).await?;
    while let Some(entry) = entries.next_entry().await? {
        let path = entry.path();
        if !entry.file_type().await?.is_file() {
            continue;
        }
        if has_segment_extension(&path, &[PARTIAL_EXTENSION]) {
            if active == Some(path.as_path()) {
                continue;
            }
            let lease = lease_path(&path);
            let last_alive = match modified_at(&lease).await {
                Ok(time) => time,
                Err(e) if e.kind() == std::io::ErrorKind::NotFound => modified_at(&path).await?,
                Err(e) => return Err(e),
            };
            if last_alive < cutoff {
                match fs::remove_file(&path).await {
                    Ok(()) => removed += 1,
                    Err(e) => warn!("Failed to delete {}: {}", path.display(), e),
                }
                let _ = fs::remove_file(&lease).await;
            }
        } else if has_segment_extension(&path, &[LEASE_EXTENSION]) {
            let partial = path.with_extension("");
            if !fs::try_exists(&partial).await? && modified_at(&path).await? < cutoff {
                let _ = fs::remove_file(&path).await;
            }
        }
    }
    Ok(removed)
}

async fn modified_at(path: &Path) -> Result<DateTime<Utc>, std::io::Error> {
    Ok(fs::metadata(path).await?.modified()?.into())
}

async fn cleanup_tree(
    camera_path: &Path,
    cutoff: DateTime<Utc>,
    matches: &(dyn Fn(&Path) -> bool + Sync),
) -> Result<usize, std::io::Error> {
    if !fs::try_exists(camera_path).await? {
        return Ok(0);
    }
    let mut deleted = 0;
    cleanup_directory(camera_path, cutoff, matches, &mut deleted).await?;
    Ok(deleted)
}

fn cleanup_directory<'a>(
    dir: &'a Path,
    cutoff: DateTime<Utc>,
    matches: &'a (dyn Fn(&Path) -> bool + Sync),
    deleted: &'a mut usize,
) -> Pin<Box<dyn Future<Output = Result<(), std::io::Error>> + Send + 'a>> {
    Box::pin(async move {
        let mut entries = fs::read_dir(dir).await?;
        while let Some(entry) = entries.next_entry().await? {
            let path = entry.path();
            let file_type = entry.file_type().await?;

            if file_type.is_dir() {
                // Read before recursing: deleting files updates the directory
                // time, and a recently modified directory may be about to
                // receive a segment
                let dir_modified: DateTime<Utc> = entry.metadata().await?.modified()?.into();
                cleanup_directory(&path, cutoff, matches, deleted).await?;
                let mut remaining = fs::read_dir(&path).await?;
                if dir_modified < cutoff && remaining.next_entry().await?.is_none() {
                    if let Err(e) = fs::remove_dir(&path).await {
                        warn!("Failed to remove empty directory {}: {}", path.display(), e);
                    }
                }
                continue;
            }

            if !file_type.is_file() || !matches(&path) {
                continue;
            }
            let modified: DateTime<Utc> = entry.metadata().await?.modified()?.into();
            if modified < cutoff {
                match fs::remove_file(&path).await {
                    Ok(()) => *deleted += 1,
                    Err(e) => warn!("Failed to delete {}: {}", path.display(), e),
                }
            }
        }
        Ok(())
    })
}

fn has_segment_extension(path: &Path, extensions: &[&str]) -> bool {
    let is_segment = path
        .file_name()
        .and_then(|name| name.to_str())
        .is_some_and(|name| name.starts_with(SEGMENT_PREFIX));
    let extension = path.extension().and_then(|ext| ext.to_str());
    is_segment && extension.is_some_and(|ext| extensions.contains(&ext))
}

#[cfg(test)]
mod tests {
    use super::*;
    use filetime::{set_file_mtime, FileTime};

    #[test]
    fn redacts_rtsp_credentials() {
        let text = "rtsp://admin:p@ss@192.0.2.10:554/live: Connection refused";
        assert_eq!(
            redact_url_credentials(text),
            "rtsp://***@192.0.2.10:554/live: Connection refused"
        );
    }

    #[test]
    fn leaves_urls_without_credentials_unchanged() {
        let text = "Opening 'rtsp://camera:554/live' and http://host/path";
        assert_eq!(redact_url_credentials(text), text);
    }

    #[test]
    fn redacts_every_url() {
        let text = "a rtsp://u:p@h1/x b rtsps://u2:p2@h2";
        assert_eq!(
            redact_url_credentials(text),
            "a rtsp://***@h1/x b rtsps://***@h2"
        );
    }

    #[test]
    fn parses_output_formats() {
        assert_eq!(OutputFormat::parse("MP4"), Ok(OutputFormat::Mp4));
        assert_eq!(OutputFormat::parse("mkv"), Ok(OutputFormat::Mkv));
        assert!(OutputFormat::parse("avi").is_err());
        assert!(OutputFormat::parse("mp4 -i x").is_err());
    }

    #[test]
    fn builds_query_api_layout() {
        let timestamp = DateTime::parse_from_rfc3339("2026-01-30T19:05:44Z")
            .unwrap()
            .with_timezone(&Utc);
        let path = segment_path(
            Path::new("/sync"),
            "camera-01",
            OutputFormat::Mp4,
            &timestamp,
        );
        assert_eq!(
            path,
            PathBuf::from(
                "/sync/camera-01/2026/01/30/19/segment_2026-01-30T19:05:44Z_camera-01.mp4"
            )
        );
    }

    #[tokio::test]
    async fn cleanup_removes_expired_segments_and_sidecars_only() {
        let dir = tempfile::tempdir().unwrap();
        let camera = dir.path().join("camera-01");
        let old_hour = camera.join("2026/01/30/19");
        let new_hour = camera.join("2026/01/31/08");
        std::fs::create_dir_all(&old_hour).unwrap();
        std::fs::create_dir_all(&new_hour).unwrap();

        let old_video = old_hour.join("segment_a_camera-01.mp4");
        let old_meta = old_hour.join("segment_a_camera-01.json");
        let triggered = new_hour.join("20260131_event_1.mp4");
        let new_video = new_hour.join("segment_b_camera-01.mp4");
        let old_partial = new_hour.join("segment_c_camera-01.mp4.partial");
        for file in [&old_video, &old_meta, &triggered, &new_video, &old_partial] {
            std::fs::write(file, b"x").unwrap();
        }
        let old_time = FileTime::from_unix_time(Utc::now().timestamp() - 7200, 0);
        for file in [&old_video, &old_meta, &triggered, &old_partial] {
            set_file_mtime(file, old_time).unwrap();
        }
        set_file_mtime(&old_hour, old_time).unwrap();

        let cutoff = Utc::now() - chrono::Duration::hours(1);
        let deleted = cleanup_segments(&camera, cutoff).await.unwrap();

        assert_eq!(deleted, 3);
        assert!(!old_partial.exists());
        assert!(!old_hour.exists(), "empty hour directory should be removed");
        assert!(
            triggered.exists(),
            "triggered clips are not continuous segments"
        );
        assert!(new_video.exists());
    }

    fn old_time(seconds_ago: u64) -> FileTime {
        FileTime::from_unix_time(Utc::now().timestamp() - seconds_ago as i64, 0)
    }

    #[tokio::test]
    async fn stale_cleanup_keeps_partials_with_fresh_leases_even_when_media_is_idle() {
        let dir = tempfile::tempdir().unwrap();
        let staging = dir.path().join("camera-01");
        std::fs::create_dir_all(&staging).unwrap();
        let idle_for = PARTIAL_IDLE_LIMIT.as_secs() + 60;

        // ffmpeg buffers low-bitrate MP4 output, so an active file can be unchanged for minutes
        let buffered = staging.join("segment_a_camera-01.mp4.partial");
        std::fs::write(&buffered, b"ftyp").unwrap();
        set_file_mtime(&buffered, old_time(idle_for)).unwrap();
        std::fs::write(lease_path(&buffered), b"lease").unwrap();

        // A stopped recorder's lease went stale along with its media
        let abandoned = staging.join("segment_b_camera-01.mp4.partial");
        std::fs::write(&abandoned, b"x").unwrap();
        std::fs::write(lease_path(&abandoned), b"lease").unwrap();
        set_file_mtime(&abandoned, old_time(idle_for)).unwrap();
        set_file_mtime(lease_path(&abandoned), old_time(idle_for)).unwrap();

        // A partial written before leases existed is judged by its own age
        let legacy_idle = staging.join("segment_c_camera-01.mkv.partial");
        let legacy_recent = staging.join("segment_d_camera-01.mkv.partial");
        std::fs::write(&legacy_idle, b"x").unwrap();
        std::fs::write(&legacy_recent, b"x").unwrap();
        set_file_mtime(&legacy_idle, old_time(idle_for)).unwrap();

        // A stale lease whose segment already finished
        let orphan_lease = lease_path(&staging.join("segment_e_camera-01.mp4.partial"));
        std::fs::write(&orphan_lease, b"lease").unwrap();
        set_file_mtime(&orphan_lease, old_time(idle_for)).unwrap();

        let removed = remove_stale_partial_segments(&staging, PARTIAL_IDLE_LIMIT, None)
            .await
            .unwrap();

        assert_eq!(removed, 2);
        assert!(buffered.exists(), "a refreshed lease protects idle media");
        assert!(lease_path(&buffered).exists());
        assert!(!abandoned.exists());
        assert!(!lease_path(&abandoned).exists());
        assert!(!legacy_idle.exists());
        assert!(legacy_recent.exists());
        assert!(!orphan_lease.exists());
    }

    #[tokio::test]
    async fn stale_cleanup_never_removes_the_recorders_own_active_segment() {
        let dir = tempfile::tempdir().unwrap();
        let staging = dir.path().join("camera-01");
        std::fs::create_dir_all(&staging).unwrap();
        let active = staging.join("segment_a_camera-01.mp4.partial");
        std::fs::write(&active, b"ftyp").unwrap();
        std::fs::write(lease_path(&active), b"lease").unwrap();
        let idle_for = PARTIAL_IDLE_LIMIT.as_secs() + 60;
        set_file_mtime(&active, old_time(idle_for)).unwrap();
        set_file_mtime(lease_path(&active), old_time(idle_for)).unwrap();

        let removed =
            remove_stale_partial_segments(&staging, PARTIAL_IDLE_LIMIT, Some(active.as_path()))
                .await
                .unwrap();

        assert_eq!(removed, 0);
        assert!(active.exists());
    }

    #[tokio::test]
    async fn lease_is_refreshed_while_held_and_removed_when_dropped() {
        let dir = tempfile::tempdir().unwrap();
        let partial = dir.path().join("segment_a_camera-01.mp4.partial");
        let lease = Lease::acquire(&partial, Duration::from_millis(50))
            .await
            .unwrap();
        let lease_file = lease_path(&partial);
        set_file_mtime(&lease_file, old_time(600)).unwrap();

        tokio::time::sleep(Duration::from_millis(300)).await;
        let refreshed: DateTime<Utc> = std::fs::metadata(&lease_file)
            .unwrap()
            .modified()
            .unwrap()
            .into();
        assert!(Utc::now() - refreshed < chrono::Duration::seconds(5));

        drop(lease);
        assert!(!lease_file.exists());
    }

    #[test]
    fn active_segment_marker_clears_on_drop() {
        let slot = Mutex::new(None);
        {
            let _active = ActiveSegment::mark(&slot, Path::new("/s/segment_a.mp4.partial"));
            assert_eq!(
                slot.lock().unwrap().as_deref(),
                Some(Path::new("/s/segment_a.mp4.partial"))
            );
        }
        assert!(slot.lock().unwrap().is_none());
    }

    fn ffmpeg_available() -> bool {
        std::process::Command::new("ffmpeg")
            .arg("-version")
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .is_ok_and(|status| status.success())
    }

    #[tokio::test]
    async fn low_bitrate_recording_survives_cleanup_beyond_the_idle_limit() {
        if !ffmpeg_available() {
            eprintln!("skipping: ffmpeg isn't installed");
            return;
        }
        let dir = tempfile::tempdir().unwrap();
        let staging = dir.path().join("camera-01");
        std::fs::create_dir_all(&staging).unwrap();
        let partial = staging.join("segment_a_camera-01.mp4.partial");
        let idle_limit = Duration::from_secs(1);

        let lease = Lease::acquire(&partial, Duration::from_millis(200))
            .await
            .unwrap();
        let input: Vec<String> = [
            "-re",
            "-f",
            "lavfi",
            "-i",
            "color=c=black:size=320x240:rate=5",
        ]
        .iter()
        .map(|arg| arg.to_string())
        .collect();
        let output = partial.clone();
        let capture = tokio::spawn(async move {
            run_ffmpeg_capture(&input, Duration::from_secs(4), OutputFormat::Mp4, &output)
                .await
                .map_err(|e| e.to_string())
        });

        // MP4 output is buffered, so the partial file stops changing while
        // ffmpeg keeps recording; cleanup runs past the idle limit throughout
        for _ in 0..6 {
            tokio::time::sleep(Duration::from_millis(500)).await;
            remove_stale_partial_segments(&staging, idle_limit, None)
                .await
                .unwrap();
        }
        let footage_start = capture
            .await
            .unwrap()
            .expect("ffmpeg should finish the segment");
        drop(lease);

        assert!(partial.exists(), "the active segment must not be deleted");
        assert!(footage_start.is_some());
        let recorded = probe_duration(&partial).await.unwrap();
        assert!(
            (recorded.as_secs_f64() - 4.0).abs() < 0.5,
            "measured {recorded:?}"
        );
    }

    #[test]
    fn progress_estimate_ignores_stall_reports_and_the_final_flush() {
        let mut tracker = ProgressTracker::default();
        for (line, time) in [
            ("frame=0", "2026-01-30T19:00:00Z"),
            ("out_time_us=N/A", "2026-01-30T19:00:00.500Z"),
            ("out_time_us=0", "2026-01-30T19:00:01Z"),
            ("out_time_us=1000000", "2026-01-30T19:00:02.300Z"),
            ("out_time_us=14200000", "2026-01-30T19:00:15.200Z"),
            // The stream stalled: ffmpeg repeats the same output time until its timeout
            ("out_time_us=14200000", "2026-01-30T19:00:20Z"),
            // Buffered frames are flushed when ffmpeg exits
            ("out_time_us=14800000", "2026-01-30T19:00:25.817Z"),
            ("progress=end", "2026-01-30T19:00:25.817Z"),
        ] {
            tracker.observe(line, at(time));
        }

        assert_eq!(tracker.footage_start(), Some(at("2026-01-30T19:00:01Z")));
    }

    #[test]
    fn stalled_stream_window_excludes_the_timeout_after_the_last_frame() {
        // The publisher paused at 19:00:15.2; ffmpeg exited successfully 10.6s
        // later with 14.2s of media
        let window = capture_window(
            Some(at("2026-01-30T19:00:01Z")),
            at("2026-01-30T19:00:25.817Z"),
            Duration::from_millis(14_200),
            Duration::from_secs(300),
        )
        .unwrap();

        assert_eq!(window.start, at("2026-01-30T19:00:01Z"));
        assert_eq!(window.end, at("2026-01-30T19:00:15.200Z"));
        assert!(window.short);
    }

    #[test]
    fn window_never_ends_after_ffmpeg_finished() {
        let window = capture_window(
            Some(at("2026-01-30T19:00:01Z")),
            at("2026-01-30T19:05:00.200Z"),
            Duration::from_secs(300),
            Duration::from_secs(300),
        )
        .unwrap();
        assert_eq!(window.end, at("2026-01-30T19:05:00.200Z"));
    }

    #[tokio::test]
    async fn stalled_input_that_exits_successfully_reports_only_its_footage() {
        if !ffmpeg_available() {
            eprintln!("skipping: ffmpeg isn't installed");
            return;
        }
        let dir = tempfile::tempdir().unwrap();
        let fifo = dir.path().join("stream.ts");
        assert!(std::process::Command::new("mkfifo")
            .arg(&fifo)
            .status()
            .unwrap()
            .success());
        let partial = dir.path().join("segment_a_camera-01.mkv.partial");

        // Feed 3s of low-latency video in real time, then stall for 4s before
        // closing the input
        let writer_fifo = fifo.clone();
        let feeder = std::thread::spawn(move || {
            let mut source = std::process::Command::new("ffmpeg")
                .args(["-hide_banner", "-loglevel", "error", "-re", "-f", "lavfi"])
                .args(["-i", "testsrc=size=160x120:rate=25:duration=3"])
                .args(["-c:v", "libx264", "-preset", "ultrafast"])
                .args(["-tune", "zerolatency", "-f", "mpegts", "pipe:1"])
                .stdout(Stdio::piped())
                .spawn()
                .unwrap();
            let mut sink = std::fs::OpenOptions::new()
                .write(true)
                .open(&writer_fifo)
                .unwrap();
            std::io::copy(source.stdout.as_mut().unwrap(), &mut sink).unwrap();
            assert!(source.wait().unwrap().success());
            let last_data_at = Utc::now();
            std::thread::sleep(Duration::from_secs(4));
            drop(sink);
            last_data_at
        });

        // Short probing so encoding starts while data flows, as with a live camera
        let input = vec![
            "-probesize".to_string(),
            "32768".to_string(),
            "-analyzeduration".to_string(),
            "500000".to_string(),
            "-f".to_string(),
            "mpegts".to_string(),
            "-i".to_string(),
            fifo.to_string_lossy().into_owned(),
        ];
        let footage_start =
            run_ffmpeg_capture(&input, Duration::from_secs(30), OutputFormat::Mkv, &partial)
                .await
                .unwrap();
        let finished_at = Utc::now();
        let last_data_at = feeder.join().unwrap();
        let recorded = probe_duration(&partial).await.unwrap();
        let window = capture_window(
            footage_start,
            finished_at,
            recorded,
            Duration::from_secs(30),
        )
        .unwrap();

        assert!(finished_at - last_data_at >= chrono::Duration::milliseconds(3_500));
        assert!(
            window.end <= last_data_at + chrono::Duration::milliseconds(1_000),
            "window ends {} but the last frame arrived by {}",
            window.end,
            last_data_at
        );
        assert!(window.short);
    }

    #[tokio::test]
    async fn retention_cleans_every_video_format_after_format_changes() {
        let dir = tempfile::tempdir().unwrap();
        let camera = dir.path().join("camera-01");
        let hour = camera.join("2026/01/30/19");
        std::fs::create_dir_all(&hour).unwrap();

        let expired = [
            hour.join("segment_a_camera-01.mp4"),
            hour.join("segment_a_camera-01.json"),
            hour.join("segment_b_camera-01.mkv"),
            hour.join("segment_b_camera-01.json"),
        ];
        let triggered_mp4 = hour.join("2026-01-30_190612_segment_alert_event_id_1.mp4");
        let triggered_mkv = hour.join("2026-01-30_190613_segment_alert_event_id_2.mkv");
        let recent_mkv = hour.join("segment_c_camera-01.mkv");
        let recent_mp4 = hour.join("segment_d_camera-01.mp4");
        let old_time = FileTime::from_unix_time(Utc::now().timestamp() - 7200, 0);
        for file in expired.iter().chain([&triggered_mp4, &triggered_mkv]) {
            std::fs::write(file, b"x").unwrap();
            set_file_mtime(file, old_time).unwrap();
        }
        std::fs::write(&recent_mkv, b"x").unwrap();
        std::fs::write(&recent_mp4, b"x").unwrap();

        let cutoff = Utc::now() - chrono::Duration::hours(1);
        let deleted = cleanup_segments(&camera, cutoff).await.unwrap();

        assert_eq!(deleted, expired.len());
        for file in &expired {
            assert!(!file.exists(), "{} should be removed", file.display());
        }
        for file in [&triggered_mp4, &triggered_mkv, &recent_mkv, &recent_mp4] {
            assert!(file.exists(), "{} should be kept", file.display());
        }
    }

    fn at(timestamp: &str) -> DateTime<Utc> {
        DateTime::parse_from_rfc3339(timestamp)
            .unwrap()
            .with_timezone(&Utc)
    }

    #[test]
    fn delayed_startup_starts_window_at_first_recorded_frame() {
        // Recording was requested at 19:00:00, connecting took 8s, and 300s were captured
        let finished_at = at("2026-01-30T19:05:08Z");
        let window = capture_window(
            None,
            finished_at,
            Duration::from_secs(300),
            Duration::from_secs(300),
        )
        .unwrap();

        assert_eq!(window.start, at("2026-01-30T19:00:08Z"));
        assert_eq!(window.end, finished_at);
        assert!(!window.short);
    }

    #[test]
    fn early_ending_stream_reports_only_recorded_footage() {
        // ffmpeg exited successfully after the stream ended 42.5s into a 300s segment
        let finished_at = at("2026-01-30T19:00:45Z");
        let window = capture_window(
            None,
            finished_at,
            Duration::from_millis(42_500),
            Duration::from_secs(300),
        )
        .unwrap();

        assert_eq!(
            window.end - window.start,
            chrono::Duration::milliseconds(42_500)
        );
        assert!(window.short);
    }

    #[test]
    fn empty_or_near_empty_recording_is_rejected() {
        let finished_at = at("2026-01-30T19:00:00Z");
        for recorded in [Duration::ZERO, Duration::from_millis(400)] {
            assert!(capture_window(None, finished_at, recorded, Duration::from_secs(300)).is_err());
        }
    }

    #[test]
    fn recording_within_tolerance_is_not_short() {
        let window = capture_window(
            None,
            at("2026-01-30T19:05:00Z"),
            Duration::from_millis(299_400),
            Duration::from_secs(300),
        )
        .unwrap();
        assert!(!window.short);
    }

    #[test]
    fn parses_ffprobe_duration_output() {
        assert_eq!(
            parse_probe_duration("299.966000\n").unwrap(),
            Duration::from_secs_f64(299.966)
        );
        for invalid in ["", "N/A\n", "-1.0", "inf"] {
            assert!(
                parse_probe_duration(invalid).is_err(),
                "{invalid:?} should fail"
            );
        }
    }

    #[tokio::test]
    async fn probes_duration_of_a_short_recording() {
        let Ok(status) = std::process::Command::new("ffmpeg")
            .arg("-version")
            .stdout(Stdio::null())
            .status()
        else {
            eprintln!("skipping: ffmpeg isn't installed");
            return;
        };
        assert!(status.success());

        let dir = tempfile::tempdir().unwrap();
        let clip = dir.path().join("segment_a_camera-01.mkv.partial");
        let generated = std::process::Command::new("ffmpeg")
            .args(["-hide_banner", "-loglevel", "error", "-f", "lavfi"])
            .args(["-i", "testsrc=size=160x120:rate=10:duration=2"])
            .args(["-c:v", "libx264", "-f", "matroska", "-y"])
            .arg(&clip)
            .status()
            .unwrap();
        assert!(generated.success());

        let recorded = probe_duration(&clip).await.unwrap();
        assert!(
            (recorded.as_secs_f64() - 2.0).abs() < 0.25,
            "measured {:?}",
            recorded
        );
    }

    #[test]
    fn default_staging_is_hidden_sibling_of_sync_dir() {
        assert_eq!(
            default_staging_path(Path::new("/cloud-sync/media")).unwrap(),
            PathBuf::from("/cloud-sync/.media-staging")
        );
        assert!(default_staging_path(Path::new("/")).is_err());
        assert!(default_staging_path(Path::new("media")).is_err());
    }

    #[test]
    fn staging_partial_is_outside_sync_dir() {
        let timestamp = DateTime::parse_from_rfc3339("2026-01-30T19:05:44Z")
            .unwrap()
            .with_timezone(&Utc);
        let partial = staging_partial_path(
            Path::new("/cloud-sync/.media-staging"),
            "camera-01",
            OutputFormat::Mkv,
            &timestamp,
        );
        assert_eq!(
            partial,
            PathBuf::from(
                "/cloud-sync/.media-staging/camera-01/segment_2026-01-30T19:05:44Z_camera-01.mkv.partial"
            )
        );
        assert!(!partial.starts_with("/cloud-sync/media"));
    }

    #[test]
    fn staging_must_be_outside_sync_dir_on_same_filesystem() {
        let dir = tempfile::tempdir().unwrap();
        let sync = dir.path().join("media");
        let sibling = dir.path().join(".media-staging");
        let nested = sync.join("staging");
        for path in [&sync, &sibling, &nested] {
            std::fs::create_dir_all(path).unwrap();
        }

        assert!(ensure_same_filesystem(&sibling, &sync).is_ok());
        assert!(ensure_same_filesystem(&nested, &sync).is_err());
        assert!(ensure_same_filesystem(&dir.path().join("missing"), &sync).is_err());
        let shm = Path::new("/dev/shm");
        if shm.is_dir() {
            assert!(ensure_same_filesystem(shm, &sync).is_err());
        }
    }

    #[tokio::test]
    async fn finished_segment_moves_from_staging_into_sync_dir() {
        let dir = tempfile::tempdir().unwrap();
        let sync = dir.path().join("media");
        let staging = default_staging_path(&sync).unwrap();
        let timestamp = Utc::now();
        let partial = staging_partial_path(&staging, "camera-01", OutputFormat::Mp4, &timestamp);
        std::fs::create_dir_all(partial.parent().unwrap()).unwrap();
        std::fs::create_dir_all(&sync).unwrap();
        std::fs::write(&partial, b"frames").unwrap();
        assert!(
            walk(&sync).is_empty(),
            "nothing is visible to ACSA while recording"
        );

        let output = segment_path(&sync, "camera-01", OutputFormat::Mp4, &timestamp);
        std::fs::create_dir_all(output.parent().unwrap()).unwrap();
        tokio::fs::rename(&partial, &output).await.unwrap();

        assert_eq!(walk(&sync), vec![output]);
        assert!(!partial.exists());
    }

    fn walk(dir: &Path) -> Vec<PathBuf> {
        let mut files = Vec::new();
        for entry in std::fs::read_dir(dir).unwrap() {
            let path = entry.unwrap().path();
            if path.is_dir() {
                files.extend(walk(&path));
            } else {
                files.push(path);
            }
        }
        files
    }

    #[test]
    fn partial_path_appends_suffix() {
        assert_eq!(
            partial_path(Path::new("/s/segment_a_camera-01.mp4")),
            PathBuf::from("/s/segment_a_camera-01.mp4.partial")
        );
    }

    #[tokio::test]
    async fn cleanup_of_missing_camera_directory_is_a_no_op() {
        let dir = tempfile::tempdir().unwrap();
        let deleted = cleanup_segments(&dir.path().join("none"), Utc::now())
            .await
            .unwrap();
        assert_eq!(deleted, 0);
    }
}
