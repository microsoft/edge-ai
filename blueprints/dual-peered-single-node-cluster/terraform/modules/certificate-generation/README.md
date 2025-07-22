<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Certificate Generation Module

This module handles the generation of TLS certificates using the Step CLI.
It runs the certs.sh script with the server VM's private IP address as the Subject Alternative Name (SAN).

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.generate_certificates](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| certs\_output\_directory | Directory where the generated certificates will be stored. | `string` | n/a | yes |
| certs\_script\_path | Path to the certs.sh script for certificate generation. | `string` | n/a | yes |
| server\_vm\_private\_ip | The private IP address of the server VM to use as Subject Alternative Name (SAN) in certificates. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| certificate\_dependency | Dependency object for other modules to wait on certificate generation. |
| certificate\_generation\_result | Result of the certificate generation process. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
