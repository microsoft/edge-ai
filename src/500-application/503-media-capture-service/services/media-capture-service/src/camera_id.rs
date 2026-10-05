//! Camera identifier validation shared by the triggered and continuous paths.
//!
//! Camera IDs become directory and file name components under the cloud sync
//! directory and blob name prefixes queried by the video query API, so they are
//! limited to the same character set that API accepts.

use std::env;

const MAX_CAMERA_ID_LEN: usize = 128;

/// Returns true when `camera_id` contains only ASCII letters, digits, `_`, or
/// `-` and is between 1 and 128 characters long.
pub fn is_valid_camera_id(camera_id: &str) -> bool {
    !camera_id.is_empty()
        && camera_id.len() <= MAX_CAMERA_ID_LEN
        && camera_id
            .bytes()
            .all(|b| b.is_ascii_alphanumeric() || b == b'_' || b == b'-')
}

/// Reads `CAMERA_ID` from the environment.
///
/// Returns `Ok(None)` when the variable is unset or empty and an error when it
/// is set to a value that fails [`is_valid_camera_id`].
pub fn camera_id_from_env() -> Result<Option<String>, String> {
    match env::var("CAMERA_ID") {
        Ok(value) if value.is_empty() => Ok(None),
        Ok(value) if is_valid_camera_id(&value) => Ok(Some(value)),
        Ok(_) => {
            Err("CAMERA_ID must be 1-128 characters of letters, digits, '_', or '-'".to_string())
        }
        Err(_) => Ok(None),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_expected_identifiers() {
        assert!(is_valid_camera_id("camera-01"));
        assert!(is_valid_camera_id("Line_2-cam3"));
        assert!(is_valid_camera_id(&"a".repeat(MAX_CAMERA_ID_LEN)));
    }

    #[test]
    fn rejects_path_and_filter_characters() {
        for value in [
            "", "../etc", "cam/01", "cam 01", "cam'01", "cam.01", "cam\\01",
        ] {
            assert!(!is_valid_camera_id(value), "{value:?} should be rejected");
        }
        assert!(!is_valid_camera_id(&"a".repeat(MAX_CAMERA_ID_LEN + 1)));
    }
}
