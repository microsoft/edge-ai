#![allow(clippy::missing_safety_doc)]
//! threshold-anomaly: map operator that turns an MQTT predict adapter response
//! into an anomaly verdict.
//!
//! The score is read from one explicitly configured field of the model
//! `outputs` (a number, a list of per-window numbers, or a list of single-value
//! rows), aggregated with `mean` or `max`, and compared to a required
//! threshold. The operator never searches the outputs for other numbers.
//! Adapter error responses become error verdicts so failures stay visible.

use std::sync::OnceLock;

use serde_json::{Map, Value};
use wasm_graph_sdk::logger::{self, Level};
use wasm_graph_sdk::macros::map_operator;
use wasm_graph_sdk::metrics::{self, CounterValue, Label};

const MODULE: &str = "threshold-anomaly";
const SCHEMA_VERSION: &str = "1.0";
const MAX_FIELD_SEGMENTS: usize = 4;
const MAX_ERROR_CODE_LEN: usize = 64;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Aggregation {
    Mean,
    Max,
}

impl Aggregation {
    fn as_str(self) -> &'static str {
        match self {
            Self::Mean => "mean",
            Self::Max => "max",
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct Config {
    pub threshold: f64,
    pub score_field: Vec<String>,
    pub aggregation: Aggregation,
}

static CONFIG: OnceLock<Config> = OnceLock::new();

/// Parses graph parameters. `threshold` is required and has no default.
pub fn parse_config(properties: &[(String, String)]) -> Result<Config, String> {
    let get = |key: &str| {
        properties
            .iter()
            .find(|(k, _)| k == key)
            .map(|(_, v)| v.trim())
            .filter(|v| !v.is_empty())
    };
    let threshold = get("threshold")
        .ok_or_else(|| "threshold is required".to_string())?
        .parse::<f64>()
        .ok()
        .filter(|value| value.is_finite())
        .ok_or_else(|| "threshold must be a finite number".to_string())?;
    let field = get("score_field").unwrap_or("score");
    let score_field: Vec<String> = field.split('.').map(str::to_string).collect();
    if score_field.len() > MAX_FIELD_SEGMENTS
        || score_field.iter().any(|segment| {
            segment.is_empty()
                || segment.len() > 64
                || !segment
                    .chars()
                    .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-')
        })
    {
        return Err("score_field must be up to four dot-separated keys".to_string());
    }
    let aggregation = match get("aggregation").unwrap_or("mean") {
        "mean" => Aggregation::Mean,
        "max" => Aggregation::Max,
        other => return Err(format!("aggregation must be mean or max, got {other}")),
    };
    Ok(Config {
        threshold,
        score_field,
        aggregation,
    })
}

fn threshold_init(configuration: ModuleConfiguration) -> bool {
    match parse_config(&configuration.properties) {
        Ok(config) => {
            logger::log(
                Level::Info,
                MODULE,
                &format!(
                    "Initialized: threshold={} score_field={} aggregation={}",
                    config.threshold,
                    config.score_field.join("."),
                    config.aggregation.as_str()
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

#[map_operator(init = "threshold_init")]
fn threshold(input: DataModel) -> Result<DataModel, Error> {
    let labels = vec![Label {
        key: "module".to_owned(),
        value: MODULE.to_owned(),
    }];
    let _ = metrics::add_to_counter("requests", CounterValue::U64(1), Some(&labels));
    let config = CONFIG.get().ok_or_else(|| Error {
        message: "Operator is not configured".to_string(),
    })?;

    let process = |bytes: &[u8]| {
        let verdict = build_verdict(bytes, config).map_err(|message| {
            logger::log(Level::Error, MODULE, &message);
            Error { message }
        })?;
        let metric = if verdict.anomaly == Some(true) {
            "anomalies"
        } else if verdict.anomaly.is_none() {
            "errors"
        } else {
            "normal"
        };
        let _ = metrics::add_to_counter(metric, CounterValue::U64(1), Some(&labels));
        Ok::<Vec<u8>, Error>(verdict.payload)
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

/// Serialized verdict and its anomaly decision (`None` for error verdicts).
#[derive(Debug)]
pub struct Verdict {
    pub payload: Vec<u8>,
    pub anomaly: Option<bool>,
}

/// Builds a verdict from one predict adapter response.
///
/// Returns an error only when the response isn't a JSON object; every other
/// problem produces an error verdict so it reaches downstream consumers.
pub fn build_verdict(payload: &[u8], config: &Config) -> Result<Verdict, String> {
    let response: Value =
        serde_json::from_slice(payload).map_err(|error| format!("Parse error: {error}"))?;
    let response = response
        .as_object()
        .ok_or_else(|| "Response must be a JSON object".to_string())?;

    let mut verdict = Map::new();
    verdict.insert("schema_version".to_string(), Value::from(SCHEMA_VERSION));
    if let Some(model_id) = response.get("model_id").and_then(Value::as_str) {
        verdict.insert("model_id".to_string(), Value::from(model_id));
    }

    let outcome = match response.get("status").and_then(Value::as_str) {
        Some("success") => response
            .get("outputs")
            .and_then(|outputs| lookup(outputs, &config.score_field))
            .and_then(window_scores)
            .ok_or_else(|| "INVALID_RESULT".to_string()),
        Some("error") => Err(response
            .get("error")
            .and_then(|error| error.get("code"))
            .and_then(Value::as_str)
            .filter(|code| code.len() <= MAX_ERROR_CODE_LEN)
            .unwrap_or("MODEL_ERROR")
            .to_string()),
        _ => Err("INVALID_RESPONSE".to_string()),
    };

    let outcome = outcome.and_then(|scores| {
        let score = aggregate(&scores, config.aggregation);
        if score.is_finite() {
            Ok((scores.len(), score))
        } else {
            Err("INVALID_RESULT".to_string())
        }
    });

    let anomaly = match outcome {
        Ok((windows, score)) => {
            let anomaly = score > config.threshold;
            verdict.insert("status".to_string(), Value::from("success"));
            verdict.insert("anomaly".to_string(), Value::from(anomaly));
            verdict.insert("score".to_string(), Value::from(score));
            verdict.insert("threshold".to_string(), Value::from(config.threshold));
            verdict.insert(
                "aggregation".to_string(),
                Value::from(config.aggregation.as_str()),
            );
            verdict.insert("windows".to_string(), Value::from(windows));
            Some(anomaly)
        }
        Err(code) => {
            verdict.insert("status".to_string(), Value::from("error"));
            verdict.insert("error_code".to_string(), Value::from(code));
            None
        }
    };
    if let Some(context) = response
        .get("context")
        .filter(|context| context.is_object())
    {
        verdict.insert("context".to_string(), context.clone());
    }
    let payload = serde_json::to_vec(&Value::Object(verdict))
        .map_err(|error| format!("Serialize error: {error}"))?;
    Ok(Verdict { payload, anomaly })
}

fn lookup<'a>(value: &'a Value, path: &[String]) -> Option<&'a Value> {
    path.iter().try_fold(value, |current, key| current.get(key))
}

/// Returns per-window scores from a number, a list of numbers, or a list of
/// single-value rows. Anything else, or any non-finite value, is rejected.
pub fn window_scores(value: &Value) -> Option<Vec<f64>> {
    let finite = |value: &Value| value.as_f64().filter(|number| number.is_finite());
    match value {
        Value::Number(_) => finite(value).map(|number| vec![number]),
        Value::Array(items) if !items.is_empty() => items
            .iter()
            .map(|item| match item {
                Value::Array(row) if row.len() == 1 => finite(&row[0]),
                _ => finite(item),
            })
            .collect(),
        _ => None,
    }
}

/// Aggregates finite scores. The mean divides before summing so large finite
/// scores can't overflow to infinity.
pub fn aggregate(scores: &[f64], aggregation: Aggregation) -> f64 {
    match aggregation {
        Aggregation::Mean => {
            let count = scores.len() as f64;
            scores.iter().map(|score| score / count).sum()
        }
        Aggregation::Max => scores.iter().copied().fold(f64::NEG_INFINITY, f64::max),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn config(threshold: &str, extra: &[(&str, &str)]) -> Config {
        let mut properties = vec![("threshold".to_string(), threshold.to_string())];
        properties.extend(
            extra
                .iter()
                .map(|(k, v)| ((*k).to_string(), (*v).to_string())),
        );
        parse_config(&properties).unwrap()
    }

    fn verdict(payload: Value, config: &Config) -> (Value, Option<bool>) {
        let verdict = build_verdict(&serde_json::to_vec(&payload).unwrap(), config).unwrap();
        (
            serde_json::from_slice(&verdict.payload).unwrap(),
            verdict.anomaly,
        )
    }

    fn success(outputs: Value) -> Value {
        serde_json::json!({
            "schema_version": "1.0",
            "model_id": "acoustic-autoencoder",
            "request_id": "req-1",
            "status": "success",
            "latency_ms": 12,
            "outputs": outputs,
            "context": {"asset_id": "asset-01"},
        })
    }

    #[test]
    fn mean_of_window_scores_against_threshold() {
        let cfg = config("10", &[]);
        let (body, anomaly) = verdict(success(serde_json::json!({"score": [8.0, 14.0]})), &cfg);
        assert_eq!(anomaly, Some(true));
        assert_eq!(body["score"], 11.0);
        assert_eq!(body["windows"], 2);
        assert_eq!(body["aggregation"], "mean");
        assert_eq!(body["context"], serde_json::json!({"asset_id": "asset-01"}));
        assert_eq!(body["model_id"], "acoustic-autoencoder");

        let (body, anomaly) = verdict(success(serde_json::json!({"score": 9.5})), &cfg);
        assert_eq!(
            (anomaly, body["windows"].clone()),
            (Some(false), Value::from(1))
        );
    }

    #[test]
    fn max_aggregation_and_nested_field_and_single_value_rows() {
        let cfg = config(
            "10",
            &[("aggregation", "max"), ("score_field", "result.errors")],
        );
        let (body, anomaly) = verdict(
            success(serde_json::json!({"result": {"errors": [[2.0], [12.0], [3.0]]}})),
            &cfg,
        );
        assert_eq!(anomaly, Some(true));
        assert_eq!(body["score"], 12.0);
    }

    #[test]
    fn invalid_results_become_error_verdicts() {
        let cfg = config("10", &[]);
        for outputs in [
            serde_json::json!({"other": 1.0}),
            serde_json::json!({"score": "high"}),
            serde_json::json!({"score": []}),
            serde_json::json!({"score": [1.0, [2.0, 3.0]]}),
            serde_json::json!({"score": {"value": 1.0}}),
            serde_json::json!([1.0]),
        ] {
            let (body, anomaly) = verdict(success(outputs.clone()), &cfg);
            assert_eq!(anomaly, None, "{outputs}");
            assert_eq!(body["status"], "error");
            assert_eq!(body["error_code"], "INVALID_RESULT");
        }
    }

    #[test]
    fn adapter_errors_pass_through_with_context() {
        let cfg = config("10", &[]);
        let (body, anomaly) = verdict(
            serde_json::json!({
                "model_id": "m",
                "status": "error",
                "error": {"code": "BACKEND_TIMEOUT", "retryable": true},
                "context": {"asset_id": "asset-01"},
            }),
            &cfg,
        );
        assert_eq!(anomaly, None);
        assert_eq!(body["error_code"], "BACKEND_TIMEOUT");
        assert_eq!(body["context"]["asset_id"], "asset-01");
        assert!(body.get("score").is_none());

        let (body, _) = verdict(serde_json::json!({"status": "pending"}), &cfg);
        assert_eq!(body["error_code"], "INVALID_RESPONSE");
    }

    /// Response shapes published by the 518 MQTT predict adapter
    /// (`model_dump_json(exclude_none=True)`) for a model that returns
    /// `{"score": ...}`, such as its local mock.
    #[test]
    fn reads_predict_adapter_responses_with_default_score_field() {
        let cfg = config("0.5", &[]);
        let (body, anomaly) = verdict(
            serde_json::json!({
                "schema_version": "1.0",
                "model_id": "acoustic-autoencoder",
                "request_id": "req-1",
                "status": "success",
                "latency_ms": 12,
                "outputs": {"score": 0.93},
                "context": {"asset_id": "asset-01", "sensor_id": "sensor-01"},
            }),
            &cfg,
        );
        assert_eq!(anomaly, Some(true));
        assert_eq!(body["status"], "success");
        assert_eq!(body["score"], 0.93);
        assert_eq!(body["windows"], 1);
        assert_eq!(body["model_id"], "acoustic-autoencoder");
        assert_eq!(
            body["context"],
            serde_json::json!({"asset_id": "asset-01", "sensor_id": "sensor-01"})
        );

        let (body, anomaly) = verdict(
            serde_json::json!({
                "schema_version": "1.0",
                "model_id": "acoustic-autoencoder",
                "request_id": "req-2",
                "status": "error",
                "latency_ms": 30001,
                "error": {
                    "code": "BACKEND_TIMEOUT",
                    "message": "model endpoint call failed",
                    "retryable": true,
                },
                "context": {"asset_id": "asset-01"},
            }),
            &cfg,
        );
        assert_eq!(anomaly, None);
        assert_eq!(body["status"], "error");
        assert_eq!(body["error_code"], "BACKEND_TIMEOUT");
        assert_eq!(body["context"], serde_json::json!({"asset_id": "asset-01"}));
    }

    #[test]
    fn mean_of_extreme_finite_scores_stays_finite() {
        assert_eq!(
            aggregate(&[f64::MAX, f64::MAX], Aggregation::Mean),
            f64::MAX
        );
        let cfg = config("10", &[]);
        let (body, anomaly) = verdict(
            success(serde_json::json!({"score": [1.7e308, 1.7e308]})),
            &cfg,
        );
        assert_eq!(anomaly, Some(true));
        assert_eq!(body["score"], 1.7e308);
    }

    #[test]
    fn rejects_non_object_responses() {
        let cfg = config("10", &[]);
        assert!(build_verdict(b"not json", &cfg).is_err());
        assert!(build_verdict(b"[1, 2]", &cfg).is_err());
    }

    #[test]
    fn configuration_requires_a_finite_threshold() {
        assert!(parse_config(&[]).is_err());
        for (key, value) in [
            ("threshold", "high"),
            ("threshold", "inf"),
            ("threshold", "NaN"),
        ] {
            assert!(
                parse_config(&[(key.to_string(), value.to_string())]).is_err(),
                "{value}"
            );
        }
        let bad = |extra: (&str, &str)| {
            parse_config(&[
                ("threshold".to_string(), "1".to_string()),
                (extra.0.to_string(), extra.1.to_string()),
            ])
            .is_err()
        };
        assert!(bad(("aggregation", "median")));
        assert!(bad(("score_field", "a..b")));
        assert!(bad(("score_field", "a.b.c.d.e")));
        assert!(bad(("score_field", "a b")));
        assert_eq!(config("1.5", &[]).score_field, vec!["score"]);
    }
}
