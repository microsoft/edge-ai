use std::{env, error::Error, path::{Path, PathBuf}, process::{Command, Stdio}, time::Duration};
use chrono::{DateTime, Utc};
use tokio::{fs, time::interval};
use tracing::{info, error, debug, warn};
use std::pin::Pin;
use std::future::Future;
use crate::acsa_writer::AcsaWriter;

pub struct ContinuousRecorder {
    camera_id: String,
    rtsp_url: String,
    segment_duration: Duration,
    output_base_path: PathBuf,
    location: String,
    retention_hours: u64,
    cleanup_interval_minutes: u64,
    output_format: String,
    acsa_writer: AcsaWriter,
}

impl ContinuousRecorder {
    pub fn new(
        camera_id: String,
        rtsp_url: String,
        segment_duration: Duration,
        output_base_path: PathBuf,
        location: String,
        retention_hours: u64,
        cleanup_interval_minutes: u64,
        output_format: String,
    ) -> Result<Self, Box<dyn Error>> {
        let acsa_writer = AcsaWriter::from_environment()?;
        Ok(Self {
            camera_id,
            rtsp_url,
            segment_duration,
            output_base_path,
            location,
            retention_hours,
            cleanup_interval_minutes,
            output_format,
            acsa_writer,
        })
    }

    pub fn from_environment() -> Result<Self, Box<dyn Error>> {
        let camera_id = env::var("CAMERA_ID")
            .unwrap_or_else(|_| "camera-01".to_string());
        let rtsp_url = env::var("RTSP_URL")
            .expect("RTSP_URL not set");
        let segment_duration_secs: u64 = env::var("CONTINUOUS_SEGMENT_DURATION_SECONDS")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(300);
        let output_base_path = PathBuf::from(
            env::var("MEDIA_CLOUD_SYNC_DIR").expect("MEDIA_CLOUD_SYNC_DIR not set")
        );
        let location = env::var("CAMERA_LOCATION")
            .unwrap_or_else(|_| "unknown".to_string());
        let retention_hours: u64 = env::var("LOCAL_RETENTION_HOURS")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(24);
        let cleanup_interval_minutes: u64 = env::var("CLEANUP_INTERVAL_MINUTES")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(60);
        let output_format = env::var("OUTPUT_FORMAT")
            .unwrap_or_else(|_| "mp4".to_string())
            .to_lowercase();

        let recorder = Self::new(
            camera_id,
            rtsp_url,
            Duration::from_secs(segment_duration_secs),
            output_base_path,
            location,
            retention_hours,
            cleanup_interval_minutes,
            output_format,
        )?;

        info!("Recording locally to ACSA-mounted volume for automatic Azure upload");
        info!("Local retention: {} hours, cleanup interval: {} minutes",
              retention_hours, cleanup_interval_minutes);

        Ok(recorder)
    }

    pub async fn record_loop(&self) -> Result<(), Box<dyn Error>> {
        info!(
            "Starting continuous recording loop for camera {} with {}s segments",
            self.camera_id,
            self.segment_duration.as_secs()
        );

        // Start cleanup task in background
        self.start_cleanup_task();

        loop {
            let segment_start = Utc::now();

            match self.record_and_upload_segment(segment_start).await {
                Ok(_) => {
                    debug!("Successfully recorded and uploaded segment for {}", self.camera_id);
                }
                Err(e) => {
                    error!("Failed to record/upload segment: {}", e);
                    tokio::time::sleep(Duration::from_secs(5)).await;
                }
            }
        }
    }

    async fn record_and_upload_segment(&self, segment_start: DateTime<Utc>) -> Result<(), Box<dyn Error>> {
        let local_file = self.generate_local_filename(&segment_start);

        self.ensure_local_directory(&local_file).await?;

        self.record_segment_with_keyframes(&local_file, self.segment_duration).await?;

        let segment_end = segment_start + chrono::Duration::from_std(self.segment_duration)?;

        // Write companion JSON metadata
        self.acsa_writer.write_segment_with_metadata(
            &local_file,
            &self.camera_id,
            &self.location,
            segment_start,
            segment_end,
        ).await?;

        info!("Segment recorded to ACSA-mounted path: {} ({:.2} MB) - ACSA will automatically upload to Azure",
            local_file.display(),
            fs::metadata(&local_file).await?.len() as f64 / 1_048_576.0
        );

        Ok(())
    }

    async fn record_segment_with_keyframes(
        &self,
        output: &Path,
        duration: Duration,
    ) -> Result<(), Box<dyn Error>> {
        info!(
            "Recording {}s segment with keyframe alignment to {}",
            duration.as_secs(),
            output.display()
        );

        let duration_str = duration.as_secs().to_string();

        // Map file extension to FFmpeg format name
        let ffmpeg_format = match self.output_format.as_str() {
            "mkv" => "matroska",
            "mp4" => "mp4",
            _ => &self.output_format,  // Use as-is for other formats
        };

        let mut ffmpeg_args = vec![
            "-rtsp_transport", "tcp",
            "-timeout", "10000000",  // 10 seconds in microseconds
            "-i", &self.rtsp_url,
            "-t", &duration_str,
            "-vf", "scale=-1:360",  // Scale down to 360p to reduce memory
            "-c:v", "libx264",
            "-preset", "ultrafast",  // Faster encoding, less memory
            "-crf", "28",  // Higher CRF for smaller file size
            "-g", "30",
            "-sc_threshold", "0",
            "-c:a", "aac",
            "-b:a", "64k",  // Lower audio bitrate
            "-f", ffmpeg_format,
        ];

        // Add movflags only for mp4 format
        if self.output_format == "mp4" {
            ffmpeg_args.push("-movflags");
            ffmpeg_args.push("+faststart");
        }

        ffmpeg_args.push("-y");
        ffmpeg_args.push(output.to_str().ok_or("Invalid path")?);

        let output_result = Command::new("ffmpeg")
            .args(&ffmpeg_args)
            .stdout(Stdio::null())
            .stderr(Stdio::piped())
            .output()?;

        if !output_result.status.success() {
            let stderr = String::from_utf8_lossy(&output_result.stderr);
            error!("FFmpeg stderr: {}", stderr);
            return Err(format!("FFmpeg failed with status: {} - {}", output_result.status,
                stderr.lines().last().unwrap_or("no error message")).into());
        }

        Ok(())
    }

    fn generate_local_filename(&self, timestamp: &DateTime<Utc>) -> PathBuf {
        let filename = format!(
            "segment_{}_{}.{}",
            timestamp.format("%Y-%m-%dT%H:%M:%SZ"),
            self.camera_id,
            self.output_format
        );

        self.output_base_path
            .join(&self.camera_id)
            .join(timestamp.format("%Y").to_string())
            .join(timestamp.format("%m").to_string())
            .join(timestamp.format("%d").to_string())
            .join(timestamp.format("%H").to_string())
            .join(filename)
    }

    async fn ensure_local_directory(&self, file_path: &Path) -> Result<(), Box<dyn Error>> {
        if let Some(parent) = file_path.parent() {
            // Always try to create the directory - create_dir_all is idempotent
            debug!("Ensuring directory exists: {}", parent.display());
            fs::create_dir_all(parent).await?;
            info!("Directory ready: {}", parent.display());
        }
        Ok(())
    }

    pub fn get_camera_id(&self) -> &str {
        &self.camera_id
    }

    pub fn get_location(&self) -> &str {
        &self.location
    }

    fn start_cleanup_task(&self) {
        let base_path = self.output_base_path.clone();
        let camera_id = self.camera_id.clone();
        let retention_hours = self.retention_hours;
        let cleanup_interval = Duration::from_secs(self.cleanup_interval_minutes * 60);
        let format = self.output_format.clone();

        tokio::spawn(async move {
            let mut interval_timer = interval(cleanup_interval);
            info!(
                "Starting file cleanup task (retention: {}h, interval: {}m) for camera {}",
                retention_hours,
                cleanup_interval.as_secs() / 60,
                camera_id
            );

            loop {
                interval_timer.tick().await;

                match Self::cleanup_old_files(&base_path, &camera_id, retention_hours, &format).await {
                    Ok(count) => {
                        if count > 0 {
                            info!("Cleaned up {} old files for camera {}", count, camera_id);
                        } else {
                            debug!("No old files to clean up for camera {}", camera_id);
                        }
                    }
                    Err(e) => {
                        warn!("Failed to clean up old files: {}", e);
                    }
                }
            }
        });
    }

    async fn cleanup_old_files(
        base_path: &Path,
        camera_id: &str,
        retention_hours: u64,
        output_format: &str,
    ) -> Result<usize, std::io::Error> {
        let camera_path = base_path.join(camera_id);

        if !camera_path.exists() {
            return Ok(0);
        }

        let now = Utc::now();
        let retention_duration = chrono::Duration::hours(retention_hours as i64);
        let cutoff_time = now - retention_duration;
        let mut deleted_count = 0;

        Self::cleanup_directory_recursive(&camera_path, cutoff_time, &mut deleted_count, output_format).await?;

        Ok(deleted_count)
    }

    fn cleanup_directory_recursive<'a>(
        dir_path: &'a Path,
        cutoff_time: DateTime<Utc>,
        deleted_count: &'a mut usize,
        output_format: &'a str,
    ) -> Pin<Box<dyn Future<Output = Result<(), std::io::Error>> + Send + 'a>> {
        Box::pin(async move {
            let mut entries = fs::read_dir(dir_path).await?;

            while let Some(entry) = entries.next_entry().await? {
                let path = entry.path();

                if path.is_dir() {
                    Self::cleanup_directory_recursive(&path, cutoff_time, deleted_count, output_format).await?;

                    // Remove empty directories
                    if let Ok(mut dir_entries) = fs::read_dir(&path).await {
                        if dir_entries.next_entry().await?.is_none() {
                            if let Err(e) = fs::remove_dir(&path).await {
                                warn!("Failed to remove empty directory {}: {}", path.display(), e);
                            } else {
                                debug!("Removed empty directory: {}", path.display());
                            }
                        }
                    }
                } else if path.extension().and_then(|s| s.to_str()) == Some(output_format) {
                    if let Ok(metadata) = fs::metadata(&path).await {
                        if let Ok(modified) = metadata.modified() {
                            let modified_datetime: DateTime<Utc> = modified.into();

                            if modified_datetime < cutoff_time {
                                match fs::remove_file(&path).await {
                                    Ok(_) => {
                                        debug!("Deleted old file: {}", path.display());
                                        *deleted_count += 1;
                                    }
                                    Err(e) => {
                                        warn!("Failed to delete {}: {}", path.display(), e);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Ok(())
        })
    }
}
