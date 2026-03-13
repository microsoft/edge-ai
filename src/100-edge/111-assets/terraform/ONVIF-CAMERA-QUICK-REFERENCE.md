# ONVIF Camera Quick Reference

## Camera Inventory Example

| Camera    | IP            | Credentials Secret    | PTZ Capabilities |
|-----------|---------------|-----------------------|------------------|
| camera-01 | 192.168.1.100 | camera-01-credentials | Pan, Tilt        |
| camera-02 | 192.168.1.101 | camera-02-credentials | Pan, Tilt        |
| camera-03 | 192.168.1.102 | camera-03-credentials | Pan, Tilt, Zoom  |

## Quick Commands

### Deployment

```bash
# Deploy cameras
cd <path-to-repo>/src/100-edge/111-assets/terraform
terraform plan -var-file="<your-tfvars-file>.tfvars" -out=tfplan
terraform apply tfplan

# Verify deployment
az resource list --resource-group <your-resource-group> \
  --resource-type Microsoft.DeviceRegistry/namespaces/devices -o table
```

### Verification

```bash
# Check devices in cluster
kubectl get devices -n azure-iot-operations

# Check devices in Azure
az resource list --resource-group <your-resource-group> \
  --resource-type Microsoft.DeviceRegistry/namespaces/devices \
  --query "[].{name:name, provisioning:properties.provisioningState}" -o table

# Check assets in Azure
az resource list --resource-group <your-resource-group> \
  --resource-type Microsoft.DeviceRegistry/namespaces/assets \
  --query "[].{name:name, provisioning:properties.provisioningState}" -o table
```

### Monitoring

```bash
# ONVIF connector logs
kubectl logs -n azure-iot-operations -l app.kubernetes.io/component=connector --tail=100 -f

# Test camera connectivity
ping <camera-ip-1>
ping <camera-ip-2>
ping <camera-ip-3>
```

## PTZ Control via MQTT

### Example Camera Commands (Pan/Tilt)

```bash
# Pan left
mosquitto_pub -h <mqtt-broker> -t "cameras/<camera-name>/ptz/pan_left" -m "1"

# Pan right
mosquitto_pub -h <mqtt-broker> -t "cameras/<camera-name>/ptz/pan_right" -m "1"

# Tilt up
mosquitto_pub -h <mqtt-broker> -t "cameras/<camera-name>/ptz/tilt_up" -m "1"

# Tilt down
mosquitto_pub -h <mqtt-broker> -t "cameras/<camera-name>/ptz/tilt_down" -m "1"

# Stop
mosquitto_pub -h <mqtt-broker> -t "cameras/<camera-name>/ptz/stop" -m "1"
```

### Example Camera Commands (Pan/Tilt/Zoom)

```bash
# All Pan/Tilt commands plus:

# Zoom in
mosquitto_pub -h <mqtt-broker> -t "cameras/<camera-name>/ptz/zoom_in" -m "1"

# Zoom out
mosquitto_pub -h <mqtt-broker> -t "cameras/<camera-name>/ptz/zoom_out" -m "1"

# Return to home position
mosquitto_pub -h <mqtt-broker> -t "cameras/<camera-name>/ptz/go_home" -m "1"
```

## PTZ Data Point Configurations

### Pan Left

```json
{
  "pan_tilt": { "x": -0.5, "y": 0.0 },
  "zoom": { "x": 0.0 }
}
```

### Pan Right

```json
{
  "pan_tilt": { "x": 0.5, "y": 0.0 },
  "zoom": { "x": 0.0 }
}
```

### Tilt Up

```json
{
  "pan_tilt": { "x": 0.0, "y": 0.5 },
  "zoom": { "x": 0.0 }
}
```

### Tilt Down

```json
{
  "pan_tilt": { "x": 0.0, "y": -0.5 },
  "zoom": { "x": 0.0 }
}
```

### Zoom In (if supported)

```json
{
  "pan_tilt": { "x": 0.0, "y": 0.0 },
  "zoom": { "x": 0.5 }
}
```

### Zoom Out (if supported)

```json
{
  "pan_tilt": { "x": 0.0, "y": 0.0 },
  "zoom": { "x": -0.5 }
}
```

### Stop

```json
{
  "pan_tilt": { "x": 0.0, "y": 0.0 },
  "zoom": { "x": 0.0 }
}
```

## Troubleshooting

### Camera not responding

```bash
# 1. Test network connectivity
ping <camera-ip>

# 2. Test ONVIF endpoint
curl -X POST http://<camera-ip>/onvif/device_service \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Body><GetSystemDateAndTime xmlns="http://www.onvif.org/ver10/device/wsdl"/></s:Body></s:Envelope>'

# 3. Check credentials
kubectl get secret <camera-credentials-secret> -n azure-iot-operations -o yaml

# 4. Check device in Azure
az resource show \
  --ids /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.DeviceRegistry/namespaces/<namespace>/devices/<camera-device-name>
```

### Authentication errors

Verify credential format in tfvars:

```hcl
usernamePasswordCredentials = {
  usernameSecretName = "<secret-name>/username"  # Format: secretname/key
  passwordSecretName = "<secret-name>/password"
}
```

## Known Limitations

- **No Event Support:** API version `2025-10-01` doesn't support event assets
- **Motion Detection:** Must be implemented through alternative means
- **Tampering Detection:** Must be implemented through alternative means

## Resource ID Format Examples

### Subscription

```text
/subscriptions/<your-subscription-id>
```

### Resource Group

```text
/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>
```

### ADR Namespace

```text
/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.DeviceRegistry/namespaces/<namespace-name>
```

### Custom Location

```text
/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.ExtendedLocation/customLocations/<custom-location-name>
```

## Configuration Files

- **Main Configuration:** Create your own `.tfvars` file based on examples in the component documentation
- **Credentials:** Kubernetes secrets created manually or via deployment scripts
- **Documentation:** See [ONVIF-CAMERA-DEPLOYMENT.md](./ONVIF-CAMERA-DEPLOYMENT.md) for detailed guidance

## See Also

- [Full Documentation](./ONVIF-CAMERA-DEPLOYMENT.md) - Complete deployment guide
- [Component README](./README.md) - 111-assets component documentation
- [ONVIF Specifications](https://www.onvif.org/specs/core/ONVIF-Core-Specification.pdf)
