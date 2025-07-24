/**
 * # Key Vault Certificate Publisher Module
 *
 * This module publishes certificates to Azure Key Vault using the exact same secret names
 * as defined in the SecretProviderClass resource. It supports both terraform-generated
 * certificates and externally provided certificates.
 */

// Write Server Certificates to Cluster A Key Vault
resource "azurerm_key_vault_secret" "cluster_a_server_root_ca_cert" {
  name         = "server-root-ca-crt"
  value        = var.certificates.server_root_ca_cert
  key_vault_id = var.cluster_a_key_vault_id

  tags = {
    certificate_type = "server-root-ca"
    cluster          = var.cluster_a_name
  }
}

resource "azurerm_key_vault_secret" "cluster_a_server_intermediate_ca_cert" {
  name         = "server-intermediate-ca-crt"
  value        = var.certificates.server_intermediate_ca_cert
  key_vault_id = var.cluster_a_key_vault_id

  tags = {
    certificate_type = "server-intermediate-ca"
    cluster          = var.cluster_a_name
  }
}

resource "azurerm_key_vault_secret" "cluster_a_server_leaf_cert" {
  name         = "server-leaf-ca-crt"
  value        = var.certificates.server_leaf_cert
  key_vault_id = var.cluster_a_key_vault_id

  tags = {
    certificate_type = "server-leaf"
    cluster          = var.cluster_a_name
  }
}

resource "azurerm_key_vault_secret" "cluster_a_server_leaf_key" {
  name         = "server-leaf-ca-key"
  value        = var.certificates.server_leaf_key
  key_vault_id = var.cluster_a_key_vault_id

  tags = {
    certificate_type = "server-leaf-key"
    cluster          = var.cluster_a_name
  }
}

// Write Client Certificates to Cluster A Key Vault
resource "azurerm_key_vault_secret" "cluster_a_client_root_ca_cert" {
  name         = "client-root-ca-crt"
  value        = var.certificates.client_root_ca_cert
  key_vault_id = var.cluster_a_key_vault_id

  tags = {
    certificate_type = "client-root-ca"
    cluster          = var.cluster_a_name
  }
}

resource "azurerm_key_vault_secret" "cluster_a_client_intermediate_ca_cert" {
  name         = "client-intermediate-ca-crt"
  value        = var.certificates.client_intermediate_ca_cert
  key_vault_id = var.cluster_a_key_vault_id

  tags = {
    certificate_type = "client-intermediate-ca"
    cluster          = var.cluster_a_name
  }
}

resource "azurerm_key_vault_secret" "cluster_a_client_leaf_cert" {
  name         = "client-leaf-ca-crt"
  value        = var.certificates.client_leaf_cert
  key_vault_id = var.cluster_a_key_vault_id

  tags = {
    certificate_type = "client-leaf"
    cluster          = var.cluster_a_name
  }
}

resource "azurerm_key_vault_secret" "cluster_a_client_leaf_key" {
  name         = "client-leaf-ca-key"
  value        = var.certificates.client_leaf_key
  key_vault_id = var.cluster_a_key_vault_id

  tags = {
    certificate_type = "client-leaf-key"
    cluster          = var.cluster_a_name
  }
}

// Write Server Certificates to Cluster B Key Vault
resource "azurerm_key_vault_secret" "cluster_b_server_root_ca_cert" {
  name         = "server-root-ca-crt"
  value        = var.certificates.server_root_ca_cert
  key_vault_id = var.cluster_b_key_vault_id

  tags = {
    certificate_type = "server-root-ca"
    cluster          = var.cluster_b_name
  }
}

resource "azurerm_key_vault_secret" "cluster_b_server_intermediate_ca_cert" {
  name         = "server-intermediate-ca-crt"
  value        = var.certificates.server_intermediate_ca_cert
  key_vault_id = var.cluster_b_key_vault_id

  tags = {
    certificate_type = "server-intermediate-ca"
    cluster          = var.cluster_b_name
  }
}

resource "azurerm_key_vault_secret" "cluster_b_server_leaf_cert" {
  name         = "server-leaf-ca-crt"
  value        = var.certificates.server_leaf_cert
  key_vault_id = var.cluster_b_key_vault_id

  tags = {
    certificate_type = "server-leaf"
    cluster          = var.cluster_b_name
  }
}

resource "azurerm_key_vault_secret" "cluster_b_server_leaf_key" {
  name         = "server-leaf-ca-key"
  value        = var.certificates.server_leaf_key
  key_vault_id = var.cluster_b_key_vault_id

  tags = {
    certificate_type = "server-leaf-key"
    cluster          = var.cluster_b_name
  }
}

// Write Client Certificates to Cluster B Key Vault
resource "azurerm_key_vault_secret" "cluster_b_client_root_ca_cert" {
  name         = "client-root-ca-crt"
  value        = var.certificates.client_root_ca_cert
  key_vault_id = var.cluster_b_key_vault_id

  tags = {
    certificate_type = "client-root-ca"
    cluster          = var.cluster_b_name
  }
}

resource "azurerm_key_vault_secret" "cluster_b_client_intermediate_ca_cert" {
  name         = "client-intermediate-ca-crt"
  value        = var.certificates.client_intermediate_ca_cert
  key_vault_id = var.cluster_b_key_vault_id

  tags = {
    certificate_type = "client-intermediate-ca"
    cluster          = var.cluster_b_name
  }
}

resource "azurerm_key_vault_secret" "cluster_b_client_leaf_cert" {
  name         = "client-leaf-ca-crt"
  value        = var.certificates.client_leaf_cert
  key_vault_id = var.cluster_b_key_vault_id

  tags = {
    certificate_type = "client-leaf"
    cluster          = var.cluster_b_name
  }
}

resource "azurerm_key_vault_secret" "cluster_b_client_leaf_key" {
  name         = "client-leaf-ca-key"
  value        = var.certificates.client_leaf_key
  key_vault_id = var.cluster_b_key_vault_id

  tags = {
    certificate_type = "client-leaf-key"
    cluster          = var.cluster_b_name
  }
}
