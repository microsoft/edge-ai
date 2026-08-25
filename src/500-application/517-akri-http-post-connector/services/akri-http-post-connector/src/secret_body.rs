//! Resolves a dataset's `request.bodySecretAlias` to its request body content via
//! the Akri operator's connector-template secrets mount using async local file
//! reads. No Kubernetes API client or additional RBAC grant is required.
//!
//! Mounted layout (per the Akri connector-template secrets contract): the file
//! `{secrets_metadata_mount}/{secret_alias}` contains a path, relative to
//! `secrets_mount`, of the file holding the actual secret content.

use std::path::{Component, Path};

use crate::config::MAX_REQUEST_BODY_BYTES;

/// Resolves `secret_alias` to its mounted request body content.
///
/// Reads `{secrets_metadata_mount}/{secret_alias}` to obtain a relative path,
/// rejects a resolved path that is absolute or contains a `..` component (the
/// mount content is platform-controlled, but this is rejected defensively before
/// ever being joined onto a real filesystem path), joins the validated relative
/// path onto `secrets_mount`, and reads the resulting file as UTF-8. Enforces the
/// [`MAX_REQUEST_BODY_BYTES`] ceiling shared with the rest of the request body
/// contract, and rejects empty content. Never panics; every failure is returned as
/// `Err`.
pub async fn resolve_body(
    secrets_metadata_mount: &Path,
    secrets_mount: &Path,
    secret_alias: &str,
) -> Result<String, String> {
    let alias_file = secrets_metadata_mount.join(secret_alias);
    let relative_path_raw = tokio::fs::read_to_string(&alias_file)
        .await
        .map_err(|err| {
            format!(
                "failed to read secret alias metadata '{}': {err}",
                alias_file.display()
            )
        })?;
    let relative_path = relative_path_raw.trim();
    if relative_path.is_empty() {
        return Err(format!(
            "secret alias metadata '{}' is empty",
            alias_file.display()
        ));
    }

    let relative_path = Path::new(relative_path);
    if relative_path.is_absolute()
        || relative_path
            .components()
            .any(|component| matches!(component, Component::ParentDir))
    {
        return Err(format!(
            "secret alias '{secret_alias}' resolved to an unsafe path '{}'",
            relative_path.display()
        ));
    }

    let content_file = secrets_mount.join(relative_path);
    let content = tokio::fs::read_to_string(&content_file)
        .await
        .map_err(|err| {
            format!(
                "failed to read secret content '{}': {err}",
                content_file.display()
            )
        })?;
    if content.is_empty() {
        return Err(format!(
            "secret content '{}' is empty",
            content_file.display()
        ));
    }
    if content.len() > MAX_REQUEST_BODY_BYTES {
        return Err(format!(
            "secret content '{}' length {} bytes exceeds the {} byte ceiling",
            content_file.display(),
            content.len(),
            MAX_REQUEST_BODY_BYTES
        ));
    }
    Ok(content)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;
    use std::sync::atomic::{AtomicU64, Ordering};

    /// A throwaway pair of secrets-metadata-mount / secrets-mount directories,
    /// removed when dropped. Built with `std::fs`/`std::env` only, matching this
    /// crate's constraint of not adding a new Cargo dependency for test scaffolding.
    struct TestMount {
        metadata_dir: PathBuf,
        secrets_dir: PathBuf,
    }

    impl TestMount {
        fn new() -> Self {
            static COUNTER: AtomicU64 = AtomicU64::new(0);
            let unique = COUNTER.fetch_add(1, Ordering::Relaxed);
            let base = std::env::temp_dir().join(format!(
                "akri-http-post-connector-secret-body-test-{}-{unique}",
                std::process::id()
            ));
            let metadata_dir = base.join("metadata");
            let secrets_dir = base.join("secrets");
            std::fs::create_dir_all(&metadata_dir).unwrap();
            std::fs::create_dir_all(&secrets_dir).unwrap();
            Self {
                metadata_dir,
                secrets_dir,
            }
        }

        fn write_alias(&self, alias: &str, relative_path: &str) {
            std::fs::write(self.metadata_dir.join(alias), relative_path).unwrap();
        }

        fn write_content(&self, relative_path: &str, content: &str) {
            std::fs::write(self.secrets_dir.join(relative_path), content).unwrap();
        }
    }

    impl Drop for TestMount {
        fn drop(&mut self) {
            if let Some(base) = self.metadata_dir.parent() {
                let _ = std::fs::remove_dir_all(base);
            }
        }
    }

    #[tokio::test]
    async fn resolves_body_from_alias_and_content_files() {
        let mount = TestMount::new();
        mount.write_alias("body-alias", "request-body\n");
        mount.write_content("request-body", "hello world");

        let resolved = resolve_body(&mount.metadata_dir, &mount.secrets_dir, "body-alias")
            .await
            .unwrap();
        assert_eq!(resolved, "hello world");
    }

    #[tokio::test]
    async fn rejects_missing_alias_file() {
        let mount = TestMount::new();
        assert!(
            resolve_body(&mount.metadata_dir, &mount.secrets_dir, "missing-alias")
                .await
                .is_err()
        );
    }

    #[tokio::test]
    async fn rejects_missing_content_file() {
        let mount = TestMount::new();
        mount.write_alias("body-alias", "missing-content");

        assert!(
            resolve_body(&mount.metadata_dir, &mount.secrets_dir, "body-alias")
                .await
                .is_err()
        );
    }

    #[tokio::test]
    async fn rejects_oversized_content() {
        let mount = TestMount::new();
        mount.write_alias("body-alias", "request-body");
        mount.write_content("request-body", &"a".repeat(MAX_REQUEST_BODY_BYTES + 1));

        assert!(
            resolve_body(&mount.metadata_dir, &mount.secrets_dir, "body-alias")
                .await
                .is_err()
        );
    }

    #[tokio::test]
    async fn rejects_empty_content() {
        let mount = TestMount::new();
        mount.write_alias("body-alias", "request-body");
        mount.write_content("request-body", "");

        assert!(
            resolve_body(&mount.metadata_dir, &mount.secrets_dir, "body-alias")
                .await
                .is_err()
        );
    }

    #[tokio::test]
    async fn rejects_parent_dir_traversal_in_relative_path() {
        let mount = TestMount::new();
        mount.write_alias("body-alias", "../../etc/passwd");

        assert!(
            resolve_body(&mount.metadata_dir, &mount.secrets_dir, "body-alias")
                .await
                .is_err()
        );
    }

    #[tokio::test]
    async fn rejects_absolute_relative_path() {
        let mount = TestMount::new();
        mount.write_alias("body-alias", "/etc/passwd");

        assert!(
            resolve_body(&mount.metadata_dir, &mount.secrets_dir, "body-alias")
                .await
                .is_err()
        );
    }
}
