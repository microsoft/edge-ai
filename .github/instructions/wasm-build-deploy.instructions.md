---
applyTo: '**/src/500-application/**/operators/**'
description: 'Build, deploy, and test standards for Rust-based WASM operators including graph schemas, Terraform integration, naming conventions, and validation rules - Brought to you by microsoft/edge-ai'
---

# Rust WASM Operator Build and Deploy Standards

These standards apply to Rust-based WASM operators. For Python-based WASM development, refer to the Python WASM instructions.

## Graph Definition Standards

All graph definitions validate against schema: `https://www.schemastore.org/aio-wasm-graph-config-1.0.0.json`

### Required Sections

#### Metadata
```yaml
metadata:
  $schema: "https://www.schemastore.org/aio-wasm-graph-config-1.0.0.json"
  name: "graph-{purpose}-{module}"
  description: "{description}"
  version: "1.0.0"
  vendor: "Microsoft"
```

#### Module Requirements

```yaml
moduleRequirements:
  apiVersion: "1.1.0"
  runtimeVersion: "1.1.0"
  features:  # Optional, required for ONNX
    - name: "wasi-nn"
```

#### Module Configurations (optional)

```yaml
moduleConfigurations:
  - name: module-{name}/{type}
    parameters:
      param_name:
        name: param_name
        description: "{description}"
        required: false  # Optional flag
```

#### Operations

```yaml
operations:
  - operationType: "source"
    name: "source"

  - operationType: "map|filter|accumulate|branch|delay"
    name: "module-{name}/{type}"
    module: "{module-name}:1.0.0"

  - operationType: "sink"
    name: "sink"
```

#### Connections

```yaml
connections:
  - from: { name: "source" }
    to: { name: "module-{name}/{type}" }

  - from: { name: "module-{name}/{type}" }
    to: { name: "sink" }
```

## Terraform Integration

### Dataflow Graph Configuration

WASM dataflow graphs are deployed via the `dataflow_graphs` variable in Terraform configurations. No blueprint modifications are required — add or update entries in your `terraform.tfvars` file.

See `blueprints/full-single-node-cluster/terraform/dataflow-graphs.tfvars.example` for the canonical example.

Add an entry to the `dataflow_graphs` variable array in your `terraform.tfvars`:

```hcl
dataflow_graphs = [
  {
    name = "{pipeline-name}"
    nodes = [
      {
        nodeType = "Source"
        name     = "{source-name}"
        sourceSettings = {
          endpointRef = "default"
          dataSources = ["{mqtt-topic-pattern}"]
        }
      },
      {
        nodeType = "Graph"
        name     = "{operator-name}"
        graphSettings = {
          registryEndpointRef = "acr-{resource_prefix}"
          artifact            = "graph-{name}:1.0.0"
          configuration = [
            { key = "{param1}", value = "{value1}" },
            { key = "{param2}", value = "{value2}" }
          ]
        }
      },
      {
        nodeType = "Destination"
        name     = "{destination-name}"
        destinationSettings = {
          endpointRef     = "default"
          dataDestination = "{mqtt-topic-output}"
        }
      }
    ]
    node_connections = [
      { from = { name = "{source-name}" }, to = { name = "{operator-name}" } },
      { from = { name = "{operator-name}" }, to = { name = "{destination-name}" } }
    ]
  }
]
```

The `registryEndpointRef` follows the pattern `acr-{var.resource_prefix}` and is configured automatically by the blueprint's ACR module.

## Build Tooling Integration

### Automatic Discovery

The build script `scripts/build-wasm.sh` automatically discovers operators in `operators/*/` directories and compiles them to `wasm32-wasip2` target.

Manual build:

```bash
cd src/500-application/{wasm-provider-folder}
./scripts/build-wasm.sh operators/{operator-name}
```

Output locations:

* Standalone operator: `operators/{name}/target/wasm32-wasip2/release/{crate_name}.wasm`
* WIT composed output (advanced): `operators/{consumer}/target/wasm32-wasip2/release/composed_{name}.wasm`

The `build-wasm.sh` script handles the full pipeline including compilation and optional `wasm-tools compose`.

### IDE Integration

Register the new operator in `.vscode/settings.json` so rust-analyzer resolves the crate:

```jsonc
"rust-analyzer.linkedProjects": [
    "src/500-application/{wasm-provider-folder}/operators/{operator-name}/Cargo.toml"
]
```

Append the new entry to the existing `rust-analyzer.linkedProjects` array. Do not remove existing entries.

### Build Requirements

Cargo configuration (`.cargo/config.toml`):

```toml
[registries]
aio-sdks = { index = "sparse+https://pkgs.dev.azure.com/azure-iot-sdks/iot-operations/_packaging/preview/Cargo/index/" }

[build]
target = "wasm32-wasip2"
```

```bash
cargo build --release \
  --target wasm32-wasip2 \
  --manifest-path "operators/{operator-name}/Cargo.toml"
```

### ORAS Push to ACR

Push WASM module:

```bash
oras push "${ACR_NAME}.azurecr.io/{module-name}:1.0.0" \
  --artifact-type application/vnd.module.wasm.content.layer.v1+wasm \
  "{module-name}.wasm:application/wasm" \
  --disable-path-validation
```

Push graph definition:

```bash
oras push "${ACR_NAME}.azurecr.io/{graph-name}:1.0.0" \
  --config /dev/null:application/vnd.microsoft.aio.graph.v1+yaml \
  "./graph-{name}.yaml:application/yaml" \
  --disable-path-validation
```

Automated push (all modules and graphs):

```bash
./scripts/push-to-acr.sh {acr-name}
```

## Testing and Debugging

### MQTT Testing Workflow

Publish test message:

```bash
mosquitto_pub -h aio-broker -p 18883 \
  -m '{"value": 123, "unit": "F"}' \
  -t "sensors/temperature/raw" \
  --cafile /var/run/certs/ca.crt \
  -D CONNECT authentication-method 'K8S-SAT' \
  -D CONNECT authentication-data $(cat /var/run/secrets/tokens/broker-sat)
```

Subscribe to output:

```bash
mosquitto_sub -h aio-broker -p 18883 \
  -t "sensors/temperature/processed" \
  --cafile /var/run/certs/ca.crt \
  -D CONNECT authentication-method 'K8S-SAT' \
  -D CONNECT authentication-data $(cat /var/run/secrets/tokens/broker-sat)
```

### Log Inspection

Dataflow operator logs:

```bash
kubectl logs -n azure-iot-operations deployment/aio-dataflow-operator -f
```

Filter for specific module:

```bash
kubectl logs -n azure-iot-operations deployment/aio-dataflow-operator -f | grep "operator-name"
```

### Common Errors and Solutions

#### `Failed to load WASM module`

- Cause: Module not pushed to ACR or wrong version
- Fix: Verify ORAS push completed successfully, check artifact reference in graph matches pushed version

#### `Parse error: expected value at line 1`

- Cause: Input JSON structure doesn't match serde struct
- Fix: Check input message format, verify struct field names match JSON keys exactly

#### `Configuration parameter not found`

- Cause: Parameter name mismatch between graph YAML and operator code
- Fix: Ensure parameter names in `moduleConfigurations` match exactly what operator reads from `configuration.properties`

#### `Init function returned false`

- Cause: Required configuration parameter missing or failed to parse
- Fix: Check logs for specific init error, verify all required parameters provided in graph configuration

#### `No output messages received`

- Cause: Operator returning Err() or filter returning false
- Fix: Check operator logs for errors, verify filter logic, confirm operator returns Ok() for test data

### Metrics Collection Verification

View metrics:

```bash
kubectl port-forward -n azure-iot-operations svc/aio-dataflow-operator-metrics 9090:9090
```

Then access Prometheus metrics at `http://localhost:9090/metrics`

Expected metrics:
- `{operator_name}_requests_total` - Request counter
- `{operator_name}_processing_time_ms` - Processing gauge
- Custom metrics defined in operator code

## Naming Conventions

### Operator Names

Format: kebab-case
Pattern: `[a-z][a-z0-9-]*`
Length: 3-50 characters
Examples: `temperature-converter`, `range-filter`, `stats-aggregator`

### Module Names

Format: Match operator name with version
Pattern: `{operator-name}:1.0.0`
Examples: `temperature-converter:1.0.0`, `range-filter:1.0.0`

### Operation Names

Format: `module-{name}/{type}`
Pattern: `module-[a-z][a-z0-9-]*/[a-z]+`
Examples: `module-temperature/converter`, `module-sensor/range-filter`

### Graph Names

Format: `graph-{purpose}-{module}.yaml`
Pattern: `graph-[a-z][a-z0-9-]*\.yaml`
Examples: `graph-simple-filter.yaml`, `graph-temperature-processing.yaml`

## Validation Rules

### Graph YAML Schema

Schema URL: `https://www.schemastore.org/aio-wasm-graph-config-1.0.0.json`

Required fields:

- `metadata.$schema`
- `metadata.name`
- `metadata.version`
- `moduleRequirements.apiVersion` = "1.1.0"
- `moduleRequirements.runtimeVersion` = "1.1.0"
- `operations` (at least source and sink)
- `connections` (connect all operations)

ONNX-specific:

- Include `moduleRequirements.features` with `wasi-nn`

### Cargo.toml Dependencies

Required exact versions:

- `wasm_graph_sdk = { version = "=1.1.3", registry = "aio-sdks" }`
- `wit-bindgen = "0.22"`

Required dependencies:

- `serde` with `derive` feature
- `serde_json` with `alloc` feature, `default-features = false`

Build target: Compile to `wasm32-wasip2`

### Build Script Integration

Automatic discovery requirements:

- Operator is in `operators/*/` directory
- `Cargo.toml` exists at `operators/{name}/Cargo.toml`
- `src/lib.rs` exists at `operators/{name}/src/lib.rs`

Registry configuration: `.cargo/config.toml` has `aio-sdks` registry configured

### ONNX-Specific Validations

Model size: < 50 MB recommended
Input tensors: Single tensor input supported
Features: Include `wasi-nn` in graph YAML
Dependencies: Include `image` crate for preprocessing
