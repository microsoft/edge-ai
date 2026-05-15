---
applyTo: '**/src/500-application/**/operators/**'
description: 'SDK reference for Rust-based WASM operator types, integration patterns, and best practices for Azure IoT Operations dataflow graphs - Brought to you by microsoft/edge-ai'
---

# Rust WASM Operator SDK Reference

This reference covers the Rust-based WASM operator SDK (`wasm_graph_sdk`). For Python-based WASM development, refer to the Python WASM instructions.

## Operator Types Reference

### Map Operator (`#[map_operator]`)

Transform input data 1:1 with optional configuration.

Use cases:

- Data format conversion (temperature units, time zones)
- Field enrichment (add computed properties)
- Data normalization (unit conversions)
- Image preprocessing (resize, color space conversion)

Signature:

```rust
#[map_operator(init = "init_function")]
fn operator_name(input: DataModel) -> Result<DataModel, Error>
```

Data flow: 1 input → 1 output (or error)

Configuration: Optional parameters via `ModuleConfiguration` in init function

Examples: temperature-converter, image-preprocessor, field-enricher

### Filter Operator (`#[filter_operator]`)

Pass or drop messages based on boolean predicate.

Use cases:

- Threshold filtering (temperature ranges, pressure limits)
- Data quality checks (null detection, range validation)
- Conditional routing (pass only specific message types)

Signature:

```rust
#[filter_operator(init = "init_function")]
fn operator_name(input: DataModel) -> Result<bool, Error>
```

Data flow: 1 input → boolean (true = pass, false = drop)

Configuration: Thresholds, comparison values via `ModuleConfiguration`

Examples: range-filter, quality-checker, type-filter

### Accumulate Operator (`#[accumulate_operator]`)

Aggregate multiple messages over time windows.

Use cases:

- Statistical aggregation (min, max, average, count)
- Time-windowed summaries
- Multi-sensor fusion

Signature:

```rust
#[accumulate_operator]
fn operator_name(
    staged: DataModel,
    inputs: Vec<DataModel>,
) -> Result<DataModel, Error>
```

Data flow: N inputs + staged state → 1 aggregated output

Configuration: Window size, aggregation functions (configured by runtime)

Examples: stats-aggregator, window-accumulator, sensor-fusion

### Branch Operator (`#[branch_operator]`)

Route messages to multiple outputs based on logic.

Use cases:

- Multi-path routing based on message content
- Fan-out to different processing pipelines
- Classification-based routing

Signature:

```rust
#[branch_operator(init = "init_function")]
fn operator_name(input: DataModel) -> Result<Vec<DataModel>, Error>
```

Data flow: 1 input → multiple outputs

Configuration: Routing rules via `ModuleConfiguration`

Examples: type-router, priority-splitter, classification-router

### Delay Operator (`#[delay_operator]`)

Control temporal message flow.

Use cases:

- Time-windowing
- Message ordering
- Rate limiting

Signature:

```rust
#[delay_operator(init = "init_function")]
fn operator_name(input: DataModel) -> Result<DataModel, Error>
```

Data flow: 1 input → 1 output (delayed)

Configuration: Delay duration via `ModuleConfiguration`

Examples: 10s-delay, rate-limiter, window-controller

### ONNX Inference Operator (`#[map_operator]` with WASI-NN)

Embed small ONNX models for low-latency inference.

Use cases:

- Image classification (MobileNet-class models)
- Inline enrichment with ML predictions
- Real-time anomaly detection

Requirements:

- Model size < 50 MB
- CPU-only inference (no GPU)
- Single tensor input
- Graph YAML includes `wasi-nn` feature

Signature:

```rust
// Embed model at compile time
static MODEL: &[u8] = include_bytes!("fixture/models/model.onnx");

#[map_operator]
fn operator_name(input: DataModel) -> Result<DataModel, Error>
```

Data flow: 1 input → preprocess → inference → postprocess → 1 output

Graph feature required:

```yaml
moduleRequirements:
  features:
    - name: "wasi-nn"
```

Examples: image-classifier, anomaly-detector, quality-inspector

## SDK Integration Patterns

### Logger Usage

```rust
use wasm_graph_sdk::logger::{self, Level};

logger::log(Level::Info, "module-name", "Initialization complete");
logger::log(Level::Error, "module-name", &format!("Failed: {}", error));
logger::log(Level::Debug, "module-name", &format!("Processing value: {}", value));
```

### Metrics Collection

```rust
use wasm_graph_sdk::metrics::{self, CounterValue, Label};

let labels = vec![Label {
    key: "module".to_owned(),
    value: "operator-name".to_owned(),
}];
let _ = metrics::add_to_counter("requests", CounterValue::U64(1), Some(&labels));
let _ = metrics::set_gauge("processing_time_ms", CounterValue::U64(duration_ms), Some(&labels));
```

### Static Configuration with OnceLock

```rust
use std::sync::OnceLock;

static CONFIG_VALUE: OnceLock<f64> = OnceLock::new();

fn operator_init(configuration: ModuleConfiguration) -> bool {
    if let Some(value_str) = configuration.properties
        .iter()
        .find(|(k, _)| k == "param_name")
        .map(|(_, v)| v.clone())
    {
        match value_str.parse::<f64>() {
            Ok(value) => {
                let _ = CONFIG_VALUE.set(value);
                true
            }
            Err(_) => false
        }
    } else {
        false
    }
}
```

### DataModel Extraction

```rust
let payload = match input {
    DataModel::Message(Message {
        payload: BufferOrBytes::Bytes(bytes),
        ..
    }) => bytes,
    DataModel::Message(Message {
        payload: BufferOrBytes::Buffer(buffer),
        ..
    }) => buffer.read(),
    DataModel::BufferOrBytes(BufferOrBytes::Buffer(buffer)) => buffer.read(),
    DataModel::BufferOrBytes(BufferOrBytes::Bytes(bytes)) => bytes,
    _ => {
        return Err(Error { message: "Unexpected input type".to_string() });
    }
};
```

### Error Handling

```rust
// Parse with error mapping
let data: InputStruct = serde_json::from_slice(&payload)
    .map_err(|e| Error { message: format!("Parse error: {}", e) })?;

// Validate and return errors
if data.value < 0.0 {
    return Err(Error { message: "Negative values not allowed".to_string() });
}

// Log errors before returning
logger::log(Level::Error, "module-name", &format!("Validation failed: {}", e));
return Err(Error { message: e.to_string() });
```

## Best Practices

### Operator Development

* Keep operators focused on single transformation, filter, or aggregation
* Use `ModuleConfiguration` to make operators reusable with runtime parameters
* Log appropriately: Info for initialization, Debug for processing, Error for failures
* Validate input data structure and ranges before processing

### Performance

* Initialize once using `OnceLock` or `LazyLock` for static state
* Avoid allocations and reuse buffers when possible
* Use serde with `alloc` feature only for efficient serialization
* Use `BufferOrBytes::Buffer` for lazy buffer loading with large payloads

### Testing

* Test incrementally: build, deploy, test after each change
* Use realistic data with actual sensor data formats
* Monitor logs and watch operator logs during testing
* Verify metrics by checking request counters and processing times

### Deployment

* Version appropriately by updating version in graph YAML for new releases
* Tag artifacts using semantic versioning for ACR artifacts
* Test in isolation by deploying to test environment before production
* Monitor after deployment by watching logs and metrics

## Advanced: WIT Component Model Composition

For teams requiring strict separation between AIO SDK plumbing and proprietary business logic, the WIT Component Model composition pattern decouples the operator into two independently compiled WASM modules composed at build time.

### Pattern Overview

* Consumer module: Imports a custom WIT interface and bridges AIO SDK types (`DataModel`, `Message`) to a clean `payload: list<u8>` interface
* Provider module: Exports the custom WIT interface with `process()` and `init()` functions containing pure business logic — no AIO SDK dependency
* Build step: Both modules are compiled separately, then linked via `wasm-tools compose`

### Advantages

* Separation of concerns: business logic has zero AIO SDK coupling
* Swappable providers: replace the provider module without changing the consumer bridge
* Algorithm confidentiality: proprietary logic ships as a standalone WASM binary
* Language-agnostic extensibility: the provider can be written in any language that compiles to WASM Component Model

### Reference Implementation

The existing operators in `src/500-application/511-rust-embedded-wasm-provider/` demonstrate this pattern:

* `operators/map/` — Consumer (AIO SDK bridge)
* `operators/custom-provider/` — Provider (business logic)
* `README.md` — Comprehensive documentation of the composition workflow

Use the component README and existing code as the canonical guide for this advanced pattern. Full templates are not provided because the WIT composition workflow involves custom interface design that varies per use case.

## Reference Examples

Existing operators in this repository (advanced WIT composition pattern):

- `src/500-application/511-rust-embedded-wasm-provider/operators/map/` — AIO SDK bridge operator using WIT composition (consumer)
- `src/500-application/511-rust-embedded-wasm-provider/operators/custom-provider/` — Business logic provider using WIT composition (provider)

These operators demonstrate the advanced WIT composition use case. For building regular standalone operators (map, filter, accumulate, branch, delay, ONNX), use the templates in `.github/instructions/wasm-operator-templates.instructions.md`.

Azure Samples:

- [explore-iot-operations/samples/wasm/operators](https://github.com/Azure-Samples/explore-iot-operations/tree/main/samples/wasm/operators) - Comprehensive operator examples

Documentation:

- [WASM Dataflow Graphs](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-dataflow-graph-wasm)
- [ONNX Inference](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/howto-wasm-onnx-inference)
