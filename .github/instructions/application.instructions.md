---
applyTo: '**/src/500-application/**'
description: 'Instructions for creating, importing, and managing edge applications - Brought to you by microsoft/edge-ai'
---
# Application Instructions

## Application Overview

Applications are containerized services that can be deployed to edge or cloud systems. They are organized in the `src/500-application/` directory using a numbered folder structure (`5xx-application-name`) with each service containerized via Docker and deployed to Azure Container Registry (ACR).

## Creating New Applications

### Step 1: Determine Application Number

Applications use a sequential numbering system starting with `5xx`:

1. List existing applications to find the next available number:

   ```bash
   ls -la src/500-application/
   ```

2. Use the next sequential number (e.g., if `503-` exists, use `504-`)

### Step 2: Create Application Directory Structure

Create the new application directory with the required structure:

```bash
# Replace 'xxx' with your number and 'your-app-name' with your application name
mkdir -p src/5xx-your-app-name/{services,scripts,charts,docs,resources,yaml}
```

### Step 3: Required Files Structure

Your application must follow this directory structure:

```text
5xx-your-application-name/
├── README.md                          # Comprehensive component documentation
├── .env                              # Environment configuration template
├── .gitignore                        # Git ignore patterns for the component
├── docker-compose.yml                # Local development and testing setup
├── charts/                           # Helm charts for production deployment
│   └── your-service-name/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── docs/                             # Additional documentation
│   ├── DOCKER_COMPOSE_README.md      # Local development guide
│   └── HELM_CHART_GUIDE.md           # Production deployment guide
├── scripts/                          # Deployment and utility scripts
│   ├── deploy-your-service.sh        # Automated deployment script
│   └── generate-env-config.sh        # Environment configuration generator
├── resources/                        # Configuration and additional resources
├── yaml/                            # Kubernetes manifests and other YAML files
└── services/                        # Service implementations
    ├── service1/
    │   ├── Dockerfile
    │   └── src/                      # Source code
    └── service2/
        └── ...
```

### Step 4: Create Essential Files

#### Application README.md

Create a comprehensive README.md following this template:

```markdown
---
title: Your Application Name
description: Brief description of what your application does
author: Your Name
ms.date: $(Get-Date -Format "MM/dd/yyyy")
ms.topic: reference
keywords:
  - application
  - edge
  - your-domain-keywords
estimated_reading_time: 5
---

# Your Application Name

Brief description of your application and its purpose.

## Overview

Detailed explanation of what the application does, its components, and use cases.

## Architecture

Description of the application architecture, including:
- Service components
- Data flow
- External dependencies
- Integration points

## Prerequisites

- List of required tools, services, or configurations
- Minimum system requirements
- Required environment variables

## Local Development

### Quick Start

```bash
# Clone and navigate to the application
cd src/5xx-your-app-name

# Copy environment template
cp .env.template .env

# Edit .env with your configuration
nano .env

# Start the application
docker compose up
```

### Environment Configuration

Description of required environment variables and configuration options.

## Production Deployment

### Using Helm Charts

```bash
# Deploy to Kubernetes
helm install your-app charts/your-service-name/
```

### Using Deployment Scripts

```bash
# Run automated deployment
./scripts/deploy-your-service.sh
```

## Testing

Description of how to test the application locally and in production.

## Troubleshooting

Common issues and their solutions.

## Contributing

Guidelines for contributing to this specific application.

```

#### Environment Configuration (.env)

Create a `.env` template file:

```bash
# Application Configuration
APP_NAME=your-application-name
APP_VERSION=1.0.0
ENVIRONMENT=development

# Service Configuration
SERVICE_PORT=8080
LOG_LEVEL=INFO

# External Dependencies
# DATABASE_URL=
# REDIS_URL=
# MQTT_BROKER=

# Security (Do not commit actual values)
# API_KEY=
# SECRET_KEY=
```

#### Docker Compose Configuration

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  your-service:
    build:
      context: ./services/your-service
      dockerfile: Dockerfile
    ports:
      - "${SERVICE_PORT:-8080}:8080"
    env_file:
      - .env
    environment:
      - ENVIRONMENT=development
      - LOG_TO_CONSOLE=true
    volumes:
      - ./resources:/app/resources:ro
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

#### Git Ignore (.gitignore)

Create `.gitignore` specific to your application:

```gitignore
# Environment files
.env
.env.*

# Logs
logs/
*.log

# Runtime data
pids/
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/

# Build outputs
dist/
build/
target/

# Language-specific ignores
# Python
__pycache__/
*.py[cod]
*$py.class
*.egg-info/

# Node.js
node_modules/
npm-debug.log*

# Rust
target/
Cargo.lock

# .NET
bin/
obj/
*.user
*.suo

# IDE files
.vscode/settings.json
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db
```

### Step 5: Implement Service(s)

#### Create Service Directory

```bash
mkdir -p src/5xx-your-app-name/services/your-service/src
```

#### Create Dockerfile

Create a multi-stage Dockerfile in `services/your-service/Dockerfile`:

```dockerfile
# Build stage
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy and install requirements
COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /app/wheels -r requirements.txt

# Runtime stage
FROM python:3.11-slim

WORKDIR /app

# Copy wheels from builder stage
COPY --from=builder /app/wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links=/wheels/ /wheels/* \
    && rm -rf /wheels

# Copy application code
COPY src/ ./src/
COPY *.py .

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser && \
    chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Expose port
EXPOSE 8080

# Run the application
CMD ["python", "app.py"]
```

#### Implement Source Code

Create your application source code in `services/your-service/src/`.

### Step 6: Create Deployment Scripts

#### Create Deployment Script

Create `scripts/deploy-your-service.sh`:

```bash
#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
APP_NAME="your-app-name"
NAMESPACE="${NAMESPACE:-default}"
HELM_RELEASE_NAME="${HELM_RELEASE_NAME:-$APP_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is required but not installed"
        exit 1
    fi

    if ! command -v helm &> /dev/null; then
        log_error "helm is required but not installed"
        exit 1
    fi

    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
}

# Deploy the application
deploy() {
    log_info "Deploying $APP_NAME to namespace $NAMESPACE..."

    # Create namespace if it doesn't exist
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

    # Deploy using Helm
    helm upgrade --install "$HELM_RELEASE_NAME" \
        "$APP_DIR/charts/$APP_NAME" \
        --namespace "$NAMESPACE" \
        --wait \
        --timeout 300s

    log_info "Deployment completed successfully"

    # Show deployment status
    kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=$APP_NAME"
}

# Main execution
main() {
    log_info "Starting deployment of $APP_NAME..."

    check_prerequisites
    deploy

    log_info "Deployment script completed"
}

# Execute main function
main "$@"
```

#### Create Environment Configuration Script

Create `scripts/generate-env-config.sh`:

```bash
#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$APP_DIR/.env"
ENV_TEMPLATE="$APP_DIR/.env.template"

# Generate .env file from template with user input
generate_env_config() {
    echo "Generating environment configuration..."

    if [[ -f "$ENV_FILE" ]]; then
        read -p ".env file already exists. Overwrite? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Keeping existing .env file"
            return 0
        fi
    fi

    # Copy template if it exists
    if [[ -f "$ENV_TEMPLATE" ]]; then
        cp "$ENV_TEMPLATE" "$ENV_FILE"
        echo "Environment file created from template"
    else
        # Create basic .env file
        cat > "$ENV_FILE" << EOF
# Application Configuration
APP_NAME=your-application-name
APP_VERSION=1.0.0
ENVIRONMENT=development

# Service Configuration
SERVICE_PORT=8080
LOG_LEVEL=INFO

# Add your configuration here
EOF
        echo "Basic environment file created"
    fi

    echo "Please edit $ENV_FILE with your specific configuration"
}

generate_env_config
```

### Step 7: Create Helm Charts

Create Helm chart structure:

```bash
mkdir -p src/5xx-your-app-name/charts/your-service-name/templates
```

Create `charts/your-service-name/Chart.yaml`:

```yaml
apiVersion: v2
name: your-service-name
description: A Helm chart for your application
type: application
version: 0.1.0
appVersion: "1.0.0"
keywords:
  - edge
  - application
  - your-domain
home: https://github.com/microsoft/edge-ai
sources:
  - https://github.com/microsoft/edge-ai
maintainers:
  - name: Your Name
    email: your.email@example.com
```

Create `charts/your-service-name/values.yaml`:

```yaml
# Default values for your-service-name
replicaCount: 1

image:
  repository: your-registry/your-app-name
  pullPolicy: IfNotPresent
  tag: "latest"

nameOverride: ""
fullnameOverride: ""

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts:
    - host: your-app.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80

nodeSelector: {}
tolerations: []
affinity: {}

env:
  - name: LOG_LEVEL
    value: "INFO"
  - name: SERVICE_PORT
    value: "8080"
```

## Importing Existing Applications

### Step 1: Assess Existing Application

Before importing, evaluate:

1. **Application Type**: Web service, batch processor, ML inference, etc.
2. **Dependencies**: External services, databases, message brokers
3. **Configuration**: Environment variables, config files, secrets
4. **Build Process**: Language runtime, build tools, dependencies
5. **Deployment Requirements**: Resource needs, scaling requirements

### Step 2: Containerize Application

If not already containerized:

1. **Create Dockerfile**: Follow multi-stage build patterns
2. **Optimize Image Size**: Use minimal base images, remove build dependencies
3. **Security**: Run as non-root user, scan for vulnerabilities
4. **Health Checks**: Implement proper health check endpoints

### Step 3: Adapt to Project Structure

1. **Move Source Code**: Place in `services/your-service/src/`
2. **Create Configuration**: Add `.env` template and Docker Compose setup
3. **Add Documentation**: Follow README.md template
4. **Create Deployment Assets**: Helm charts and deployment scripts

### Step 4: Test Integration

1. **Local Testing**: Verify Docker Compose works
2. **Build Pipeline**: Ensure container builds successfully
3. **Deployment Testing**: Test Helm chart deployment
4. **Integration Testing**: Verify with other services if applicable

## Application Management Tasks

### Adding New Services to Existing Application

To add a new service to an existing multi-service application:

1. **Create Service Directory**:

   ```bash
   mkdir -p src/5xx-your-app-name/services/new-service/src
   ```

2. **Implement Service**: Add Dockerfile and source code

3. **Update Docker Compose**: Add service definition

4. **Update Helm Charts**: Add templates for new service

5. **Update Documentation**: Document the new service

### Updating Application Dependencies

1. **Language Dependencies**: Update `requirements.txt`, `package.json`, `Cargo.toml`, etc.
2. **Base Images**: Update Dockerfile base image versions
3. **External Services**: Update connection configurations
4. **Test Changes**: Verify all functionality works with updates

### Application Scaling and Performance

1. **Resource Configuration**: Update Helm chart resource limits/requests
2. **Horizontal Scaling**: Configure autoscaling parameters
3. **Performance Monitoring**: Add observability and metrics
4. **Load Testing**: Verify performance under load

### Security Hardening

1. **Container Security**:
   - Use minimal base images
   - Run as non-root user
   - Scan for vulnerabilities

2. **Configuration Security**:
   - Use secrets management
   - Avoid hardcoded credentials
   - Validate input data

3. **Network Security**:
   - Implement proper ingress rules
   - Use network policies
   - Enable TLS/encryption

### Application Monitoring and Observability

1. **Health Checks**: Implement `/health` and `/ready` endpoints
2. **Metrics**: Export Prometheus metrics
3. **Logging**: Structured logging with appropriate levels
4. **Tracing**: Add distributed tracing for complex applications

## Build Pipeline Integration

### Image Naming Convention

Applications follow this naming convention:

- **Single-service applications**: `<application-name-without-5xx>:YYYY-MM-dd-<short-commit-sha>`
- **Multi-service applications**: `<application-name-without-5xx>.<service-name>:YYYY-MM-dd-<short-commit-sha>`

Examples:

- `basic-inference:2024-08-18-a1b2c3d` (single service)
- `media-capture.api:2024-08-18-a1b2c3d` (multi-service)

### Automated Building

The build pipeline automatically:

1. **Detects Changes**: Monitors `src/500-application/` for changes
2. **Builds Images**: Creates Docker images for modified services
3. **Tags Images**: Uses date and commit SHA for versioning
4. **Pushes to ACR**: Uploads to Azure Container Registry
5. **Updates Charts**: Optionally updates Helm chart image tags

## Best Practices

### Code Organization

1. **Separation of Concerns**: Keep services focused and loosely coupled
2. **Configuration Management**: Use environment variables for configuration
3. **Error Handling**: Implement proper error handling and logging
4. **Testing**: Include unit tests and integration tests

### Container Best Practices

1. **Multi-stage Builds**: Separate build and runtime stages
2. **Minimal Images**: Use distroless or alpine base images
3. **Security**: Regular vulnerability scanning and updates
4. **Resource Efficiency**: Optimize for CPU and memory usage

### Documentation Standards

1. **README.md**: Comprehensive component documentation
2. **Code Comments**: Clear and concise inline documentation
3. **API Documentation**: OpenAPI/Swagger for REST APIs
4. **Deployment Guides**: Step-by-step deployment instructions

### Development Workflow

1. **Local Development**: Use Docker Compose for local testing
2. **Version Control**: Follow semantic versioning principles
3. **Testing Strategy**: Automated testing at multiple levels
4. **Continuous Integration**: Automated builds and deployments

## Troubleshooting

### Common Issues

#### Application Won't Start

1. Check environment variables in `.env` file
2. Verify Docker image builds successfully
3. Check application logs: `docker compose logs your-service`
4. Validate configuration files

#### Container Build Failures

1. Check Dockerfile syntax and commands
2. Verify base image availability
3. Check file paths and permissions
4. Review build context and .dockerignore

#### Deployment Issues

1. Verify Kubernetes cluster connectivity
2. Check Helm chart syntax: `helm lint charts/your-service/`
3. Validate resource requirements and limits
4. Check namespace and RBAC permissions

#### Performance Problems

1. Monitor resource usage: `kubectl top pods`
2. Check application metrics and logs
3. Profile application performance
4. Review scaling configuration

### Getting Help

1. **Documentation**: Check application-specific README.md
2. **Logs**: Review application and container logs
3. **Community**: Consult project documentation and issues
4. **Support**: Contact the Edge AI team for assistance

## Examples and References

### Reference Applications

- **500-basic-inference**: Simple ML inference service
- **501-rust-telemetry**: Rust-based telemetry service
- **502-rust-http-connector**: HTTP connector implementation
- **503-media-capture-service**: Media capture and processing service

### Sample Templates

Reference the existing applications in `src/500-application/` for:

- Directory structure examples
- Docker and Docker Compose configurations
- Helm chart implementations
- Deployment script patterns

---

*This instruction guide is designed to provide comprehensive guidance for all application-related tasks in the Edge AI Accelerator project. Follow these guidelines to ensure consistency, maintainability, and successful deployment of your applications.*
