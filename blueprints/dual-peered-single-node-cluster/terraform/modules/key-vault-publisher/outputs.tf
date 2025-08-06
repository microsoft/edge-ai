output "cluster_a_certificate_secret_ids" {
  description = "Resource IDs of certificate secrets created in Cluster A Key Vault."
  value = {
    server_root_ca_cert         = azurerm_key_vault_secret.cluster_a_server_root_ca_cert.id
    server_intermediate_ca_cert = azurerm_key_vault_secret.cluster_a_server_intermediate_ca_cert.id
    server_leaf_cert            = azurerm_key_vault_secret.cluster_a_server_leaf_cert.id
    server_leaf_key             = azurerm_key_vault_secret.cluster_a_server_leaf_key.id
    client_root_ca_cert         = azurerm_key_vault_secret.cluster_a_client_root_ca_cert.id
    client_intermediate_ca_cert = azurerm_key_vault_secret.cluster_a_client_intermediate_ca_cert.id
    client_leaf_cert            = azurerm_key_vault_secret.cluster_a_client_leaf_cert.id
    client_leaf_key             = azurerm_key_vault_secret.cluster_a_client_leaf_key.id
  }
}

output "cluster_b_certificate_secret_ids" {
  description = "Resource IDs of certificate secrets created in Cluster B Key Vault."
  value = {
    server_root_ca_cert         = azurerm_key_vault_secret.cluster_b_server_root_ca_cert.id
    server_intermediate_ca_cert = azurerm_key_vault_secret.cluster_b_server_intermediate_ca_cert.id
    server_leaf_cert            = azurerm_key_vault_secret.cluster_b_server_leaf_cert.id
    server_leaf_key             = azurerm_key_vault_secret.cluster_b_server_leaf_key.id
    client_root_ca_cert         = azurerm_key_vault_secret.cluster_b_client_root_ca_cert.id
    client_intermediate_ca_cert = azurerm_key_vault_secret.cluster_b_client_intermediate_ca_cert.id
    client_leaf_cert            = azurerm_key_vault_secret.cluster_b_client_leaf_cert.id
    client_leaf_key             = azurerm_key_vault_secret.cluster_b_client_leaf_key.id
  }
}

output "certificate_secret_names" {
  description = "Names of certificate secrets created in Key Vault (same for both clusters)."
  value = {
    server_root_ca_cert         = "server-root-ca-crt"
    server_intermediate_ca_cert = "server-intermediate-ca-crt"
    server_leaf_cert            = "server-leaf-ca-crt"
    server_leaf_key             = "server-leaf-ca-key"
    client_root_ca_cert         = "client-root-ca-crt"
    client_intermediate_ca_cert = "client-intermediate-ca-crt"
    client_leaf_cert            = "client-leaf-ca-crt"
    client_leaf_key             = "client-leaf-ca-key"
  }
}
