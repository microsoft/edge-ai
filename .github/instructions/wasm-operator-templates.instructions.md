---
applyTo: '**/src/500-application/**/operators/**'
description: 'Code templates for Rust-based WASM operator modules including Cargo.toml, Map, Filter, Accumulate, ONNX, Graph YAML, and Terraform configurations - Brought to you by microsoft/edge-ai'
---

# Rust WASM Operator Code Templates

These templates are for Rust-based WASM operators built with `wasm_graph_sdk`. For Python-based WASM development, refer to the Python WASM instructions.

## Cargo.toml Template

Use this template for all operator types. Add `image` dependency only for ONNX operators.

```toml
[package]
name = "{{operator-name}}"
version = "0.1.0"
license = "MIT"
edition = "2021"

[dependencies]
wit-bindgen = "0.22"
wasm_graph_sdk = { version = "=1.1.3", registry = "aio-sdks" }
serde = { version = "1", default-features = false, features = ["derive"] }
serde_json = { version = "1", default-features = false, features = ["alloc"] }
# Uncomment for ONNX operators only:
# image = { version = "0.24", default-features = false, features = ["png", "jpeg"] }

[lib]
crate-type = ["cdylib"]

[workspace]
```

Placeholders:

- `{{operator-name}}` - Kebab-case operator name (e.g., `temperature-converter`)

## Map Operator Template

Complete map operator with configuration, data extraction, transformation, metrics, and logging.

```rust
#![allow(clippy::missing_safety_doc)]

use wasm_graph_sdk::logger::{self, Level};
use wasm_graph_sdk::macros::map_operator;
use wasm_graph_sdk::metrics::{self, CounterValue, Label};
use wasm_graph_sdk::{DataModel, Error, Message, BufferOrBytes, ModuleConfiguration};
use std::sync::OnceLock;

// Configuration parameters
static {{CONFIG_PARAM}}: OnceLock<{{CONFIG_TYPE}}> = OnceLock::new();

// Input data structure
#[derive(Debug, serde::Deserialize)]
struct {{InputStruct}} {
    {{input_field_1}}: {{type_1}},
    {{input_field_2}}: {{type_2}},
}

// Output data structure
#[derive(Debug, serde::Serialize)]
struct {{OutputStruct}} {
    {{output_field_1}}: {{type_1}},
    {{output_field_2}}: {{type_2}},
}

fn {{operator_name}}_init(configuration: ModuleConfiguration) -> bool {
    logger::log(Level::Info, "{{operator-name}}", "Initializing");

    // Extract configuration parameter
    if let Some(param_value) = configuration.properties
        .iter()
        .find(|(k, _)| k == "{{param_name}}")
        .map(|(_, v)| v.clone())
    {
        match param_value.parse::<{{CONFIG_TYPE}}>() {
            Ok(value) => {
                let _ = {{CONFIG_PARAM}}.set(value);
                logger::log(Level::Info, "{{operator-name}}", "Configuration loaded");
                true
            }
            Err(_) => {
                logger::log(Level::Error, "{{operator-name}}", "Failed to parse configuration");
                false
            }
        }
    } else {
        // Optional: Set default or fail if required
        logger::log(Level::Warn, "{{operator-name}}", "Using default configuration");
        let _ = {{CONFIG_PARAM}}.set({{default_value}});
        true
    }
}

#[map_operator(init = "{{operator_name}}_init")]
fn {{operator_name}}(input: DataModel) -> Result<DataModel, Error> {
    // Metrics
    let labels = vec![Label {
        key: "module".to_owned(),
        value: "{{operator-name}}".to_owned(),
    }];
    let _ = metrics::add_to_counter("requests", CounterValue::U64(1), Some(&labels));

    // Extract payload
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

    // Parse input
    let input_data: {{InputStruct}} = serde_json::from_slice(&payload)
        .map_err(|e| Error { message: format!("Parse error: {}", e) })?;

    // Get config value
    let config_value = {{CONFIG_PARAM}}.get().copied().unwrap_or({{default_value}});

    // Transform data (customize this section)
    let output_data = {{OutputStruct}} {
        {{output_field_1}}: {{transformation_logic_1}},
        {{output_field_2}}: {{transformation_logic_2}},
    };

    // Serialize output
    let result_bytes = serde_json::to_vec(&output_data)
        .map_err(|e| Error { message: format!("Serialize error: {}", e) })?;

    // Return result preserving message metadata
    match input {
        DataModel::Message(msg) => Ok(DataModel::Message(Message {
            timestamp: msg.timestamp,
            topic: msg.topic,
            payload: BufferOrBytes::Bytes(result_bytes),
            properties: msg.properties,
            content_type: msg.content_type,
            schema: msg.schema,
        })),
        DataModel::BufferOrBytes(_) => Ok(DataModel::BufferOrBytes(
            BufferOrBytes::Bytes(result_bytes)
        )),
        _ => Err(Error { message: "Unexpected type".to_string() }),
    }
}
```

Placeholders:

- `{{operator-name}}` - Kebab-case name for logging
- `{{operator_name}}` - Snake_case function name
- `{{CONFIG_PARAM}}` - SCREAMING_SNAKE_CASE config variable
- `{{CONFIG_TYPE}}` - Rust type (f64, String, etc.)
- `{{InputStruct}}` - PascalCase input struct name
- `{{OutputStruct}}` - PascalCase output struct name
- `{{param_name}}` - Configuration parameter key from graph
- `{{default_value}}` - Default configuration value
- `{{transformation_logic_*}}` - Custom transformation code

## Filter Operator Template

Complete filter operator with threshold configuration and boolean predicate.

```rust
#![allow(clippy::missing_safety_doc)]

use wasm_graph_sdk::logger::{self, Level};
use wasm_graph_sdk::macros::filter_operator;
use wasm_graph_sdk::metrics::{self, CounterValue, Label};
use wasm_graph_sdk::{DataModel, Error, Message, BufferOrBytes, ModuleConfiguration};
use std::sync::OnceLock;

// Threshold parameters
static MIN_THRESHOLD: OnceLock<{{THRESHOLD_TYPE}}> = OnceLock::new();
static MAX_THRESHOLD: OnceLock<{{THRESHOLD_TYPE}}> = OnceLock::new();

// Input data structure
#[derive(Debug, serde::Deserialize)]
struct {{InputStruct}} {
    {{filter_field}}: {{THRESHOLD_TYPE}},
    // Add other fields as needed
}

fn {{operator_name}}_init(configuration: ModuleConfiguration) -> bool {
    logger::log(Level::Info, "{{operator-name}}", "Initializing");

    // Extract min threshold
    if let Some(min_str) = configuration.properties
        .iter()
        .find(|(k, _)| k == "min_threshold")
        .map(|(_, v)| v.clone())
    {
        match min_str.parse::<{{THRESHOLD_TYPE}}>() {
            Ok(min) => { let _ = MIN_THRESHOLD.set(min); }
            Err(_) => {
                logger::log(Level::Error, "{{operator-name}}", "Invalid min_threshold");
                return false;
            }
        }
    }

    // Extract max threshold
    if let Some(max_str) = configuration.properties
        .iter()
        .find(|(k, _)| k == "max_threshold")
        .map(|(_, v)| v.clone())
    {
        match max_str.parse::<{{THRESHOLD_TYPE}}>() {
            Ok(max) => { let _ = MAX_THRESHOLD.set(max); }
            Err(_) => {
                logger::log(Level::Error, "{{operator-name}}", "Invalid max_threshold");
                return false;
            }
        }
    }

    true
}

#[filter_operator(init = "{{operator_name}}_init")]
fn {{operator_name}}(input: DataModel) -> Result<bool, Error> {
    // Metrics
    let labels = vec![Label {
        key: "module".to_owned(),
        value: "{{operator-name}}".to_owned(),
    }];
    let _ = metrics::add_to_counter("requests", CounterValue::U64(1), Some(&labels));

    // Extract payload
    let payload = match input {
        DataModel::Message(Message {
            payload: BufferOrBytes::Bytes(bytes),
            ..
        }) => bytes,
        DataModel::Message(Message {
            payload: BufferOrBytes::Buffer(buffer),
            ..
        }) => buffer.read(),
        _ => return Err(Error { message: "Unexpected input".to_string() }),
    };

    // Parse input
    let data: {{InputStruct}} = serde_json::from_slice(&payload)
        .map_err(|e| Error { message: format!("Parse error: {}", e) })?;

    // Apply filter logic
    let min = MIN_THRESHOLD.get().copied().unwrap_or({{DEFAULT_MIN}});
    let max = MAX_THRESHOLD.get().copied().unwrap_or({{DEFAULT_MAX}});

    let passes = data.{{filter_field}} >= min && data.{{filter_field}} <= max;

    if !passes {
        logger::log(
            Level::Debug,
            "{{operator-name}}",
            &format!("Filtered: {}={}", "{{filter_field}}", data.{{filter_field}})
        );
        let _ = metrics::add_to_counter("filtered", CounterValue::U64(1), Some(&labels));
    }

    Ok(passes)
}
```

Placeholders:

- `{{operator-name}}` - Kebab-case name for logging
- `{{operator_name}}` - Snake_case function name
- `{{THRESHOLD_TYPE}}` - Numeric type (f64, i64, u32, etc.)
- `{{InputStruct}}` - PascalCase input struct name
- `{{filter_field}}` - Field to apply filter on
- `{{DEFAULT_MIN}}`, `{{DEFAULT_MAX}}` - Default threshold values

## Accumulate Operator Template

Complete accumulate operator with aggregation logic and state management.

```rust
#![allow(clippy::missing_safety_doc)]

use wasm_graph_sdk::logger::{self, Level};
use wasm_graph_sdk::macros::accumulate_operator;
use wasm_graph_sdk::metrics::{self, CounterValue, Label};
use wasm_graph_sdk::{DataModel, Error, Message, BufferOrBytes};

// Input data structure
#[derive(Debug, Clone, serde::Deserialize)]
struct {{InputStruct}} {
    {{value_field}}: {{VALUE_TYPE}},
    // Add other fields as needed
}

// Accumulated state structure
#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
struct {{AccumulatedStruct}} {
    count: u64,
    sum: {{VALUE_TYPE}},
    min: {{VALUE_TYPE}},
    max: {{VALUE_TYPE}},
    average: {{VALUE_TYPE}},
}

impl Default for {{AccumulatedStruct}} {
    fn default() -> Self {
        Self {
            count: 0,
            sum: {{ZERO_VALUE}},
            min: {{MAX_VALUE}},
            max: {{MIN_VALUE}},
            average: {{ZERO_VALUE}},
        }
    }
}

#[accumulate_operator]
fn {{operator_name}}(
    staged: DataModel,
    inputs: Vec<DataModel>,
) -> Result<DataModel, Error> {
    logger::log(
        Level::Info,
        "{{operator-name}}",
        &format!("Accumulating {} inputs", inputs.len())
    );

    // Extract or initialize staged data
    let mut agg = if let DataModel::BufferOrBytes(BufferOrBytes::Bytes(bytes)) = staged {
        serde_json::from_slice::<{{AccumulatedStruct}}>(&bytes).unwrap_or_default()
    } else {
        {{AccumulatedStruct}}::default()
    };

    // Process all inputs
    for input in inputs {
        let payload = match input {
            DataModel::Message(Message {
                payload: BufferOrBytes::Bytes(bytes),
                ..
            }) => bytes,
            _ => continue,
        };

        if let Ok(data) = serde_json::from_slice::<{{InputStruct}}>(&payload) {
            agg.count += 1;
            agg.sum += data.{{value_field}};
            agg.min = agg.min.min(data.{{value_field}});
            agg.max = agg.max.max(data.{{value_field}});
        }
    }

    // Calculate average
    if agg.count > 0 {
        agg.average = agg.sum / {{COUNT_CONVERSION}};
    }

    // Metrics
    let labels = vec![Label {
        key: "module".to_owned(),
        value: "{{operator-name}}".to_owned(),
    }];
    let _ = metrics::set_gauge("accumulated_count", CounterValue::U64(agg.count), Some(&labels));

    // Serialize result
    let result_bytes = serde_json::to_vec(&agg)
        .map_err(|e| Error { message: format!("Serialize error: {}", e) })?;

    Ok(DataModel::BufferOrBytes(BufferOrBytes::Bytes(result_bytes)))
}
```

Placeholders:

- `{{operator-name}}` - Kebab-case name for logging
- `{{operator_name}}` - Snake_case function name
- `{{InputStruct}}` - PascalCase input struct name
- `{{AccumulatedStruct}}` - PascalCase accumulated state struct name
- `{{VALUE_TYPE}}` - Numeric type (f64, i64, etc.)
- `{{value_field}}` - Field to aggregate
- `{{ZERO_VALUE}}` - Zero value for type (0.0, 0)
- `{{MAX_VALUE}}` - Maximum value for type (f64::INFINITY, i64::MAX)
- `{{MIN_VALUE}}` - Minimum value for type (f64::NEG_INFINITY, i64::MIN)
- `{{COUNT_CONVERSION}}` - Convert count to VALUE_TYPE (agg.count as f64)

## ONNX Inference Operator Template

Complete ONNX operator with embedded model, preprocessing, inference, and postprocessing.

```rust
#![allow(clippy::missing_safety_doc)]

use wasm_graph_sdk::logger::{self, Level};
use wasm_graph_sdk::macros::map_operator;
use wasm_graph_sdk::metrics::{self, CounterValue, Label};
use wasm_graph_sdk::{DataModel, Error, Message, BufferOrBytes, ModuleConfiguration};
use std::sync::{LazyLock, OnceLock};

// Import wasi-nn bindings
use crate::wasi::nn::{
    graph::{load, ExecutionTarget, Graph, GraphEncoding, GraphExecutionContext},
    tensor::{Tensor, TensorData, TensorDimensions, TensorType},
};

// Embed ONNX model and labels at compile time
static MODEL: &[u8] = include_bytes!("fixture/models/{{model-file}}.onnx");
static LABELS: &str = include_str!("fixture/labels/{{labels-file}}.txt");

// Configuration parameters
static TOP_K: OnceLock<usize> = OnceLock::new();
static THRESHOLD: OnceLock<f32> = OnceLock::new();

// Initialize graph and context once, reuse across messages
static mut CONTEXT: LazyLock<GraphExecutionContext> = LazyLock::new(|| {
    logger::log(Level::Info, "{{operator-name}}", "Loading ONNX model");
    let graph = load(
        &[MODEL.to_vec()],
        GraphEncoding::Onnx,
        ExecutionTarget::Cpu
    ).expect("Failed to load ONNX model");
    Graph::init_execution_context(&graph).expect("Failed to create execution context")
});

#[derive(Debug, serde::Deserialize)]
struct ImageInput {
    image_bytes: Vec<u8>,
}

#[derive(Debug, serde::Serialize)]
struct ClassificationResult {
    predictions: Vec<Prediction>,
}

#[derive(Debug, serde::Serialize)]
struct Prediction {
    label: String,
    confidence: f32,
}

fn {{operator_name}}_init(configuration: ModuleConfiguration) -> bool {
    logger::log(Level::Info, "{{operator-name}}", "Initializing");

    // Extract top_k parameter
    if let Some(top_k_str) = configuration.properties
        .iter()
        .find(|(k, _)| k == "top_k")
        .map(|(_, v)| v.clone())
    {
        if let Ok(k) = top_k_str.parse::<usize>() {
            let _ = TOP_K.set(k);
        }
    }

    // Extract threshold parameter
    if let Some(threshold_str) = configuration.properties
        .iter()
        .find(|(k, _)| k == "threshold")
        .map(|(_, v)| v.clone())
    {
        if let Ok(t) = threshold_str.parse::<f32>() {
            let _ = THRESHOLD.set(t);
        }
    }

    // Set defaults
    let _ = TOP_K.get_or_init(|| 5);
    let _ = THRESHOLD.get_or_init(|| 0.1);

    true
}

#[map_operator(init = "{{operator_name}}_init")]
fn {{operator_name}}(input: DataModel) -> Result<DataModel, Error> {
    // Metrics
    let labels = vec![Label {
        key: "module".to_owned(),
        value: "{{operator-name}}".to_owned(),
    }];
    let _ = metrics::add_to_counter("inference_requests", CounterValue::U64(1), Some(&labels));

    // Extract image bytes from input
    let payload = match input {
        DataModel::Message(Message {
            payload: BufferOrBytes::Bytes(bytes),
            ..
        }) => bytes,
        DataModel::Message(Message {
            payload: BufferOrBytes::Buffer(buffer),
            ..
        }) => buffer.read(),
        _ => {
            return Err(Error { message: "Unexpected input type".to_string() });
        }
    };

    let image_input: ImageInput = serde_json::from_slice(&payload)
        .map_err(|e| Error { message: format!("Parse error: {}", e) })?;

    // Preprocess: decode, resize, normalize
    let preprocessed_tensor = preprocess_image(&image_input.image_bytes)?;

    // Run inference
    let raw_output = run_inference(preprocessed_tensor)?;

    // Postprocess: top-K, threshold
    let top_k = TOP_K.get().copied().unwrap_or(5);
    let threshold = THRESHOLD.get().copied().unwrap_or(0.1);
    let top_predictions = postprocess_predictions(raw_output, top_k, threshold)?;

    let result = ClassificationResult {
        predictions: top_predictions,
    };

    let result_bytes = serde_json::to_vec(&result)
        .map_err(|e| Error { message: format!("Serialize error: {}", e) })?;

    match input {
        DataModel::Message(msg) => Ok(DataModel::Message(Message {
            timestamp: msg.timestamp,
            topic: msg.topic,
            payload: BufferOrBytes::Bytes(result_bytes),
            properties: msg.properties,
            content_type: Some("application/json".to_string()),
            schema: msg.schema,
        })),
        DataModel::BufferOrBytes(_) => Ok(DataModel::BufferOrBytes(
            BufferOrBytes::Bytes(result_bytes)
        )),
        _ => Err(Error { message: "Unexpected type".to_string() }),
    }
}

fn preprocess_image(image_bytes: &[u8]) -> Result<Vec<f32>, Error> {
    // Decode image
    let img = image::load_from_memory(image_bytes)
        .map_err(|e| Error { message: format!("Image decode error: {}", e) })?;

    // Resize to model input size (e.g., 224x224 for MobileNet)
    let resized = img.resize_exact({{IMAGE_SIZE}}, {{IMAGE_SIZE}}, image::imageops::FilterType::Triangle);

    // Convert to RGB and normalize to [0, 1]
    let rgb = resized.to_rgb8();
    let mut tensor_data = Vec::with_capacity({{IMAGE_SIZE}} * {{IMAGE_SIZE}} * 3);

    for pixel in rgb.pixels() {
        tensor_data.push(pixel[0] as f32 / 255.0);  // R
        tensor_data.push(pixel[1] as f32 / 255.0);  // G
        tensor_data.push(pixel[2] as f32 / 255.0);  // B
    }

    Ok(tensor_data)
}

fn run_inference(input_tensor: Vec<f32>) -> Result<Vec<f32>, Error> {
    unsafe {
        // Set input tensor (shape: [1, 3, H, W] for NCHW format)
        let dimensions = vec![1, 3, {{IMAGE_SIZE}}, {{IMAGE_SIZE}}];
        let tensor = Tensor {
            dimensions: &dimensions,
            tensor_type: TensorType::Fp32,
            data: TensorData::F32(&input_tensor),
        };

        CONTEXT.set_input(0, tensor)
            .map_err(|e| Error { message: format!("Set input error: {:?}", e) })?;

        // Execute inference
        CONTEXT.compute()
            .map_err(|e| Error { message: format!("Inference error: {:?}", e) })?;

        // Get output tensor
        let output_size = CONTEXT.get_output_size(0)
            .map_err(|e| Error { message: format!("Get output size error: {:?}", e) })?;

        let mut output_buffer = vec![0f32; output_size];
        CONTEXT.get_output(0, &mut output_buffer)
            .map_err(|e| Error { message: format!("Get output error: {:?}", e) })?;

        Ok(output_buffer)
    }
}

fn postprocess_predictions(
    logits: Vec<f32>,
    top_k: usize,
    threshold: f32
) -> Result<Vec<Prediction>, Error> {
    // Apply softmax
    let max_logit = logits.iter().cloned().fold(f32::NEG_INFINITY, f32::max);
    let exp_sum: f32 = logits.iter().map(|&x| (x - max_logit).exp()).sum();
    let probabilities: Vec<f32> = logits.iter()
        .map(|&x| (x - max_logit).exp() / exp_sum)
        .collect();

    // Get top-K with indices
    let mut indexed: Vec<(usize, f32)> = probabilities.iter()
        .enumerate()
        .map(|(i, &p)| (i, p))
        .collect();
    indexed.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());

    // Parse labels
    let label_lines: Vec<&str> = LABELS.lines().collect();

    // Build predictions above threshold
    let mut predictions = Vec::new();
    for (idx, prob) in indexed.iter().take(top_k) {
        if *prob >= threshold {
            let label = label_lines.get(*idx)
                .map(|s| s.to_string())
                .unwrap_or_else(|| format!("class_{}", idx));
            predictions.push(Prediction {
                label,
                confidence: *prob,
            });
        }
    }

    Ok(predictions)
}
```

Placeholders:

- `{{operator-name}}` - Kebab-case name for logging
- `{{operator_name}}` - Snake_case function name
- `{{model-file}}` - ONNX model filename without extension
- `{{labels-file}}` - Labels filename without extension
- `{{IMAGE_SIZE}}` - Model input image size (typically 224)

Required files:

- Place ONNX model at `src/fixture/models/{{model-file}}.onnx`
- Place labels file at `src/fixture/labels/{{labels-file}}.txt`
- Model size < 50 MB
- Graph YAML includes `wasi-nn` feature

## Graph Definition Template

Use this template for all operator types. Include `wasi-nn` feature only for ONNX operators.

```yaml
metadata:
  $schema: "https://www.schemastore.org/aio-wasm-graph-config-1.0.0.json"
  name: "graph-{{purpose}}-{{module-name}}"
  description: "{{description}}"
  version: "1.0.0"
  vendor: "Microsoft"

moduleRequirements:
  apiVersion: "1.1.0"
  runtimeVersion: "1.1.0"
  # Uncomment for ONNX operators only:
  # features:
  #   - name: "wasi-nn"

# Include this section only if operator has configuration parameters
moduleConfigurations:
  - name: module-{{module-name}}/{{operator-type}}
    parameters:
      {{param-1-name}}:
        name: {{param-1-name}}
        description: "{{param-1-description}}"
        # required: true  # Optional: mark parameter as required
      {{param-2-name}}:
        name: {{param-2-name}}
        description: "{{param-2-description}}"

operations:
  - operationType: "source"
    name: "source"

  - operationType: "{{operator-type}}"
    name: "module-{{module-name}}/{{operator-type}}"
    module: "{{module-name}}:1.0.0"

  - operationType: "sink"
    name: "sink"

connections:
  - from: { name: "source" }
    to: { name: "module-{{module-name}}/{{operator-type}}" }

  - from: { name: "module-{{module-name}}/{{operator-type}}" }
    to: { name: "sink" }
```

Placeholders:

- `{{purpose}}` - Brief purpose description (e.g., `simple`, `temperature-processing`)
- `{{module-name}}` - Kebab-case module name matching Cargo.toml
- `{{description}}` - Human-readable description
- `{{operator-type}}` - One of: `map`, `filter`, `accumulate`, `branch`, `delay`
- `{{param-*-name}}` - Configuration parameter key (snake_case)
- `{{param-*-description}}` - Parameter description

## Terraform Dataflow Configuration Template

Add this entry to the `dataflow_graphs` variable array in blueprint Terraform configuration (see `blueprints/full-single-node-cluster/terraform/dataflow-graphs.tfvars.example`).

```hcl
{
  name = "{{pipeline-name}}"
  nodes = [
    {
      nodeType = "Source"
      name = "{{source-name}}"
      sourceSettings = {
        endpointRef = "default"
        dataSources = ["{{input-topic-pattern}}"]
      }
    },
    {
      nodeType = "Graph"
      name = "{{graph-name}}"
      graphSettings = {
        registryEndpointRef = "acr-{{resource_prefix}}"
        artifact = "graph-{{graph-artifact-name}}:1.0.0"
        # Include configuration section only if operator has parameters
        configuration = [
          { key = "{{param-1-key}}", value = "{{param-1-value}}" },
          { key = "{{param-2-key}}", value = "{{param-2-value}}" }
        ]
      }
    },
    {
      nodeType = "Destination"
      name = "{{destination-name}}"
      destinationSettings = {
        endpointRef = "default"
        dataDestination = "{{output-topic}}"
      }
    }
  ]
  node_connections = [
    {
      from = { name = "{{source-name}}" }
      to = { name = "{{graph-name}}" }
    },
    {
      from = { name = "{{graph-name}}" }
      to = { name = "{{destination-name}}" }
    }
  ]
}
```

Placeholders:

- `{{pipeline-name}}` - Unique pipeline identifier (kebab-case)
- `{{source-name}}` - Source node identifier
- `{{graph-name}}` - Graph node identifier
- `{{destination-name}}` - Destination node identifier
- `{{input-topic-pattern}}` - MQTT input topic (supports wildcards: `sensors/+/data`)
- `{{output-topic}}` - MQTT output topic
- `{{graph-artifact-name}}` - Graph YAML artifact name in ACR (matches graph metadata name)
- `{{param-*-key}}` - Configuration parameter key
- `{{param-*-value}}` - Configuration parameter value

## Template Placeholder Reference

All placeholders use double curly braces: `{{placeholder-name}}`

### Required Placeholders

* `{{operator-name}}` - Kebab-case operator name (e.g., `temperature-converter`, `range-filter`)
  * Pattern: `[a-z][a-z0-9-]*`
  * Length: 3-50 characters
  * Used in: Cargo.toml, logging, metrics

* `{{operator_name}}` - Snake_case function name (e.g., `temperature_converter`, `range_filter`)
  * Pattern: `[a-z][a-z0-9_]*`
  * Used in: Rust function definitions

* `{{operator-type}}` - Operator type (e.g., `map`, `filter`, `accumulate`, `branch`, `delay`)
  * One of the 5 supported types
  * Used in: Graph YAML operations

* `{{module-name}}` - Module name matching operator name
  * Same as `{{operator-name}}` in most cases
  * Used in: Graph YAML module references, ACR artifacts

### Struct Placeholders (PascalCase)

* `{{InputStruct}}` - Input data structure name (e.g., `TemperatureData`, `SensorReading`)
* `{{OutputStruct}}` - Output data structure name (e.g., `ConvertedTemperature`, `FilterResult`)
* `{{AccumulatedStruct}}` - Accumulated state structure (e.g., `AggregatedStats`, `WindowedData`)

### Configuration Placeholders

* `{{CONFIG_PARAM}}` - SCREAMING_SNAKE_CASE static configuration variable
* `{{CONFIG_TYPE}}` - Configuration value type (f64, String, usize, etc.)
* `{{param_name}}` - snake_case configuration parameter key from graph
* `{{default_value}}` - Default value for optional configuration

### Type Placeholders

* `{{VALUE_TYPE}}` - Numeric type for values (f64, i64, u32)
* `{{THRESHOLD_TYPE}}` - Numeric type for thresholds (f64, i64)
* `{{ZERO_VALUE}}` - Zero value for type (0.0, 0)
* `{{MAX_VALUE}}` - Maximum value (f64::INFINITY, i64::MAX)
* `{{MIN_VALUE}}` - Minimum value (f64::NEG_INFINITY, i64::MIN)

### Field Placeholders

* `{{input_field_*}}` - Input struct field names
* `{{output_field_*}}` - Output struct field names
* `{{value_field}}` - Field to aggregate or filter on
* `{{filter_field}}` - Field to apply filter predicate on

### ONNX-Specific Placeholders

* `{{model-file}}` - ONNX model filename without extension
* `{{labels-file}}` - Labels filename without extension
* `{{IMAGE_SIZE}}` - Model input image dimension (typically 224)

### Graph Placeholders

* `{{purpose}}` - Graph purpose (e.g., `simple`, `temperature-processing`)
* `{{description}}` - Human-readable description
* `{{param-*-name}}` - Parameter name
* `{{param-*-description}}` - Parameter description

### Terraform Placeholders

* `{{pipeline-name}}` - Dataflow pipeline name
* `{{source-name}}`, `{{graph-name}}`, `{{destination-name}}` - Node names
* `{{input-topic-pattern}}` - MQTT input topic pattern
* `{{output-topic}}` - MQTT output topic
* `{{graph-artifact-name}}` - ACR artifact name
* `{{param-*-key}}`, `{{param-*-value}}` - Configuration pairs

### Logic Placeholders

* `{{transformation_logic_*}}` - Custom transformation code in map operators
* `{{aggregation_logic}}` - Aggregation update code in accumulate operators
* `{{post_processing}}` - Derived calculations after aggregation
* `{{COUNT_CONVERSION}}` - Convert count to VALUE_TYPE (e.g., `agg.count as f64`)

### Conditional Patterns

Conditionals are documentation markers, not actual templating syntax:

* `# Uncomment for ONNX operators only:` - Include wasi-nn feature or image dependency
* `# Include this section only if...` - Include moduleConfigurations or configuration array

### Validation Rules

* Operator names follow kebab-case, 3-50 characters
* Operator type is one of: map, filter, accumulate, branch, delay
* ONNX models are < 50 MB
* Graph YAML validates against schema
* Terraform HCL follows valid syntax
