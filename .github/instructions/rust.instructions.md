---
applyTo: '**/*.rs'
description: 'Instructions for Rust implementation - Brought to you by microsoft/edge-ai'
---

# Rust Instructions

You are an expert in Rust development with deep knowledge of best practices and efficient implementation patterns.
When writing or evaluating Rust code in this infrastructure project, always follow the conventions in this document.

Rust files in this project are primarily for edge AI applications, WASM operators, telemetry services, and IoT workloads that support edge deployment scenarios.

You will ALWAYS think hard about Rust instructions and established conventions.

- **CRITICAL**: Comprehensive Rust conventions are provided by the [hve-core](https://github.com/microsoft/hve-core) VS Code extension and loaded automatically when installed
- You will ALWAYS understand all guidelines and follow them precisely
- You will ALWAYS follow the Rust conventions from hve-core instructions

<!-- <rust-instructions> -->
## Required Reading Process

When working with Rust files in this project:

1. Follow the comprehensive Rust instructions provided by the hve-core extension
2. Follow the Rust standards documentation provided by the hve-core extension
3. Follow the Rust testing guidelines provided by the hve-core extension
4. You must read ALL lines from instruction files
5. You must FOLLOW ALL instructions contained in these files

### Required File Details

| Requirement         | Value                                                                  |
|---------------------|------------------------------------------------------------------------|
| Instructions Source | hve-core extension `.github/instructions/coding-standards/rust/` files |
| Read All Lines      | Required                                                               |
| Minimum Lines       | 1000 (combined)                                                        |
| Follow Instructions | Required                                                               |
<!-- </rust-instructions> -->

## Project-Specific Guidelines

### Target Files

- These instructions apply specifically to Rust files with pattern `**/*.rs`
- Rust code in this project supports edge AI inference, WASM operators for dataflow graphs, telemetry services, and IoT connectors
- Each Rust component should align with the project's edge AI and infrastructure automation goals

### Workspace Architecture

- The root `Cargo.toml` uses a disabled workspace (`members = []`) for microservices architecture
- Each Rust service maintains independent `Cargo.lock` files for isolated dependency management
- Services opt-in to the `aio-sdks` private registry when using Azure IoT Operations SDKs
- Registry configuration is defined in `.cargo/config.toml`

### Cargo.toml Conventions

- Use `edition = "2021"` for all new crates
- Set `license = "MIT"` for open-source components
- Pin exact versions for Azure IoT SDKs (`version = "=1.1.3"`)
- WASM operators must set `crate-type = ["cdylib"]` under `[lib]`
- Include `[workspace]` at the bottom to isolate from the root workspace

### Release Profile

- Use `strip = true` in `[profile.release]` to remove debug symbols
- Enable `lto = true` for link-time optimization when binary size matters
- Set `panic = "abort"` for smaller binaries on edge deployments

## Implementation Requirements

When implementing any Rust functionality in this project:

- You must have read the complete Rust documentation before proceeding
- You must adhere to all guidelines provided by the hve-core extension instructions
- You must implement all patterns exactly as specified in the Rust conventions
