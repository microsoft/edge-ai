# Multi-Asset Deployment Tool

Utility for batch deploying multiple IoT assets from CSV files to Azure IoT Operations using the 111-assets component.

## Overview

The shell script automates the deployment of multiple namespaced assets and devices by:

1. **Parsing** a multi-asset CSV file
2. **Extracting** unique asset names
3. **Generating** Bicep deployment parameters for each asset
4. **Deploying** each asset separately using Azure CLI and Bicep
5. **Cleaning up** temporary files

This tool leverages the [111-assets component](../../100-edge/111-assets/) for infrastructure provisioning.

## Features

- **Batch Processing**: Deploy multiple assets from a single CSV file
- **N-Row Pattern**: Support any number of data points per asset
- **Automated Deployment**: Generates Bicep parameters and deploys via Azure CLI
- **Error Handling**: Robust error checking and cleanup
- **CI/CD Ready**: Suitable for automation pipelines
- **Works around Bicep limitations** using shell scripting for complex CSV processing

## Quick Start

### Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Resource group created
- Azure Arc-enabled Kubernetes cluster with custom location configured
- Azure Device Registry (ADR) namespace provisioned

### Basic Usage

```bash
cd src/900-tools-utilities/903-multi-asset-deploy

./deploy-multi-assets.sh \
  samples/multi-assets-example.csv \
  my-resource-group \
  "/subscriptions/xxx/resourceGroups/my-rg/providers/Microsoft.ExtendedLocation/customLocations/my-location" \
  my-adr-namespace
```

### Parameters

| Parameter            | Required | Description                                       | Example                                          |
|----------------------|----------|---------------------------------------------------|--------------------------------------------------|
| `csv_file`           | Yes      | Path to multi-asset CSV file                      | `samples/multi-assets-example.csv`               |
| `resource_group`     | Yes      | Azure resource group name                         | `my-resource-group`                              |
| `custom_location_id` | Yes      | Full Azure resource ID for custom location        | `/subscriptions/.../customLocations/my-location` |
| `adr_namespace`      | No       | ADR namespace name (default: `default-namespace`) | `my-adr-namespace`                               |

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

### 2. Parameter Generation

For each asset, the script generates a Bicep parameters JSON file containing:

- Asset metadata (from first row)
- All data points (from all rows for that asset)
- Device and endpoint configuration
- Dataset and destination settings

### 3. Individual Deployment

For each asset, the script:

1. Creates a temporary parameters file with asset-specific configuration
2. Calls `az deployment group create` with the 111-assets Bicep template
3. Deploys the asset with all its data points
4. Removes temporary files

## Example Output

```bash
🚀 Deploying namespaced-oven...
✅ namespaced-oven deployed

🚀 Deploying namespaced-microwave...
✅ namespaced-microwave deployed

🎉 All assets deployed!
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

## CI/CD Integration

### Azure DevOps Pipeline

```yaml
steps:
- task: AzureCLI@2
  displayName: 'Deploy Multi-Asset IoT Resources'
  inputs:
    azureSubscription: '$(azureServiceConnection)'
    scriptType: 'bash'
    scriptLocation: 'scriptPath'
    scriptPath: 'src/900-tools-utilities/903-multi-asset-deploy/deploy-multi-assets.sh'
    arguments: |
      $(csvFileName)
      $(resourceGroupName)
      $(customLocationId)
      $(adrNamespaceName)
```

### GitHub Actions

```yaml
- name: Azure Login
  uses: azure/login@v1
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}

- name: Deploy Multi-Asset IoT Resources
  run: |
    ./src/900-tools-utilities/903-multi-asset-deploy/deploy-multi-assets.sh \
      ${{ github.workspace }}/assets.csv \
      ${{ vars.RESOURCE_GROUP }} \
      ${{ vars.CUSTOM_LOCATION_ID }} \
      ${{ vars.ADR_NAMESPACE }}
```

## Component Integration

This utility deploys assets using the [111-assets Bicep component](../../100-edge/111-assets/bicep/):

```plaintext
src/900-tools-utilities/903-multi-asset-deploy/
├── deploy-multi-assets.sh              # Deployment script
├── README.md                           # This file
└── samples/
    └── multi-assets-example.csv        # Example CSV file

Referenced Component:
src/100-edge/111-assets/bicep/
├── main.bicep                          # Asset deployment template
├── types.bicep                         # Type definitions
└── types.core.bicep                    # Core types
```

## Related Components

- [111-assets](../../100-edge/111-assets/) - Core asset deployment component
- [110-iot-ops](../../100-edge/110-iot-ops/) - Azure IoT Operations infrastructure
- [100-cncf-cluster](../../100-edge/100-cncf-cluster/) - CNCF-compliant Kubernetes cluster

## License

See [LICENSE](../../../LICENSE) in the repository root.
