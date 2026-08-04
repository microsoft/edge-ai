//! Test-only byte-length and SHA-256 instrumentation for a request body.
//!
//! Used to prove that a request body reaches the runtime without truncation or
//! transcoding after Device Registry projection. Does not send or forward the body.

use sha2::{Digest, Sha256};

/// Byte length and hex-encoded SHA-256 digest of a request body.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BodyProof {
    pub byte_len: usize,
    pub sha256_hex: String,
}

/// Records the UTF-8 byte length and SHA-256 digest of `body`.
pub fn record(body: &str) -> BodyProof {
    let bytes = body.as_bytes();
    let mut hasher = Sha256::new();
    hasher.update(bytes);
    let digest = hasher.finalize();
    let sha256_hex = digest.iter().map(|byte| format!("{byte:02x}")).collect();
    BodyProof {
        byte_len: bytes.len(),
        sha256_hex,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn records_empty_body() {
        let proof = record("");
        assert_eq!(proof.byte_len, 0);
        assert_eq!(
            proof.sha256_hex,
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        );
    }

    #[test]
    fn records_known_test_vector() {
        let proof = record("abc");
        assert_eq!(proof.byte_len, 3);
        assert_eq!(
            proof.sha256_hex,
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        );
    }

    #[test]
    fn byte_len_counts_utf8_bytes_not_chars() {
        // "café" has 4 chars but 5 UTF-8 bytes (é is 2 bytes).
        let proof = record("café");
        assert_eq!(proof.byte_len, 5);
    }

    #[test]
    fn record_is_deterministic() {
        let body = "a".repeat(10_000);
        assert_eq!(record(&body), record(&body));
    }

    #[test]
    fn different_bodies_produce_different_hashes() {
        let first = record("hello");
        let second = record("hello!");
        assert_ne!(first.sha256_hex, second.sha256_hex);
    }
}
