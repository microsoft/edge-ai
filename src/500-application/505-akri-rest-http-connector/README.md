---
title: Akri REST HTTP Connector
description: Complete standalone development and demo environment for integrating REST/HTTP endpoints with Azure IoT Operations using the Akri connector framework
author: Edge AI Team
ms.date: 11/05/2025
ms.topic: reference
estimated_reading_time: 8
keywords:
  - azure iot operations
  - akri connector
  - rest http connector
  - device discovery
  - asset management
  - edge computing
  - docker compose
  - terraform
---

The Akri REST HTTP Connector provides a complete, standalone development and testing environment
for integrating REST/HTTP endpoints with Azure IoT Operations. This component demonstrates how to
use the Akri connector framework to discover, connect to, and manage REST/HTTP devices as assets
in the Azure IoT Operations ecosystem.

This application component provides two deployment modes:

1. **Local Development Environment**: Docker Compose setup for development, testing, and
   demonstration
2. **Production Deployment (Terraform)**: ⚠️ **RECOMMENDED** - Use Terraform-based deployment via
   blueprints (see [Production Deployment](#2-production-deployment-using-terraform) below)

The connector enables Azure IoT Operations to periodically perform GET requests to configured REST
endpoints and forward the retrieved data to destinations such as MQTT brokers or state stores.

> **💡 RECOMMENDED APPROACH**: For production deployments, use the Terraform-based configuration in
> the `full-single-node-cluster` blueprint with the `rest-connector-assets.tfvars.example` file as a
> reference for configuring your REST connector assets.

## Local Development Architecture

The Docker Compose environment simulates a complete Azure IoT Operations ecosystem:

- **MQTT Broker**: Local Mosquitto broker for message routing
- **Mock REST Endpoints**: Simulated weather stations, sensors, and authenticated devices
- **Connector Test Client**: Simulates the Akri REST connector behavior
- **MQTT Monitor**: Real-time message monitoring for debugging

## Azure IoT Operations Integration

For Azure IoT Operations deployments, the component uses:

- **Connector Templates**: Deployed via the `110-iot-ops` component's `akri-connectors` module
- **Asset Endpoint Profiles**: Kubernetes resources defining REST endpoint configurations
- **Asset Definitions**: Resources configuring data sources and destinations
- **Device Registry Integration**: Automatic asset registration with Azure Device Registry

## Deployment Prerequisites

### Local Development

- **Docker**: Version 20.10+ with Docker Compose support
- **curl**: For testing REST endpoints
- **mosquitto-clients** (optional): For MQTT testing with `mosquitto_sub`

### Azure IoT Operations Integration (Terraform - Recommended)

- **Blueprint Deployment**: Use `full-single-node-cluster` blueprint with REST connector variables
- **Terraform**: Version 1.9.8 or later
- **Azure Subscription**: Active subscription with appropriate permissions
- **Example Configuration**: Reference `blueprints/full-single-node-cluster/terraform/rest-connector-assets.tfvars.example`

## Quick Start

### 1. Local Development Environment Setup

Start the complete local development environment:

```bash
# Navigate to the component directory
cd src/500-application/505-akri-rest-http-connector

# Start all services
docker compose up -d

# View service status
docker compose ps

# View logs
docker compose logs -f

# Stop the environment
docker compose down
```

### 2. Production Deployment Using Terraform

**RECOMMENDED** - Deploy REST connector assets using Infrastructure as Code:

#### Setup Prerequisites

1. Deploy the `full-single-node-cluster` blueprint (or another blueprint with IoT Operations)
2. Ensure Docker Compose environment is running (for testing with mock endpoints)

#### Terraform Configuration

Create or modify `rest-connector-assets.tfvars` in the blueprint:

```bash
cd blueprints/full-single-node-cluster/terraform

# Copy example configuration
cp rest-connector-assets.tfvars.example rest-connector-assets.tfvars

# Edit configuration to match your endpoints
# For local testing with this Docker Compose environment:
# - weather-station: http://host.docker.internal:8080 (or VM IP)
# - sensor-simulator: http://host.docker.internal:8081
# - auth-device: http://host.docker.internal:8082
```

#### Deploy

```bash
# Preview changes
terraform plan -var-file="rest-connector-assets.tfvars"

# Apply configuration
terraform apply -var-file="rest-connector-assets.tfvars"
```

#### Verify

```bash
# Check deployed devices and assets
kubectl get devices,assets -n azure-iot-operations

# Monitor MQTT messages
kubectl exec -it mqtt-client -n azure-iot-operations -- \
  sh -c "mqttui -b mqtts://aio-broker.azure-iot-operations:18883 \
         -u 'K8S-SAT' \
         --password \$(cat /var/run/secrets/tokens/broker-sat) \
         --insecure"
```

**Configuration Reference**: See `blueprints/full-single-node-cluster/terraform/rest-connector-assets.tfvars.example`
for a complete example of all available configuration options.

## Field-Based API

The sensor-simulator now serves field-centric endpoints for retrieving individual field values or
collections in a single call. These routes back the connector test client and the new Helm chart.

### Endpoints

#### Get Single Field Value

```bash
curl http://localhost:8081/sensor/fields/temp-celsius-01
```

Response:

```json
{
   "field_id": "temp-celsius-01",
   "name": "Temperature Sensor 01 - Celsius",
   "data_type": "float",
   "value": 23.45,
   "units": "°C",
   "timestamp": "2025-11-05T14:30:45.123456Z",
   "quality": "good",
   "metadata": {
      "sensor_location": "Room A",
      "measurement_range": "15.0 to 35.0"
   }
}
```

#### Get Multiple Field Values

```bash
curl "http://localhost:8081/sensor/array/field?field_id=temp-celsius-01&field_id=humidity-pct-01"
```

#### List All Fields

```bash
curl http://localhost:8081/sensor/fields
```

#### Health Check

```bash
curl http://localhost:8081/health
```

## Configuring Dataset Assets for Sensor Simulator

When configuring assets in your `terraform.tfvars` or `rest-connector-assets.tfvars`, you can reference multiple sensor simulator fields in a single dataset by using the `/sensor/array/field` endpoint with multiple `field_id` query parameters.

### Dataset Configuration Example

```hcl
namespaced_assets = [
  {
    name         = "rest-http-simulator-asset"
    display_name = "REST HTTP Simulator Streams"
    enabled      = true
    device_ref = {
      device_name   = "rest-generic-sensor"
      endpoint_name = "generic-sensor-endpoint"
    }
    description   = "Asset definition for the REST HTTP simulator telemetry sources"
    manufacturer  = "SimTech"
    model         = "REST-SIM-500"
    serial_number = "RS-001"
    attributes = {
      assetId   = "rest-http-simulator-asset"
      assetType = "rest-http-simulator"
      location  = "Test Environment"
    }
    datasets = [
      // Dataset 1: Temperature, Humidity, Pressure - 5 second polling
      {
        name                  = "telemetry"
        data_source           = "/sensor/array/field?field_id=temp-celsius-01&field_id=humidity-pct-01&field_id=pressure-kpa-01"
        dataset_configuration = "{\"samplingIntervalInMilliseconds\":5000}"
        data_points           = []
        destinations = [
          {
            target = "Mqtt"
            configuration = {
              topic  = "rest-http-simulator/telemetry"
              retain = "Never"
              qos    = "Qos1"
            }
          }
        ]
      },
      // Dataset 2: Status and Alarm - 15 second polling
      {
        name                  = "status-alarms"
        data_source           = "/sensor/array/field?field_id=status-indicator-01&field_id=alarm-active-01"
        dataset_configuration = "{\"samplingIntervalInMilliseconds\":15000}"
        data_points           = []
        destinations = [
          {
            target = "Mqtt"
            configuration = {
              topic  = "rest-http-simulator/status-alarms"
              retain = "Never"
              qos    = "Qos1"
            }
          }
        ]
      }
    ]
    default_datasets_configuration = "{\"publishingInterval\":5000,\"samplingInterval\":5000,\"queueSize\":1}"
  }
]
```

### Key Configuration Points

- **data_source**: Use `/sensor/array/field?field_id=<id1>&field_id=<id2>` to retrieve multiple fields in one request
- **dataset_configuration**: Inline JSON string specifying `samplingIntervalInMilliseconds` for polling frequency
- **Multiple datasets**: You can define multiple datasets per asset, each with different field combinations and polling intervals
- **MQTT destinations**: Configure topic routing, QoS levels, and retention policies for each dataset

For a complete example, refer to `blueprints/full-single-node-cluster/terraform/rest-connector-assets.tfvars.example`.

## Field Configuration

Field metadata drives the simulator responses. By default, the container loads
`/app/field_sources.json`, which mirrors the file found at `resources/field_sources.json` in the
repository. Override the path by setting the `FIELD_CONFIG_PATH` environment variable.

### Field Configuration Schema

```json
{
   "fields": {
      "field-id": {
         "name": "Human-readable field name",
         "data_type": "float|integer|string|boolean",
         "units": "Measurement units",
         "min_value": 0.0,
         "max_value": 100.0,
         "string_options": ["OPTION1", "OPTION2"],
         "metadata": {
            "custom_key": "custom_value"
         }
      }
   },
   "simulator_metadata": {
      "device_id": "field-sensor-simulator-001",
      "version": "2.0.0",
      "description": "Field-based sensor data simulator"
   }
}
```

### Validation Rules

When configuring custom field sources, the following validation rules apply:

- **String type fields**: Must include `string_options` array with at least one option

  ```json
  {
    "data_type": "string",
    "string_options": ["OK", "WARNING", "ERROR"]  // Required for string type
  }
  ```

- **Numeric range validation**: If both `min_value` and `max_value` are provided, must satisfy `max_value >= min_value`

  ```json
  {
    "data_type": "float",
    "min_value": 15.0,
    "max_value": 35.0  // Must be >= min_value
  }
  ```

- **Data type constraints**:
  - `integer`: Generates random integers within specified range
  - `float`: Generates random floating-point values (rounded to 2 decimal places)
  - `string`: Randomly selects from `string_options` array
  - `boolean`: Randomly generates `true` or `false`

- **Optional fields**: `units`, `min_value`, `max_value`, `metadata` are all optional
- **Required fields**: `name` and `data_type` are required for all field configurations

### Custom Field Configuration Example

```json
{
   "fields": {
      "temp-celsius-01": {
         "name": "Temperature Sensor 01 - Celsius",
         "data_type": "float",
         "units": "degC",
         "min_value": 15.0,
         "max_value": 35.0,
         "metadata": {
            "sensor_location": "Room A",
            "measurement_type": "ambient_temperature"
         }
      },
      "status-indicator-01": {
         "name": "Device Status Indicator",
         "data_type": "string",
         "units": "",
         "string_options": ["OK", "WARNING", "ERROR", "OFFLINE", "MAINTENANCE"],
         "metadata": {
            "indicator_type": "device_health"
         }
      },
      "alarm-active-01": {
         "name": "High Temperature Alarm",
         "data_type": "boolean",
         "units": "",
         "metadata": {
            "alarm_threshold": "35 degC",
            "alarm_type": "temperature_high"
         }
      }
   }
}
```

Supported data types include floating-point, integer, string (requiring `string_options`), and
boolean values. Update `resources/field_sources.json` to customize existing entries or mount your
own file using Docker Compose or Kubernetes volumes.

## Helm Deployment

A dedicated Helm chart is available at `charts/sensor-simulator` for production deployments.

1. **Build and push the container image** to Azure Container Registry (ACR).
2. **Create an image pull secret** (for example, `acr-auth`) in the
    `azure-iot-operations` namespace.
3. **Install the chart**:

    ```bash
    cd src/500-application/505-akri-rest-http-connector/charts
    export ACR_NAME="your-acr"
    export IMAGE_TAG="1.0.0"

    helm install sensor-simulator ./sensor-simulator \
       --namespace azure-iot-operations \
       --create-namespace \
       --set image.repository="${ACR_NAME}.azurecr.io/sensor-simulator" \
       --set image.tag="${IMAGE_TAG}"
    ```

4. **Verify the deployment**:

    ```bash
    kubectl get pods -n azure-iot-operations -l app.kubernetes.io/name=sensor-simulator
    kubectl port-forward -n azure-iot-operations svc/sensor-simulator 8081:8081
    curl http://localhost:8081/health
    ```

Override `fieldConfig` values in `values.yaml` or via `--set-file`/`--values` during installation to
customize simulated fields. Configuration changes trigger a rollout through the embedded checksum
annotation on the ConfigMap.

## Development Workflow

### Local Testing and Development

1. **Start the environment:**

   ```bash
   cd src/500-application/505-akri-rest-http-connector
   docker compose up -d
   ```

2. **Test mock REST endpoints:**

   ```bash
   # Weather station (anonymous access)
   curl http://localhost:8080/api/weather

   # Sensor device - retrieve specific fields
   curl "http://localhost:8081/sensor/array/field?field_id=temp-celsius-01&field_id=humidity-pct-01"

   # Sensor device - list available fields
   curl http://localhost:8081/sensor/fields

   # Legacy endpoint (deprecated but available for testing)
   curl http://localhost:8081/api/sensor/data

   # Authenticated device (basic auth)
   curl -u deviceuser:devicepass123 http://localhost:8082/api/device/status
   ```

3. **Monitor MQTT messages:**

   ```bash
   # Using mosquitto client
   mosquitto_sub -h localhost -p 11883 -t "akri/#" -v

   # Or view container logs
   docker compose logs -f mqtt-monitor
   ```

4. **Customize configuration:**

   ```bash
   # Copy and edit environment file
   cp .env.example .env
   nano .env

   # Restart with new configuration
   docker compose down
   docker compose up -d
   ```

## Azure Integration Testing

1. **Verify prerequisites:**

   ```bash
   # Verify Azure login
   az account show

   # Verify kubectl connectivity
   kubectl cluster-info

   # Verify IoT Operations is deployed
   kubectl get connectortemplate -n azure-iot-operations
   ```

2. **Deploy assets using Terraform:**

   Deploy the REST connector assets using the blueprint's Terraform configuration as shown in
   the [Production Deployment](#2-production-deployment-using-terraform) section above.

3. **Monitor deployment:**

   ```bash
   # Check deployed devices and assets
   kubectl get devices,assets -n azure-iot-operations

   # Monitor connector pods
   kubectl get pods -n azure-iot-operations | grep rest-connector

   # View connector logs
   kubectl logs -f $(kubectl get pods -n azure-iot-operations -o name | grep rest-connector | head -1)
   ```

## Application Configuration

### Environment Variables

The local development environment supports customization through environment variables:

```bash
# MQTT Configuration
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=11883
MQTT_USERNAME=
MQTT_PASSWORD=

# REST Endpoint Configuration
WEATHER_STATION_PORT=8080
SENSOR_SIMULATOR_PORT=8081
AUTHENTICATED_DEVICE_PORT=8082

# Authentication
DEVICE_USERNAME=deviceuser
DEVICE_PASSWORD=devicepass123

# Polling Configuration
POLLING_INTERVAL_SECONDS=30
CONNECTION_TIMEOUT_SECONDS=10

# Topic Configuration
WEATHER_TOPIC=akri/weather-station-001/data
SENSOR_TOPIC=akri/sensor-001/data
DEVICE_TOPIC=akri/device-001/status
```

### Azure Deployment Configuration

Azure deployments are configured through Terraform variables in the blueprint. See
`blueprints/full-single-node-cluster/terraform/rest-connector-assets.tfvars.example` for a
complete reference of all available configuration options.

Key configuration includes:

- **Namespaced Devices**: Define REST endpoint URLs, authentication, and discovery settings
- **Namespaced Assets**: Define data collection, MQTT destinations, and sampling intervals
- **Blueprint Variables**: Control connector deployment and configuration

## Services Overview

### Local Development Services

| Service               | Port         | Description                          | Authentication |
|-----------------------|--------------|--------------------------------------|----------------|
| mosquitto-broker      | 11883, 19001 | MQTT broker for message routing      | None           |
| weather-station       | 8080         | Mock weather API endpoint            | Anonymous      |
| sensor-simulator      | 8081         | Field-based sensor simulation API    | Anonymous      |
| authenticated-device  | 8082         | Mock device with authentication      | Basic Auth     |
| connector-test-client | -            | Simulates Akri connector behavior    | -              |
| mqtt-monitor          | -            | Displays MQTT messages for debugging | -              |

### Data Flow

```text
REST Endpoints → Connector Test Client → MQTT Broker → MQTT Monitor
     ↑                                         ↓
Mock Devices                            Published Topics
(weather, sensor,                        (akri/*/data)
 authenticated)
```

## Testing and Validation

### Automated Testing

Test the local mock endpoints:

```bash
# Test specific endpoints
curl http://localhost:8080/api/weather | jq .
curl "http://localhost:8081/sensor/array/field?field_id=temp-celsius-01&field_id=humidity-pct-01" | jq .
curl -u deviceuser:devicepass123 http://localhost:8082/api/device/status | jq .
```

### Integration Testing

1. **REST Endpoint Validation:**
   - Verify all mock endpoints return valid JSON
   - Test authentication on protected endpoints
   - Validate response schemas

2. **MQTT Message Flow:**
   - Monitor MQTT topics for expected messages
   - Verify message format and content
   - Test message routing and topic naming

3. **Error Handling:**
   - Test with invalid credentials
   - Test with unreachable endpoints
   - Verify retry mechanisms

### Azure Deployment Validation

```bash
# Check deployed resources
kubectl get devices,assets,connectorinstances -n azure-iot-operations

# Monitor connector logs
kubectl logs -l app=rest-connector -n azure-iot-operations -f

# Test MQTT message flow in Azure
kubectl exec -it mqtt-client -n azure-iot-operations -- \
  mosquitto_sub -h aio-broker -t "akri/#" -v
```

## Troubleshooting

### Local Development Issues

1. **Port conflicts:**

   ```bash
   # Check if ports are in use
   netstat -tulpn | grep -E ':(8080|8081|8082|11883|19001)'

   # Stop conflicting services or modify .env file
   ```

2. **Container startup issues:**

   ```bash
   # Check service status
   docker compose ps

   # View detailed logs
   docker compose logs [service-name]

   # Recreate containers
   docker compose down
   docker compose up -d --force-recreate
   ```

3. **MQTT connectivity:**

   ```bash
   # Test MQTT broker directly
   mosquitto_pub -h localhost -p 11883 -t "test/topic" -m "test message"
   mosquitto_sub -h localhost -p 11883 -t "test/topic" -C 1
   ```

### Azure Deployment Issues

1. **Connector template not found:**

   ```bash
   # Verify IoT Operations includes REST connector support
   kubectl get connectortemplate -n azure-iot-operations

   # Deploy through 110-iot-ops component with should_enable_akri_rest_connector = true
   ```

2. **Asset creation failures:**

   ```bash
   # Check asset status
   kubectl describe asset rest-weather-sensor-asset -n azure-iot-operations

   # Verify device registry namespace
   az iot ops asset list --resource-group your-rg --device-registry your-registry
   ```

3. **Authentication issues:**

   ```bash
   # Verify Azure login and permissions
   az account show
   az role assignment list --assignee $(az account show --query user.name -o tsv)

   # Check kubectl access
   kubectl auth can-i create assets -n azure-iot-operations
   ```

## Architecture Integration

This component integrates with the broader edge-ai project architecture:

- **Infrastructure Foundation**: Uses the `akri-connectors` module from `src/100-edge/110-iot-ops`
- **Blueprint Integration**: Can be included in blueprints like `full-single-node-cluster`
- **Asset Management**: Works with `src/100-edge/111-assets` for device discovery
- **Application Layer**: Part of the `500-application` workload components

## Development Guidelines

### Adding New Mock Endpoints

1. Create new service in `services/` directory
2. Add service to `docker-compose.yml`
3. Update environment variables in `.env.example`
4. Update documentation

### Customizing for Different REST APIs

1. Modify endpoint URLs in device definitions
2. Update authentication methods as needed
3. Adjust polling intervals and timeout values
4. Customize MQTT topic structures
5. Update asset metadata and schemas

## Advanced Usage

### Custom REST Endpoints

Configure custom REST endpoints in your `rest-connector-assets.tfvars` file:

```hcl
namespaced_devices = {
  "weather-api" = {
    endpoint_url          = "https://api.weather.gov/stations/KORD/observations/latest"
    authentication_method = "Anonymous"
  }
  # Add more devices as needed
}
```

Then deploy using Terraform as shown in the
[Production Deployment](#2-production-deployment-using-terraform) section.

### Multiple Environment Management

Use different environment files for local development:

```bash
# Development environment
cp .env.dev .env
docker compose up -d

# Testing environment
cp .env.test .env
docker compose up -d

# Production environment
cp .env.prod .env
docker compose up -d
```

### Integration with CI/CD

The component can be integrated into CI/CD pipelines:

```bash
# In CI pipeline - test local mock services
docker compose up -d
docker compose ps
curl http://localhost:8080/api/weather
docker compose down
```

## Next Steps

- **Explore Integration**: See how this component integrates with IoT Operations in
  `src/100-edge/110-iot-ops`
- **Deploy Complete Solutions**: Use blueprints like `full-single-node-cluster` for end-to-end
  deployments
- **Custom Connectors**: Use this as a template for building other Akri connectors
- **Production Deployment**: Integrate with your Azure IoT Operations clusters using Terraform

## Security Considerations

- Use HTTPS for production REST endpoints
- Implement proper certificate validation
- Secure authentication credentials using Azure Key Vault references
- Follow Azure security best practices
- Regular monitoring and access review
- Use managed identities where possible

## Contributing

When contributing to this component:

1. Follow the established Terraform module structure
2. Update documentation for any configuration changes
3. Test with different authentication methods
4. Validate against Azure IoT Operations compatibility
5. Include example configurations for new features

## Support

For issues and questions:

- Check the troubleshooting section above
- Review `blueprints/full-single-node-cluster/terraform/rest-connector-assets.tfvars.example`
  for configuration reference
- Review Azure IoT Operations documentation
- File issues in the project repository
- Contact the Edge AI team for component-specific questions

---

*AI and automation capabilities described in this component should be implemented following
responsible AI principles, including fairness, reliability, safety, privacy, inclusiveness,
transparency, and accountability. Organizations should ensure appropriate governance, monitoring,
and human oversight are in place for all AI-powered solutions.*

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
