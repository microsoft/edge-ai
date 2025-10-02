# Multi-Asset Deployment Guide

This guide explains how to use the `deploy-multi-assets.sh` script to deploy multiple IoT assets from a single CSV file using the n-row processing pattern.

## Overview

The shell script automates the deployment of multiple assets by:

1. **Parsing** a multi-asset CSV file
2. **Extracting** unique asset names
3. **Creating** individual CSV files per asset
4. **Deploying** each asset separately using Bicep
5. **Cleaning up** temporary files

## Quick Start

### Prerequisites

- Azure CLI installed and logged in (`az login`)
- Resource group created
- Azure Arc-enabled Kubernetes cluster with custom location
- ADR namespace configured

### Basic Usage

```bash
./deploy-multi-assets.sh \
  multi-assets-example.csv \
  my-resource-group \
  "/subscriptions/xxx/resourceGroups/my-rg/providers/Microsoft.ExtendedLocation/customLocations/my-location" \
  my-adr-namespace
```

### Parameters

| Parameter            | Description                                | Required | Example                                            |
|----------------------|--------------------------------------------|----------|----------------------------------------------------|
| `csv_file`           | Path to multi-asset CSV file               | Yes      | `multi-assets-example.csv`                         |
| `resource_group`     | Azure resource group name                  | Yes      | `my-resource-group`                                |
| `custom_location_id` | Full Azure resource ID for custom location | Yes      | `/subscriptions/.../customLocations/my-location`   |
| `adr_namespace`      | ADR namespace name                         | No       | `my-adr-namespace` (default: `your-adr-namespace`) |

## CSV File Format

The script expects a CSV file with the following structure:

```csv
asset_name,display_name,device_name,endpoint_name,description,documentation_uri,enabled,hardware_revision,manufacturer,manufacturer_uri,model,product_code,serial_number,software_revision,dataset_name,datapoint_name,data_source,datapoint_config,destination_target,destination_topic,destination_retain,destination_qos,default_datasets_config,default_events_config

# Oven with 3 data points
namespaced-oven,Industrial Oven,oven-device-001,opc-endpoint,High-temperature industrial oven,https://docs.example.com/oven,true,v2.1,ACME Manufacturing,https://acme.com,Model-500,OV500,SN123456,v1.5,telemetry,temperature,ns=2;s=Temperature,"{""samplingInterval"": 1000}",mqtt-target,oven/telemetry,true,1,auto,auto
namespaced-oven,Industrial Oven,oven-device-001,opc-endpoint,High-temperature industrial oven,https://docs.example.com/oven,true,v2.1,ACME Manufacturing,https://acme.com,Model-500,OV500,SN123456,v1.5,telemetry,pressure,ns=2;s=Pressure,"{""samplingInterval"": 2000}",mqtt-target,oven/telemetry,true,1,auto,auto
namespaced-oven,Industrial Oven,oven-device-001,opc-endpoint,High-temperature industrial oven,https://docs.example.com/oven,true,v2.1,ACME Manufacturing,https://acme.com,Model-500,OV500,SN123456,v1.5,telemetry,status,ns=2;s=Status,"{""samplingInterval"": 5000}",mqtt-target,oven/telemetry,true,1,auto,auto

# Microwave with 3 data points
namespaced-microwave,Commercial Microwave,microwave-device-001,opc-endpoint,Commercial grade microwave unit,https://docs.example.com/microwave,true,v1.3,XYZ Kitchen,https://xyzkitchen.com,MW-200,MW200,SN789123,v2.1,sensors,power_level,ns=2;s=PowerLevel,"{""samplingInterval"": 500}",mqtt-target,microwave/sensors,true,1,auto,auto
namespaced-microwave,Commercial Microwave,microwave-device-001,opc-endpoint,Commercial grade microwave unit,https://docs.example.com/microwave,true,v1.3,XYZ Kitchen,https://xyzkitchen.com,MW-200,MW200,SN789123,v2.1,sensors,door_status,ns=2;s=DoorStatus,"{""samplingInterval"": 1000}",mqtt-target,microwave/sensors,true,1,auto,auto
namespaced-microwave,Commercial Microwave,microwave-device-001,opc-endpoint,Commercial grade microwave unit,https://docs.example.com/microwave,true,v1.3,XYZ Kitchen,https://xyzkitchen.com,MW-200,MW200,SN789123,v2.1,sensors,timer,ns=2;s=Timer,"{""samplingInterval"": 2000}",mqtt-target,microwave/sensors,true,1,auto,auto
```

### Key Points

- **Asset grouping**: Rows with the same `asset_name` (first column) are grouped together
- **N-row processing**: Each asset can have any number of data point rows
- **Comments**: Lines starting with `#` are ignored
- **Header**: First non-comment line must be the CSV header

## How It Works

### 1. Asset Discovery

The script extracts unique asset names from the first column:

```bash
# From the example CSV above, discovers:
# - namespaced-oven
# - namespaced-microwave
```

### 2. Asset Separation

Creates individual CSV files for each asset:

```bash
# Creates temporary files:
# /tmp/tmp.xxx/namespaced-oven-assets.csv    (header + 3 oven rows)
# /tmp/tmp.xxx/namespaced-microwave-assets.csv (header + 3 microwave rows)
```

### 3. Individual Deployment

For each asset, the script:

1. Copies the asset-specific CSV to `namespaced-assets-template.csv`
2. Calls `az deployment group create` with `parameters-practical-n-rows.bicep`
3. Uses n-row processing to create data points from all CSV rows
4. Deploys the asset with all its data points

### 4. Cleanup

Removes temporary files and restores original CSV files.

## Example Output

```bash
🎯 Multi-Asset IoT Deployment Script
==================================
🔐 Checking Azure CLI authentication...
   Subscription: My Azure Subscription
   ID: 12345678-1234-1234-1234-123456789012
📁 Created temporary directory: /tmp/tmp.AbCdEf
📊 Processing CSV file: multi-assets-example.csv
   Found 2 unique assets:
   - namespaced-oven
   - namespaced-microwave

   Asset 'namespaced-oven' has 3 data point rows
🚀 Deploying asset: namespaced-oven
   CSV file: /tmp/tmp.AbCdEf/namespaced-oven-assets.csv
   Resource prefix: namespacedoven
✅ Successfully deployed asset: namespaced-oven

   Asset 'namespaced-microwave' has 3 data point rows
🚀 Deploying asset: namespaced-microwave
   CSV file: /tmp/tmp.AbCdEf/namespaced-microwave-assets.csv
   Resource prefix: namespacedmicrowave
✅ Successfully deployed asset: namespaced-microwave

🧹 Cleaning up temporary files in /tmp/tmp.AbCdEf
📋 Deployment Summary
====================
   Total assets processed: 2
   Successful deployments: 2
   Failed deployments: 0
🎉 All assets deployed successfully!
```

## Advanced Usage

### Custom Azure Configuration

```bash
# Use different Azure subscription
az account set --subscription "My Other Subscription"

# Deploy to different location
export LOCATION="East US 2"
./deploy-multi-assets.sh multi-assets.csv my-rg "/subscriptions/.../customLocations/my-location"
```

### Multiple Asset Types

You can add any number of assets to your CSV:

```csv
# Pump with 1 data point
pump-001,Hydraulic Pump,pump-device-001,opc-endpoint,Main hydraulic pump,https://docs.example.com/pump,true,v1.0,GHI Systems,https://ghi.com,HP-50,HP50,SN112233,v1.0,status,pressure,ns=2;s=HydraulicPressure,"{""samplingInterval"": 1000}",mqtt-target,pump/status,true,1,auto,auto

# Conveyor with 5 data points
conveyor-belt-a,Conveyor Belt A,conveyor-device-001,opc-endpoint,Main production conveyor,https://docs.example.com/conveyor,true,v3.0,DEF Industries,https://def.com,CB-1000,CB1000,SN456789,v1.2,metrics,belt_speed,ns=2;s=BeltSpeed,"{""samplingInterval"": 250}",mqtt-target,conveyor/metrics,true,1,auto,auto
conveyor-belt-a,Conveyor Belt A,conveyor-device-001,opc-endpoint,Main production conveyor,https://docs.example.com/conveyor,true,v3.0,DEF Industries,https://def.com,CB-1000,CB1000,SN456789,v1.2,metrics,motor_current,ns=2;s=MotorCurrent,"{""samplingInterval"": 500}",mqtt-target,conveyor/metrics,true,1,auto,auto
conveyor-belt-a,Conveyor Belt A,conveyor-device-001,opc-endpoint,Main production conveyor,https://docs.example.com/conveyor,true,v3.0,DEF Industries,https://def.com,CB-1000,CB1000,SN456789,v1.2,metrics,vibration,ns=2;s=Vibration,"{""samplingInterval"": 100}",mqtt-target,conveyor/metrics,true,1,auto,auto
conveyor-belt-a,Conveyor Belt A,conveyor-device-001,opc-endpoint,Main production conveyor,https://docs.example.com/conveyor,true,v3.0,DEF Industries,https://def.com,CB-1000,CB1000,SN456789,v1.2,metrics,temperature,ns=2;s=BeltTemp,"{""samplingInterval"": 2000}",mqtt-target,conveyor/metrics,true,1,auto,auto
conveyor-belt-a,Conveyor Belt A,conveyor-device-001,opc-endpoint,Main production conveyor,https://docs.example.com/conveyor,true,v3.0,DEF Industries,https://def.com,CB-1000,CB1000,SN456789,v1.2,metrics,position,ns=2;s=Position,"{""samplingInterval"": 100}",mqtt-target,conveyor/metrics,true,1,auto,auto
```

The script will automatically discover and deploy all assets, regardless of how many data points each has.

## Troubleshooting

### Common Issues

| Issue                              | Solution                                                    |
|------------------------------------|-------------------------------------------------------------|
| `Error: Not logged into Azure CLI` | Run `az login` first                                        |
| `Error: CSV file not found`        | Check the file path and ensure the CSV exists               |
| `Error: Bicep template not found`  | Ensure you're running the script from the correct directory |
| `Deployment failed`                | Check Azure CLI output for specific error details           |

### Debugging

Add debug output by modifying the script:

```bash
# Add after set -euo pipefail
set -x  # Enable debug output
```

## Integration with CI/CD

### Azure DevOps Pipeline

```yaml
steps:
- task: AzureCLI@2
  displayName: 'Deploy Multi-Asset IoT Resources'
  inputs:
    azureSubscription: '$(azureServiceConnection)'
    scriptType: 'bash'
    scriptLocation: 'scriptPath'
    scriptPath: 'src/100-edge/111-assets/deploy-multi-assets.sh'
    arguments: |
      $(csvFileName)
      $(resourceGroupName)
      $(customLocationId)
      $(adrNamespaceName)
```

### GitHub Actions

```yaml
- name: Deploy Multi-Asset IoT Resources
  run: |
    ./src/100-edge/111-assets/deploy-multi-assets.sh \
      ${{ github.workspace }}/assets.csv \
      ${{ vars.RESOURCE_GROUP }} \
      ${{ vars.CUSTOM_LOCATION_ID }} \
      ${{ vars.ADR_NAMESPACE }}
  env:
    AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}
```

## Benefits

✅ **Automated deployment** of multiple assets from single CSV
✅ **N-row processing** - any number of data points per asset
✅ **Scalable** - add unlimited assets to CSV
✅ **Production ready** - proper error handling and cleanup
✅ **CI/CD friendly** - suitable for automation pipelines
✅ **Works around Bicep limitations** using shell scripting

This approach gives you the best of both worlds: the flexibility of shell scripting for complex CSV processing combined with the power of Bicep for infrastructure deployment! 🚀
