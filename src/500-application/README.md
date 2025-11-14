---
title: Edge Applications
description: Directory containing application projects that can be built and deployed to an edge or cloud based system with Docker containers and Azure Container Registry
author: Edge AI Team
ms.date: 2025-06-07
ms.topic: reference
keywords:
  - application
  - docker
  - azure container registry
  - acr
  - helm charts
  - multi-stage builds
  - edge deployment
  - cloud deployment
estimated_reading_time: 7
---

## Edge Applications

This directory contains application projects that can be built and deployed to edge or cloud systems. Applications are organized using a numbered folder structure (`5xx-application-name`) with each service containerized via Docker and deployed to Azure Container Registry (ACR). The `500-basic-inference` project serves as a basic reference implementation, while `507-ai-inference` provides a production-ready dual-backend solution.

## Adding a New Application

To add a new application to this repository, follow these guidelines:

### Naming Convention

Create a new directory with the naming pattern `5xx-your-application-name` where `xx` represents the next available number in sequence.

### Required Files and Directories

Your application should include the following structure:

```text
5xx-your-application-name/
├── README.md                  # Comprehensive component documentation
├── .env                       # Environment configuration template
├── .gitignore                 # Git ignore patterns for the component
├── docker-compose.yml         # Local development and testing setup
├── charts/                    # Helm charts for production deployment
│   └── your-service-name/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── docs/                      # Additional documentation
│   ├── DOCKER_COMPOSE_README.md    # Local development guide
│   └── HELM_CHART_GUIDE.md         # Production deployment guide
├── scripts/                   # Deployment and utility scripts
│   ├── deploy-your-service.sh      # Automated deployment script
│   ├── generate-env-config.sh      # Environment configuration generator
├── resources/                 # Configuration and additional resources
├── yaml/                      # Kubernetes manifests and other YAML files
└── services/                  # Service implementations
    ├── service1/
│   ├── Dockerfile
│   └── src/               # Source code
└── service2/
    └── ...
```

## Available Applications

The following applications are currently available in this directory:

- **[500-basic-inference](./500-basic-inference/README.md)** - Reference implementation for basic ML inference workloads
- **[501-rust-telemetry](./501-rust-telemetry/README.md)** - Rust-based telemetry collection service
- **[502-rust-http-connector](./502-rust-http-connector/README.md)** - HTTP connector service built in Rust
- **[503-media-capture-service](./503-media-capture-service/README.md)** - Media capture and processing service
- **[504-mqtt-otel-trace-exporter](./504-mqtt-otel-trace-exporter/README.md)** - MQTT OpenTelemetry trace exporter for observability
- **[505-akri-rest-http-connector](./505-akri-rest-http-connector/README.md)** - Akri REST HTTP connector for Azure IoT Operations
- **[506-ros2-connector](./506-ros2-connector/README.md)** - ROS2 connector integration for robotics workloads
- **[507-ai-inference](./507-ai-inference/README.md)** - Production-ready AI inference service with dual backend support (ONNX Runtime and Candle)
- **[508-media-connector](./508-media-connector/README.md)** - Akri media connector for camera integration with Azure IoT Operations

## Service Implementation

### Docker and Containerization

1. **Dockerfile**: Each application must contain at least one `Dockerfile` for building service images.
   - For a single-service application, place the `Dockerfile` at the root of your application directory.
   - For multi-service applications, place each `Dockerfile` within its respective service directory under `services/`.
   - **Use multi-stage builds where possible** to keep images small and secure. This approach separates the build
     environment from the runtime environment.

Example multi-stage Dockerfile:

```dockerfile
# Build stage
FROM python:3.9-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy and install requirements
COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /app/wheels -r requirements.txt

# Runtime stage
FROM python:3.9-slim

WORKDIR /app

# Copy wheels from builder stage
COPY --from=builder /app/wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links=/wheels/ /wheels/* \
    && rm -rf /wheels

# Copy application code
COPY . .

# Run the application
CMD ["python", "app.py"]
```

### Service Structure and Resources

For each service in `services/`:

- Include language-specific dependencies (`Cargo.toml`, `package.json`, `requirements.txt`)
- Structure source code in `src/` directory
- Follow multi-stage build patterns with minimal runtime dependencies

The `resources/` folder should contain service-specific configuration files, templates, and sample data.

The `yaml/` folder should include Kubernetes manifests not covered by Helm charts (CRDs, storage, security policies).

## Local Development

### Environment Configuration

Create a `.env` template file with:

- Default values and comments for all configuration options
- Documentation of required vs optional variables
- Support for environment-specific configurations

> **Note**: The `.env` file should be added to `.gitignore` and not checked into the repository to avoid exposing sensitive configuration values.

Provide a `scripts/generate-env-config.sh` script for automated configuration setup and validation.

### Docker Compose Setup

Include a `docker-compose.yml` file for local development that:

- Enables running your complete application with `docker compose up`
- Includes required dependencies (databases, message brokers, etc.)
- Uses .env variables to simplify development
- Sets up proper networking and volume mounts

Example Docker Compose service configuration:

```yaml
services:
  your-service:
    build: ./services/your-service
    env_file:
      - .env # Primary configuration file
    environment:
      # Only override critical local development settings
      - ENVIRONMENT=development
      - LOG_TO_CONSOLE=true
```

Testing with different `.env` files:

- **Default**: `docker compose up` (uses `.env`)
- **Debug**: `docker compose --env-file .env.debug up`
- **CI/CD**: `docker compose --env-file .env.ci up`

## Testing and Validation

Design your application to support:

- Local development with Docker Compose
- Automated environment setup and testing
- Clear separation between local and production configurations
- Comprehensive testing covering multiple deployment scenarios
- Test execution integrated into Docker builds with results saved to `/test-results`

## Production Deployment

### Helm Charts

Place production Helm charts in the `charts/` directory with:

- Standard structure: `Chart.yaml`, `values.yaml`, `templates/`, `_helpers.tpl`
- Environment-specific value overrides and sensible defaults
- Proper secrets and configuration management
- Automated packaging and deployment via build pipeline

### Deployment Scripts

Create comprehensive deployment and testing scripts:

- `scripts/deploy-your-service.sh`: Automated deployment with rollback capabilities
- `scripts/test-docker-compose.sh`: Local testing with Docker Compose
- `scripts/test-kubernetes.sh`: Production testing in Kubernetes

## Documentation

Include comprehensive documentation:

- **Component README.md**: Overview, prerequisites, structure, deployment options, configuration, and troubleshooting
- **Specialized Documentation** in `docs/` folder:
  - `DOCKER_COMPOSE_README.md`: Local development guide
  - `HELM_CHART_GUIDE.md`: Production deployment guide

## Build Pipeline Integration

### Image Naming Convention

Images built from your application will follow this naming convention:

- For single-service applications:
  `<application-name-without-5xx>:YYYY-MM-dd-<short-commit-sha>`

- For multi-service applications:
  `<application-name-without-5xx>.<service-name>:YYYY-MM-dd-<short-commit-sha>`

For example:

- `basic-inference:2023-12-15-a1b2c3d` (single service)
- `basic-inference.pipeline:2023-12-15-a1b2c3d` (multi-service)

This naming convention is used by the build pipeline to properly tag and push images to the Azure Container Registry.

### Rust Enterprise Package Feeds

Applications using Rust reference packages may need a private artifact feed in enterprise environments. This repository uses Cargo's named registry feature to access packages from enterprise feeds.

#### How Cargo Named Registries Work

Cargo supports multiple package registries beyond the default crates.io. The build system uses a simple, transparent approach:

**Registry Configuration** (`.cargo/config.toml`):

```toml
[registries]
aio-sdks = { index = "sparse+https://pkgs.dev.azure.com/azure-iot-sdks/iot-operations/_packaging/preview/Cargo/index/" }
```

This configuration defines a named registry called `aio-sdks` that points to an Azure DevOps Artifacts feed containing Azure IoT Operations packages.

**Application Dependencies** (application `Cargo.toml`):

```toml
[dependencies]
azure_iot_operations_mqtt = { version = "0.9.0", registry = "aio-sdks" }
```

Applications explicitly specify `registry = "aio-sdks"` for packages from the private feed. This tells Cargo to fetch these packages from the Azure DevOps registry instead of crates.io.

**Authentication:**

- **Local Development**: Developers must authenticate to Azure DevOps using `cargo login --registry aio-sdks` with a Personal Access Token (PAT)
- **Azure Pipelines**: Build pipeline automatically authenticates using managed service credentials configured in the pipeline

#### Why This Approach is Used

**Transparent Registry Access:**

- Named registries allow packages from multiple sources without conflicts
- No patching, stub implementations, or feature flag complexity required
- Standard Cargo functionality with explicit registry declarations
- Packages from crates.io and Azure DevOps artifact feeds coexist naturally

**Enterprise Package Management:**

- Private registries ensure intellectual property protection and controlled distribution
- Enables dependency auditing and compliance tracking for regulated industries
- Organizations maintain private Rust crates for proprietary algorithms and internal libraries

**Build System Integration:**

The build orchestrator (`scripts/build/application-builder.ps1`) includes basic Rust project detection via `Initialize-RustRegistryConfiguration`, which logs when a Rust project is detected and relies on the registry configuration already present in `.cargo/config.toml`.

#### Dynamic Cargo.lock Generation for Multi-Registry Builds

**Important**: Applications that switch between public (e.g. crates.io) and private (e.g. Azure DevOps Artifacts) package registries must **NOT** commit `Cargo.lock` files to version control. Instead, `Cargo.lock` should be generated dynamically during the Docker build process.

**Dockerfile Pattern for Dynamic Lock File Generation:**

```dockerfile
# Copy workspace crates to root /crates for path dependencies
COPY ./crates /crates

# Generate lock files for workspace crates dynamically (uses find -execdir for resilience)
RUN find /crates -name Cargo.toml -execdir cargo generate-lockfile \;

WORKDIR /app

# Copy dependency files first for better Docker layer caching
COPY ./Cargo.toml ./Cargo.toml
COPY ./.cargo ./.cargo

# Generate Cargo.lock dynamically (supports registry switching)
RUN cargo generate-lockfile

# Continue with build...
```

**Why This Pattern is Required:**

- **Registry Switching**: `Cargo.lock` files are environment-specific and contain resolved dependencies from different registries
- **Local vs CI/CD**: Local development uses crates.io, Azure Pipelines use authenticated Azure DevOps Artifacts feeds
- **Build Reproducibility**: Each environment generates its own lock file with correct registry URLs and authentication context
- **Workspace Dependencies**: Workspace crates (in `crates/` directory) also need dynamic lock file generation
- **Resilient Discovery**: Uses `find -execdir` to reliably discover and process all workspace crates regardless of directory structure or naming

**Gitignore Configuration:**

Ensure your application's `.gitignore` includes:

```gitignore
Cargo.lock
```

This prevents committing environment-specific lock files that would break builds in different contexts.

**Reference Implementation:**

See `503-media-capture-service/services/media-capture-service/Dockerfile` for a complete example of this pattern in production use.

#### Adding New Private Packages

When adding applications that reference new private packages from a registry:

1. **Add dependency** in application `Cargo.toml` with explicit registry:

   ```toml
   [dependencies]
   your_private_package = { version = "0.1.0", registry = "aio-sdks" }
   ```

2. **Authenticate locally** (one-time setup):

   ```bash
   cargo login --registry aio-sdks
   # Enter your Azure DevOps Personal Access Token when prompted
   ```

3. **Build and test** - Cargo automatically fetches from the correct registry

**Note:** All packages must explicitly specify `registry = "aio-sdks"` to use the private feed. Standard dependencies without a registry specification will continue to use crates.io.

## Supply Chain Security for Production Deployments

### SLSA Attestation Best Practices

While the sample applications in this repository are reference implementations and do not require SLSA (Supply-chain Levels for Software Artifacts) attestation, **production deployments of edge AI applications should implement SLSA attestation** for enhanced supply chain security.

#### When to Implement SLSA Attestation

**Implement SLSA attestation when:**

- Publishing container images to public or shared registries
- Distributing applications to external customers or partners
- Meeting compliance requirements for regulated industries
- Building production systems with multiple teams or vendors
- Deploying to environments where supply chain integrity is critical

**SLSA attestation is NOT needed for:**

- Local development and testing (like these samples)
- Internal proof-of-concepts or demos
- Applications that remain within a single, controlled environment

#### SLSA Implementation for Edge AI Applications

**Level 1 Requirements:**

- Automated build process with version control integration
- Immutable build environment (containers, VMs)
- Build provenance tracking

**Level 2 Requirements (Recommended):**

- Hosted build service (GitHub Actions, Azure DevOps)
- Tamper-resistant build logs
- Signed provenance metadata

**Level 3 Requirements (Advanced):**

- Hardware-based key storage
- Non-falsifiable provenance
- Isolated build environments

#### Practical Implementation Steps

1. **Enable SLSA in CI/CD Workflows:**

   ```yaml
   # Example GitHub Actions workflow with SLSA attestation
   jobs:
   build:
       runs-on: ubuntu-latest
       outputs:
       hashes: ${{ steps.hash.outputs.hashes }}
       steps:
       - uses: actions/checkout@v4
       - name: Build container
           run: docker build -t myapp:${{ github.sha }} .
       - name: Generate artifact hashes
           id: hash
           run: |
           # Generate SHA256 hash of container image
           HASH=$(docker images --digests myapp:${{ github.sha }} --format '{{.Digest}}')
           echo "hashes={\"myapp:${{ github.sha }}\":\"sha256:$HASH\"}" >> "$GITHUB_OUTPUT"

   slsa-attestation:
       needs: build
       permissions:
       id-token: write
       contents: read
       uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.0.0
       with:
       base64-subjects: "${{ needs.build.outputs.hashes }}"
   ```

2. **Configure Container Registry Integration:**

   - Use registries that support SLSA attestation (GitHub Container Registry, Azure Container Registry)
   - Enable automatic vulnerability scanning
   - Implement signature verification policies

3. **Consumer Verification:**

   - Document how downstream users can verify attestations
   - Provide verification tools and scripts
   - Include attestation verification in deployment documentation

#### Edge AI Specific Considerations

**Model Artifacts:**

- Apply SLSA attestation to ML model files and training datasets
- Track model lineage and training provenance
- Implement model signature verification

**Hardware Dependencies:**

- Document hardware-specific optimizations and their security implications
- Verify integrity of hardware acceleration libraries (CUDA, OpenVINO)
- Implement secure boot chains for edge devices

**Network Constraints:**

- Design for intermittent connectivity during attestation verification
- Cache attestation metadata for offline verification
- Implement graceful degradation when attestation services are unavailable

#### Resources and Tools

- **SLSA Framework**: [https://slsa.dev/](https://slsa.dev/)
- **GitHub SLSA Generator**: [slsa-framework/slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator)
- **Azure DevOps SLSA**: [Microsoft DevSecOps for SLSA](https://learn.microsoft.com/azure/devops/pipelines/security/overview)
- **Container Signing**: [Cosign](https://github.com/sigstore/cosign) for container image signing and verification

#### Integration with Existing Security Infrastructure

This repository implements comprehensive supply chain security through:

- **SHA Pinning**: All dependencies use immutable references (`scripts/security/Update-*SHAPinning.ps1`)
- **Staleness Monitoring**: Automated detection of outdated dependencies (`scripts/security/Test-SHAStaleness.ps1`)
- **Security Templates**: Cross-platform CI/CD security monitoring (`.azdo/templates/security-*.yml`)
- **Dependency Management**: Automated updates via Dependabot and Azure DevOps scanning

When implementing SLSA attestation for production deployments, build upon these existing security practices for comprehensive supply chain protection.

### Docker Base Image Security Standards

#### SHA256 Pinning Requirement

All Docker base images MUST be pinned to SHA256 digests for supply chain security. This prevents supply chain attacks by ensuring immutable base image references.

**Required Format:**

```dockerfile
FROM mcr.microsoft.com/azurelinux/base/core:3.0.20250910@sha256:919cfecd0ffe136adff3bea7030f3e6abc6633a4069a6de44b2070bb86c40c81
```

**Prohibited Format:**

```dockerfile
FROM mcr.microsoft.com/azurelinux/base/core:3.0.20250910
```

#### Policy Enforcement

SHA256 pinning is enforced through multiple mechanisms:

- **Hadolint DL3006 Rule:** Automated linting via MegaLinter (`.mega-linter.yml`) enforces SHA256 digests on all FROM statements
- **Pre-Build Validation:** GitHub Actions workflow (`.github/workflows/application-matrix-builds.yml`) validates Dockerfiles before builds
- **Security Gate:** Build pipeline fails if Dockerfiles lack SHA256 digests, preventing non-compliant images from being built

#### Exception: ROS2 Images

Applications in `506-ros2-connector` are exempt from SHA256 pinning due to upstream team's rolling tag strategy and build pruning practices. Timestamped ROS2 builds are regularly deleted by the upstream team, making SHA256 pins unstable.

See: `src/500-application/506-ros2-connector/.hadolint.yaml` for local configuration

#### Maintenance

**Automated Updates:**

- **Azure DevOps Dependabot:** Weekly SHA256 digest updates configured in `.azdo/pipelines/dependabot.yml`
- **GitHub Dependabot:** Configured for GitHub-hosted repositories via `.github/dependabot.yml`

**Manual Updates:**

```powershell
# Update all SHA256 digests across application Dockerfiles
pwsh scripts/security/Update-DockerSHAPinning.ps1 -Force

# Preview changes before applying (dry-run mode)
pwsh scripts/security/Update-DockerSHAPinning.ps1 -WhatIf
```

**Staleness Monitoring:**

```powershell
# Check for outdated SHA256 digests (90-day threshold)
pwsh scripts/security/Test-SHAStaleness.ps1 -MaxAgeDays 90

# Generate detailed staleness report
pwsh scripts/security/Test-SHAStaleness.ps1 -MaxAgeDays 90 -Detailed
```

#### Integration with Supply Chain Security

This SHA256 pinning requirement complements the SLSA attestation practices documented above:

- **Immutable Base Images:** SHA256 digests prevent supply chain tampering at the base image layer
- **Combined Provenance:** Use SHA256 pinning with SLSA attestation for complete supply chain provenance tracking
- **Automated Monitoring:** Security templates (`.azdo/templates/security-*.yml`) monitor both SHA staleness and attestation validity
- **Defense in Depth:** Multiple enforcement layers (MegaLinter, pre-build validation, security gates) ensure compliance

---

<!-- markdownlint-disable MD036 -->

_🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers._

<!-- markdownlint-enable MD036 -->
