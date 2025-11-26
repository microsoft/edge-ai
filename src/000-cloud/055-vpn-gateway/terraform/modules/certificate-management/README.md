<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Certificate Management for VPN Gateway

Manages root certificates for VPN Gateway Point-to-Site authentication.
Supports auto-generation with TLS provider, existing certificate retrieval,
and Key Vault storage for secure certificate management.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.51.0 |
| tls | >= 4.0.6 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.51.0 |
| tls | >= 4.0.6 |

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_secret.vpn_root_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.vpn_root_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [tls_private_key.vpn_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.vpn_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [azurerm_key_vault_secret.existing_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module | `string` | n/a | yes |
| instance | Instance identifier for naming resources | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| should\_generate\_ca | Whether to generate a new CA certificate. When false, uses existing certificate from Key Vault | `bool` | n/a | yes |
| certificate\_subject | Certificate subject information for auto-generated certificates | ```object({ common_name = string organization = string organizational_unit = string country = string province = string locality = string })``` | ```{ "common_name": "VPN Gateway Root Certificate", "country": "US", "locality": "Redmond", "organization": "Edge AI Accelerator", "organizational_unit": "IT", "province": "WA" }``` | no |
| certificate\_validity\_days | Validity period in days for auto-generated certificates | `number` | `365` | no |
| existing\_certificate\_name | Name of existing certificate in Key Vault when should\_generate\_ca is false | `string` | `null` | no |
| key\_vault | Key Vault object for certificate storage | ```object({ id = string name = string vault_uri = string })``` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| certificate\_name | The name of the root certificate |
| certificate\_source | The source of the certificate for debugging |
| certificate\_subject | The certificate subject information |
| public\_certificate\_data | The public certificate data for VPN Gateway configuration |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
