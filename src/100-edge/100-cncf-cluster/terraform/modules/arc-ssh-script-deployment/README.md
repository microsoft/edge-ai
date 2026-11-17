<!-- BEGIN_TF_DOCS -->
# Arc SSH Script Deployment

Delivers a cluster setup script to an Azure Arc-connected machine over `az ssh arc` rather than a
CustomScript extension. Required for hosts where the extension handler environment cannot run the
script, and for resource groups whose deny assignments make extension resources undeletable.

Requires Azure CLI with the `ssh` extension on the machine running Terraform.

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.12.0, < 2.0 |
| azapi     | >= 2.3.0         |

## Providers

| Name      | Version  |
|-----------|----------|
| azapi     | >= 2.3.0 |
| terraform | n/a      |

## Resources

| Name                                                                                                                           | Type     |
|--------------------------------------------------------------------------------------------------------------------------------|----------|
| [azapi_resource.ssh_endpoint](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource)              | resource |
| [azapi_resource.ssh_service_configuration](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [terraform_data.ssh_script_deployment](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name                                            | Description                                                                                                | Type                                                                   | Default | Required |
|-------------------------------------------------|------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------|---------|:--------:|
| arc\_machine\_id                                | The ID of the Azure Arc-connected machine to deploy the script to.                                         | `string`                                                               | n/a     |   yes    |
| kubernetes\_distro                              | The Kubernetes distribution (e.g., 'k3s', 'aks') - Used to construct the Key Vault secret name.            | `string`                                                               | n/a     |   yes    |
| node\_type                                      | The node type (e.g., 'server', 'node') - Used to construct the Key Vault secret name.                      | `string`                                                               | n/a     |   yes    |
| secret\_name\_prefix                            | Optional prefix for the Key Vault secret name.                                                             | `string`                                                               | n/a     |   yes    |
| should\_use\_script\_from\_secrets\_for\_deploy | Whether to use the deploy-script-secrets.sh script to fetch and execute deployment scripts from Key Vault  | `bool`                                                                 | n/a     |   yes    |
| ssh\_local\_user                                | Local account on the Arc-connected machine used for the SSH session; must have passwordless sudo.          | `string`                                                               | n/a     |   yes    |
| ssh\_private\_key\_path                         | Path on the machine running Terraform to the private key authorized for 'ssh\_local\_user'.                | `string`                                                               | n/a     |   yes    |
| arc\_onboarding\_identity                       | User Assigned Managed Identity object for Arc onboarding with Key Vault access                             | ```object({ id = string client_id = string principal_id = string })``` | `null`  |    no    |
| key\_vault                                      | The Key Vault object containing id, name, and vault\_uri properties                                        | ```object({ id = string name = string vault_uri = string })```         | `null`  |    no    |
| script\_content                                 | The content of the script to deploy when not fetching from Key Vault.                                      | `string`                                                               | `null`  |    no    |
| should\_create\_ssh\_endpoint                   | Whether to create the Hybrid Connectivity default endpoint and SSH service configuration for this machine. | `bool`                                                                 | `false` |    no    |
| ssh\_port                                       | Port advertised by the SSH service configuration when 'should\_create\_ssh\_endpoint' is true.             | `number`                                                               | `22`    |    no    |

## Outputs

| Name              | Description                                                            |
|-------------------|------------------------------------------------------------------------|
| script\_deployed  | Whether a script was delivered to the Arc-connected machine over SSH.  |
| ssh\_endpoint\_id | The ID of the Hybrid Connectivity default endpoint, if it was created. |
<!-- END_TF_DOCS -->
