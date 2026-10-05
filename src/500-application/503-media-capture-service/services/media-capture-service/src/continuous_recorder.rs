//! Continuous recording mode: records fixed-length segments from an RTSP
//! stream into the cloud sync directory, where ACSA uploads them to Blob
//! Storage.
//!
//! Segments are written to
//! `{MEDIA_CLOUD_SYNC_DIR}/{camera_id}/{YYYY}/{MM}/{DD}/{HH}/segment_{start}_{camera_id}.{ext}`
//! with a JSON metadata sidecar, which is the layout the video query API lists
//! by prefix.

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
    time::Duration,
};
use tokio::{fs, process::Command, time::interval};
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
    pub location: String,
    /// Local segments older than this are deleted; `None` disables cleanup.
    pub retention: Option<Duration>,
    pub cleanup_interval: Duration,
    pub output_format: OutputFormat,
}

pub struct ContinuousRecorder {
    config: ContinuousRecorderConfig,
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
        Self { config }
    }

    /// Builds the recorder from environment variables. `CAMERA_ID`,
    /// `RTSP_URL`, and `MEDIA_CLOUD_SYNC_DIR` are required.
    pub fn from_environment() -> Result<Self, Box<dyn Error>> {
        let camera_id =
            camera_id_from_env()?.ok_or("CAMERA_ID must be set for continuous recording")?;
        let rtsp_url = required_env("RTSP_URL")?;
        let output_base_path = PathBuf::from(required_env("MEDIA_CLOUD_SYNC_DIR")?);
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

        // Segments left by an interrupted earlier run are incomplete
        let camera_path = self.config.output_base_path.join(&self.config.camera_id);
        match remove_partial_segments(&camera_path).await {
            Ok(0) => {}
            Ok(count) => warn!("Removed {count} incomplete segments from an earlier run"),
            Err(e) => warn!("Failed to remove incomplete segments: {e}"),
        }

        if let Some(retention) = self.config.retention {
            self.start_cleanup_task(retention);
        }

        loop {
            let segment_start = Utc::now();
            match self.record_segment(segment_start).await {
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

    async fn record_segment(
        &self,
        segment_start: DateTime<Utc>,
    ) -> Result<PathBuf, Box<dyn Error>> {
        let output = segment_path(
            &self.config.output_base_path,
            &self.config.camera_id,
            self.config.output_format,
            &segment_start,
        );
        if let Some(parent) = output.parent() {
            fs::create_dir_all(parent).await?;
        }

        let partial = partial_path(&output);
        if let Err(e) = self.run_ffmpeg(&partial).await {
            let _ = fs::remove_file(&partial).await;
            return Err(e);
        }
        fs::rename(&partial, &output).await?;

        let segment_end = segment_start + chrono::Duration::from_std(self.config.segment_duration)?;
        AcsaWriter::write_segment_with_metadata(
            &output,
            &self.config.camera_id,
            &self.config.location,
            segment_start,
            segment_end,
        )
        .await?;

        info!(
            "Recorded {} ({:.2} MB) for upload by ACSA",
            output.display(),
            fs::metadata(&output).await?.len() as f64 / 1_048_576.0
        );
        Ok(output)
    }

    async fn run_ffmpeg(&self, output: &Path) -> Result<(), Box<dyn Error>> {
        let duration = self.config.segment_duration.as_secs().to_string();
        let output_str = output.to_str().ok_or("Segment path is not valid UTF-8")?;

        let mut command = Command::new("ffmpeg");
        command
            .args(["-hide_banner", "-loglevel", "error"])
            .args(["-rtsp_transport", "tcp"])
            // RTSP socket I/O timeout in microseconds
            .args(["-timeout", "10000000"])
            .args(["-i", &self.config.rtsp_url])
            .args(["-t", &duration])
            // Downscale to 360p and favor encoding speed to bound CPU and memory use
            .args(["-vf", "scale=-2:360"])
            .args(["-c:v", "libx264", "-preset", "ultrafast", "-crf", "28"])
            .args(["-g", "30", "-sc_threshold", "0"])
            .args(["-c:a", "aac", "-b:a", "64k"])
            .args(["-f", self.config.output_format.muxer()]);
        if self.config.output_format == OutputFormat::Mp4 {
            command.args(["-movflags", "+faststart"]);
        }
        command
            .args(["-y", output_str])
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::piped())
            .kill_on_drop(true);

        let child = command.spawn()?;
        let limit = self.config.segment_duration + FFMPEG_GRACE;
        let result = tokio::time::timeout(limit, child.wait_with_output())
            .await
            .map_err(|_| {
                format!(
                    "ffmpeg did not finish within {}s and was stopped",
                    limit.as_secs()
                )
            })??;

        if !result.status.success() {
            let stderr = redact_url_credentials(&String::from_utf8_lossy(&result.stderr));
            let last_line = stderr.lines().next_back().unwrap_or("no error output");
            return Err(format!("ffmpeg exited with {}: {}", result.status, last_line).into());
        }
        Ok(())
    }

    fn start_cleanup_task(&self, retention: Duration) {
        let camera_path = self.config.output_base_path.join(&self.config.camera_id);
        let extension = self.config.output_format.extension();
        let cleanup_interval = self.config.cleanup_interval;
        let camera_id = self.config.camera_id.clone();
        let retention = chrono::Duration::from_std(retention).unwrap_or(chrono::Duration::MAX);

        tokio::spawn(async move {
            let mut timer = interval(cleanup_interval);
            loop {
                timer.tick().await;
                let cutoff = Utc::now() - retention;
                match cleanup_segments(&camera_path, cutoff, extension).await {
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

/// Returns the path ffmpeg writes to before the segment is complete.
pub fn partial_path(output: &Path) -> PathBuf {
    let mut name = output.as_os_str().to_owned();
    name.push(".");
    name.push(PARTIAL_EXTENSION);
    PathBuf::from(name)
}

/// Deletes continuous segment videos, metadata sidecars, and incomplete
/// segments under `camera_path` that were last modified before `cutoff`, then
/// removes empty directories. Triggered clips aren't touched because they
/// don't use the `segment_` prefix.
pub async fn cleanup_segments(
    camera_path: &Path,
    cutoff: DateTime<Utc>,
    video_extension: &str,
) -> Result<usize, std::io::Error> {
    let matches = |path: &Path| {
        is_segment_file(path, video_extension) || is_segment_file(path, PARTIAL_EXTENSION)
    };
    cleanup_tree(camera_path, cutoff, &matches).await
}

/// Deletes every incomplete segment under `camera_path`.
pub async fn remove_partial_segments(camera_path: &Path) -> Result<usize, std::io::Error> {
    let matches = |path: &Path| is_segment_file(path, PARTIAL_EXTENSION);
    cleanup_tree(camera_path, DateTime::<Utc>::MAX_UTC, &matches).await
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

fn is_segment_file(path: &Path, extension: &str) -> bool {
    let is_segment = path
        .file_name()
        .and_then(|name| name.to_str())
        .is_some_and(|name| name.starts_with(SEGMENT_PREFIX));
    let actual = path.extension().and_then(|ext| ext.to_str());
    is_segment
        && (actual == Some(extension)
            || (extension != PARTIAL_EXTENSION && actual == Some(METADATA_EXTENSION)))
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
        let deleted = cleanup_segments(&camera, cutoff, "mp4").await.unwrap();

        assert_eq!(deleted, 3);
        assert!(!old_partial.exists());
        assert!(!old_hour.exists(), "empty hour directory should be removed");
        assert!(
            triggered.exists(),
            "triggered clips are not continuous segments"
        );
        assert!(new_video.exists());
    }

    #[tokio::test]
    async fn removes_all_partial_segments_on_startup() {
        let dir = tempfile::tempdir().unwrap();
        let hour = dir.path().join("camera-01/2026/01/30/19");
        std::fs::create_dir_all(&hour).unwrap();
        let complete = hour.join("segment_a_camera-01.mp4");
        let partial = partial_path(&hour.join("segment_b_camera-01.mp4"));
        std::fs::write(&complete, b"x").unwrap();
        std::fs::write(&partial, b"x").unwrap();

        let removed = remove_partial_segments(&dir.path().join("camera-01"))
            .await
            .unwrap();

        assert_eq!(removed, 1);
        assert!(complete.exists());
        assert!(!partial.exists());
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
        let deleted = cleanup_segments(&dir.path().join("none"), Utc::now(), "mp4")
            .await
            .unwrap();
        assert_eq!(deleted, 0);
    }
}
