---
title: MQTT Tools (900-mqtt-tools)
description: MQTT client tools and utilities for testing and monitoring MQTT communications in Azure IoT Operations
author: Edge AI Platform Team
ms.date: 2025-01-15
keywords: mqtt, testing, monitoring, azure-iot-operations, mosquitto, mqttui
estimated_reading_time: 5 minutes
---

Welcome to the MQTT Tools component. This component provides MQTT client tools and utilities for debugging, testing, and monitoring MQTT communications in Azure IoT Operations environments.

## Overview

The 900-mqtt-tools component deploys a Kubernetes pod containing MQTT client tools including mosquitto-clients and mqttui for interacting with MQTT brokers in Azure IoT Operations. This toolset enables developers and operators to test MQTT connections, publish/subscribe to topics, and monitor MQTT traffic.

## Component Architecture

### Tools Included

- **mosquitto-clients**: Command-line MQTT client tools (mosquitto_pub, mosquitto_sub)
- **mqttui**: Interactive TUI (Terminal User Interface) for MQTT operations
- **Alpine Linux**: Lightweight container base with shell access

### Authentication Support

- **Service Account Token Authentication**: Uses Kubernetes service account tokens for AIO MQTT broker authentication
- **Trust Bundle Integration**: Includes Azure IoT Operations root CA certificate trust bundle
- **Audience Configuration**: Configured for `aio-internal` audience matching BrokerAuthentication

## Files and Resources

### YAML Manifests

| File                                               | Description                                       |
|----------------------------------------------------|---------------------------------------------------|
| **[yaml/mqtt-tools.yaml](./yaml/mqtt-tools.yaml)** | Kubernetes deployment manifest for MQTT tools pod |

### Kubernetes Resources

- **ServiceAccount**: `mqtt-tools` in `azure-iot-operations` namespace
- **Deployment**: Single replica pod with mosquitto-clients and mqttui
- **Volumes**: Service account token projection and trust bundle configuration

## Quick Start

### Deploy MQTT Tools

```bash
# Apply the MQTT tools deployment
kubectl apply -f yaml/mqtt-tools.yaml

# Verify deployment
kubectl get pods -n azure-iot-operations -l app=mqtt-tools
```

### Connect to Tools Pod

```bash
# Connect to the MQTT tools pod
kubectl exec -it deployment/mqtt-tools -n azure-iot-operations -- sh

# Test MQTT connection (inside pod)
mosquitto_sub -h aio-broker -t "test/topic" --cafile /var/run/certs/ca.crt \
  -D CONNECT authentication-method 'K8S-SAT' \
  -D CONNECT authentication-data $(cat /var/run/secrets/tokens/broker-sat)
```

### Interactive MQTT Monitoring

```bash
# Launch mqttui for interactive monitoring
mqttui -h aio-broker --ca-file /var/run/certs/ca.crt \
  --auth-method 'K8S-SAT' \
  --auth-data $(cat /var/run/secrets/tokens/broker-sat)
```

## Usage Examples

### Publishing Messages

```bash
# Publish a test message
mosquitto_pub -h aio-broker -t "industrial/sensor/temperature" \
  -m '{"value": 25.5, "unit": "celsius", "timestamp": "2025-01-15T10:30:00Z"}' \
  --cafile /var/run/certs/ca.crt \
  -D CONNECT authentication-method 'K8S-SAT' \
  -D CONNECT authentication-data $(cat /var/run/secrets/tokens/broker-sat)
```

### Subscribing to Topics

```bash
# Subscribe to sensor data
mosquitto_sub -h aio-broker -t "industrial/+/temperature" \
  --cafile /var/run/certs/ca.crt \
  -D CONNECT authentication-method 'K8S-SAT' \
  -D CONNECT authentication-data $(cat /var/run/secrets/tokens/broker-sat)
```

### Monitoring Multiple Topics

```bash
# Monitor all industrial topics with timestamps
mosquitto_sub -h aio-broker -t "industrial/#" -F "@Y-@m-@d @H:@M:@S %t %p" \
  --cafile /var/run/certs/ca.crt \
  -D CONNECT authentication-method 'K8S-SAT' \
  -D CONNECT authentication-data $(cat /var/run/secrets/tokens/broker-sat)
```

## Configuration Details

### Authentication Configuration

The MQTT tools are configured for Azure IoT Operations authentication:

- **Audience**: `aio-internal` (matches BrokerAuthentication configuration)
- **Token Path**: `/var/run/secrets/tokens/broker-sat`
- **CA Certificate**: `/var/run/certs/ca.crt`
- **Token Expiration**: 86400 seconds (24 hours)

### Volume Mounts

- **Service Account Token**: Projected volume with broker service account token
- **Trust Bundle**: ConfigMap volume with Azure IoT Operations root CA certificate

## Troubleshooting

### Common Issues

1. **Connection Refused**
   - Verify MQTT broker is running: `kubectl get pods -n azure-iot-operations`
   - Check broker service: `kubectl get svc -n azure-iot-operations`

2. **Authentication Failed**
   - Verify service account token: `cat /var/run/secrets/tokens/broker-sat`
   - Check BrokerAuthentication configuration audience matches `aio-internal`

3. **Certificate Errors**
   - Verify trust bundle: `ls -la /var/run/certs/`
   - Check ca.crt file exists and is readable

### Debug Commands

```bash
# Check pod status
kubectl describe pod -n azure-iot-operations -l app=mqtt-tools

# View pod logs
kubectl logs -n azure-iot-operations -l app=mqtt-tools

# Test network connectivity
kubectl exec -it deployment/mqtt-tools -n azure-iot-operations -- nslookup aio-broker
```

## Related Components

- **[Azure Resource Providers](../azure-resource-providers/README.md)**: Azure resource management
- **[IoT Operations (110-iot-ops)](../100-edge/110-iot-ops/README.md)**: Azure IoT Operations deployment

## Support

For questions or issues with the MQTT tools component:

1. Check the [troubleshooting section](#troubleshooting) above
2. Review Azure IoT Operations MQTT broker documentation
3. Verify authentication and network configuration

---

<!-- markdownlint-disable MD036 -->
*🔧 This component provides essential MQTT testing and monitoring capabilities for Azure IoT Operations environments. Use responsibly and follow security best practices.*
<!-- markdownlint-enable MD036 -->
