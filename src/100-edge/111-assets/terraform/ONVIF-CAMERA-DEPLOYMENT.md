# ONVIF Camera Deployment with Azure Device Registry

## Overview

This document describes the deploy      "camera-01-endpoint" = {
        endpoint_type = "Microsoft.Onvif"
        address       = "<http://192.168.1.100/onvif/device_service>"
        version       = "1.0"
        authentication = {of ONVIF cameras using Azure Device Registry namespaced devices and assets API. This deployment integrates Amcrest and Reolink PTZ cameras with Azure IoT Operations.

## Deployment Summary

**Deployment Date:** December 19, 2025
**API Version:** Microsoft.DeviceRegistry/namespaces/devices@2025-10-01
**Location:** eastus2
**Namespace:** `<namespace-name>`
**Custom Location:** `<custom-location-name>`

### Successfully Deployed Resources

#### Devices (3)

| Device Name     | IP Address    | Endpoint Name       | ONVIF Path            | Capabilities    |
|-----------------|---------------|---------------------|-----------------------|-----------------|
| `<camera-name-1>` | `<camera-ip-1>` | `<camera-endpoint-1>` | /onvif/device_service | Pan, Tilt       |
| `<camera-name-2>` | `<camera-ip-2>` | `<camera-endpoint-2>` | /onvif/device_service | Pan, Tilt       |
| `<camera-name-3>` | `<camera-ip-3>` | `<camera-endpoint-3>` | /onvif/device_service | Pan, Tilt, Zoom |

#### Assets (3)

| Asset Name              | Device Reference | Type        | Data Points |
|-------------------------|------------------|-------------|-------------|
| amcrest-01-ptz-commands | `<camera-name-1>`  | PTZ Control | 5           |
| amcrest-02-ptz-commands | `<camera-name-2>`  | PTZ Control | 5           |
| reolink-01-ptz-commands | `<camera-name-3>`  | PTZ Control | 8           |

### PTZ Data Points

**Amcrest Cameras (PT only):**

- pan_left
- pan_right
- tilt_up
- tilt_down
- stop

**Reolink Camera (PTZ):**

- pan_left
- pan_right
- tilt_up
- tilt_down
- zoom_in
- zoom_out
- go_home
- stop

## Authentication

Cameras use UsernamePassword authentication with credentials stored in Kubernetes secrets:

```yaml
# Secrets in azure-iot-operations namespace
- <camera-credentials-1>/username
- <camera-credentials-1>/password
- <camera-credentials-2>/username
- <camera-credentials-2>/password
- <camera-credentials-3>/username
- <camera-credentials-3>/password
```

**Secret Reference Format:** `{secret-name}/{key}`

## Deployment Configuration

### Terraform Variables File

Location: `src/100-edge/111-assets/terraform/onvif-cameras-fixed.tfvars`

Key configuration elements:

```hcl
location = "eastus2"

resource_group = {
  name = "<resource-group>"
  id   = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>"
}

adr_namespace = {
  id = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.DeviceRegistry/namespaces/`<namespace-name>`"
}

custom_location_id = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.ExtendedLocation/customLocations/`<custom-location-name>`"
```

### Device Definition Pattern

```hcl
{
  name    = "`<camera-name-1>`"
  enabled = true
  endpoints = {
    outbound = { assigned = {} }
    inbound = {
      "`<camera-endpoint-1>`" = {
        endpoint_type = "Microsoft.ONVIF"
        address       = "http://`<camera-ip-1>`/onvif/device_service"
        version       = "21.06"
        authentication = {
          method = "UsernamePassword"
          usernamePasswordCredentials = {
            usernameSecretName = "<camera-credentials-1>/username"
            passwordSecretName = "<camera-credentials-1>/password"
          }
        }
      }
    }
  }
}
```

### Asset Definition Pattern

```hcl
{
  name    = "amcrest-01-ptz-commands"
  enabled = true
  device_ref = {
    device_name   = "`<camera-name-1>`"
    endpoint_name = "`<camera-endpoint-1>`"
  }
  data_points = [
    {
      name                     = "pan_left"
      data_source              = "pan_left"
      capability_id            = "http://www.onvif.org/ver20/ptz/wsdl/ContinuousMove"
      observability_mode       = "none"
      data_point_configuration = jsonencode({
        pan_tilt = { x = -0.5, y = 0.0 }
        zoom     = { x = 0.0 }
      })
    }
    // Additional data points...
  ]
}
```

## Deployment Commands

```bash
# Navigate to component directory
cd ~/source/repos/edge-ai/src/100-edge/111-assets/terraform

# Initialize Terraform (if not already done)
terraform init

# Plan deployment
terraform plan -var-file="onvif-cameras-fixed.tfvars" -out=tfplan

# Apply deployment
terraform apply tfplan
```

## Known Limitations

### Event Assets Not Supported

**Issue:** API version `2025-10-01` does not support the `events` property on assets.

**Error:**

```text
ERROR CODE: HttpRequestPayloadAPISpecValidationFailed
Additional properties not allowed: events
```

**Impact:**

- Motion detection events cannot be configured through Device Registry API
- Tampering detection events cannot be configured through Device Registry API

**Attempted Configuration:**

```hcl
events = [{
  name = "camera_events"
  event_points = [{
    name                      = "motion_detected"
    event_notifier            = "motion"
    event_point_configuration = jsonencode({
      capability_id = "http://onvif.org/onvif/ver10/events/wsdl/EventsBinding/PullPointSubscription"
      topic         = "tns1:VideoAnalytics/MotionDetection"
    })
  }]
}]
```

## Workarounds for Event Monitoring

### Option 1: Direct ONVIF Event Subscription

Use the ONVIF connector or a custom application to subscribe directly to camera events:

```python
# Python example using onvif-zeep
from onvif import ONVIFCamera

camera = ONVIFCamera('`<camera-ip-1>`', 80, 'username', 'password')
event_service = camera.create_events_service()

# Subscribe to events
subscription = event_service.CreatePullPointSubscription()
```

### Option 2: ONVIF Connector Monitoring

Monitor ONVIF connector logs for event discovery:

```bash
kubectl logs -n azure-iot-operations -l app.kubernetes.io/component=connector --tail=100 -f
```

### Option 3: Application-Level Event Handling

Implement event detection in your application layer:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: camera-event-monitor
spec:
  template:
    spec:
      containers:
      - name: monitor
        image: your-event-monitor:latest
        env:
        - name: CAMERA_IPS
          value: "`<camera-ip-1>`,`<camera-ip-2>`,`<camera-ip-3>`"
```

### Option 4: Wait for API Update

Monitor Azure Device Registry API updates for future event support. Check for newer API versions:

```bash
az provider show --namespace Microsoft.DeviceRegistry \
  --query "resourceTypes[?resourceType=='namespaces/assets'].apiVersions" -o table
```

## Verification

### Check Device Status in Azure

```bash
# List all devices
az resource list --resource-group <resource-group> \
  --resource-type Microsoft.DeviceRegistry/namespaces/devices \
  --query "[].{name:name, provisioningState:properties.provisioningState}" -o table

# Get specific device details
az resource show \
  --ids /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.DeviceRegistry/namespaces/`<namespace-name>`/devices/`<camera-name-1>` \
  --query "{name:name, enabled:properties.enabled, provisioningState:properties.provisioningState}" -o json
```

### Check Asset Status in Azure

```bash
# List all assets
az resource list --resource-group <resource-group> \
  --resource-type Microsoft.DeviceRegistry/namespaces/assets \
  --query "[].{name:name, provisioningState:properties.provisioningState}" -o table

# Get specific asset details
az resource show \
  --ids /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.DeviceRegistry/namespaces/`<namespace-name>`/assets/amcrest-01-ptz-commands \
  --query "{name:name, enabled:properties.enabled, deviceRef:properties.deviceRef}" -o json
```

### Check Kubernetes Resources

From the K3s cluster (linux-edge-02):

```bash
# Check devices (shows namespaced devices synced to cluster)
kubectl get devices -n azure-iot-operations

# Check ONVIF connector status
kubectl get pods -n azure-iot-operations -l app.kubernetes.io/component=connector

# View ONVIF connector logs
kubectl logs -n azure-iot-operations -l app.kubernetes.io/component=connector --tail=100
```

**Note:** The `kubectl get assets` command shows legacy CRD-based assets. Namespaced assets created through the Device Registry API are managed in Azure, not as Kubernetes CRDs.

## Testing PTZ Commands

### Via MQTT

Publish to MQTT topics to control cameras:

```bash
# Pan left
mosquitto_pub -h <mqtt-broker> -t "cameras/amcrest-01/ptz/pan_left" -m "1"

# Tilt up
mosquitto_pub -h <mqtt-broker> -t "cameras/amcrest-01/ptz/tilt_up" -m "1"

# Stop movement
mosquitto_pub -h <mqtt-broker> -t "cameras/amcrest-01/ptz/stop" -m "1"

# Zoom in (Reolink only)
mosquitto_pub -h <mqtt-broker> -t "cameras/reolink-01/ptz/zoom_in" -m "1"
```

### Via Azure Portal

1. Navigate to Azure IoT Operations in Azure Portal
2. Select your IoT Hub
3. Browse to Device Registry > Namespaces > `<namespace-name>`
4. Select device > Assets > PTZ Commands
5. Use the portal interface to send commands

## Troubleshooting

### Device Creation Failed with Authentication Error

**Error:** `Invalid Host Authentication user name or password credentials`

**Solution:** Verify credential format uses `secretname/key` pattern:

```hcl
usernamePasswordCredentials = {
  usernameSecretName = "<camera-credentials-1>/username"  # NOT just "<camera-credentials-1>"
  passwordSecretName = "<camera-credentials-1>/password"
}
```

### Cameras Not Responding to PTZ Commands

**Possible Causes:**

1. Network connectivity issues (verify ping to camera IPs)
2. ONVIF service not running on cameras
3. Incorrect ONVIF endpoint path
4. Authentication failures

**Diagnostics:**

```bash
# Test network connectivity
ping `<camera-ip-1>`

# Test ONVIF endpoint
curl -X POST http://`<camera-ip-1>`/onvif/device_service \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Body><GetSystemDateAndTime xmlns="http://www.onvif.org/ver10/device/wsdl"/></s:Body></s:Envelope>'

# Check ONVIF connector logs
kubectl logs -n azure-iot-operations -l app.kubernetes.io/component=connector --tail=200
```

### Assets Not Appearing in Kubernetes

Namespaced assets ARE visible in Kubernetes using the correct API group. Use the full API group name:

```bash
# View namespaced assets
kubectl get assets.namespaces.deviceregistry.microsoft.com -n azure-iot-operations

# View namespaced devices
kubectl get devices.namespaces.deviceregistry.microsoft.com -n azure-iot-operations
```

You can also verify in Azure:

```bash
az resource list --resource-group <resource-group> \
  --resource-type Microsoft.DeviceRegistry/namespaces/assets -o table
```

## Architecture Notes

### Namespaced vs Legacy Assets

This deployment uses the **modern namespaced API** approach:

| Feature       | Namespaced API (Used Here) | Legacy CRD API                  |
|---------------|----------------------------|---------------------------------|
| API Type      | Azure Resource Manager     | Kubernetes CRD                  |
| Management    | Azure Portal + CLI         | kubectl                         |
| Version       | 2025-10-01                 | deviceregistry.microsoft.com/v1 |
| Scope         | Azure subscription         | Kubernetes namespace            |
| Event Support | Not yet (API limitation)   | Yes (via CRD)                   |

### Why Namespaced API?

- **Cloud-native management:** Resources managed through Azure ARM
- **Centralized visibility:** View/manage from Azure Portal
- **Better integration:** Native Azure RBAC and governance
- **Future-proof:** Microsoft's strategic direction for Device Registry

### When to Use Legacy API?

Use legacy CRD-based assets when:

- Event support is critical and cannot be worked around
- Air-gapped or edge-first scenarios
- Existing automation depends on kubectl-based workflows

## File References

**Configuration Files:**

- Main config: `src/100-edge/111-assets/terraform/onvif-cameras-fixed.tfvars`
- Credentials: `src/500-application/510-onvif-connector/credentials.yaml`
- Legacy YAML (reference): `src/500-application/510-onvif-connector/aep-*.yaml`

**Component Files:**

- Module: `src/100-edge/111-assets/terraform/`
- Variables: `src/100-edge/111-assets/terraform/variables.tf`
- Main: `src/100-edge/111-assets/terraform/main.tf`

## Next Steps

1. **Test PTZ Functionality**
   - Verify each camera responds to pan/tilt commands
   - Test zoom functionality on Reolink camera
   - Validate stop command halts movement

2. **Implement Event Monitoring**
   - Choose workaround approach (direct ONVIF, application-level, etc.)
   - Set up event logging/alerting
   - Create event-driven automation workflows

3. **Monitor API Updates**
   - Watch for Device Registry API updates supporting events
   - Test with preview API versions if available
   - Plan migration when events are supported

4. **Production Hardening**
   - Implement TLS/secure ONVIF endpoints
   - Add camera health monitoring
   - Set up alerting for camera connectivity issues
   - Document operational runbooks

## References

- [Azure Device Registry Documentation](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/overview-manage-assets)
- [ONVIF Specifications](https://www.onvif.org/specs/core/ONVIF-Core-Specification.pdf)
- [Azure IoT Operations](https://learn.microsoft.com/azure/iot-operations/)
- [Terraform azapi Provider](https://registry.terraform.io/providers/Azure/azapi/latest/docs)

## Support

For issues or questions:

- Azure Support: Create ticket through Azure Portal
- GitHub Issues: [microsoft/edge-ai](https://github.com/microsoft/edge-ai/issues)
- ONVIF Forum: [ONVIF Community](https://www.onvif.org/community/)
