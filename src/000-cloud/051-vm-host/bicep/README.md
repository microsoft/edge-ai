<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# VM Host Component

Provisions virtual machines and networking infrastructure for hosting Azure IoT Operations edge deployments.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|adminPassword|The admin password for the VM.|`securestring`|n/a|yes|
|arcOnboardingIdentityName|The user-assigned identity for Arc onboarding.|`string`|n/a|no|
|storageProfile|The storage profile for the VM.|`[_1.StorageProfile](#user-defined-types)`|[variables('_1.storageProfileDefaults')]|no|
|vmUsername|Username used for the host VM that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)|`string`|n/a|no|
|vmCount|The number of host VMs to create if a multi-node cluster is needed.|`int`|1|no|
|vmSkuSize|Size of the VM.|`string`|Standard_D8s_v3|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|`false`|no|
|subnetId|The subnet ID to connect the VMs to.|`string`|n/a|yes|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|virtualMachine|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|attribution||
|virtualMachine|Creates a Linux virtual machine with networking components for Azure IoT Operations deployments.|

## Module Details

### attribution



### virtualMachine

Creates a Linux virtual machine with networking components for Azure IoT Operations deployments.

#### Parameters for virtualMachine

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|adminPassword|The admin password for the VM.|`securestring`|n/a|yes|
|arcOnboardingIdentityName|The user-assigned identity for Arc onboarding.|`string`|n/a|no|
|storageProfile|The storage profile for the VM.|`[_1.StorageProfile](#user-defined-types)`|[variables('_1.storageProfileDefaults')]|no|
|vmSkuSize|Size of the VM.|`string`|Standard_D8s_v3|no|
|vmUsername|Username used for the host VM that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)|`string`|n/a|no|
|subnetId|The subnet ID to connect the VM to.|`string`|n/a|yes|
|vmIndex|The VM index for naming purposes.|`int`|0|no|

#### Resources for virtualMachine

|Name|Type|API Version|
| :--- | :--- | :--- |
|arcOnboardingIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2024-11-30|
|publicIp|`Microsoft.Network/publicIPAddresses`|2024-05-01|
|networkInterface|`Microsoft.Network/networkInterfaces`|2024-05-01|
|linuxVm|`Microsoft.Compute/virtualMachines`|2024-07-01|

#### Outputs for virtualMachine

|Name|Type|Description|
| :--- | :--- | :--- |
|adminUsername|`string`|The admin username for SSH access to the VM.|
|privateIpAddress|`string`|The private IP address of the VM.|
|publicFqdn|`string`|The public FQDN of the VM.|
|publicIpAddress|`string`|The public IP address of the VM.|
|vmId|`string`|The ID of the VM.|
|vmName|`string`|The name of the VM.|

## User Defined Types

### `_1.StorageProfile`

The storage profile for the VM.

|Property|Type|Description|
| :--- | :--- | :--- |
|imageReference|`object`|The image reference for the VM.|
|osDisk|`object`|The OS disk configuration for the VM.|

### `_2.Common`

Common settings for the components.

|Property|Type|Description|
| :--- | :--- | :--- |
|resourcePrefix|`string`|Prefix for all resources in this module|
|location|`string`|Location for all resources in this module|
|environment|`string`|Environment for all resources in this module: dev, test, or prod|
|instance|`string`|Instance identifier for naming resources: 001, 002, etc...|

## Outputs

|Name|Type|Description|
| :--- | :--- | :--- |
|adminUsername|`string`|The admin username for SSH access to the VMs.|
|privateIpAddresses|`array`|An array containing the private IP addresses of all deployed VMs.|
|publicFqdns|`array`|An array containing the public FQDNs of all deployed VMs.|
|publicIpAddresses|`array`|An array containing the public IP addresses of all deployed VMs.|
|vmIds|`array`|An array containing the IDs of all deployed VMs.|
|vmNames|`array`|An array containing the names of all deployed VMs.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->