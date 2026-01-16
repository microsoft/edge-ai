<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Arc Extensions

Deploys foundational Arc-enabled Kubernetes cluster extensions including cert-manager and Azure Container Storage (ACSA).

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|arcConnectedClusterName|The resource name for the Arc connected cluster.|`string`|n/a|yes|
|certManagerConfig|The settings for the cert-manager Extension.|`[_1.CertManagerExtension](#user-defined-types)`|[variables('_1.certManagerExtensionDefaults')]|no|
|containerStorageConfig|The settings for the Azure Container Storage for Azure Arc Extension.|`[_1.ContainerStorageExtension](#user-defined-types)`|[variables('_1.containerStorageExtensionDefaults')]|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|aioCertManager|`Microsoft.KubernetesConfiguration/extensions`|2024-11-01|
|containerStorage|`Microsoft.KubernetesConfiguration/extensions`|2024-11-01|

## User Defined Types

### `_1.CertManagerExtension`

The settings for the cert-manager Extension.

|Property|Type|Description|
| :--- | :--- | :--- |
|enabled|`bool`|Whether to deploy the cert-manager extension.|
|release|`[_1.Release](#user-defined-types)`|The common settings for the extension.|
|settings|`object`||

### `_1.ContainerStorageExtension`

The settings for the Azure Container Storage for Azure Arc Extension.

|Property|Type|Description|
| :--- | :--- | :--- |
|enabled|`bool`|Whether to deploy the container storage extension.|
|release|`[_1.Release](#user-defined-types)`|The common settings for the extension.|
|settings|`object`||

### `_1.Release`

The common settings for Azure Arc Extensions.

|Property|Type|Description|
| :--- | :--- | :--- |
|version|`string`|The version of the extension.|
|train|`string`|The release train that has the version to deploy (ex., "preview", "stable").|
|autoUpgradeMinorVersion|`bool`|Whether to automatically upgrade minor versions of the extension.|

## Outputs

|Name|Type|Description|
| :--- | :--- | :--- |
|certManagerExtensionId|`string`|The resource ID of the cert-manager extension.|
|certManagerExtensionName|`string`|The name of the cert-manager extension.|
|containerStorageExtensionId|`string`|The resource ID of the Azure Container Storage extension.|
|containerStorageExtensionName|`string`|The name of the Azure Container Storage extension.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->