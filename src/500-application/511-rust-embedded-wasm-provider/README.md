---
title: Rust Embedded WASM Provider
description: WebAssembly operators for Azure IoT Operations dataflow graphs using WIT Component Model composition
author: Edge AI Team
ms.date: 2026-02-17
ms.topic: reference
keywords:
  - wasm
  - webassembly
  - dataflow
  - azure iot operations
  - rust
  - map operator
  - custom provider
  - wit
  - component model
  - composition
estimated_reading_time: 10
---

## Rust Embedded WASM Provider

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)

WebAssembly (WASM) operators for data processing with Azure IoT Operations dataflow graphs, using the WIT Component Model composition pattern to separate infrastructure plumbing from business logic.

## Overview

This application provides two composed WASM modules written in Rust (`map` + `custom-provider`) that are linked at build time using the [WASM Component Model](https://component-model.bytecodealliance.org/) and WIT (WebAssembly Interface Type) contracts. This separation isolates AIO infrastructure concerns from business logic, enabling teams to develop and deploy custom data-processing algorithms independently.

### Why WIT Component Model Composition?

Azure IoT Operations dataflow graphs run WASM modules inside a sandboxed runtime. The AIO SDK provides macros (`#[map_operator]`) that generate the required WASM exports, but the resulting modules tightly couple AIO envelope handling (message types, buffer extraction, metadata preservation) with the actual data transformation logic.

The WIT composition pattern introduces a **component boundary** between the two concerns. This boundary is particularly valuable when users need to inject custom workload implementations containing sensitive or proprietary data algorithms: the provider component encapsulates domain-specific logic behind a clean byte-payload contract, keeping intellectual property isolated from infrastructure plumbing and independently deployable as a sealed WASM binary.

1. A shared WIT contract (`custom.wit`) defines a simple interface with `init()` and `process()` functions operating on raw `payload: list<u8>` — no AIO types leak through.
2. The **map operator** imports this interface and handles all AIO SDK integration: extracting payloads from `Message`/`BufferOrBytes` variants, forwarding configuration, and re-wrapping results with original metadata.
3. The **custom-provider** exports the same interface with the actual business logic, compiled as a standalone WASM component.
4. At build time, `wasm-tools compose` fuses the two modules by matching the provider's exports against the map's imports, producing a single deployable `composed_map_custom.wasm`.

### Advantages

- **Separation of concerns** — Domain experts implement `init()` + `process()` against a clean byte-payload contract without touching AIO types, message envelopes, or SDK macros.
- **Swappable providers** — Replace the custom-provider with a different implementation (format conversion, ML inference, enrichment) without modifying or recompiling the map operator. Teams can develop proprietary algorithms in isolation and slot them into the pipeline as opaque WASM binaries in any supported programming language.
- **Protect sensitive algorithms** — Custom providers compile to sealed `.wasm` components that expose only the WIT-declared `init()` and `process()` surface. Internal logic, model weights, and data transformation strategies remain opaque to the host runtime, other components, and anyone inspecting the deployment. This makes the pattern suitable for workloads where algorithm confidentiality matters.
- **Language-agnostic extensibility** — The WIT contract is language-neutral. Providers can be implemented in any language targeting the WASM Component Model (C, Go, JavaScript via `jco`, Python via `componentize-py`).
- **Security by construction** — Each component runs within the WASM sandbox. The custom-provider cannot access the host, filesystem, or network beyond what the WIT interface exposes.
- **Independent versioning** — Modules are pushed to ACR as separate OCI artifacts, enabling granular version management and rolling updates at the component level.

### Key Callouts

- **Duplicated WIT files** — The `custom.wit` file exists in both `operators/map/wit/` and `operators/custom-provider/wit/`. These must stay identical; any drift causes silent type mismatches during composition.
- **World directives matter** — The same WIT package defines two worlds: `custom-provider` (with `export custom;`) and `custom-impl` (with `import custom;`). The world selection determines whether `wit_bindgen` generates trait implementations or function call stubs.
- **Manual type bridging** — The map operator manually converts between AIO SDK types (`DataModel`, `Message`, `BufferOrBytes`) and the simpler WIT-defined types. This bridging code is sensitive to AIO SDK version changes.
- **Multi-step build** — The composed module requires: compile both crates → `wasm-tools metadata add` → `wasm-tools compose`. The `build-wasm.sh` script automates this sequence.
- **Version pinning** — Both modules pin `wasm_graph_sdk = "=1.1.3"` and `wit-bindgen = "0.22"`. Any version drift between modules can cause ABI mismatches detectable only at composition time or runtime.

### Operators

| Operator          | Role                | Description                                                                   |
|-------------------|---------------------|-------------------------------------------------------------------------------|
| `map`             | Composed (consumer) | AIO SDK bridge that imports the custom WIT interface and delegates processing |
| `custom-provider` | Composed (provider) | Implements custom WIT interface with business logic for composition with map  |

## Technology Background

This section provides context on the WebAssembly technologies underpinning these operators.

### WebAssembly (Wasm)

[WebAssembly](https://webassembly.org/) (abbreviated Wasm) is a binary instruction format for a stack-based virtual machine. Wasm is designed as a portable compilation target for programming languages, enabling deployment on the web and beyond for client and server applications. Open standards for WebAssembly are developed in a [W3C Community Group](https://www.w3.org/community/webassembly/) and a [W3C Working Group](https://www.w3.org/wasm/).

Key properties relevant to dataflow operators:

- **Efficient and fast** — the binary format is size- and load-time-efficient, aiming to execute at native speed by leveraging [common hardware capabilities](https://webassembly.org/docs/portability/#assumptions-for-efficient-execution).
- **Safe** — Wasm describes a memory-safe, sandboxed [execution environment](https://webassembly.github.io/spec/core/exec/index.html#linear-memory). Modules cannot access host memory, filesystem, or network unless explicitly granted through imports.
- **Portable** — the same `.wasm` binary runs on any platform with a conforming runtime, from browsers to edge devices.
- **Open and debuggable** — a [textual format](https://webassembly.github.io/spec/core/text/index.html) exists for debugging, testing, and inspection.

However, core Wasm modules have a limited type system: functions can only exchange integers (`i32`, `i64`) and floats (`f32`, `f64`). Compound types like strings, lists, and records must be manually represented via offsets into shared linear memory. This limitation motivates the Component Model.

### WASM Component Model

The [WebAssembly Component Model](https://component-model.bytecodealliance.org/introduction.html) extends core Wasm modules with a richer type system and a standard way for separately-compiled modules to interoperate across languages. A **component** is a self-describing WebAssembly binary that interacts only through typed interfaces instead of shared memory.

Core concepts:

- **Components** — encapsulate one or more core Wasm modules. Unlike core modules, components never export or import linear memory, enforcing strict isolation. Components use a distinct binary format (version `0x1000d`) and can be inspected with `wasm-tools print`.
- **Interfaces** — collections of type definitions and function declarations expressed in [WIT (WebAssembly Interface Types)](https://component-model.bytecodealliance.org/design/wit.html). Each interface describes a single-focus, composable contract (e.g., "handle HTTP request", "wall clock") through which components interact. Interfaces support rich types — strings, lists, records, enums, variants — eliminating the need for manual memory offset conventions.
- **Worlds** — a [world](https://component-model.bytecodealliance.org/design/worlds.html) is a higher-level contract that collects multiple interfaces, labeling each as an import or export. A world describes everything a component provides and everything it requires to run. Targeting a world is analogous to linking against a specific version of a standard library.
- **Composition** — two components can be composed when the imports of one are satisfied by the exports of another. Composition can be repeated arbitrarily, building a single deployable component from many interlocking pieces. This project uses composition to fuse the `map` operator (which imports a custom interface) with the `custom-provider` (which exports that same interface).

Benefits over raw core modules:

- **Language-neutral interoperability** — a component compiled from Go can call a component compiled from Rust or C, relying on the shared Canonical ABI without custom FFI glue.
- **Strong sandboxing** — components interact only through declared imports and exports. If a component lacks an import for a secret store, it cannot access that store, even within the same process.
- **Static analyzability** — component graphs can be analyzed before deployment to verify access boundaries and data-flow properties.

For more background, see the specification's [goals](https://github.com/WebAssembly/component-model/blob/main/design/high-level/Goals.md), [use cases](https://github.com/WebAssembly/component-model/blob/main/design/high-level/UseCases.md), and [design choices](https://github.com/WebAssembly/component-model/blob/main/design/high-level/Choices.md).

### WASI (WebAssembly System Interface)

[WASI](https://wasi.dev/) is a group of standards-track API specifications for software compiled to Wasm. WASI provides a secure, standard interface for applications that can be compiled from any language and run anywhere — from browsers to clouds to embedded devices and edge runtimes like Azure IoT Operations.

WASI standardizes APIs that components commonly need: file I/O, random number generation, clocks, environment variables, and network sockets. By standardizing these APIs, WASI enables software written in different languages to compose without costly interface systems like HTTP-based microservices.

Key milestones:

- **WASI 0.1 (Preview 1)** — initial specification targeting core Wasm modules.
- **WASI 0.2 (Preview 2)** — stable release (January 25, 2024) built on the Component Model, providing [a stable set of WIT definitions](https://github.com/WebAssembly/WASI/blob/main/docs/Preview2.md) that components can target. Users can pin to any stable release >= `v0.2.0`.

This project targets `wasm32-wasip2` (WASI Preview 2), meaning each operator compiles as a WASI-compatible component.
WASI is an open standard under active development by the [WASI Subgroup](https://github.com/WebAssembly/WASI/blob/main/Charter.md) in the W3C WebAssembly Community Group.
Many runtimes support WASI, including [Wasmtime](https://wasmtime.dev/), [WAMR](https://bytecodealliance.github.io/wamr.dev/), [WasmEdge](https://wasmedge.org/), and [wazero](https://wazero.io/).
The [WASI.dev roadmap](https://wasi.dev/roadmap) tracks upcoming releases.

### wasm-tools

[`wasm-tools`](https://github.com/bytecodealliance/wasm-tools) is a [Bytecode Alliance](https://bytecodealliance.org/) CLI and Rust library suite for low-level manipulation of WebAssembly modules and components. This project uses `wasm-tools` in the build pipeline to compose operators.

Subcommands used in this project:

| Subcommand                 | Purpose                                                                 |
|----------------------------|-------------------------------------------------------------------------|
| `wasm-tools component new` | Create a component from a core Wasm binary with embedded WIT metadata   |
| `wasm-tools compose`       | Fuse two components by matching one's exports against another's imports |
| `wasm-tools metadata add`  | Add name or producer metadata to a component or module                  |
| `wasm-tools validate`      | Validate a `.wasm` file against the spec (useful for CI checks)         |
| `wasm-tools component wit` | Extract the WIT interface from an existing component for inspection     |

Additional capabilities include parsing (`parse`), printing (`print`), mutation testing (`mutate`, `smith`), shrinking (`shrink`), and demangling symbol names (`demangle`). The full tool list and corresponding Rust crates are documented in the [wasm-tools README](https://github.com/bytecodealliance/wasm-tools#tools-included).

Install via Cargo:

```bash
cargo install --locked wasm-tools
```

Or via `cargo binstall` for precompiled binaries:

```bash
cargo binstall wasm-tools
```

## Architecture

```text
┌─────────────┐    MQTT     ┌───────────────────────────────────────┐    MQTT     ┌─────────────┐
│   Source     │────────────▶│           Dataflow Graph              │────────────▶│    Sink      │
│   Endpoint   │             │  ┌─────────────────────────────────┐  │             │   Endpoint   │
└─────────────┘             │  │  composed_map_custom.wasm       │  │             └─────────────┘
                            │  │  (map + custom-provider)        │  │
                            │  └─────────────────────────────────┘  │
                            └───────────────────────────────────────┘
                                              │
                                              ▼
                                ┌─────────────────────────────┐
                                │  Azure Container Registry   │
                                │  (WASM Modules + Graphs)    │
                                └─────────────────────────────┘
```

## Prerequisites

- [Full Single Node Cluster](../../../blueprints/full-single-node-cluster/) blueprint deployed with dataflow graph configuration (see [dataflow-graphs.tfvars.example](../../../blueprints/full-single-node-cluster/terraform/dataflow-graphs.tfvars.example))
- [Rust toolchain](https://rustup.rs/) with `wasm32-wasip2` target
- [`wasm-tools` CLI](https://github.com/bytecodealliance/wasm-tools) for module composition
- [ORAS CLI](https://oras.land/docs/installation) for pushing to container registry
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with container registry access

## Deployment

### Step 1: Install WASM Target

```bash
rustup target add wasm32-wasip2
```

### Step 2: Install wasm-tools

```bash
cargo install wasm-tools
```

### Step 3: Build the Operators

Run the build script from the application root to compile both operators and produce the composed module:

```bash
./scripts/build-wasm.sh
```

This builds `map` and `custom-provider` for the `wasm32-wasip2` target, then composes them into `composed_map_custom.wasm` using `wasm-tools compose`.

### Step 4: Push to Azure Container Registry

Push the composed module and graph definition to your ACR:

```bash
./scripts/push-to-acr.sh <acr_name>
```

This pushes:

- The composed `map-custom` WASM module as an OCI artifact
- The `graph-simple-map-custom.yaml` graph definition

### Step 5: Deploy Dataflow Graph

After pushing to ACR, the dataflow graph is deployed through the `full-single-node-cluster` blueprint with the dataflow graph configuration enabled. The graph definition references the composed module and wires it between a source and sink endpoint.

## Operator Details

### map + custom-provider (WIT Composition)

The `map` operator uses the WASM Component Model to separate AIO SDK integration from business logic. It imports a custom WIT interface (`map:custom/custom`) and delegates payload processing to a composed provider module.

The `custom-provider` exports this same WIT interface, implementing `init()` and `process()` with the actual transformation logic. At build time, `wasm-tools compose` links the two modules into a single `composed_map_custom.wasm` that satisfies AIO's runtime expectations.

```text
┌──────────────────────────────────────────────────────────────────────┐
│                    composed_map_custom.wasm                         │
│  ┌─────────────────────────┐     ┌────────────────────────────────┐ │
│  │     map operator        │     │      custom-provider           │ │
│  │                         │     │                                │ │
│  │  AIO DataModel ──────┐  │     │  ┌──────────────────────────┐  │ │
│  │  payload extraction  │  │     │  │  init() / process()      │  │ │
│  │  metadata preserve   │  │────▶│  │  business logic on raw   │  │ │
│  │  type bridging       │  │     │  │  payload bytes           │  │ │
│  │  #[map_operator]     │  │◀────│  └──────────────────────────┘  │ │
│  └─────────────────────────┘     └────────────────────────────────┘ │
│         import custom;                  export custom;              │
└──────────────────────────────────────────────────────────────────────┘
```

## Graph Definitions

The graph definition in `resources/graphs/` connects a source endpoint through the composed map-custom module to a sink endpoint:

| Graph                          | Description         |
|--------------------------------|---------------------|
| `graph-simple-map-custom.yaml` | Source → map → Sink |

## Updating the Version

To release a new version of the operators:

1. Increment the version in [operators/map/Cargo.toml](operators/map/Cargo.toml):

   ```toml
   [package]
   version = "2.0.0"
   ```

2. Update the graph artifact reference in [blueprints/full-single-node-cluster/terraform/terraform.tfvars](../../../blueprints/full-single-node-cluster/terraform/terraform.tfvars) to match the new version:

   ```hcl
   artifact = "graph-simple-map-custom:2.0.0"
   ```

3. Rebuild and push the updated artifacts:

   ```bash
   ./scripts/build-wasm.sh
   ./scripts/push-to-acr.sh <acr_name>
   ```

   The `push-to-acr.sh` script reads the version from `Cargo.toml`, generates a versioned graph file, and pushes both the composed WASM module and the graph definition to ACR under the new tag.

4. Redeploy the blueprint. Terraform will detect the changed `artifact` reference and apply the updated dataflow graph, which AIO reconciles to pull the new artifacts from ACR.

## Project Structure

```text
511-rust-embedded-wasm-provider/
├── .cargo/
│   └── config.toml           # WASM target and aio-sdks registry
├── operators/                 # WASM operator implementations
│   ├── map/                   # Map transformation with WIT (composed consumer)
│   └── custom-provider/       # WIT export provider (composed provider)
├── resources/
│   └── graphs/                # Graph definition YAMLs
│       └── graph-simple-map-custom.yaml
└── scripts/
    ├── build-wasm.sh          # Build all WASM modules and compose
    └── push-to-acr.sh         # Push to Azure Container Registry
```

## Integration with Azure IoT Operations

Deploy the `full-single-node-cluster` blueprint with dataflow graph configuration as a prerequisite. Then build and push the operators:

1. Build the WASM modules: `./scripts/build-wasm.sh`
2. Push to your ACR: `./scripts/push-to-acr.sh <acr_name>`

The blueprint configures the AIO instance with a registry endpoint pointing to the ACR, and the dataflow graph resource references the pushed modules. See the [dataflow-graphs.tfvars.example](../../../blueprints/full-single-node-cluster/terraform/dataflow-graphs.tfvars.example) for the required variable configuration.

## Development

### Cargo Registry Authentication

The operators depend on `wasm_graph_sdk` from the `aio-sdks` private registry. Set your PAT:

```bash
export CARGO_REGISTRIES_AIO_SDKS_TOKEN="your-pat-token"
```

### Local Build

```bash
cd operators/map
cargo build --release --target wasm32-wasip2
```

## Testing

Deploy the MQTT client for testing:

```bash
kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/explore-iot-operations/main/samples/quickstarts/mqtt-client.yaml
```

### Publish Test Messages

```bash
kubectl exec --stdin --tty mqtt-client -n azure-iot-operations -- sh -c '
# Create and run temperature.sh from within the MQTT client pod
while true; do
  # Generate a random temperature value between 0 and 6000 Celsius
  random_value=$(shuf -i 0-6000 -n 1)
  payload="{\"temperature\":{\"value\":$random_value,\"unit\":\"C\"}}"

  echo "Publishing temperature: $payload"

  # Publish to the input topic
  mosquitto_pub -h aio-broker -p 18883 \
    -m "$payload" \
    -t "raw" \
    -d \
    --cafile /var/run/certs/ca.crt \
    -D PUBLISH user-property __ts $(date +%s)000:0:df \
    -D CONNECT authentication-method "K8S-SAT" \
    -D CONNECT authentication-data $(cat /var/run/secrets/tokens/broker-sat)

  sleep 1
done'
```

### Subscribe to Processed Messages

```bash
kubectl exec --stdin --tty mqtt-client -n azure-iot-operations -- sh -c '
mosquitto_sub -h aio-broker -p 18883 \
  -t "processed" \
  --cafile /var/run/certs/ca.crt \
  -D CONNECT authentication-method "K8S-SAT" \
  -D CONNECT authentication-data "$(cat /var/run/secrets/tokens/broker-sat)"'
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

<!-- markdownlint-disable MD036 -->
*Based on [azure-edge-extensions-aio-dataflow-graphs](https://github.com/Azure-Samples/azure-edge-extensions-aio-dataflow-graphs)*
<!-- markdownlint-enable MD036 -->
