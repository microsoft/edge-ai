# Secret Provider Class Module

This module creates Azure Key Vault Secret Provider Classes for Azure IoT Operations when certificate generation is disabled. It provisions `Microsoft.SecretSyncController/azureKeyVaultSecretProviderClasses` resources for both clusters to enable secret synchronization from Key Vault.

## Usage

This module is typically used as an alternative to the certificate generation module when `should_create_certificates` is set to `false`. It sets up the necessary secret provider classes for both clusters in the dual-peered cluster blueprint.

```hcl
module "secret_provider_class" {
  count  = var.should_create_certificates ? 0 : 1
  source = "./modules/secret-provider-class"

  cluster_a_name                    = local.cluster_a_name
  cluster_a_location               = var.location
  cluster_a_resource_group         = module.cluster_a_cloud_resource_group.resource_group
  cluster_a_custom_location_id     = module.cluster_a_edge_iot_ops.custom_location_id
  cluster_a_key_vault              = module.cluster_a_cloud_security_identity.key_vault
  cluster_a_secret_sync_identity   = module.cluster_a_cloud_security_identity.secret_sync_identity

  cluster_b_name                    = local.cluster_b_name
  cluster_b_location               = var.location
  cluster_b_resource_group         = module.cluster_b_cloud_resource_group.resource_group
  cluster_b_custom_location_id     = module.cluster_b_edge_iot_ops.custom_location_id
  cluster_b_key_vault              = module.cluster_b_cloud_security_identity.key_vault
  cluster_b_secret_sync_identity   = module.cluster_b_cloud_security_identity.secret_sync_identity

  depends_on = [
    module.cluster_a_edge_iot_ops,
    module.cluster_b_edge_iot_ops
  ]
}
```

## Dependencies

This module depends on:

- Azure IoT Operations instances being deployed for both clusters
- Custom locations being available for both clusters
- Key Vaults and secret sync identities being provisioned
- Azure Resource Manager (ARM) templates for the Secret Sync Controller

## Outputs

- `cluster_a_secret_provider_class` - The Secret Provider Class resource for Cluster A
- `cluster_b_secret_provider_class` - The Secret Provider Class resource for Cluster B
- `secret_sync_dependency` - Dependency marker for secret synchronization setup completion

## Conditional Usage

This module is designed to be used conditionally with the certificate generation module:

```hcl
// Either generate certificates...
module "certificate_generation" {
  count  = var.should_create_certificates ? 1 : 0
  source = "./modules/certificate-generation"
  // ...
}

// ...or set up secret provider classes
module "secret_provider_class" {
  count  = var.should_create_certificates ? 0 : 1
  source = "./modules/secret-provider-class"
  // ...
}
```
