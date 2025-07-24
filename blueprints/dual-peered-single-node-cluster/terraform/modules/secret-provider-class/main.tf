/**
 * # Secret Provider Class Module
 *
 * Creates Azure Key Vault Secret Provider Classes for Azure IoT Operations
 * when certificate generation is disabled. This module provisions the
 * Microsoft.SecretSyncController/azureKeyVaultSecretProviderClasses
 * resources for both clusters to enable secret synchronization from Key Vault.
 */

data "azurerm_subscription" "current" {}

// Secret Provider Class for Cluster A
resource "azapi_resource" "cluster_a_secret_provider_class" {
  type      = "Microsoft.SecretSyncController/azureKeyVaultSecretProviderClasses@2024-08-21-preview"
  name      = "spc-ops-aio-${var.cluster_a_name}"
  location  = var.cluster_a_location
  parent_id = var.cluster_a_resource_group.id

  body = {
    extendedLocation = {
      name = var.cluster_a_custom_location_id
      type = "CustomLocation"
    }
    properties = {
      clientId     = var.cluster_a_secret_sync_identity.client_id
      keyvaultName = var.cluster_a_key_vault.name
      tenantId     = data.azurerm_subscription.current.tenant_id
      objects = [
        {
          objectName = "server-root-ca-crt"
          objectType = "secret"
        },
        {
          objectName = "server-intermediate-ca-crt"
          objectType = "secret"
        },
        {
          objectName = "server-leaf-ca-crt"
          objectType = "secret"
        },
        {
          objectName = "server-leaf-ca-key"
          objectType = "secret"
        },
        {
          objectName = "client-root-ca-crt"
          objectType = "secret"
        },
        {
          objectName = "client-intermediate-ca-crt"
          objectType = "secret"
        },
        {
          objectName = "client-leaf-ca-crt"
          objectType = "secret"
        },
        {
          objectName = "client-leaf-ca-key"
          objectType = "secret"
        }
      ]
    }
  }
}

// Secret Provider Class for Cluster B
resource "azapi_resource" "cluster_b_secret_provider_class" {
  type      = "Microsoft.SecretSyncController/azureKeyVaultSecretProviderClasses@2024-08-21-preview"
  name      = "spc-ops-aio-${var.cluster_b_name}"
  location  = var.cluster_b_location
  parent_id = var.cluster_b_resource_group.id

  body = {
    extendedLocation = {
      name = var.cluster_b_custom_location_id
      type = "CustomLocation"
    }
    properties = {
      clientId     = var.cluster_b_secret_sync_identity.client_id
      keyvaultName = var.cluster_b_key_vault.name
      tenantId     = data.azurerm_subscription.current.tenant_id
      objects = [
        {
          objectName = "server-root-ca-crt"
          objectType = "secret"
        },
        {
          objectName = "server-intermediate-ca-crt"
          objectType = "secret"
        },
        {
          objectName = "server-leaf-ca-crt"
          objectType = "secret"
        },
        {
          objectName = "server-leaf-ca-key"
          objectType = "secret"
        },
        {
          objectName = "client-root-ca-crt"
          objectType = "secret"
        },
        {
          objectName = "client-intermediate-ca-crt"
          objectType = "secret"
        },
        {
          objectName = "client-leaf-ca-crt"
          objectType = "secret"
        },
        {
          objectName = "client-leaf-ca-key"
          objectType = "secret"
        }
      ]
    }
  }
}

// Secret Sync for Cluster A ConfigMap
resource "azapi_resource" "cluster_a_secret_sync" {
  type      = "Microsoft.SecretSyncController/secretSyncs@2024-08-21-preview"
  name      = var.cluster_a_synced_certificates_secret_name
  location  = var.cluster_a_location
  parent_id = var.cluster_a_resource_group.id

  body = {
    extendedLocation = {
      name = var.cluster_a_custom_location_id
      type = "CustomLocation"
    }
    properties = {
      secretProviderClassName = azapi_resource.cluster_a_secret_provider_class.name
      kubernetesSecretType    = "Opaque"
      serviceAccountName      = var.cluster_a_secret_sync_identity.client_id
      objectSecretMapping = [
        {
          sourcePath = "server-root-ca-crt"
          targetKey  = "server-root-ca-crt"
        }
      ]
    }
  }

  depends_on = [azapi_resource.cluster_a_secret_provider_class]
}

// Secret Sync for Cluster A Secret
resource "azapi_resource" "cluster_a_secret_sync" {
  type      = "Microsoft.SecretSyncController/secretSyncs@2024-08-21-preview"
  name      = var.site_client_secret_name
  location  = var.cluster_a_location
  parent_id = var.cluster_a_resource_group.id

  body = {
    extendedLocation = {
      name = var.cluster_a_custom_location_id
      type = "CustomLocation"
    }
    properties = {
      secretProviderClassName = azapi_resource.cluster_a_secret_provider_class.name
      kubernetesSecretType    = "Opaque"
      serviceAccountName      = var.cluster_a_secret_sync_identity.client_id
      objectSecretMapping = [
        {
          sourcePath = "client-intermediate-ca-crt"
          targetKey  = "client_intermediate_certs.pem"
        },
        {
          sourcePath = "client-leaf-ca-crt"
          targetKey  = "client_cert.pem"
        },
        {
          sourcePath = "client-leaf-ca-key"
          targetKey  = "client_key.pem"
        }
      ]
    }
  }

  depends_on = [azapi_resource.cluster_a_secret_provider_class]
}

// Secret Sync for Cluster B ConfigMap
resource "azapi_resource" "cluster_b_secret_sync" {
  type      = "Microsoft.SecretSyncController/secretSyncs@2024-08-21-preview"
  name      = var.cluster_b_synced_certificates_secret_name
  location  = var.cluster_b_location
  parent_id = var.cluster_b_resource_group.id

  body = {
    extendedLocation = {
      name = var.cluster_b_custom_location_id
      type = "CustomLocation"
    }
    properties = {
      secretProviderClassName = azapi_resource.cluster_b_secret_provider_class.name
      kubernetesSecretType    = "Opaque"
      serviceAccountName      = var.cluster_b_secret_sync_identity.client_id
      objectSecretMapping = [
        {
          sourcePath = "client-root-ca-crt"
          targetKey  = "client-root-ca-crt"
        }
      ]
    }
  }

  depends_on = [azapi_resource.cluster_b_secret_provider_class]
}

// Secret Sync for Cluster B TLS Secret
resource "azapi_resource" "cluster_b_secret_sync" {
  type      = "Microsoft.SecretSyncController/secretSyncs@2024-08-21-preview"
  name      = var.enterprise_broker_tls_cert_secret_name
  location  = var.cluster_b_location
  parent_id = var.cluster_b_resource_group.id

  body = {
    extendedLocation = {
      name = var.cluster_b_custom_location_id
      type = "CustomLocation"
    }
    properties = {
      secretProviderClassName = azapi_resource.cluster_b_secret_provider_class.name
      kubernetesSecretType    = "kubernetes.io/tls"
      serviceAccountName      = var.cluster_b_secret_sync_identity.client_id
      objectSecretMapping = [
        # Server Certificates
        {
          sourcePath = "server-leaf-ca-crt"
          targetKey  = "tls.crt"
        },
        {
          sourcePath = "server-leaf-ca-key"
          targetKey  = "tls.key"
        }
      ]
    }
  }

  depends_on = [azapi_resource.cluster_b_secret_provider_class]
}
