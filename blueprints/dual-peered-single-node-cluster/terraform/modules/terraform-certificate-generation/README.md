# Terraform Certificate Generation Module

This module generates TLS certificates using Terraform's native TLS provider instead of executing the Step CLI script. It creates the same certificate hierarchy as the `certs.sh` script: Root CA, Intermediate CA, and Leaf certificates for both server and client authentication.

## Overview

This module provides a pure Terraform alternative to the `certificate-generation` module, eliminating the need for external dependencies like the Step CLI. It generates the exact same certificates and file structure as the original `certs.sh` script.

## Generated Certificates

The module creates a complete PKI structure with the following certificates:

### Server Certificate Chain

1. **Server Root CA** (`l4-server-root-ca.crt/key`)
   - Common Name: "AIO Root CA"
   - Validity: 10 years
   - Self-signed root certificate

2. **Server Intermediate CA** (`l4-server-intermediate-ca.crt/key`)
   - Common Name: "AIO Intermediate CA 1"
   - Validity: 5 years
   - Signed by Server Root CA

3. **Server Leaf Certificate** (`l4-server-leaf-ca.crt/key`)
   - Common Name: "mqtts-endpoint"
   - Validity: 100 days (2400 hours)
   - Signed by Server Intermediate CA
   - Includes SAN (Subject Alternative Name) with the server VM's private IP
   - Bundled with certificate chain (leaf + intermediate + root)

### Client Certificate Chain

1. **Client Root CA** (`l4-client-root-ca.crt/key`)
   - Common Name: "Client Root CA"
   - Validity: 10 years
   - Self-signed root certificate

2. **Client Intermediate CA** (`l4-client-intermediate-ca.crt/key`)
   - Common Name: "Client Intermediate CA 1"
   - Validity: 5 years
   - Signed by Client Root CA

3. **Client Leaf Certificate** (`l4-client-leaf-ca.crt/key`)
   - Common Name: "client"
   - Validity: 100 days (2400 hours)
   - Signed by Client Intermediate CA
   - Bundled with certificate chain (leaf + intermediate + root)

## Usage

This module is designed to be used as an alternative to the `certificate-generation` module when you prefer pure Terraform implementation without external tool dependencies.

```hcl
module "terraform_certificate_generation" {
  count  = var.should_create_certificates && var.use_terraform_certificates ? 1 : 0
  source = "./modules/terraform-certificate-generation"

  server_vm_private_ip   = module.cluster_a_cloud_vm_host.virtual_machines[0].private_ip_address
  certs_output_directory = "${path.module}/../certs"

  depends_on = [
    module.cluster_a_cloud_vm_host,
    module.cluster_b_cloud_vm_host
  ]
}
```

## Advantages

- **No External Dependencies**: Pure Terraform implementation using TLS provider
- **Version Control Friendly**: Certificate generation is deterministic and reproducible
- **Cross-Platform**: Works on any platform that supports Terraform
- **State Tracking**: Certificates are tracked in Terraform state
- **Sensitive Value Handling**: Private keys are properly marked as sensitive

## Disadvantages

- **State File Security**: Private keys are stored in Terraform state (ensure state is encrypted and secured)
- **Certificate Rotation**: Requires Terraform apply to rotate certificates
- **Limited Customization**: Less flexible than Step CLI for advanced certificate features

## Security Considerations

- **State File Protection**: Ensure Terraform state files are encrypted and access-controlled
- **Private Key Security**: Private keys are marked as sensitive but still present in state
- **Certificate Rotation**: Plan for regular certificate rotation workflows
- **File Permissions**: Generated certificate files have default permissions (consider using `file_permission` if needed)

## Comparison with Step CLI Module

| Feature | Terraform Module | Step CLI Module |
|---------|-----------------|-----------------|
| External Dependencies | None | Requires Step CLI |
| Certificate Format | Standard X.509 | Step CLI format |
| Customization | Limited to TLS provider | Full Step CLI features |
| State Management | Terraform managed | File-based |
| Cross-Platform | Yes | Step CLI availability |
| Security | State file concerns | Local file concerns |

## File Structure

After successful execution, the following files are created in the specified output directory:

```plaintext
certs/
├── l4-server-root-ca.crt          # Server Root CA certificate
├── l4-server-root-ca.key          # Server Root CA private key
├── l4-server-intermediate-ca.crt  # Server Intermediate CA certificate
├── l4-server-intermediate-ca.key  # Server Intermediate CA private key
├── l4-server-leaf-ca.crt          # Server leaf certificate (bundled)
├── l4-server-leaf-ca.key          # Server leaf private key
├── l4-client-root-ca.crt          # Client Root CA certificate
├── l4-client-root-ca.key          # Client Root CA private key
├── l4-client-intermediate-ca.crt  # Client Intermediate CA certificate
├── l4-client-intermediate-ca.key  # Client Intermediate CA private key
├── l4-client-leaf-ca.crt          # Client leaf certificate (bundled)
└── l4-client-leaf-ca.key          # Client leaf private key
```

## Variables

| Name | Type | Description | Required |
|------|------|-------------|----------|
| `server_vm_private_ip` | string | The private IP address of the server VM to use as Subject Alternative Name (SAN) | Yes |
| `certs_output_directory` | string | Directory where the generated certificates will be stored | Yes |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `server_root_ca_cert` | Server Root CA certificate PEM | No |
| `server_intermediate_ca_cert` | Server Intermediate CA certificate PEM | No |
| `server_leaf_cert` | Server leaf certificate (bundled) PEM | No |
| `server_leaf_key` | Server leaf certificate private key PEM | Yes |
| `client_root_ca_cert` | Client Root CA certificate PEM | No |
| `client_intermediate_ca_cert` | Client Intermediate CA certificate PEM | No |
| `client_leaf_cert` | Client leaf certificate (bundled) PEM | No |
| `client_leaf_key` | Client leaf certificate private key PEM | Yes |
| `certificate_files` | List of all certificate files created | No |
| `certificate_dependency` | Dependency marker for completion | No |

## Dependencies

This module requires:

- Terraform >= 1.9.8
- TLS provider >= 4.0.0
- Local provider >= 2.0.0

## Example Integration

```hcl
# Variable to choose certificate generation method
variable "use_terraform_certificates" {
  type        = bool
  description = "Use Terraform TLS provider instead of Step CLI for certificate generation."
  default     = false
}

# Terraform-based certificate generation
module "terraform_certificate_generation" {
  count  = var.should_create_certificates && var.use_terraform_certificates ? 1 : 0
  source = "./modules/terraform-certificate-generation"

  server_vm_private_ip   = module.cluster_a_cloud_vm_host.virtual_machines[0].private_ip_address
  certs_output_directory = "${path.module}/../certs"

  depends_on = [
    module.cluster_a_cloud_vm_host,
    module.cluster_b_cloud_vm_host
  ]
}

# Step CLI-based certificate generation
module "certificate_generation" {
  count  = var.should_create_certificates && !var.use_terraform_certificates ? 1 : 0
  source = "./modules/certificate-generation"

  server_vm_private_ip   = module.cluster_a_cloud_vm_host.virtual_machines[0].private_ip_address
  certs_script_path      = "${path.module}/../scripts/certs.sh"
  certs_output_directory = "${path.module}/../certs"

  depends_on = [
    module.cluster_a_cloud_vm_host,
    module.cluster_b_cloud_vm_host
  ]
}
```
