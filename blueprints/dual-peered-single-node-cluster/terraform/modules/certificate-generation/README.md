# Certificate Generation Module

This module handles the generation of TLS certificates using the Step CLI tool. It executes the `certs.sh` script with the server VM's private IP address as the Subject Alternative Name (SAN) to ensure proper certificate validation for MQTT communication.

## Features

- **Dynamic IP Support**: Uses the actual server VM IP address as SAN
- **Step CLI Integration**: Leverages the Step CLI for certificate generation
- **Modular Design**: Clean module that executes when called (conditional execution handled by parent)
- **Modern Terraform**: Uses `terraform_data` resource for lifecycle management
- **Dependency Management**: Properly tracks when certificates are generated for downstream modules

## Requirements

- **Step CLI**: Must be installed on the machine running Terraform
- **Shell Access**: Requires ability to execute shell commands via `local-exec` provisioner
- **Terraform 1.9.8+**: Required for `terraform_data` resource support

## Usage

```terraform
# Conditional module execution - only runs when certificates should be created
module "certificate_generation" {
  count  = var.should_create_certificates ? 1 : 0
  source = "./modules/certificate-generation"

  server_vm_private_ip   = "10.1.1.4"
  certs_script_path      = "../scripts/certs.sh"
  certs_output_directory = "../certs"
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| server_vm_private_ip | The private IP address of the server VM to use as Subject Alternative Name (SAN) in certificates | `string` | n/a | yes |
| certs_script_path | Path to the certs.sh script for certificate generation | `string` | n/a | yes |
| certs_output_directory | Directory where the generated certificates will be stored | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| certificate_generation_result | Result of the certificate generation process including status and metadata |
| certificate_dependency | Dependency object for other modules to wait on certificate generation |

## Generated Certificates

When executed, the module generates the following certificate files:

### Server Certificates

- `l4-server-root-ca.crt` - Server root CA certificate
- `l4-server-root-ca.key` - Server root CA private key
- `l4-server-intermediate-ca.crt` - Server intermediate CA certificate
- `l4-server-intermediate-ca.key` - Server intermediate CA private key
- `l4-server-leaf-ca.crt` - Server leaf certificate (with VM IP as SAN)
- `l4-server-leaf-ca.key` - Server leaf private key

### Client Certificates

- `l4-client-root-ca.crt` - Client root CA certificate
- `l4-client-root-ca.key` - Client root CA private key
- `l4-client-intermediate-ca.crt` - Client intermediate CA certificate
- `l4-client-intermediate-ca.key` - Client intermediate CA private key
- `l4-client-leaf-ca.crt` - Client leaf certificate
- `l4-client-leaf-ca.key` - Client leaf private key

## Execution Triggers

The certificate generation re-runs when any of the following change (using `terraform_data.triggers_replace`):

- The server VM's private IP address changes
- The `certs.sh` script content is modified (based on file hash)

This ensures certificates are regenerated with the correct IP address whenever the infrastructure changes.

## Error Handling

The module includes built-in error handling:

- Validates Step CLI availability before execution
- Provides clear error messages if prerequisites are missing
- Ensures output directory exists before generation
- Makes the script executable before running

## Dependencies

Other modules should reference the `certificate_dependency` output to ensure certificates are generated before they are needed. Since the module uses `count`, use `try()` to handle the optional dependency:

```terraform
module "custom_script_deployment" {
  # ...other configuration...

  iot_ops_dependency = compact([
    module.cluster_a_edge_iot_ops,
    module.cluster_b_edge_iot_ops,
    try(module.certificate_generation[0].certificate_dependency, null)
  ])
}
```
