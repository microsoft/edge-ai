# ONVIF Camera Quick Start Deployment Guide

This guide helps you deploy **any ONVIF-compatible camera** to Azure IoT Operations using the Device Registry component. Whether you have Amcrest, Reolink, Hikvision, Dahua, or any other ONVIF camera, this guide will work.

## Prerequisites

Before starting, ensure you have:

- ✅ **Azure IoT Operations** deployed and running on your cluster
- ✅ **ONVIF Connector** installed (part of Azure IoT Operations)
- ✅ **Camera accessible** on your network with known IP address
- ✅ **Camera credentials** (username and password)
- ✅ **ONVIF service enabled** on your camera (see Step 1A below)
- ✅ **Azure CLI** installed with `az` command available
- ✅ **kubectl** access to your Kubernetes cluster

## Step 1: Gather Camera Information

### Step 1A: Enable ONVIF Service (Critical)

⚠️ **IMPORTANT**: Many cameras have ONVIF disabled by default. You MUST enable it before proceeding.

#### Enable ONVIF on Your Camera

1. **Access Camera Web Interface**
   - Open browser: `http://YOUR-CAMERA-IP`
   - Login with admin credentials

2. **Navigate to ONVIF Settings**
   - Common paths:
     - Settings → Network → Advanced → ONVIF
     - Settings → Network → Port → ONVIF
     - Network → Integration → ONVIF
     - System → Network Services → ONVIF

3. **Enable ONVIF Service**
   - ☑️ Enable ONVIF (toggle to ON)
   - ☑️ Set Authentication to **Digest** or **Username/Password**
   - ☑️ Set Port (usually 80, 8000, or 8080)
   - ☑️ Click **Save** or **Apply**

4. **Verify User Permissions**
   - Ensure ONVIF user has appropriate permissions
   - Some cameras require "Administrator" role for ONVIF access

5. **Reboot Camera** (if required)
   - Some cameras require reboot after enabling ONVIF
   - Wait 60-90 seconds for full startup

#### Verify ONVIF is Working

Test your camera's ONVIF endpoint:

```bash
# Test ONVIF endpoint (replace with your camera IP)
curl -X POST http://YOUR-CAMERA-IP/onvif/device_service \
  -H "Content-Type: application/soap+xml" \
  --max-time 10 \
  -d '<?xml version="1.0" encoding="UTF-8"?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Body><GetSystemDateAndTime xmlns="http://www.onvif.org/ver10/device/wsdl"/></s:Body></s:Envelope>'
```

**Expected Success Response**:

```xml
<tds:GetSystemDateAndTimeResponse>
  <tds:SystemDateAndTime>
    ...
  </tds:SystemDateAndTime>
</tds:GetSystemDateAndTimeResponse>
```

**Common Error Responses**:

| Error                         | Meaning                           | Solution                        |
|-------------------------------|-----------------------------------|---------------------------------|
| `Data required for operation` | ONVIF service disabled            | Enable ONVIF in camera settings |
| `Connection refused`          | Wrong port or service not running | Try ports 80, 8000, 8080        |
| `Connection timeout`          | Firewall or wrong IP              | Check network connectivity      |
| `401 Unauthorized`            | Authentication required           | This is OK - service is enabled |

### Step 1B: Gather Required Information

You'll need the following information about your camera:

### Required Information

| Item            | Description           | Example                 |
|-----------------|-----------------------|-------------------------|
| **Camera IP**   | Network IP address    | `192.168.1.100`         |
| **ONVIF Port**  | Usually 80 or 8000    | `80`                    |
| **ONVIF Path**  | Service endpoint path | `/onvif/device_service` |
| **Username**    | Camera admin username | `admin`                 |
| **Password**    | Camera admin password | `YourPassword123`       |
| **Camera Name** | Unique identifier     | `camera-01`             |

### How to Find ONVIF Information

#### Method 1: Check Camera Documentation

- Look for "ONVIF" settings in manual
- Common paths: `/onvif/device_service`, `/onvif/services`
- Common ports: 80, 8000, 8080

#### Method 2: Use ONVIF Device Manager (Windows)

1. Download [ONVIF Device Manager](https://sourceforge.net/projects/onvifdm/)
2. Scan your network for ONVIF devices
3. Note the service URL shown

#### Method 3: Test with curl

```bash
# Test ONVIF endpoint (replace with your camera IP)
curl -X POST http://192.168.1.100/onvif/device_service \
  -H "Content-Type: application/soap+xml" \
  --max-time 10 \
  -d '<?xml version="1.0" encoding="UTF-8"?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Body><GetSystemDateAndTime xmlns="http://www.onvif.org/ver10/device/wsdl"/></s:Body></s:Envelope>'
```

**If successful**, you'll see XML response with date/time:

```xml
<tds:GetSystemDateAndTimeResponse>...
```

**If you see error**: `Data required for operation` - ONVIF service is disabled. See Step 1A above to enable it.

## Step 2: Determine Camera Capabilities

### Check PTZ Support

#### Via Camera Web Interface

- Log into camera web UI
- Look for PTZ controls or settings
- Note which controls work: Pan, Tilt, Zoom

#### Via ONVIF Device Manager

- Connect to camera
- Check "PTZ" tab
- Test controls to confirm functionality

### Common Camera Types

| Camera Type          | PTZ Capabilities       | Example Brands                |
|----------------------|------------------------|-------------------------------|
| **Fixed**            | None                   | Most basic IP cameras         |
| **Pan/Tilt (PT)**    | Pan, Tilt, Stop        | Amcrest, many indoor cameras  |
| **PTZ**              | Pan, Tilt, Zoom, Home  | Reolink, Hikvision PTZ models |
| **PTZ with Presets** | PTZ + Preset positions | Professional PTZ cameras      |

## Step 3: Create Kubernetes Secrets

### Create Credentials File

Create a file named `camera-credentials.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: camera-01-credentials
  namespace: azure-iot-operations
data:
  username: YWRtaW4=        # Replace with base64-encoded username
  password: WW91clBhc3N3b3JkMTIz  # Replace with base64-encoded password
type: Opaque
```

### Encode Your Credentials

```bash
# Encode username
echo -n "admin" | base64
# Output: YWRtaW4=

# Encode password
echo -n "YourPassword123" | base64
# Output: WW91clBhc3N3b3JkMTIz=
```

Replace the values in `camera-credentials.yaml` with your encoded credentials.

### Apply Secrets to Cluster

```bash
kubectl apply -f camera-credentials.yaml
```

### Verify Secret Creation

```bash
kubectl get secret camera-01-credentials -n azure-iot-operations
```

## Step 4: Choose Deployment Method

You can deploy using **automated scripts** (recommended for first-time users), **Bicep**, or **Terraform**.

### Option 0: Automated Deployment Scripts (Recommended)

The easiest way to deploy is using the automated deployment scripts that handle everything for you:

**Terraform Script:**

```bash
cd ~/source/repos/edge-ai/src/100-edge/111-assets/scripts
./deploy-onvif-camera-terraform.sh
```

**Bicep Script:**

```bash
cd ~/source/repos/edge-ai/src/100-edge/111-assets/scripts
./deploy-onvif-camera-bicep.sh
```

These scripts will:

- ✅ Interactively prompt for all required information
- ✅ Test ONVIF connectivity
- ✅ Discover and validate Azure resources
- ✅ Create Kubernetes secrets automatically
- ✅ Generate deployment configuration
- ✅ Deploy to Azure with confirmation
- ✅ Verify deployment status
- ✅ Display comprehensive summary

See [scripts/README.md](./scripts/README.md) for full documentation.

**If you prefer manual deployment, continue with Options A or B below.**

---

## Option A: Deploy Using Bicep

### 4A.1: Create Bicep Parameters File

Create `camera-deployment.bicepparam`:

```bicep
using './main.bicep'

// Common settings
param common = {
  environment: 'dev'
  location: 'eastus2'
  resource: 'camera'
  instance: '001'
}

// Custom location (get from your cluster)
param customLocationId = '/subscriptions/YOUR-SUBSCRIPTION-ID/resourceGroups/YOUR-RG/providers/Microsoft.ExtendedLocation/customLocations/YOUR-CUSTOM-LOCATION'

// ADR Namespace
param adrNamespaceName = 'YOUR-ADR-NAMESPACE-NAME'

// Camera device configuration
param namespacedDevices = [
  {
    name: 'camera-01'
    isEnabled: true
    endpoints: {
      outbound: {
        assigned: {}
      }
      inbound: {
        'camera-01-endpoint': {
          endpointType: 'Microsoft.Onvif'
          address: 'http://192.168.1.100/onvif/device_service'  // Replace with your camera
          version: '1.0'
          authentication: {
            method: 'UsernamePassword'
            usernamePasswordCredentials: {
              usernameSecretName: 'camera-01-credentials/username'
              passwordSecretName: 'camera-01-credentials/password'
            }
          }
        }
      }
    }
  }
]

// PTZ control asset with managementGroups (MRPC-based PTZ control)
// This configuration enables PTZ commands via the MRPC protocol
// Topic pattern: {namespace}/mrpc/{asset}/{commandName}
// Example: azure-iot-operations/mrpc/camera-01-ptz/RelativeMove
param namespacedAssets = [
  {
    name: 'camera-01-ptz'
    isEnabled: true
    deviceRef: {
      deviceName: 'camera-01'
      endpointName: 'camera-01-endpoint'
    }
    // managementGroups enable PTZ control via MRPC protocol
    managementGroups: [
      {
        name: 'ptz'
        actions: [
          {
            name: 'RelativeMove'
            actionType: 'Call'
            targetUri: 'dtmi:onvif:ptz:RelativeMove;1'
          }
          {
            name: 'ContinuousMove'
            actionType: 'Call'
            targetUri: 'dtmi:onvif:ptz:ContinuousMove;1'
          }
          {
            name: 'Stop'
            actionType: 'Call'
            targetUri: 'dtmi:onvif:ptz:Stop;1'
          }
          {
            name: 'GotoHomePosition'
            actionType: 'Call'
            targetUri: 'dtmi:onvif:ptz:GotoHomePosition;1'
          }
          {
            name: 'GotoPreset'
            actionType: 'Call'
            targetUri: 'dtmi:onvif:ptz:GotoPreset;1'
          }
        ]
      }
    ]
  }
]
```

### 4A.2: Get Required Azure Resource IDs

```bash
# Get your subscription ID
az account show --query id -o tsv

# Get resource group ID
az group show --name YOUR-RESOURCE-GROUP --query id -o tsv

# Get custom location ID
az customlocation show --name YOUR-CUSTOM-LOCATION --resource-group YOUR-RESOURCE-GROUP --query id -o tsv

# Get ADR namespace name
az resource list --resource-type Microsoft.DeviceRegistry/namespaces --query "[0].name" -o tsv
```

### 4A.3: Update Parameters File

Replace these placeholders in `camera-deployment.bicepparam`:

- `YOUR-SUBSCRIPTION-ID`: Your Azure subscription ID
- `YOUR-RG`: Your resource group name
- `YOUR-CUSTOM-LOCATION`: Your custom location name
- `YOUR-ADR-NAMESPACE-NAME`: Your ADR namespace name
- `192.168.1.100`: Your camera's IP address
- `/onvif/device_service`: Your camera's ONVIF path

### 4A.4: Deploy with Bicep

```bash
# Navigate to component directory
cd ~/source/repos/edge-ai/src/100-edge/111-assets/bicep

# Deploy using Azure CLI
az deployment group create \
  --resource-group YOUR-RESOURCE-GROUP \
  --template-file main.bicep \
  --parameters camera-deployment.bicepparam
```

---

## Option B: Deploy Using Terraform

### 4B.1: Create Terraform Variables File

Create `camera-deployment.tfvars`:

```hcl
# Location
location = "eastus2"

# Resource Group (must include both name and id)
resource_group = {
  name = "YOUR-RESOURCE-GROUP"
  id   = "/subscriptions/YOUR-SUBSCRIPTION-ID/resourceGroups/YOUR-RESOURCE-GROUP"
}

# ADR Namespace (must include id)
adr_namespace = {
  id = "/subscriptions/YOUR-SUBSCRIPTION-ID/resourceGroups/YOUR-RESOURCE-GROUP/providers/Microsoft.DeviceRegistry/namespaces/YOUR-ADR-NAMESPACE"
}

# Custom Location ID
custom_location_id = "/subscriptions/YOUR-SUBSCRIPTION-ID/resourceGroups/YOUR-RESOURCE-GROUP/providers/Microsoft.ExtendedLocation/customLocations/YOUR-CUSTOM-LOCATION"

# Camera Device Configuration
namespaced_devices = [
  {
    name    = "camera-01"
    enabled = true
    endpoints = {
      outbound = { assigned = {} }
      inbound = {
        "camera-01-endpoint" = {
          endpoint_type = "Microsoft.Onvif"
          address       = "http://192.168.1.100/onvif/device_service"  # Replace with your camera
          version       = "1.0"
          authentication = {
            method = "UsernamePassword"
            usernamePasswordCredentials = {
              usernameSecretName = "camera-01-credentials/username"
              passwordSecretName = "camera-01-credentials/password"
            }
          }
        }
      }
    }
  }
]

# PTZ Control Asset with management_groups (MRPC-based PTZ control)
# This configuration enables PTZ commands via the MRPC protocol
# Topic pattern: {namespace}/mrpc/{asset}/{commandName}
# Example: azure-iot-operations/mrpc/camera-01-ptz/RelativeMove
namespaced_assets = [
  {
    name    = "camera-01-ptz"
    enabled = true
    device_ref = {
      device_name   = "camera-01"
      endpoint_name = "camera-01-endpoint"
    }
    # management_groups enable PTZ control via MRPC protocol
    management_groups = [
      {
        name = "ptz"
        actions = [
          {
            name        = "RelativeMove"
            action_type = "Call"
            target_uri  = "dtmi:onvif:ptz:RelativeMove;1"
          },
          {
            name        = "ContinuousMove"
            action_type = "Call"
            target_uri  = "dtmi:onvif:ptz:ContinuousMove;1"
          },
          {
            name        = "Stop"
            action_type = "Call"
            target_uri  = "dtmi:onvif:ptz:Stop;1"
          },
          {
            name        = "GotoHomePosition"
            action_type = "Call"
            target_uri  = "dtmi:onvif:ptz:GotoHomePosition;1"
          },
          {
            name        = "GotoPreset"
            action_type = "Call"
            target_uri  = "dtmi:onvif:ptz:GotoPreset;1"
          }
        ]
      }
    ]
  }
]
```

### 4B.2: Get Required Azure Resource IDs

```bash
# Same commands as Bicep section 4A.2
az account show --query id -o tsv
az group show --name YOUR-RESOURCE-GROUP --query id -o tsv
# ... etc
```

### 4B.3: Deploy with Terraform

```bash
# Navigate to component directory
cd ~/source/repos/edge-ai/src/100-edge/111-assets/terraform

# Initialize Terraform (first time only)
terraform init

# Plan deployment
terraform plan -var-file="camera-deployment.tfvars" -out=tfplan

# Apply deployment
terraform apply tfplan
```

---

## Step 5: Verify Deployment

### Check Device in Azure

```bash
# List all devices
az resource list --resource-group YOUR-RESOURCE-GROUP \
  --resource-type Microsoft.DeviceRegistry/namespaces/devices \
  --query "[].{name:name, provisioning:properties.provisioningState}" -o table

# Check specific device
az resource show \
  --ids /subscriptions/YOUR-SUB-ID/resourceGroups/YOUR-RG/providers/Microsoft.DeviceRegistry/namespaces/YOUR-NAMESPACE/devices/camera-01 \
  --query "{name:name, enabled:properties.enabled, provisioning:properties.provisioningState}"
```

### Check Asset in Azure

```bash
# List all assets
az resource list --resource-group YOUR-RESOURCE-GROUP \
  --resource-type Microsoft.DeviceRegistry/namespaces/assets \
  --query "[].{name:name, provisioning:properties.provisioningState}" -o table
```

### Check Device in Kubernetes

```bash
# From your Kubernetes cluster
kubectl get devices -n azure-iot-operations
```

### Monitor ONVIF Connector

```bash
# View connector logs
kubectl logs -n azure-iot-operations -l app.kubernetes.io/component=connector --tail=100 -f
```

## Step 6: Configure PTZ Control with managementGroups

✅ **UPDATE (February 2026)**: Full ONVIF camera functionality including **managementGroups** for PTZ control IS supported in both Terraform and Bicep IaC. The connector uses the **MRPC protocol** over MQTT for PTZ commands.

### Asset Configuration Types

For complete ONVIF functionality, assets can include:

| Configuration           | Purpose                                      | IaC Support         |
|-------------------------|----------------------------------------------|---------------------|
| **datasets/dataPoints** | Read telemetry FROM device                   | ✅ Terraform + Bicep |
| **events**              | Receive event notifications (motion, alarms) | ✅ Terraform + Bicep |
| **managementGroups**    | Send commands TO device (PTZ control)        | ✅ Terraform + Bicep |

### MRPC Protocol for PTZ Commands

The ONVIF connector uses the **MRPC (Message-based RPC) protocol** for PTZ commands:

- **Topic Pattern**: `{namespace}/mrpc/{asset}/{commandName}`
- **Example**: `azure-iot-operations/mrpc/camera-01-ptz/RelativeMove`
- **Commands**: `RelativeMove`, `ContinuousMove`, `Stop`, `GotoPreset`, `GotoHomePosition`

> **Note**: Simple `mosquitto_pub` commands will NOT work for PTZ. The MRPC protocol requires CloudEvents format, correlation IDs, and response topic handling. Use the [Azure Samples PTZ Demo](https://github.com/Azure-Samples/explore-iot-operations/tree/main/samples/aio-onvif-connector-ptz-demo) or direct ONVIF SOAP commands.

### Connector Observation Behavior

The ONVIF connector logs: `Asset Endpoint is not being observed` when:

- Asset has only `management_groups` configured (no `datasets` or `events`)
- This is **expected behavior** - the connector still processes PTZ commands via MRPC

### Recommended Testing Approaches

**Option 1: Use Operations Experience UI** (Easiest)

1. Access Azure IoT Operations Experience portal
2. Navigate to your asset
3. Configure Management Groups with PTZ actions
4. Test PTZ commands through the UI

**Option 2: Direct ONVIF Testing** (Workaround)
Test PTZ functionality directly with camera's ONVIF endpoint:

```bash
# Test Pan/Tilt Up (replace with your camera details)
curl -X POST "http://CAMERA-IP:PORT/onvif/ptz_service" \
  --anyauth --user "USERNAME:PASSWORD" \
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

# Stop movement
curl -X POST "http://CAMERA-IP:PORT/onvif/ptz_service" \
  --anyauth --user "USERNAME:PASSWORD" \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">
  <s:Body>
    <Stop xmlns="http://www.onvif.org/ver20/ptz/wsdl">
      <ProfileToken>000</ProfileToken>
      <PanTilt>true</PanTilt>
      <Zoom>true</Zoom>
    </Stop>
  </s:Body>
</s:Envelope>'
```

**Option 3: MQTT Testing** (Limited - May Not Work)

If managementGroups is configured (through UI or future updates):

```bash
# Install mosquitto client if needed
sudo apt-get install mosquitto-clients

# Pan camera left (ONLY works if managementGroups configured)
mosquitto_pub -h <mqtt-broker-host> -t "cameras/camera-01/ptz/pan_left" -m "1"

# Stop movement
mosquitto_pub -h <mqtt-broker-host> -t "cameras/camera-01/ptz/stop" -m "1"
```

See [Troubleshooting → PTZ Commands Not Working](#ptz-commands-not-working) for detailed explanation.

## Adding Zoom Support (PTZ Cameras)

If your camera supports zoom, add these data points:

### Bicep

Add to `dataPoints` array in `camera-deployment.bicepparam`:

```bicep
{
  name: 'zoom_in'
  dataSource: 'zoom_in'
  dataPointConfiguration: '{"capability_id":"http://www.onvif.org/ver20/ptz/wsdl/ContinuousMove","pan_tilt":{"x":0.0,"y":0.0},"zoom":{"x":0.5}}'
}
{
  name: 'zoom_out'
  dataSource: 'zoom_out'
  dataPointConfiguration: '{"capability_id":"http://www.onvif.org/ver20/ptz/wsdl/ContinuousMove","pan_tilt":{"x":0.0,"y":0.0},"zoom":{"x":-0.5}}'
}
{
  name: 'go_home'
  dataSource: 'go_home'
  dataPointConfiguration: '{"capability_id":"http://www.onvif.org/ver20/ptz/wsdl/GotoHomePosition"}'
}
```

### Terraform

Add to `data_points` array in `camera-deployment.tfvars`:

```hcl
{
  name                     = "zoom_in"
  data_source              = "zoom_in"
  capability_id            = "http://www.onvif.org/ver20/ptz/wsdl/ContinuousMove"
  observability_mode       = "none"
  data_point_configuration = jsonencode({
    pan_tilt = { x = 0.0, y = 0.0 }
    zoom     = { x = 0.5 }
  })
},
{
  name                     = "zoom_out"
  data_source              = "zoom_out"
  capability_id            = "http://www.onvif.org/ver20/ptz/wsdl/ContinuousMove"
  observability_mode       = "none"
  data_point_configuration = jsonencode({
    pan_tilt = { x = 0.0, y = 0.0 }
    zoom     = { x = -0.5 }
  })
},
{
  name                     = "go_home"
  data_source              = "go_home"
  capability_id            = "http://www.onvif.org/ver20/ptz/wsdl/GotoHomePosition"
  observability_mode       = "none"
  data_point_configuration = jsonencode({})
}
```

## Adding Multiple Cameras

To add more cameras, duplicate the device and asset configuration blocks:

### Bicep Example

```bicep
param namespacedDevices = [
  {
    name: 'camera-01'
    // ... camera 01 config
  }
  {
    name: 'camera-02'  // Second camera
    isEnabled: true
    endpoints: {
      outbound: { assigned: {} }
      inbound: {
        'camera-02-endpoint': {
          endpointType: 'Microsoft.ONVIF'
          address: 'http://192.168.1.101/onvif/device_service'  // Different IP
          // ... rest of config
        }
      }
    }
  }
]
```

Remember to:

1. Create separate Kubernetes secrets for each camera
2. Use unique device names (`camera-01`, `camera-02`, etc.)
3. Use unique endpoint names matching the device

## Troubleshooting

### Camera Not Responding

#### Check Network Connectivity

```bash
ping 192.168.1.100
```

#### Test ONVIF Endpoint

```bash
curl -X POST http://192.168.1.100/onvif/device_service \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Body><GetSystemDateAndTime xmlns="http://www.onvif.org/ver10/device/wsdl"/></s:Body></s:Envelope>'
```

#### Verify Credentials

```bash
# Decode username from secret
kubectl get secret camera-01-credentials -n azure-iot-operations \
  -o jsonpath='{.data.username}' | base64 -d

# Test credentials on camera web interface
```

### ONVIF Service Disabled

Error: `Data required for operation` or generic SOAP fault

**Root Cause**: ONVIF service is not enabled in camera firmware settings.

**Solutions**:

1. **Access camera web interface** at `http://YOUR-CAMERA-IP`
2. **Navigate to ONVIF settings** (usually under Settings → Network → Advanced)
3. **Enable ONVIF service** (toggle to ON)
4. **Set authentication** to Digest or Username/Password
5. **Save settings** and **reboot camera**
6. **Wait 60 seconds** for camera to fully restart
7. **Test again** using curl command from Step 1A

### Authentication Errors

Error: `Invalid Host Authentication user name or password credentials`

Solutions:

1. Verify secret exists and is in correct namespace
2. Check credential encoding (no trailing newlines)
3. Confirm camera username/password are correct
4. Ensure secret reference format: `secretname/key`
5. Verify user has ONVIF permissions in camera settings

### PTZ Commands Not Working

⚠️ **CRITICAL LIMITATION**: PTZ control via IaC (Infrastructure as Code) is not fully documented in Azure IoT Operations.

#### Root Cause: Incomplete Asset Configuration

The configurations in this guide (both Bicep and Terraform) use **datasets with dataPoints** only, which are designed for **telemetry observation** (reading data FROM devices). Complete ONVIF functionality requires **events** (receiving notifications) and **managementGroups** (sending commands), which are not documented for IaC deployment.

**Evidence from ONVIF Connector Logs**:

```text
<4> Asset Endpoint is not being observed. Received Asset Update Notification: 
Asset { datasets: [...], events: [], management_groups: [], ... }
```

When both `events: []` and `management_groups: []` are empty, the connector ignores the asset for event notifications and command processing.

#### Understanding the Asset Configuration Structure

| Configuration Type      | Purpose               | Use Case                                    | IaC Support                          |
|-------------------------|-----------------------|---------------------------------------------|--------------------------------------|
| **datasets/dataPoints** | Telemetry observation | Reading sensor data, monitoring             | ✅ Fully documented                   |
| **events**              | Event notifications   | Motion detection, alarms, tampering alerts  | ✅ Documented (not shown in examples) |
| **managementGroups**    | Command/control       | PTZ commands, device control, configuration | ❌ Not documented for IaC             |

#### Recommended Solutions

1. **Use Azure IoT Operations Experience UI** (Recommended)
   - Access Operations Experience web portal
   - Navigate to "Management groups" page
   - Configure PTZ actions (pan, tilt, zoom) through UI
   - This is Microsoft's intended approach for PTZ configuration

2. **Wait for Documentation Updates**
   - Microsoft may document managementGroups IaC structure in future releases
   - Monitor Azure IoT Operations documentation for updates

3. **Direct ONVIF Control** (Workaround)
   - Use curl or ONVIF libraries to send PTZ commands directly to camera
   - Bypass Azure IoT Operations connector entirely
   - Example from this repository's testing:

```bash
# Direct PTZ control (confirmed working)
curl -X POST "http://CAMERA-IP:PORT/onvif/ptz_service" \
  --anyauth --user "USERNAME:PASSWORD" \
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

#### Diagnostic Steps

1. **Check Asset Configuration**:

```bash
kubectl get assets.namespaces.deviceregistry.microsoft.com -n azure-iot-operations ASSET-NAME -o yaml
```

Look for `management_groups: []` (empty) vs `management_groups: [...]` (configured).

1. **Check Connector Logs for "Not Being Observed"**:

```bash
kubectl logs -n azure-iot-operations -l app.kubernetes.io/component=connector --tail=500 | grep "not being observed"
```

If you see this message with your asset name, the asset lacks proper managementGroups configuration.

1. **Verify Credentials Still Work**:

```bash
# Test direct ONVIF access (this should work)
curl -X POST http://CAMERA-IP/onvif/device_service \
  -H "Content-Type: application/soap+xml" \
  --max-time 10 \
  -d '<?xml version="1.0" encoding="UTF-8"?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Body><GetSystemDateAndTime xmlns="http://www.onvif.org/ver10/device/wsdl"/></s:Body></s:Envelope>'
```

#### Common Issues (Non-Configuration Related)

1. Camera doesn't support PTZ - Check camera specifications
2. Wrong capability_id - Some cameras use different ONVIF profiles
3. Camera in manual mode - Some cameras disable remote PTZ when in manual control
4. Network connectivity issues - Verify camera is reachable from cluster

#### Asset Management Resources

- **Microsoft Learn**: [Manage Assets in Azure IoT Operations](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/overview-manage-assets)
- **Operations Experience UI**: Access through Azure Portal → Your IoT Operations Instance
- **DTDL Schema**: [PTZ MRPC Interface Definition](https://github.com/Azure-Samples/explore-iot-operations/tree/main/samples/aio-onvif-connector-ptz-demo)

### Device Not Showing in Kubernetes

Namespaced devices ARE visible in Kubernetes using the correct API group:

```bash
# View namespaced devices
kubectl get devices.namespaces.deviceregistry.microsoft.com -n azure-iot-operations

# View namespaced assets
kubectl get assets.namespaces.deviceregistry.microsoft.com -n azure-iot-operations
```

You can also verify in Azure:

```bash
az resource list --resource-type Microsoft.DeviceRegistry/namespaces/devices -o table
```

## Camera-Specific Notes

### Reolink Cameras

- Default ONVIF port: **80**
- Path: `/onvif/device_service`
- **ONVIF disabled by default** - must enable in Settings → Network → Advanced → ONVIF
- Authentication: **Digest** recommended
- User permissions: Ensure ONVIF permission enabled for your user account
- **Reboot required** after enabling ONVIF
- PTZ models: TrackMix, RLC-823A support full PTZ control
- Auto-tracking may interfere with remote PTZ - disable if needed

### Amcrest Cameras

- Default ONVIF port: **80**
- Path: `/onvif/device_service`
- **ONVIF enabled by default** on most models
- Default credentials: `admin` / `admin` (or password set during initial setup)
- Authentication: Supports both Basic and Digest
- Modern models require password setup during first boot
- IP4M-1041B and similar models have ONVIF Profile S/T support
- Check Settings → Network → ONVIF to verify service is running

### Hikvision Cameras

- Default ONVIF port: **80**
- Path: `/onvif/device_service`
- Enable ONVIF in camera settings first
- May require enabling "Platform Access" in network settings

### Dahua Cameras

- Default ONVIF port: **80**
- Path: `/onvif/device_service`
- Enable ONVIF authentication in camera web UI
- Check "ONVIF" under Settings > Network > Port

### Axis Cameras

- Default ONVIF port: **80**
- Path: `/onvif/device_service`
- ONVIF enabled by default on most models
- May require firmware update for full ONVIF support

### Budget/Generic Cameras

- Check manual for ONVIF support and port
- Common ports: 80, 8000, 8080, 8899
- Try multiple path variations if needed
- May have limited ONVIF profile support

## Next Steps

1. **Add Event Monitoring** - See [main deployment guide](./terraform/ONVIF-CAMERA-DEPLOYMENT.md) for workarounds
2. **Create Control Dashboard** - Build web interface for PTZ control
3. **Add More Cameras** - Scale to multiple camera deployment
4. **Integrate with Applications** - Connect camera feeds to your applications

## Additional Resources

- **Detailed Documentation**: [ONVIF-CAMERA-DEPLOYMENT.md](./terraform/ONVIF-CAMERA-DEPLOYMENT.md)
- **Quick Reference**: [ONVIF-CAMERA-QUICK-REFERENCE.md](./terraform/ONVIF-CAMERA-QUICK-REFERENCE.md)
- **Credentials Guide**: [CREDENTIALS-README.md](../../../500-application/510-onvif-connector/CREDENTIALS-README.md)
- **ONVIF Specifications**: <https://www.onvif.org/specs/core/ONVIF-Core-Specification.pdf>
- **Azure IoT Operations**: <https://learn.microsoft.com/azure/iot-operations/>

## Support

For issues specific to:

- **This guide**: Check troubleshooting section above
- **Azure IoT Operations**: Create Azure support ticket
- **Camera compatibility**: Consult camera manufacturer documentation
- **ONVIF protocol**: Visit [ONVIF community forums](https://www.onvif.org/community/)

---

## Known Limitations

### Complete ONVIF Functionality via IaC

**Status**: ✅ Fully Supported (Updated February 2026)

Complete ONVIF camera functionality is supported in both Terraform and Bicep:

| Configuration        | REST API Documentation | IaC Support         | Operations Experience UI |
|----------------------|------------------------|---------------------|--------------------------|
| **datasets**         | ✅ Documented           | ✅ Terraform + Bicep | ✅ Supported              |
| **events**           | ✅ Documented           | ✅ Terraform + Bicep | ✅ Supported              |
| **managementGroups** | ✅ Documented           | ✅ Terraform + Bicep | ✅ Supported              |

**Important Notes**:

- The connector logs `Asset Endpoint is not being observed` for PTZ-only assets (with only `management_groups`). This is expected - the asset IS recognized for MRPC commands.
- PTZ commands use the **MRPC protocol**, NOT simple MQTT publish. Topic pattern: `{namespace}/mrpc/{asset}/{commandName}`
- For PTZ testing, use the [Azure Samples PTZ Demo](https://github.com/Azure-Samples/explore-iot-operations/tree/main/samples/aio-onvif-connector-ptz-demo) or direct ONVIF SOAP commands.

**Secret Reference Format**: Use `secret-name/key` pattern (e.g., `camera-credentials/username`, `camera-credentials/password`).

**Last Updated**: February 2, 2026  
**AIO Version Tested**: 1.2.x  
**Connector Version**: 1.2.39

---

**Quick Start Status**: This guide works with any ONVIF-compatible camera ✅  
**PTZ Control Status**: Requires Operations Experience UI for full functionality ⚠️  
**Last Updated**: December 24, 2025  
**Tested With**: Azure IoT Operations v1.2.83, ONVIF Profile S/T cameras
