<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Terraform Certificate Generation Module

This module generates TLS certificates using Terraform's native TLS provider
instead of executing the Step CLI script. It creates the same certificate
hierarchy as the certs.sh script: Root CA, Intermediate CA, and Leaf certificates
for both server and client authentication.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| local | >= 2.0.0 |
| tls | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| tls | >= 4.0.0 |

## Resources

| Name | Type |
|------|------|
| [tls_cert_request.client_intermediate_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_cert_request.client_leaf](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_cert_request.server_intermediate_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_cert_request.server_leaf](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_locally_signed_cert.client_intermediate_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_locally_signed_cert.client_leaf](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_locally_signed_cert.server_intermediate_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_locally_signed_cert.server_leaf](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_private_key.client_intermediate_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.client_leaf](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.client_root_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.server_intermediate_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.server_leaf](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.server_root_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.client_root_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [tls_self_signed_cert.server_root_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| server\_vm\_private\_ip | The private IP address of the server VM to use as Subject Alternative Name (SAN) in certificates. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| certificates | All generated certificates and keys in a single object. |
| client\_intermediate\_ca\_cert | Client Intermediate CA certificate. |
| client\_intermediate\_ca\_key | Client Intermediate CA private key. |
| client\_leaf\_cert | Client leaf certificate (bundled with chain). |
| client\_leaf\_key | Client leaf certificate private key. |
| client\_root\_ca\_cert | Client Root CA certificate. |
| client\_root\_ca\_key | Client Root CA private key. |
| server\_intermediate\_ca\_cert | Server Intermediate CA certificate. |
| server\_intermediate\_ca\_key | Server Intermediate CA private key. |
| server\_leaf\_cert | Server leaf certificate (bundled with chain). |
| server\_leaf\_key | Server leaf certificate private key. |
| server\_root\_ca\_cert | Server Root CA certificate. |
| server\_root\_ca\_key | Server Root CA private key. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
