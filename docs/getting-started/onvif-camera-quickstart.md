---
title: ONVIF Camera Deployment Guide
description: Register an ONVIF camera with Azure IoT Operations as a device with credentials and a pan-tilt-zoom control asset by using the Azure CLI, Bicep, or Terraform
author: Edge AI Team
ms.date: 2026-10-05
ms.topic: how-to
estimated_reading_time: 15
keywords:
  - onvif
  - camera
  - ptz
  - device-registry
  - azure-iot-operations
---

## ONVIF Camera Deployment Guide

This guide registers an ONVIF camera with Azure IoT Operations. It checks the camera, stores its credentials, creates a device with an ONVIF inbound endpoint, and adds an asset with pan-tilt-zoom (PTZ) actions. For the design behind this integration, see the [ONVIF connector ADR](../solution-adr-library/onvif-connector-camera-integration.md).

## Prerequisites

* Azure IoT Operations deployed with the ONVIF connector template enabled: `should_enable_akri_onvif_connector = true` in Terraform or `shouldEnableAkriOnvifConnector: true` in Bicep for the [110-iot-ops](../../src/100-edge/110-iot-ops/README.md) component
* Secret sync enabled for the instance, with access to its Azure Key Vault
* A camera that the cluster can reach, with ONVIF enabled and digest authentication configured
* Azure CLI with the `azure-iot-ops` extension, and `kubectl` access to the cluster

## Step 1: Check the Camera

Many cameras ship with ONVIF turned off. Turn it on in the camera's web interface, set authentication to digest, and reboot if required.

Use [onvif-ptz-check.sh](../../src/100-edge/111-assets/scripts/README.md) to confirm that the camera responds and to collect the values later steps need:

```bash
cd src/100-edge/111-assets/scripts
export CAMERA_HOST=<camera-ip>
export CAMERA_USERNAME=<camera-username>

./onvif-ptz-check.sh services
```

The script prompts for the password. Note the device service address for the inbound endpoint and the PTZ service address. Then list the media profiles and test movement with a profile that has a PTZ configuration:

```bash
export ONVIF_MEDIA_URL=<media-service-address>
export ONVIF_PTZ_URL=<ptz-service-address>

./onvif-ptz-check.sh profiles
PROFILE_TOKEN=<profile-token> ./onvif-ptz-check.sh move
```

| Result                                                 | Meaning                             | Action                                                     |
|--------------------------------------------------------|-------------------------------------|------------------------------------------------------------|
| `Connection refused`                                   | Wrong port or ONVIF service stopped | Check the ONVIF port; common values are 80, 8000, and 8080 |
| Timeout                                                | Firewall or wrong address           | Check network connectivity from the cluster                |
| `HTTP 401`                                             | Credentials rejected                | Check the username, password, and ONVIF user permissions   |
| `HTTP 400` or `500` with `Data required for operation` | ONVIF turned off on the camera      | Turn on ONVIF in the camera settings                       |

## Step 2: Store the Camera Credentials

The connector reads credentials from a synced secret on the cluster.

1. Add the camera username and password as secrets in the Key Vault that secret sync uses. See [Add secrets to Azure Key Vault](https://learn.microsoft.com/azure/iot-operations/secure-iot-ops/howto-manage-secrets#add-secrets-to-azure-key-vault).
2. Create one synced secret that maps both Key Vault secrets to the `username` and `password` keys:

    ```bash
    az iot ops secretsync secret set \
      --instance <instance-name> \
      --resource-group <resource-group> \
      --name <camera-name>-credentials \
      --secret target=username source=<key-vault-username-secret> \
      --secret target=password source=<key-vault-password-secret>
    ```

The device endpoint references these values as `<camera-name>-credentials/username` and `<camera-name>-credentials/password`.

## Step 3: Register the Camera Device

Use the option that matches how you manage the deployment.

### Option A: Azure CLI

```bash
az iot ops ns device create \
  --name <camera-name> \
  --instance <instance-name> \
  --resource-group <resource-group>

az iot ops ns device endpoint inbound add onvif \
  --device <camera-name> \
  --name <camera-name>-endpoint \
  --instance <instance-name> \
  --resource-group <resource-group> \
  --endpoint-address http://<camera-ip>/onvif/device_service \
  --user-ref <camera-name>-credentials/username \
  --pass-ref <camera-name>-credentials/password
```

### Option B: Bicep With the 111-assets Component

Create `camera.bicepparam` in the repository root:

```bicep
using 'src/100-edge/111-assets/bicep/main.bicep'

param common = {
  resourcePrefix: '<resource-prefix>'
  location: '<location>'
  environment: 'dev'
  instance: '001'
}

param customLocationId = '<custom-location-resource-id>'
param adrNamespaceName = '<adr-namespace-name>'

param namespacedDevices = [
  {
    name: '<camera-name>'
    isEnabled: true
    endpoints: {
      outbound: {
        assigned: {}
      }
      inbound: {
        '<camera-name>-endpoint': {
          endpointType: 'Microsoft.Onvif'
          address: 'http://<camera-ip>/onvif/device_service'
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

Deploy it to the resource group that contains the Azure IoT Operations instance:

```bash
az deployment group create \
  --resource-group <resource-group> \
  --parameters camera.bicepparam
```

Look up the resource values with:

```bash
az customlocation show --name <custom-location> --resource-group <resource-group> --query id --output tsv
az resource list --resource-group <resource-group> --resource-type Microsoft.DeviceRegistry/namespaces --query "[].name" --output tsv
```

### Option C: Terraform With the full-multi-node-cluster Blueprint

When you deploy with the [full-multi-node-cluster](../../blueprints/full-multi-node-cluster/README.md) blueprint, add the camera to the same variables file and apply the blueprint again. The blueprint passes `namespaced_devices` and `namespaced_assets` to the 111-assets component. The [onvif-connector-assets.tfvars.example](../../blueprints/full-multi-node-cluster/terraform/onvif-connector-assets.tfvars.example) file shows a complete configuration.

```hcl
should_enable_akri_onvif_connector = true

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

## Step 4: Add the PTZ Control Asset

PTZ control uses an asset with a management group of `Call` actions. The asset references the device endpoint from Step 3. In the operations experience, you can also create it with **Import and create asset** on the discovered ONVIF asset.

In Bicep, add this parameter to `camera.bicepparam` and deploy again:

```bicep
param namespacedAssets = [
  {
    name: '<camera-name>-ptz'
    isEnabled: true
    deviceRef: {
      deviceName: '<camera-name>'
      endpointName: '<camera-name>-endpoint'
    }
    attributes: {}
    datasets: []
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

In Terraform, add this variable to the blueprint variables file and apply again:

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
          { name = "RelativeMove", action_type = "Call", target_uri = "dtmi:onvif:ptz:RelativeMove;1" },
          { name = "ContinuousMove", action_type = "Call", target_uri = "dtmi:onvif:ptz:ContinuousMove;1" },
          { name = "Stop", action_type = "Call", target_uri = "dtmi:onvif:ptz:Stop;1" },
          { name = "GotoHomePosition", action_type = "Call", target_uri = "dtmi:onvif:ptz:GotoHomePosition;1" },
          { name = "GotoPreset", action_type = "Call", target_uri = "dtmi:onvif:ptz:GotoPreset;1" },
        ]
      }
    ]
  }
]
```

The connector logs `Asset Endpoint is not being observed` for an asset that has only management groups. This message is expected.

## Step 5: Verify the Deployment

```bash
az resource list --resource-group <resource-group> \
  --resource-type Microsoft.DeviceRegistry/namespaces/devices \
  --query "[].{name:name, provisioning:properties.provisioningState}" --output table

kubectl get devices.namespaces.deviceregistry.microsoft.com --namespace azure-iot-operations
kubectl get assets.namespaces.deviceregistry.microsoft.com --namespace azure-iot-operations
kubectl logs --namespace azure-iot-operations --selector app.kubernetes.io/component=connector --tail=100
```

## Step 6: Control the Camera

The connector exposes PTZ operations as MQTT RPC commands on the topic `{namespace}/mrpc/{asset}/{commandName}`, for example `azure-iot-operations/mrpc/<camera-name>-ptz/RelativeMove`. A `RelativeMove` request carries a profile token from Step 1:

```json
{
  "RelativeMove": {
    "ProfileToken": "<profile-token>",
    "Translation": { "PanTilt": { "x": 0.1, "y": 0.0 } }
  }
}
```

MQTT RPC requests need a correlation ID and a response topic, so a plain `mosquitto_pub` message doesn't get a response. Use a client built on the Azure IoT Operations SDKs, such as the [ONVIF PTZ demo](https://github.com/Azure-Samples/explore-iot-operations/tree/main/samples/aio-onvif-connector-ptz-demo). To call actions from the cloud, see [Enable and run management actions](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/howto-use-management-actions).

## Troubleshooting

### Device Missing in Kubernetes

Query the namespaced Device Registry resource types:

```bash
kubectl get devices.namespaces.deviceregistry.microsoft.com --namespace azure-iot-operations
kubectl get assets.namespaces.deviceregistry.microsoft.com --namespace azure-iot-operations
```

### Authentication Errors in Connector Logs

* Confirm that the synced secret exists in the `azure-iot-operations` namespace and has `username` and `password` keys
* Confirm that the endpoint references use the `<secret-name>/<key>` form
* Run `onvif-ptz-check.sh services` with `K8S_SECRET_NAME=<camera-name>-credentials` to test the synced credentials against the camera

### PTZ Commands Have No Effect

* Run `onvif-ptz-check.sh move` to confirm that the camera moves without Azure IoT Operations
* Use a profile token whose `PTZ` column shows `yes`
* Some cameras support only `ContinuousMove`; send `ContinuousMove` followed by `Stop`

## Additional Resources

* [Configure the connector for ONVIF](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/howto-use-onvif-connector)
* [Manage secrets for your Azure IoT Operations deployment](https://learn.microsoft.com/azure/iot-operations/secure-iot-ops/howto-manage-secrets)
* [ONVIF profiles, add-ons, and specifications](https://www.onvif.org/profiles-add-ons-specifications/)
