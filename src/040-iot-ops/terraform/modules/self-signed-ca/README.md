<!-- BEGIN_TF_DOCS -->
# Generate AIO CA

Generates a Root CA and Intermediate CA for use with Azure IoT Operations (AIO).

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

## Providers

The following providers are used by this module:

- tls

## Resources

The following resources are used by this module:

- [tls_cert_request.intermediate_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) (resource)
- [tls_locally_signed_cert.intermediate_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) (resource)
- [tls_private_key.intermediate_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) (resource)
- [tls_private_key.root_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) (resource)
- [tls_self_signed_cert.root_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) (resource)

## Outputs

The following outputs are exported:

### aio\_ca

Description: n/a
<!-- END_TF_DOCS -->
