# Docker Compose Development Environment

This docker-compose.yml provides a complete development and testing environment for the Akri REST HTTP Connector component.

## Services Overview

### Core Infrastructure

- **mosquitto-broker**: Local MQTT broker for message routing and testing
  - Ports: 1883 (MQTT), 9001 (WebSockets)
  - Configuration: `resources/mosquitto.conf`

### Mock REST Endpoints

- **weather-station**: Simulates a weather station REST API
  - Port: 8080
  - Endpoints: `/api/weather`, `/api/weather/history`, `/health`
  - Authentication: None (anonymous access)

- **sensor-simulator**: Simulates a generic temperature/humidity sensor
  - Port: 8081
  - Endpoints: `/api/sensor/data`, `/api/sensor/status`, `/health`
  - Authentication: None (anonymous access)

- **authenticated-device**: Simulates a device requiring HTTP Basic Authentication
  - Port: 8082
  - Endpoints: `/api/device/status`, `/api/device/config`, `/health`
  - Authentication: Basic HTTP (deviceuser:devicepass123)

### Test Services

- **connector-test-client**: Simulates Akri REST connector behavior
  - Polls all REST endpoints periodically
  - Publishes data to MQTT topics
  - Demonstrates authentication and error handling
  - No exposed ports (internal service)

- **mqtt-monitor**: Subscribes to MQTT topics for debugging
  - Monitors all `akri/#` topics
  - Displays received messages in container logs
  - No exposed ports (internal service)

## Quick Start

1. **Start all services:**

   ```bash
   docker compose up -d
   ```

2. **View logs:**

   ```bash
   # All services
   docker-compose logs -f

   # Specific service
   docker-compose logs -f connector-test-client
   docker-compose logs -f mqtt-monitor
   ```

3. **Test REST endpoints:**

   ```bash
   # Weather station (no auth)
   curl http://localhost:8080/api/weather

   # Sensor device (no auth)
   curl http://localhost:8081/api/sensor/data

   # Authenticated device (basic auth required)
   curl -u deviceuser:devicepass123 http://localhost:8082/api/device/status
   ```

4. **Monitor MQTT messages:**

   ```bash
   # Using mosquitto client tools
   mosquitto_sub -h localhost -t "akri/#" -v

   # Or view mqtt-monitor service logs
   docker-compose logs -f mqtt-monitor
   ```

## Development Workflow

### Testing Connector Logic

The `connector-test-client` service demonstrates how the actual Akri REST connector would:

1. **Poll REST endpoints** at configured intervals
2. **Handle authentication** (none, basic HTTP, certificates)
3. **Publish data to MQTT** with proper formatting
4. **Handle errors** with retry logic and error reporting
5. **Add metadata** about collection time and connector info

### Adding New Endpoints

1. Create a new service directory under `services/`
2. Add Dockerfile and application code
3. Add service definition to docker-compose.yml
4. Update connector-test-client to poll the new endpoint
5. Test the integration

### Customizing Configuration

Key environment variables in docker-compose.yml:

- **Polling intervals**: `POLLING_INTERVAL_SECONDS`
- **Authentication**: `AUTH_USERNAME`, `AUTH_PASSWORD`
- **MQTT topics**: `WEATHER_TOPIC`, `SENSOR_TOPIC`, etc.
- **Retry behavior**: `RETRY_ATTEMPTS`, `RETRY_DELAY_SECONDS`

## MQTT Topic Structure

The connector publishes data to structured topics:

- `akri/weather-station-001/data` - Weather data
- `akri/generic-sensor-001/data` - Sensor readings
- `akri/auth-device-001/status` - Authenticated device status
- `akri/errors` - Error messages and retry information

## Data Formats

All REST endpoints return JSON data with:

- Timestamp in ISO format
- Device identification
- Measurement data
- Status and metadata information
- Connector-added metadata (collection time, etc.)

## Health Checks

All services include health checks:

- REST endpoints: HTTP GET to `/health`
- MQTT broker: Connection and subscription test
- Test client: Internal connection monitoring

## Troubleshooting

### Common Issues

1. **Services not starting:**

   ```bash
   docker-compose down -v
   docker-compose build --no-cache
   docker-compose up -d
   ```

2. **MQTT connection failures:**
   - Check mosquitto-broker logs
   - Verify network connectivity
   - Check firewall/port bindings

3. **Authentication errors:**
   - Verify credentials: `deviceuser:devicepass123`
   - Check service logs for auth failures

4. **No data in MQTT topics:**
   - Check connector-test-client logs
   - Verify REST endpoints are healthy
   - Check MQTT connection status

### Viewing Service Status

```bash
# Check all service health
docker-compose ps

# Check specific service logs
docker-compose logs -f [service-name]

# Execute commands in running containers
docker-compose exec connector-test-client /bin/bash
```

## Integration with Real Akri Connector

This development environment simulates the behavior of the actual Akri REST HTTP Connector. The real connector would:

1. Use Kubernetes CRDs for configuration (ConnectorTemplate, Device, Asset)
2. Connect to Azure IoT Operations MQTT broker
3. Integrate with Azure Device Registry for schema registration
4. Support x.509 certificate authentication
5. Provide OpenTelemetry metrics and monitoring

The mock services and test client help validate the REST endpoint integration patterns before deploying to a real Azure IoT Operations environment.

## Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (clears MQTT persistence)
docker-compose down -v

# Stop and remove images
docker-compose down --rmi all
```
