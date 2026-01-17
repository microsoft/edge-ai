<!-- BEGIN_TF_DOCS -->
# Command Invoke Module

Internal module for executing AKS Run Command actions with optional file attachments.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| archive   | >= 2.5.0        |
| azapi     | >= 2.3.0        |
| random    | >= 3.5.1        |

## Providers

| Name    | Version  |
|---------|----------|
| archive | >= 2.5.0 |
| azapi   | >= 2.3.0 |

## Resources

| Name                                                                                                                              | Type     |
|-----------------------------------------------------------------------------------------------------------------------------------|----------|
| [archive_file.attachments](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/resources/file)                  | resource |
| [azapi_resource_action.command_invoke](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource_action) | resource |

## Inputs

| Name             | Description                                                      | Type     | Default | Required |
|------------------|------------------------------------------------------------------|----------|---------|:--------:|
| cluster\_id      | AKS cluster resource ID                                          | `string` | n/a     |   yes    |
| command          | kubectl/helm command to execute (nullable; null -> empty string) | `string` | n/a     |   yes    |
| file\_path       | Path to a single file to attach                                  | `string` | n/a     |   yes    |
| folder\_path     | Path to a single folder whose contents are attached              | `string` | n/a     |   yes    |
| timeout\_minutes | Execution timeout (minutes)                                      | `number` | n/a     |   yes    |

## Outputs

| Name                | Description                                                 |
|---------------------|-------------------------------------------------------------|
| exit\_code          | The exit code of the command execution.                     |
| id                  | The ID of the run command execution.                        |
| logs                | The logs from the command execution.                        |
| provisioning\_state | The provisioning state of the command execution.            |
| success             | Whether the command execution was successful (exit code 0). |
<!-- END_TF_DOCS -->
