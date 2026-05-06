//! Fuzz target: exercises serde_json parsing of telemetry payloads.
#![no_main]

use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    let _ = serde_json::from_slice::<serde_json::Value>(data);
});
