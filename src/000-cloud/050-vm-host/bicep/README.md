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
|vmSkuSize|Size of the VM|`string`|Standard_D8s_v3|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|network|`Microsoft.Resources/deployments`|2022-09-01|
|virtualMachine|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|network|Creates virtual network, subnet, and network security group resources for VM deployments.|
|virtualMachine|Creates a Linux virtual machine with networking components for Azure IoT Operations deployments.|

## Module Details

### network

Creates virtual network, subnet, and network security group resources for VM deployments.

#### Parameters for network

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|addressPrefix|The address prefix for the virtual network.|`string`|10.0.0.0/16|no|
|subnetAddressPrefix|The subnet address prefix.|`string`|10.0.1.0/24|no|

#### Resources for network

|Name|Type|API Version|
| :--- | :--- | :--- |
|networkSecurityGroup|`Microsoft.Network/networkSecurityGroups`|2024-05-01|
|virtualNetwork|`Microsoft.Network/virtualNetworks`|2024-05-01|

#### Outputs for network

|Name|Type|Description|
| :--- | :--- | :--- |
|networkSecurityGroupId|`string`||
|networkSecurityGroupName|`string`||
|subnetId|`string`||
|virtualNetworkId|`string`||
|virtualNetworkName|`string`||

### virtualMachine

Creates a Linux virtual machine with networking components for Azure IoT Operations deployments.

#### Parameters for virtualMachine

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|storageProfile|The storage profile for the VM.|`[_1.StorageProfile](#user-defined-types)`|[variables('_1.storageProfileDefaults')]|no|
|adminPassword|The admin password for the VM.|`securestring`|n/a|yes|
|arcOnboardingIdentityName|The user-assigned identity for Arc onboarding.|`string`|n/a|yes|
|subnetId|The subnet ID to connect the VM to.|`string`|n/a|yes|
|vmIndex|The VM index for naming purposes.|`int`|0|no|
|vmSkuSize|Size of the VM|`string`|Standard_D8s_v3|no|
|vmUsername|Username used for the host VM that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)|`string`|n/a|yes|

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
|adminUsername|`string`||
|privateIpAddress|`string`||
|publicFqdn|`string`||
|publicIpAddress|`string`||
|vmId|`string`||
|vmName|`string`||

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
|adminUsername|`string`||
|privateIpAddresses|`array`||
|publicFqdns|`array`||
|publicIpAddresses|`array`||
|vmIds|`array`||
|vmNames|`array`||

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->