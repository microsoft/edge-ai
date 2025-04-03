# Application

This directory contains application projects that can be built and deployed to an edge or cloud based system. Every
application will have one or more services with a `Dockerfile` for each service that will be built and deployed into
an Azure Container Registry (ACR).

## Project Structure

Applications are organized using a numbered folder structure (`5xx-application-name`). The `500-basic-inference` project
serves as a reference implementation that you can examine for guidance.

## Adding a New Application

To add a new application to this repository, follow these guidelines:

### Naming Convention

1. Create a new directory with the naming pattern `5xx-your-application-name` where `xx` represents the next available
   number in sequence.

### Required Files and Directories

Your application should include the following structure:

```text
5xx-your-application-name/
├── README.md                  # Description of your application
├── Dockerfile                 # Only if you have a single service
├── docker-compose.yaml        # For building and running locally
├── charts/                    # Helm charts for deployment
├── docs/                      # Additional documentation
├── resources/                 # Configuration and additional resources
├── yaml/                      # Kubernetes manifests and other YAML files
└── services/                  # Multiple services (if applicable)
    ├── service1/
    │   └── Dockerfile
    ├── service2/
    │   └── Dockerfile
    └── ...
```

### Docker and Containerization

1. **Dockerfile**: Each application must contain at least one `Dockerfile` for building service images.
    - For a single-service application, place the `Dockerfile` at the root of your application directory.
    - For multi-service applications, place each `Dockerfile` within its respective service directory under `services/`.
    - **Use multi-stage builds where possible** to keep images small and secure. This approach separates the build
      environment from the runtime environment.

    Example of a multi-stage Dockerfile:

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

2. **docker-compose.yaml**: Include a `docker-compose.yaml` file at the root of your application for local development
   and testing. This should enable running your complete application with `docker compose up`.

### Testing

1. Tests should be executed as part of your Docker build process.
2. Include test execution in your `Dockerfile` using appropriate test commands.
3. Test results and outputs should be saved to `/test-results` within the container that's mapped to a `test-results`
   folder in your service folder. This path will be extracted by the build pipeline for reporting.

### Helm Charts

If your application requires Helm deployment:

1. Place all Helm charts in the `charts/` directory.
2. Each chart must follow standard Helm chart structure with a valid `Chart.yaml`.
3. The build pipeline will automatically find, package, and push these charts to the ACR.

### Documentation

1. Include a descriptive `README.md` at the root of your application folder explaining:
    - Purpose of the application
    - How to build and run it
    - Configuration options
    - Any dependencies

2. Place additional documentation in the `docs/` folder.

### Additional Resources

1. The `resources/` folder should contain any extra resources or configurations needed by your application.
   Example: `500-basic-inference` includes a `mosquitto.conf` file in its resources folder for running a local MQTT
   broker.

2. The `yaml/` folder should contain Kubernetes manifests and any additional YAML needed for deployment.

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
