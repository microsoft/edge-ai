#![allow(clippy::missing_safety_doc)]
//! featurize-acoustic: map operator that turns a mono audio window into
//! 640-dimensional log-mel feature rows and wraps them as an MQTT predict
//! adapter request.
//!
//! Features follow the DCASE 2020 Task 2 autoencoder baseline: a power
//! spectrogram (`n_fft = 1024`, `hop = 512`, periodic Hann window, centered
//! zero padding), a Slaney-normalized 128-band mel filterbank, `10 * log10`
//! scaling, and five consecutive frames concatenated frame-major into one
//! 640-value row per window.
//!
//! Input: `{"sample_rate": 16000, "samples": [...], ...}` with samples in
//! `[-1, 1]`. Output: `{"inputs": [[640 floats], ...], "context": {...}}`,
//! where `context` carries the configured identity fields from the input.

use std::sync::OnceLock;

use rustfft::num_complex::Complex;
use rustfft::FftPlanner;
use serde_json::{Map, Value};
use wasm_graph_sdk::logger::{self, Level};
use wasm_graph_sdk::macros::map_operator;
use wasm_graph_sdk::metrics::{self, CounterValue, Label};

const MODULE: &str = "featurize-acoustic";

pub const N_MELS: usize = 128;
pub const FRAMES: usize = 5;
pub const N_FFT: usize = 1024;
pub const HOP_LENGTH: usize = 512;
pub const INPUT_DIM: usize = N_MELS * FRAMES;
// f64 machine epsilon, the log floor used by the reference implementation.
// It's representable in f32, so silent bins match the reference exactly.
const EPS: f32 = f64::EPSILON as f32;

const MIN_SAMPLE_RATE: u32 = 8_000;
const MAX_SAMPLE_RATE: u32 = 192_000;
const MAX_CONTEXT_VALUE_LEN: usize = 128;

#[derive(Debug, Clone, PartialEq)]
pub struct Config {
    pub max_batch_size: usize,
    pub max_samples: usize,
    pub context_fields: Vec<String>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            max_batch_size: 32,
            max_samples: 960_000,
            context_fields: vec![
                "asset_id".to_string(),
                "sensor_id".to_string(),
                "timestamp".to_string(),
            ],
        }
    }
}

static CONFIG: OnceLock<Config> = OnceLock::new();

/// Parses graph parameters. Unknown keys are ignored; invalid values fail init.
pub fn parse_config(properties: &[(String, String)]) -> Result<Config, String> {
    let mut config = Config::default();
    for (key, value) in properties {
        match key.as_str() {
            "max_batch_size" => {
                config.max_batch_size = parse_bounded(key, value, 1, 1024)?;
            }
            "max_samples" => {
                config.max_samples = parse_bounded(key, value, N_FFT, 10_000_000)?;
            }
            "context_fields" => {
                config.context_fields = value
                    .split(',')
                    .map(str::trim)
                    .filter(|field| !field.is_empty())
                    .map(str::to_string)
                    .collect();
                if config.context_fields.len() > 8 {
                    return Err("context_fields accepts at most 8 field names".to_string());
                }
            }
            _ => {}
        }
    }
    Ok(config)
}

fn parse_bounded(key: &str, value: &str, min: usize, max: usize) -> Result<usize, String> {
    value
        .trim()
        .parse::<usize>()
        .ok()
        .filter(|parsed| (min..=max).contains(parsed))
        .ok_or_else(|| format!("{key} must be an integer from {min} to {max}"))
}

fn featurize_init(configuration: ModuleConfiguration) -> bool {
    match parse_config(&configuration.properties) {
        Ok(config) => {
            logger::log(
                Level::Info,
                MODULE,
                &format!(
                    "Initialized: max_batch_size={} max_samples={}",
                    config.max_batch_size, config.max_samples
                ),
            );
            let _ = CONFIG.set(config);
            true
        }
        Err(error) => {
            logger::log(
                Level::Error,
                MODULE,
                &format!("Invalid configuration: {error}"),
            );
            false
        }
    }
}

#[map_operator(init = "featurize_init")]
fn featurize(input: DataModel) -> Result<DataModel, Error> {
    let labels = vec![Label {
        key: "module".to_owned(),
        value: MODULE.to_owned(),
    }];
    let _ = metrics::add_to_counter("requests", CounterValue::U64(1), Some(&labels));
    let config = CONFIG.get_or_init(Config::default);

    let process = |bytes: &[u8]| {
        let request = build_request(bytes, config).map_err(|message| {
            let _ = metrics::add_to_counter("errors", CounterValue::U64(1), Some(&labels));
            logger::log(Level::Error, MODULE, &message);
            Error { message }
        })?;
        if request.dropped_windows > 0 {
            let _ = metrics::add_to_counter(
                "dropped_windows",
                CounterValue::U64(request.dropped_windows as u64),
                Some(&labels),
            );
            logger::log(
                Level::Warn,
                MODULE,
                &format!(
                    "Forwarded the first {} windows; {} exceeded max_batch_size",
                    config.max_batch_size, request.dropped_windows
                ),
            );
        }
        Ok::<Vec<u8>, Error>(request.payload)
    };

    match input {
        DataModel::Message(message) => {
            let bytes = match &message.payload {
                BufferOrBytes::Bytes(bytes) => bytes.clone(),
                BufferOrBytes::Buffer(buffer) => buffer.read(),
            };
            let output = process(&bytes)?;
            Ok(DataModel::Message(Message {
                payload: BufferOrBytes::Bytes(output),
                ..message
            }))
        }
        DataModel::BufferOrBytes(payload) => {
            let bytes = match payload {
                BufferOrBytes::Bytes(bytes) => bytes,
                BufferOrBytes::Buffer(buffer) => buffer.read(),
            };
            Ok(DataModel::BufferOrBytes(BufferOrBytes::Bytes(process(
                &bytes,
            )?)))
        }
        _ => Err(Error {
            message: "Unexpected input type".to_string(),
        }),
    }
}

/// Serialized predict request and the number of windows beyond `max_batch_size`.
#[derive(Debug)]
pub struct Request {
    pub payload: Vec<u8>,
    pub dropped_windows: usize,
}

/// Validates an audio message and returns the serialized predict request.
pub fn build_request(payload: &[u8], config: &Config) -> Result<Request, String> {
    let input: Value =
        serde_json::from_slice(payload).map_err(|error| format!("Parse error: {error}"))?;
    let object = input
        .as_object()
        .ok_or_else(|| "Input must be a JSON object".to_string())?;

    let sample_rate = object
        .get("sample_rate")
        .and_then(Value::as_u64)
        .and_then(|rate| u32::try_from(rate).ok())
        .filter(|rate| (MIN_SAMPLE_RATE..=MAX_SAMPLE_RATE).contains(rate))
        .ok_or_else(|| {
            format!("sample_rate must be an integer from {MIN_SAMPLE_RATE} to {MAX_SAMPLE_RATE}")
        })?;

    let raw_samples = object
        .get("samples")
        .and_then(Value::as_array)
        .ok_or_else(|| "samples must be an array of numbers".to_string())?;
    if raw_samples.len() > config.max_samples {
        return Err(format!(
            "samples exceeds max_samples={}",
            config.max_samples
        ));
    }
    let samples = raw_samples
        .iter()
        .map(|value| {
            value
                .as_f64()
                .filter(|sample| sample.is_finite() && (-1.0..=1.0).contains(sample))
                .map(|sample| sample as f32)
        })
        .collect::<Option<Vec<f32>>>()
        .ok_or_else(|| "samples must be finite numbers in [-1, 1]".to_string())?;

    let features = wav_to_features(&samples, sample_rate);
    if features.is_empty() {
        return Err(format!(
            "Audio too short: at least {} samples are needed for one window",
            HOP_LENGTH * (FRAMES - 1)
        ));
    }
    let dropped_windows = features.len().saturating_sub(config.max_batch_size);
    let batch: Vec<Vec<f32>> = features.into_iter().take(config.max_batch_size).collect();

    let mut request = Map::new();
    request.insert(
        "inputs".to_string(),
        serde_json::to_value(&batch).map_err(|error| format!("Serialize error: {error}"))?,
    );
    let context = extract_context(object, &config.context_fields);
    if !context.is_empty() {
        request.insert("context".to_string(), Value::Object(context));
    }
    let payload = serde_json::to_vec(&Value::Object(request))
        .map_err(|error| format!("Serialize error: {error}"))?;
    Ok(Request {
        payload,
        dropped_windows,
    })
}

/// Copies short string and number identity fields into the request context.
pub fn extract_context(object: &Map<String, Value>, fields: &[String]) -> Map<String, Value> {
    fields
        .iter()
        .filter_map(|field| {
            let value = object.get(field)?;
            let keep = match value {
                Value::String(text) => text.len() <= MAX_CONTEXT_VALUE_LEN,
                Value::Number(_) => true,
                _ => false,
            };
            keep.then(|| (field.clone(), value.clone()))
        })
        .collect()
}

/// Returns `(n_windows, 640)` frame-major log-mel feature rows.
pub fn wav_to_features(samples: &[f32], sample_rate: u32) -> Vec<Vec<f32>> {
    let log_mel = log_mel_spectrogram(samples, sample_rate);
    let n_frames = log_mel.first().map_or(0, Vec::len);
    if n_frames < FRAMES {
        return Vec::new();
    }
    let mut rows = vec![vec![0.0f32; INPUT_DIM]; n_frames - FRAMES + 1];
    for (window, row) in rows.iter_mut().enumerate() {
        for frame in 0..FRAMES {
            for mel in 0..N_MELS {
                row[N_MELS * frame + mel] = log_mel[mel][window + frame];
            }
        }
    }
    rows
}

/// Returns the `[N_MELS][frames]` log-mel spectrogram in decibels.
pub fn log_mel_spectrogram(samples: &[f32], sample_rate: u32) -> Vec<Vec<f32>> {
    let power = stft_power(samples);
    let n_frames = power.first().map_or(0, Vec::len);
    let filterbank = mel_filterbank(sample_rate);
    let mut log_mel = vec![vec![0.0f32; n_frames]; N_MELS];
    for (mel, weights) in filterbank.iter().enumerate() {
        for frame in 0..n_frames {
            let energy: f32 = weights
                .iter()
                .zip(power.iter())
                .map(|(weight, bin)| weight * bin[frame])
                .sum();
            log_mel[mel][frame] = 10.0 * (energy + EPS).log10();
        }
    }
    log_mel
}

/// Power spectrogram `[N_FFT / 2 + 1][frames]` with a periodic Hann window and
/// centered zero padding.
pub fn stft_power(samples: &[f32]) -> Vec<Vec<f32>> {
    let n_bins = N_FFT / 2 + 1;
    if samples.is_empty() {
        return vec![Vec::new(); n_bins];
    }
    let pad = N_FFT / 2;
    let mut padded = vec![0.0f32; samples.len() + 2 * pad];
    padded[pad..pad + samples.len()].copy_from_slice(samples);
    let n_frames = 1 + (padded.len() - N_FFT) / HOP_LENGTH;

    let window: Vec<f32> = (0..N_FFT)
        .map(|i| 0.5 - 0.5 * (2.0 * std::f32::consts::PI * i as f32 / N_FFT as f32).cos())
        .collect();
    let fft = FftPlanner::<f32>::new().plan_fft_forward(N_FFT);
    let mut spectrum = vec![vec![0.0f32; n_frames]; n_bins];
    let mut buffer = vec![Complex::new(0.0f32, 0.0f32); N_FFT];
    for frame in 0..n_frames {
        let start = frame * HOP_LENGTH;
        for (i, slot) in buffer.iter_mut().enumerate() {
            *slot = Complex::new(padded[start + i] * window[i], 0.0);
        }
        fft.process(&mut buffer);
        for (bin, row) in spectrum.iter_mut().enumerate() {
            row[frame] = buffer[bin].norm_sqr();
        }
    }
    spectrum
}

/// Slaney-normalized mel filterbank `[N_MELS][N_FFT / 2 + 1]` from 0 Hz to Nyquist.
pub fn mel_filterbank(sample_rate: u32) -> Vec<Vec<f32>> {
    let n_bins = N_FFT / 2 + 1;
    let sr = sample_rate as f32;
    let fft_freqs: Vec<f32> = (0..n_bins).map(|i| i as f32 * sr / N_FFT as f32).collect();
    let max_mel = hz_to_mel(sr / 2.0);
    let hz_points: Vec<f32> = (0..N_MELS + 2)
        .map(|i| mel_to_hz(max_mel * i as f32 / (N_MELS + 1) as f32))
        .collect();

    (0..N_MELS)
        .map(|mel| {
            let (lower, center, upper) = (hz_points[mel], hz_points[mel + 1], hz_points[mel + 2]);
            let norm = 2.0 / (upper - lower);
            fft_freqs
                .iter()
                .map(|&freq| {
                    let rising = (freq - lower) / (center - lower);
                    let falling = (upper - freq) / (upper - center);
                    rising.min(falling).max(0.0) * norm
                })
                .collect()
        })
        .collect()
}

const F_SP: f32 = 200.0 / 3.0;
const MIN_LOG_HZ: f32 = 1000.0;
const MIN_LOG_MEL: f32 = MIN_LOG_HZ / F_SP;

fn log_step() -> f32 {
    6.4f32.ln() / 27.0
}

/// Slaney mel scale: linear below 1 kHz, logarithmic above.
pub fn hz_to_mel(freq: f32) -> f32 {
    if freq >= MIN_LOG_HZ {
        MIN_LOG_MEL + (freq / MIN_LOG_HZ).ln() / log_step()
    } else {
        freq / F_SP
    }
}

pub fn mel_to_hz(mel: f32) -> f32 {
    if mel >= MIN_LOG_MEL {
        MIN_LOG_HZ * (log_step() * (mel - MIN_LOG_MEL)).exp()
    } else {
        F_SP * mel
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn tone(len: usize, sample_rate: u32, freq: f32, amplitude: f32) -> Vec<f32> {
        (0..len)
            .map(|i| {
                amplitude
                    * (2.0 * std::f32::consts::PI * freq * i as f32 / sample_rate as f32).sin()
            })
            .collect()
    }

    fn props(pairs: &[(&str, &str)]) -> Vec<(String, String)> {
        pairs
            .iter()
            .map(|(k, v)| ((*k).to_string(), (*v).to_string()))
            .collect()
    }

    #[test]
    fn window_count_follows_centered_framing() {
        assert!(wav_to_features(&tone(2047, 16_000, 440.0, 0.5), 16_000).is_empty());
        assert_eq!(
            wav_to_features(&tone(2048, 16_000, 440.0, 0.5), 16_000).len(),
            1
        );
        assert_eq!(
            wav_to_features(&tone(4096, 16_000, 440.0, 0.5), 16_000).len(),
            5
        );
        assert!(wav_to_features(&tone(4096, 16_000, 440.0, 0.5), 16_000)
            .iter()
            .all(|row| row.len() == INPUT_DIM));
    }

    #[test]
    fn rows_are_frame_major_shifts_of_the_spectrogram() {
        let samples = tone(4096, 16_000, 1000.0, 0.3);
        let rows = wav_to_features(&samples, 16_000);
        assert_eq!(rows[0][N_MELS..2 * N_MELS], rows[1][..N_MELS]);
    }

    #[test]
    fn tone_energy_peaks_in_the_matching_mel_band() {
        let rate = 16_000;
        let log_mel = log_mel_spectrogram(&tone(8192, rate, 3200.0, 0.5), rate);
        let frame = 8;
        let peak = (0..N_MELS)
            .max_by(|a, b| log_mel[*a][frame].total_cmp(&log_mel[*b][frame]))
            .unwrap();
        let mel = hz_to_mel(3200.0);
        let band_center =
            mel_to_hz(hz_to_mel(rate as f32 / 2.0) * (peak + 1) as f32 / (N_MELS + 1) as f32);
        assert!(
            (band_center - 3200.0).abs() < 150.0,
            "peak band {peak} at {band_center} Hz, mel {mel}"
        );
    }

    #[test]
    fn silence_maps_to_the_epsilon_floor() {
        let rows = wav_to_features(&vec![0.0; 2048], 16_000);
        let floor = 10.0 * EPS.log10();
        assert!(rows[0].iter().all(|value| (value - floor).abs() < 1e-3));
    }

    /// Signal from scripts/generate-librosa-reference.py, computed in f64 and
    /// cast to f32 like the NumPy reference.
    fn reference_signal(len: usize, sample_rate: u32) -> Vec<f32> {
        let mut state: u64 = 12_345;
        (0..len)
            .map(|i| {
                state = (1_103_515_245 * state + 12_345) % (1 << 31);
                let t = i as f64 / f64::from(sample_rate);
                let noise = state as f64 / f64::from(1u32 << 31) - 0.5;
                (0.3 * (2.0 * std::f64::consts::PI * 440.0 * t).sin()
                    + 0.2 * (2.0 * std::f64::consts::PI * 3200.0 * t).sin()
                    + 0.05 * noise) as f32
            })
            .collect()
    }

    #[test]
    fn matches_librosa_reference_features() {
        let fixture: Value =
            serde_json::from_str(include_str!("../tests/fixtures/librosa-reference.json")).unwrap();
        let sample_rate = fixture["sample_rate"].as_u64().unwrap() as u32;
        let samples = reference_signal(
            fixture["num_samples"].as_u64().unwrap() as usize,
            sample_rate,
        );
        let rows = wav_to_features(&samples, sample_rate);
        assert_eq!(rows.len() as u64, fixture["windows"].as_u64().unwrap());

        let indices: Vec<usize> = fixture["indices"]
            .as_array()
            .unwrap()
            .iter()
            .map(|index| index.as_u64().unwrap() as usize)
            .collect();
        for (window, expected) in fixture["values"].as_array().unwrap().iter().enumerate() {
            for (index, value) in indices.iter().zip(expected.as_array().unwrap()) {
                let actual = rows[window][*index];
                let expected = value.as_f64().unwrap() as f32;
                assert!(
                    (actual - expected).abs() < 0.05,
                    "window {window} index {index}: {actual} vs {expected}"
                );
            }
            let mean = rows[window].iter().sum::<f32>() / INPUT_DIM as f32;
            let expected_mean = fixture["row_means"][window].as_f64().unwrap() as f32;
            assert!(
                (mean - expected_mean).abs() < 0.05,
                "window {window} mean {mean} vs {expected_mean}"
            );
        }
    }

    #[test]
    fn mel_scale_round_trips() {
        for freq in [0.0, 300.0, 999.0, 1000.0, 4000.0, 8000.0] {
            assert!((mel_to_hz(hz_to_mel(freq)) - freq).abs() < 0.05, "{freq}");
        }
    }

    #[test]
    fn filterbank_is_non_negative_and_covers_every_band() {
        let filterbank = mel_filterbank(16_000);
        assert_eq!(filterbank.len(), N_MELS);
        assert!(filterbank.iter().flatten().all(|weight| *weight >= 0.0));
        assert!(filterbank
            .iter()
            .all(|band| band.iter().any(|weight| *weight > 0.0)));
    }

    #[test]
    fn builds_adapter_request_with_context() {
        let samples = tone(2048, 16_000, 440.0, 0.2);
        let payload = serde_json::json!({
            "schema_version": "1.0",
            "asset_id": "asset-01",
            "sensor_id": "sensor-01",
            "timestamp": "2026-01-02T03:04:05.678Z",
            "health_state": "healthy",
            "sample_rate": 16_000,
            "samples": samples,
        });
        let request =
            build_request(&serde_json::to_vec(&payload).unwrap(), &Config::default()).unwrap();
        assert_eq!(request.dropped_windows, 0);
        let output: Value = serde_json::from_slice(&request.payload).unwrap();
        assert_eq!(output["inputs"].as_array().unwrap().len(), 1);
        assert_eq!(output["inputs"][0].as_array().unwrap().len(), INPUT_DIM);
        assert_eq!(
            output["context"],
            serde_json::json!({
                "asset_id": "asset-01",
                "sensor_id": "sensor-01",
                "timestamp": "2026-01-02T03:04:05.678Z",
            })
        );
    }

    #[test]
    fn caps_rows_at_max_batch_size() {
        let config = Config {
            max_batch_size: 2,
            ..Config::default()
        };
        let payload =
            serde_json::json!({"sample_rate": 16_000, "samples": tone(8192, 16_000, 440.0, 0.2)});
        let request = build_request(&serde_json::to_vec(&payload).unwrap(), &config).unwrap();
        assert_eq!(request.dropped_windows, 11);
        let output: Value = serde_json::from_slice(&request.payload).unwrap();
        assert_eq!(output["inputs"].as_array().unwrap().len(), 2);
        assert!(output.get("context").is_none());
    }

    #[test]
    fn rejects_invalid_audio() {
        let config = Config {
            max_samples: 4096,
            ..Config::default()
        };
        for payload in [
            serde_json::json!([1, 2]),
            serde_json::json!({"samples": [0.0]}),
            serde_json::json!({"sample_rate": 100, "samples": [0.0]}),
            serde_json::json!({"sample_rate": 16_000, "samples": "loud"}),
            serde_json::json!({"sample_rate": 16_000, "samples": [0.0, 1.5]}),
            serde_json::json!({"sample_rate": 16_000, "samples": [0.0, "x"]}),
            serde_json::json!({"sample_rate": 16_000, "samples": vec![0.0; 100]}),
            serde_json::json!({"sample_rate": 16_000, "samples": vec![0.0; 4097]}),
        ] {
            assert!(
                build_request(&serde_json::to_vec(&payload).unwrap(), &config).is_err(),
                "{payload}"
            );
        }
        assert!(build_request(b"not json", &config).is_err());
    }

    #[test]
    fn context_keeps_only_short_scalars() {
        let object = serde_json::json!({
            "asset_id": "asset-01",
            "count": 3,
            "nested": {"a": 1},
            "long": "x".repeat(200),
        });
        let fields: Vec<String> = ["asset_id", "count", "nested", "long", "missing"]
            .iter()
            .map(|field| (*field).to_string())
            .collect();
        let context = extract_context(object.as_object().unwrap(), &fields);
        assert_eq!(
            Value::Object(context),
            serde_json::json!({"asset_id": "asset-01", "count": 3})
        );
    }

    #[test]
    fn parses_configuration() {
        let config = parse_config(&props(&[
            ("max_batch_size", "8"),
            ("max_samples", "16000"),
            ("context_fields", "device, asset_id"),
        ]))
        .unwrap();
        assert_eq!(config.max_batch_size, 8);
        assert_eq!(config.max_samples, 16_000);
        assert_eq!(config.context_fields, vec!["device", "asset_id"]);
        assert_eq!(parse_config(&[]).unwrap(), Config::default());
        for (key, value) in [
            ("max_batch_size", "0"),
            ("max_batch_size", "many"),
            ("max_samples", "10"),
            ("context_fields", "a,b,c,d,e,f,g,h,i"),
        ] {
            assert!(
                parse_config(&props(&[(key, value)])).is_err(),
                "{key}={value}"
            );
        }
    }
}
