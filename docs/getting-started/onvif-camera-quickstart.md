---
title: ONVIF Camera Deployment Guide
description: Deploy any ONVIF-compatible camera to Azure IoT Operations using the Device Registry component with Bicep, Terraform, or automated scripts
author: Edge AI Team
ms.date: 2026-03-13
ms.topic: quickstart
estimated_reading_time: 15
keywords:
  - onvif
  - camera
  - ptz
  - device-registry
  - azure-iot-operations
  - quickstart
---

## ONVIF Camera Deployment Guide

Deploy any ONVIF-compatible camera to Azure IoT Operations using the 111-assets component. This guide covers device registration, credential management, and PTZ control configuration.

## Prerequisites

- Azure IoT Operations deployed and running on your cluster
- ONVIF Connector installed (part of Azure IoT Operations)
- Camera accessible on your network with known IP address
- Camera credentials (username and password)
- Azure CLI installed with `az` command available
- `kubectl` access to your Kubernetes cluster

## Step 1: Enable and Verify ONVIF on Your Camera

Many cameras ship with ONVIF disabled. Enable it before proceeding.

1. Access your camera's web interface at `http://<camera-ip>`
2. Navigate to ONVIF settings (typically under Settings > Network > Advanced > ONVIF)
3. Enable ONVIF service, set authentication to **Digest**, and save
4. Reboot the camera if required and wait 60-90 seconds

Verify the ONVIF endpoint responds:

```bash
curl -X POST http://<camera-ip>/onvif/device_service \
  -H "Content-Type: application/soap+xml" \
  --max-time 10 \
  -d '<?xml version="1.0" encoding="UTF-8"?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Body><GetSystemDateAndTime xmlns="http://www.onvif.org/ver10/device/wsdl"/></s:Body></s:Envelope>'
```

A successful response includes `GetSystemDateAndTimeResponse`. Common errors:

| Error                         | Meaning                            | Solution                        |
|-------------------------------|------------------------------------|---------------------------------|
| `Data required for operation` | ONVIF disabled                     | Enable ONVIF in camera settings |
| `Connection refused`          | Wrong port or service not running  | Try ports 80, 8000, 8080        |
| `Connection timeout`          | Firewall or wrong IP               | Check network connectivity      |
| `401 Unauthorized`            | Auth required (service IS enabled) | Proceed to Step 2               |

## Step 2: Gather Camera Information

| Item        | Description           | Example                 |
|-------------|-----------------------|-------------------------|
| Camera IP   | Network IP address    | `<camera-ip>`           |
| ONVIF Port  | Usually 80 or 8000    | `80`                    |
| ONVIF Path  | Service endpoint path | `/onvif/device_service` |
| Username    | Camera admin username | `admin`                 |
| Password    | Camera admin password | (your password)         |
| Camera Name | Unique identifier     | `camera-01`             |

### Determine PTZ Capabilities

Check your camera's web interface or documentation for PTZ support:

| Camera Type      | Capabilities           | Notes                    |
|------------------|------------------------|--------------------------|
| Fixed            | None                   | Basic IP cameras         |
| Pan/Tilt (PT)    | Pan, Tilt, Stop        | Many indoor cameras      |
| PTZ              | Pan, Tilt, Zoom, Home  | PTZ-capable models       |
| PTZ with Presets | PTZ + Preset positions | Professional PTZ cameras |

## Step 3: Create Kubernetes Secrets

Encode your credentials and create a Kubernetes secret:

```bash
kubectl create secret generic <camera-name>-credentials \
  -n azure-iot-operations \
  --from-literal=username='<camera-username>' \
  --from-literal=password='<camera-password>'
```

Verify:

```bash
kubectl get secret <camera-name>-credentials -n azure-iot-operations
```

## Step 4: Deploy

Choose one of three deployment methods.

### Option A: Automated Scripts (Recommended)

Interactive scripts that handle secrets, configuration, and deployment:

```bash
cd src/100-edge/111-assets/scripts

# Terraform deployment
./deploy-onvif-camera-terraform.sh

# Bicep deployment
./deploy-onvif-camera-bicep.sh
```

The scripts prompt for camera details, test ONVIF connectivity, discover Azure resources, generate configuration, and deploy with verification.

See [scripts/README.md](../../src/100-edge/111-assets/scripts/README.md) for usage details.

### Option B: Bicep

Create `camera-deployment.bicepparam`:

```bicep
using './main.bicep'

param common = {
  environment: 'dev'
  location: 'eastus2'
  resource: 'camera'
  instance: '001'
}

param customLocationId = '<custom-location-resource-id>'
param adrNamespaceName = '<adr-namespace-name>'

param namespacedDevices = [
  {
    name: '<camera-name>'
    isEnabled: true
    endpoints: {
      outbound: { assigned: {} }
      inbound: {
        '<camera-name>-endpoint': {
          endpointType: 'Microsoft.Onvif'
          address: 'http://<camera-ip>/onvif/device_service'
          version: '1.0'
          authentication: {
            method: 'UsernamePassword'
            usernamePasswordCredentials: {
              usernameSecretName: '<camera-name>-credentials/username'
              passwordSecretName: '<camera-name>-credentials/password'
            }
          }
        }
      }
    }
  }
]
```

Deploy:

```bash
cd src/100-edge/111-assets/bicep
az deployment group create \
  --resource-group <resource-group> \
  --template-file main.bicep \
  --parameters camera-deployment.bicepparam
```

### Option C: Terraform

Create `camera-deployment.tfvars`:

```hcl
location = "eastus2"

resource_group = {
  name = "<resource-group>"
  id   = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>"
}

adr_namespace = {
  id = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.DeviceRegistry/namespaces/<namespace>"
}

custom_location_id = "<custom-location-resource-id>"

namespaced_devices = [
  {
    name    = "<camera-name>"
    enabled = true
    endpoints = {
      outbound = { assigned = {} }
      inbound = {
        "<camera-name>-endpoint" = {
          endpoint_type = "Microsoft.Onvif"
          address       = "http://<camera-ip>/onvif/device_service"
          version       = "1.0"
          authentication = {
            method = "UsernamePassword"
            usernamePasswordCredentials = {
              usernameSecretName = "<camera-name>-credentials/username"
              passwordSecretName = "<camera-name>-credentials/password"
            }
          }
        }
      }
    }
  }
]
```

Deploy:

```bash
cd src/100-edge/111-assets/terraform
terraform init
terraform plan -var-file="camera-deployment.tfvars" -out=tfplan
terraform apply tfplan
```

### Get Required Azure Resource IDs

```bash
az account show --query id -o tsv
az group show --name <resource-group> --query id -o tsv
az customlocation show --name <custom-location> --resource-group <resource-group> --query id -o tsv
az resource list --resource-type Microsoft.DeviceRegistry/namespaces --query "[0].name" -o tsv
```

## Step 5: Verify Deployment

```bash
# Devices in Azure
az resource list --resource-group <resource-group> \
  --resource-type Microsoft.DeviceRegistry/namespaces/devices \
  --query "[].{name:name, provisioning:properties.provisioningState}" -o table

# Devices in Kubernetes
kubectl get devices.namespaces.deviceregistry.microsoft.com -n azure-iot-operations

# Assets in Kubernetes
kubectl get assets.namespaces.deviceregistry.microsoft.com -n azure-iot-operations

# ONVIF connector logs
kubectl logs -n azure-iot-operations -l app.kubernetes.io/component=connector --tail=100 -f
```

## Step 6: Configure PTZ Control

PTZ control uses **managementGroups** with the MRPC protocol. Add this to your asset configuration:

### Bicep managementGroups

```bicep
param namespacedAssets = [
  {
    name: '<camera-name>-ptz'
    isEnabled: true
    deviceRef: {
      deviceName: '<camera-name>'
      endpointName: '<camera-name>-endpoint'
    }
    managementGroups: [
      {
        name: 'ptz'
        actions: [
          { name: 'RelativeMove', actionType: 'Call', targetUri: 'dtmi:onvif:ptz:RelativeMove;1' }
          { name: 'ContinuousMove', actionType: 'Call', targetUri: 'dtmi:onvif:ptz:ContinuousMove;1' }
          { name: 'Stop', actionType: 'Call', targetUri: 'dtmi:onvif:ptz:Stop;1' }
          { name: 'GotoHomePosition', actionType: 'Call', targetUri: 'dtmi:onvif:ptz:GotoHomePosition;1' }
          { name: 'GotoPreset', actionType: 'Call', targetUri: 'dtmi:onvif:ptz:GotoPreset;1' }
        ]
      }
    ]
  }
]
```

### Terraform management_groups

```hcl
namespaced_assets = [
  {
    name    = "<camera-name>-ptz"
    enabled = true
    device_ref = {
      device_name   = "<camera-name>"
      endpoint_name = "<camera-name>-endpoint"
    }
    management_groups = [
      {
        name = "ptz"
        actions = [
          { name = "RelativeMove",    action_type = "Call", target_uri = "dtmi:onvif:ptz:RelativeMove;1" },
          { name = "ContinuousMove",  action_type = "Call", target_uri = "dtmi:onvif:ptz:ContinuousMove;1" },
          { name = "Stop",            action_type = "Call", target_uri = "dtmi:onvif:ptz:Stop;1" },
          { name = "GotoHomePosition", action_type = "Call", target_uri = "dtmi:onvif:ptz:GotoHomePosition;1" },
          { name = "GotoPreset",      action_type = "Call", target_uri = "dtmi:onvif:ptz:GotoPreset;1" }
        ]
      }
    ]
  }
]
```

### MRPC Protocol

PTZ commands use the MRPC (Message-based RPC) protocol over MQTT:

- **Topic pattern**: `{namespace}/mrpc/{asset}/{commandName}`
- **Example**: `azure-iot-operations/mrpc/camera-01-ptz/RelativeMove`

The connector logs `Asset Endpoint is not being observed` for PTZ-only assets (with only `management_groups`). This is expected behavior.

For PTZ testing, use the [Azure Samples PTZ Demo](https://github.com/Azure-Samples/explore-iot-operations/tree/main/samples/aio-onvif-connector-ptz-demo) or direct ONVIF SOAP commands.

### Direct ONVIF PTZ Testing

Test PTZ independently of Azure IoT Operations:

```bash
curl -X POST "http://<camera-ip>/onvif/ptz_service" \
  --anyauth --user "<username>:<password>" \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">
  <s:Body>
    <ContinuousMove xmlns="http://www.onvif.org/ver20/ptz/wsdl">
      <ProfileToken>000</ProfileToken>
      <Velocity>
        <PanTilt x="0.0" y="0.5" xmlns="http://www.onvif.org/ver10/schema"/>
        <Zoom x="0.0" xmlns="http://www.onvif.org/ver10/schema"/>
      </Velocity>
    </ContinuousMove>
  </s:Body>
</s:Envelope>'
```

## Troubleshooting

### Camera Not Responding

1. Verify network: `ping <camera-ip>`
2. Test ONVIF endpoint with curl (see Step 1)
3. Check credentials: `kubectl get secret <camera-name>-credentials -n azure-iot-operations -o jsonpath='{.data.username}' | base64 -d`

### ONVIF Service Disabled

Error: `Data required for operation`

Enable ONVIF in camera web interface under Settings > Network > Advanced > ONVIF. Save and reboot.

### Authentication Errors

- Verify secret exists in `azure-iot-operations` namespace
- Check credential encoding has no trailing newlines
- Confirm the camera user has ONVIF permissions
- Use secret reference format: `<secret-name>/<key>`

### PTZ Commands Not Working

- Verify camera supports PTZ (check specs)
- Use Operations Experience UI for PTZ configuration and testing
- Test direct ONVIF SOAP commands to confirm camera PTZ works
- Check connector logs: `kubectl logs -n azure-iot-operations -l app.kubernetes.io/component=connector --tail=500`

### Device Not Showing in Kubernetes

Use the correct API group:

```bash
kubectl get devices.namespaces.deviceregistry.microsoft.com -n azure-iot-operations
kubectl get assets.namespaces.deviceregistry.microsoft.com -n azure-iot-operations
```

## Additional Resources

- [ONVIF Specifications](https://www.onvif.org/specs/core/ONVIF-Core-Specification.pdf)
- [Azure IoT Operations Documentation](https://learn.microsoft.com/azure/iot-operations/)
- [Manage Assets in Azure IoT Operations](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/overview-manage-assets)
- [PTZ Demo Sample](https://github.com/Azure-Samples/explore-iot-operations/tree/main/samples/aio-onvif-connector-ptz-demo)
