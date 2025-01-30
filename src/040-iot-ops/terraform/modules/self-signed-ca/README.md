<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Generate AIO CA

Generates a Root CA and Intermediate CA for use with Azure IoT Operations (AIO).

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| tls | n/a |

## Resources

| Name | Type |
|------|------|
| [tls_cert_request.intermediate_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_locally_signed_cert.intermediate_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_private_key.intermediate_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.root_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.root_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |

## Outputs

| Name | Description |
|------|-------------|
| aio\_ca | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
