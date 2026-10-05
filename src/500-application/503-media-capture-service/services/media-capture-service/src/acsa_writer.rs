//! Writes the JSON metadata sidecar for each continuous recording segment.
//!
//! Segments are written under the Azure Container Storage enabled by Azure Arc
//! (ACSA) cloud-backed volume, which uploads both files to Blob Storage. The
//! video query API reads `segment_start`, `segment_end`, `duration_seconds`,
//! and `location` from the sidecar.

use chrono::{DateTime, Utc};
use serde_json::json;
use std::{error::Error, path::Path};
use tokio::fs;
use tracing::debug;

pub struct AcsaWriter;

impl AcsaWriter {
    /// Writes `<segment>.json` next to `video_file`.
    pub async fn write_segment_with_metadata(
        video_file: &Path,
        camera_id: &str,
        camera_location: &str,
        segment_start: DateTime<Utc>,
        segment_end: DateTime<Utc>,
    ) -> Result<(), Box<dyn Error>> {
        let metadata = json!({
            "camera_id": camera_id,
            "location": camera_location,
            "segment_start": segment_start.to_rfc3339(),
            "segment_end": segment_end.to_rfc3339(),
            "duration_seconds": (segment_end - segment_start).num_seconds(),
            "file_name": video_file.file_name().and_then(|name| name.to_str()),
        });

        let metadata_path = video_file.with_extension("json");
        fs::write(&metadata_path, serde_json::to_string_pretty(&metadata)?).await?;
        debug!("Metadata written for segment: {}", metadata_path.display());

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn writes_sidecar_with_query_fields() {
        let dir = tempfile::tempdir().unwrap();
        let video = dir
            .path()
            .join("segment_2026-01-30T19:05:44Z_camera-01.mp4");
        let start = DateTime::parse_from_rfc3339("2026-01-30T19:05:44Z")
            .unwrap()
            .with_timezone(&Utc);
        let end = start + chrono::Duration::seconds(300);

        AcsaWriter::write_segment_with_metadata(&video, "camera-01", "line-1", start, end)
            .await
            .unwrap();

        let raw = std::fs::read_to_string(video.with_extension("json")).unwrap();
        let value: serde_json::Value = serde_json::from_str(&raw).unwrap();
        assert_eq!(value["camera_id"], "camera-01");
        assert_eq!(value["location"], "line-1");
        assert_eq!(value["segment_start"], "2026-01-30T19:05:44+00:00");
        assert_eq!(value["segment_end"], "2026-01-30T19:10:44+00:00");
        assert_eq!(value["duration_seconds"], 300);
        assert_eq!(
            value["file_name"],
            "segment_2026-01-30T19:05:44Z_camera-01.mp4"
        );
    }
}
