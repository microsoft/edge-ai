use std::{error::Error, path::{Path, PathBuf}};
use chrono::{DateTime, Utc};
use tokio::fs;
use tracing::{info, debug};
use serde_json::json;

pub struct AcsaWriter {
    acsa_mount_path: PathBuf,
}

impl AcsaWriter {
    pub fn new(acsa_mount_path: PathBuf) -> Self {
        Self { acsa_mount_path }
    }

    pub fn from_environment() -> Result<Self, Box<dyn Error>> {
        let acsa_mount_path = std::env::var("MEDIA_CLOUD_SYNC_DIR")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/media-capture-backed-acsa"));

        Ok(Self::new(acsa_mount_path))
    }

    pub async fn write_segment_with_metadata(
        &self,
        video_file: &Path,
        camera_id: &str,
        camera_location: &str,
        segment_start: DateTime<Utc>,
        segment_end: DateTime<Utc>,
    ) -> Result<(), Box<dyn Error>> {
        info!(
            "Writing video segment to ACSA volume: {}",
            video_file.display()
        );

        let metadata = json!({
            "camera_id": camera_id,
            "location": camera_location,
            "segment_start": segment_start.to_rfc3339(),
            "segment_end": segment_end.to_rfc3339(),
            "duration_seconds": (segment_end - segment_start).num_seconds(),
            "file_path": video_file.to_str(),
        });

        let metadata_path = video_file.with_extension("json");
        fs::write(&metadata_path, serde_json::to_string_pretty(&metadata)?).await?;

        debug!(
            "Metadata written for segment: {}",
            metadata_path.display()
        );

        info!(
            "ACSA will automatically sync {} to Azure Blob Storage",
            video_file.display()
        );

        Ok(())
    }

    pub fn generate_acsa_path(
        &self,
        camera_id: &str,
        timestamp: &DateTime<Utc>,
    ) -> PathBuf {
        let hash_prefix = Self::calculate_hash_prefix(camera_id);

        self.acsa_mount_path
            .join(hash_prefix)
            .join(camera_id)
            .join(timestamp.format("%Y").to_string())
            .join(timestamp.format("%m").to_string())
            .join(timestamp.format("%d").to_string())
            .join(timestamp.format("%H").to_string())
            .join(format!(
                "segment_{}_{}.mp4",
                timestamp.format("%Y-%m-%dT%H:%M:%SZ"),
                camera_id
            ))
    }

    fn calculate_hash_prefix(camera_id: &str) -> String {
        use md5::Digest;
        let digest = md5::compute(camera_id.as_bytes());
        format!("{:03}", digest[0] as u32 % 1000)
    }
}
