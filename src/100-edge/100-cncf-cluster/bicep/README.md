<!-- BEGIN_BICEP_DOCS -->
<!-- markdownlint-disable MD033 -->

# CNCF Cluster Component

This module provisions and deploys automation scripts to a VM host that create and configure a K3s Kubernetes cluster with Arc connectivity.
The scripts handle primary and secondary node(s) setup, cluster administration, workload identity enablement, and installation of required Azure Arc extensions.

## Parameters

| Name                             | Description                                                                                                                                                                                                                                       | Type                               | Default                                                                                                                            | Required |
|:---------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                           | The common component configuration.                                                                                                                                                                                                               | `[_1.Common](#user-defined-types)` | n/a                                                                                                                                | yes      |
| arcConnectedClusterName          | The resource name for the Arc connected cluster.                                                                                                                                                                                                  | `string`                           | [format('arck-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| arcOnboardingSpClientId          | Service Principal Client ID with Kubernetes Cluster - Azure Arc Onboarding permissions.                                                                                                                                                           | `string`                           | n/a                                                                                                                                | no       |
| arcOnboardingSpClientSecret      | The Service Principal Client Secret for Arc onboarding.                                                                                                                                                                                           | `securestring`                     | n/a                                                                                                                                | no       |
| arcOnboardingSpPrincipalId       | Service Principal Object Id used when assigning roles for Arc onboarding.                                                                                                                                                                         | `string`                           | n/a                                                                                                                                | no       |
| arcOnboardingIdentityName        | The resource name for the identity used for Arc onboarding.                                                                                                                                                                                       | `string`                           | n/a                                                                                                                                | no       |
| customLocationsOid               | The object id of the Custom Locations Entra ID application for your tenant.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre><br> | `string`                           | n/a                                                                                                                                | yes      |
| shouldAddCurrentUserClusterAdmin | Whether to add the current user as a cluster admin.                                                                                                                                                                                               | `bool`                             | `true`                                                                                                                             | no       |
| shouldEnableArcAutoUpgrade       | Whether to enable auto-upgrade for Azure Arc agents.                                                                                                                                                                                              | `bool`                             | [not(equals(parameters('common').environment, 'prod'))]                                                                            | no       |
| clusterAdminOid                  | The Object ID that will be given cluster-admin permissions.                                                                                                                                                                                       | `string`                           | n/a                                                                                                                                | no       |
| clusterAdminUpn                  | The User Principal Name that will be given cluster-admin permissions.                                                                                                                                                                             | `string`                           | n/a                                                                                                                                | no       |
| clusterNodeVirtualMachineNames   | The node virtual machines names.                                                                                                                                                                                                                  | `array`                            | n/a                                                                                                                                | no       |
| clusterServerVirtualMachineName  | The server virtual machines name.                                                                                                                                                                                                                 | `string`                           | n/a                                                                                                                                | no       |
| clusterServerHostMachineUsername | Username used for the host machines that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)                                                                                                         | `string`                           | [parameters('common').resourcePrefix]                                                                                              | no       |
| clusterServerIp                  | The IP address for the server for the cluster. (Needed for mult-node cluster)                                                                                                                                                                     | `string`                           | n/a                                                                                                                                | no       |
| serverToken                      | The token that will be given to the server for the cluster or used by agent nodes.                                                                                                                                                                | `securestring`                     | n/a                                                                                                                                | no       |
| shouldAssignRoles                | Whether to assign roles for Arc Onboarding.                                                                                                                                                                                                       | `bool`                             | `true`                                                                                                                             | no       |
| shouldDeployScriptToVm           | Whether to deploy the scripts to the VM.                                                                                                                                                                                                          | `bool`                             | `true`                                                                                                                             | no       |
| shouldSkipInstallingAzCli        | Should skip downloading and installing Azure CLI on the server.                                                                                                                                                                                   | `bool`                             | `false`                                                                                                                            | no       |
| shouldSkipAzCliLogin             | Should skip login process with Azure CLI on the server.                                                                                                                                                                                           | `bool`                             | `false`                                                                                                                            | no       |
| deployUserTokenSecretName        | The name for the deploy user token secret in Key Vault.                                                                                                                                                                                           | `string`                           | deploy-user-token                                                                                                                  | no       |
| deployKeyVaultName               | The name of the Key Vault that will have scripts and secrets for deployment.                                                                                                                                                                      | `string`                           | n/a                                                                                                                                | yes      |
| deployKeyVaultResourceGroupName  | The resource group name where the Key Vault is located. Defaults to the current resource group.                                                                                                                                                   | `string`                           | [resourceGroup().name]                                                                                                             | no       |
| k3sTokenSecretName               | The name for the K3s token secret in Key Vault.                                                                                                                                                                                                   | `string`                           | k3s-server-token                                                                                                                   | no       |
| nodeScriptSecretName             | The name for the node script secret in Key Vault.                                                                                                                                                                                                 | `string`                           | cluster-node-ubuntu-k3s                                                                                                            | no       |
| serverScriptSecretName           | The name for the server script secret in Key Vault.                                                                                                                                                                                               | `string`                           | cluster-server-ubuntu-k3s                                                                                                          | no       |
| telemetry_opt_out                | Whether to opt out of telemetry data collection.                                                                                                                                                                                                  | `bool`                             | `false`                                                                                                                            | no       |

## Resources

| Name                    | Type                              | API Version |
|:------------------------|:----------------------------------|:------------|
| ubuntuK3s               | `Microsoft.Resources/deployments` | 2025-04-01  |
| roleAssignment          | `Microsoft.Resources/deployments` | 2025-04-01  |
| keyVaultRoleAssignments | `Microsoft.Resources/deployments` | 2025-04-01  |
| deployScriptsToVm       | `Microsoft.Resources/deployments` | 2025-04-01  |

## Modules

| Name                    | Description                                                                                                     |
|:------------------------|:----------------------------------------------------------------------------------------------------------------|
| ubuntuK3s               | Configures K3s Kubernetes clusters on Ubuntu virtual machines and connects them to Azure Arc.                   |
| roleAssignment          | Assigns the required Kubernetes Cluster - Azure Arc Onboarding role to a managed identity or service principal. |
| keyVaultRoleAssignments | Assigns appropriate roles to access Key Vault secrets.                                                          |
| deployScriptsToVm       | Deploys a script to a virtual machine using the CustomScript extension.                                         |

## Module Details

### ubuntuK3s

Configures K3s Kubernetes clusters on Ubuntu virtual machines and connects them to Azure Arc.

#### Parameters for ubuntuK3s

| Name                             | Description                                                                                                                                                                                                                                                                                                                                                                              | Type                               | Default | Required |
|:---------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------|:--------|:---------|
| common                           | The common component configuration.                                                                                                                                                                                                                                                                                                                                                      | `[_1.Common](#user-defined-types)` | n/a     | yes      |
| arcResourceName                  | The name of the Azure Arc resource.                                                                                                                                                                                                                                                                                                                                                      | `string`                           | n/a     | yes      |
| arcTenantId                      | The tenant ID for Azure Arc resource.                                                                                                                                                                                                                                                                                                                                                    | `string`                           | n/a     | yes      |
| customLocationsOid               | The object id of the Custom Locations Entra ID application for your tenant.<br>If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre><br> | `string`                           | n/a     | yes      |
| shouldEnableArcAutoUpgrade       | Whether to enable auto-upgrades for Arc agents.                                                                                                                                                                                                                                                                                                                                          | `bool`                             | n/a     | yes      |
| arcOnboardingSpClientId          | The Service Principal Client ID for Arc onboarding.                                                                                                                                                                                                                                                                                                                                      | `string`                           | n/a     | no       |
| arcOnboardingSpClientSecret      | The Service Principal Client Secret for Arc onboarding.                                                                                                                                                                                                                                                                                                                                  | `securestring`                     | n/a     | no       |
| clusterAdminOid                  | The Object ID that will be given cluster-admin permissions.                                                                                                                                                                                                                                                                                                                              | `string`                           | n/a     | no       |
| clusterAdminUpn                  | The User Principal Name that will be given cluster-admin permissions.                                                                                                                                                                                                                                                                                                                    | `string`                           | n/a     | no       |
| clusterServerHostMachineUsername | Username for the host machine with kube-config settings.                                                                                                                                                                                                                                                                                                                                 | `string`                           | n/a     | yes      |
| clusterServerIp                  | The IP address for the server for the cluster. (Needed for mult-node cluster)                                                                                                                                                                                                                                                                                                            | `string`                           | n/a     | no       |
| deployAdminOid                   | The Object ID that will be given deployment admin permissions.                                                                                                                                                                                                                                                                                                                           | `string`                           | n/a     | no       |
| serverToken                      | The token that will be given to the server for the cluster or used by agent nodes.                                                                                                                                                                                                                                                                                                       | `securestring`                     | n/a     | no       |
| deployUserTokenSecretName        | The name for the deploy user token secret in Key Vault.                                                                                                                                                                                                                                                                                                                                  | `string`                           | n/a     | yes      |
| keyVaultName                     | The name of the Key Vault to save the scripts to.                                                                                                                                                                                                                                                                                                                                        | `string`                           | n/a     | yes      |
| k3sTokenSecretName               | The name for the K3s token secret in Key Vault.                                                                                                                                                                                                                                                                                                                                          | `string`                           | n/a     | yes      |
| nodeScriptSecretName             | The name for the node script secret in Key Vault.                                                                                                                                                                                                                                                                                                                                        | `string`                           | n/a     | yes      |
| serverScriptSecretName           | The name for the server script secret in Key Vault.                                                                                                                                                                                                                                                                                                                                      | `string`                           | n/a     | yes      |
| shouldSkipAzCliLogin             | Should skip login process with Azure CLI on the server.                                                                                                                                                                                                                                                                                                                                  | `bool`                             | n/a     | yes      |
| shouldSkipInstallingAzCli        | Should skip downloading and installing Azure CLI on the server.                                                                                                                                                                                                                                                                                                                          | `bool`                             | n/a     | yes      |

#### Resources for ubuntuK3s

| Name                         | Type                                | API Version |
|:-----------------------------|:------------------------------------|:------------|
| keyVault::serverScriptSecret | `Microsoft.KeyVault/vaults/secrets` | 2024-11-01  |
| keyVault::nodeScriptSecret   | `Microsoft.KeyVault/vaults/secrets` | 2024-11-01  |

#### Outputs for ubuntuK3s

| Name                          | Type           | Description                                                                                      |
|:------------------------------|:---------------|:-------------------------------------------------------------------------------------------------|
| clusterServerScript           | `securestring` | The script for setting up the host machine for the cluster server.                               |
| clusterNodeScript             | `securestring` | The script for setting up the host machine for the cluster node.                                 |
| clusterServerScriptSecretName | `string`       | The Key Vault Secret name for the script for setting up the host machine for the cluster server. |
| clusterNodeScriptSecretName   | `string`       | The Key Vault Secret name for the script for setting up the host machine for the cluster node.   |

### roleAssignment

Assigns the required Kubernetes Cluster - Azure Arc Onboarding role to a managed identity or service principal.

#### Parameters for roleAssignment

| Name                     | Description                                                                      | Type     | Default | Required |
|:-------------------------|:---------------------------------------------------------------------------------|:---------|:--------|:---------|
| arcOnboardingPrincipalId | The Principal ID for the identity that will be assigned the Arc Onboarding role. | `string` | n/a     | yes      |

#### Resources for roleAssignment

| Name                                                                                                       | Type                                      | API Version |
|:-----------------------------------------------------------------------------------------------------------|:------------------------------------------|:------------|
| [guid(resourceGroup().id, parameters('arcOnboardingPrincipalId'), '34e09817-6cbe-4d01-b1a2-e0eac5743d41')] | `Microsoft.Authorization/roleAssignments` | 2022-04-01  |

#### Outputs for roleAssignment

| Name             | Type     | Description                                                                  |
|:-----------------|:---------|:-----------------------------------------------------------------------------|
| roleAssignmentId | `string` | The ID of the role assignment for Kubernetes Cluster - Azure Arc Onboarding. |

### keyVaultRoleAssignments

Assigns appropriate roles to access Key Vault secrets.

#### Parameters for keyVaultRoleAssignments

| Name                     | Description                                                            | Type     | Default | Required |
|:-------------------------|:-----------------------------------------------------------------------|:---------|:--------|:---------|
| arcOnboardingPrincipalId | The principal ID of the Arc identity that needs access to the secrets. | `string` | n/a     | yes      |
| keyVaultName             | The name of the Key Vault containing the scripts.                      | `string` | n/a     | yes      |
| nodeScriptSecretName     | The name for the node script secret in Key Vault.                      | `string` | n/a     | yes      |
| serverScriptSecretName   | The name for the server script secret in Key Vault.                    | `string` | n/a     | yes      |

#### Resources for keyVaultRoleAssignments

| Name                                                                                                                                             | Type                                      | API Version |
|:-------------------------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------|:------------|
| [guid(resourceGroup().id, parameters('arcOnboardingPrincipalId'), 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')]                                       | `Microsoft.Authorization/roleAssignments` | 2022-04-01  |
| [guid(resourceGroup().id, parameters('arcOnboardingPrincipalId'), parameters('serverScriptSecretName'), '21090545-7ca7-4776-b22c-e363652d74d2')] | `Microsoft.Authorization/roleAssignments` | 2022-04-01  |
| [guid(resourceGroup().id, parameters('arcOnboardingPrincipalId'), parameters('serverScriptSecretName'), '4633458b-17de-408a-b874-0445c86b69e6')] | `Microsoft.Authorization/roleAssignments` | 2022-04-01  |
| [guid(resourceGroup().id, parameters('arcOnboardingPrincipalId'), parameters('nodeScriptSecretName'), '21090545-7ca7-4776-b22c-e363652d74d2')]   | `Microsoft.Authorization/roleAssignments` | 2022-04-01  |
| [guid(resourceGroup().id, parameters('arcOnboardingPrincipalId'), parameters('nodeScriptSecretName'), '4633458b-17de-408a-b874-0445c86b69e6')]   | `Microsoft.Authorization/roleAssignments` | 2022-04-01  |

### deployScriptsToVm

Deploys a script to a virtual machine using the CustomScript extension.

#### Parameters for deployScriptsToVm

| Name                            | Description                                                        | Type                               | Default | Required |
|:--------------------------------|:-------------------------------------------------------------------|:-----------------------------------|:--------|:---------|
| common                          | The common component configuration.                                | `[_1.Common](#user-defined-types)` | n/a     | yes      |
| clusterNodeVirtualMachineNames  | The node virtual machines names.                                   | `array`                            | n/a     | yes      |
| clusterNodeScript               | The script for setting up the host machine for the cluster node.   | `securestring`                     | n/a     | yes      |
| clusterServerVirtualMachineName | The server virtual machines name.                                  | `string`                           | n/a     | yes      |
| clusterServerScript             | The script for setting up the host machine for the cluster server. | `securestring`                     | n/a     | yes      |

#### Resources for deployScriptsToVm

| Name                                                | Type                                           | API Version |
|:----------------------------------------------------|:-----------------------------------------------|:------------|
| clusterServerVirtualMachine::linuxServerScriptSetup | `Microsoft.Compute/virtualMachines/extensions` | 2024-11-01  |
| linuxNodeScriptSetup                                | `Microsoft.Compute/virtualMachines/extensions` | 2024-11-01  |

## User Defined Types

### `_1.Common`

Common settings for the components.

| Property       | Type     | Description                                                      |
|:---------------|:---------|:-----------------------------------------------------------------|
| resourcePrefix | `string` | Prefix for all resources in this module                          |
| location       | `string` | Location for all resources in this module                        |
| environment    | `string` | Environment for all resources in this module: dev, test, or prod |
| instance       | `string` | Instance identifier for naming resources: 001, 002, etc...       |

## Outputs

| Name                                 | Type     | Description                                                        |
|:-------------------------------------|:---------|:-------------------------------------------------------------------|
| connectedClusterName                 | `string` | The connected cluster name                                         |
| connectedClusterResourceGroupName    | `string` | The connected cluster resource group name                          |
| azureArcProxyCommand                 | `string` | Azure Arc proxy command for accessing the cluster                  |
| clusterServerScriptSecretName        | `string` | The name of the Key Vault secret containing the server script      |
| clusterNodeScriptSecretName          | `string` | The name of the Key Vault secret containing the node script        |
| clusterServerScriptSecretShowCommand | `string` | The AZ CLI command to get the cluster server script from Key Vault |
| clusterNodeScriptSecretShowCommand   | `string` | The AZ CLI command to get the cluster node script from Key Vault   |

<!-- END_BICEP_DOCS -->