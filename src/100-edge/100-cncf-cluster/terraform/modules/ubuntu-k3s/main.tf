/**
 * # Ubuntu k3s
 *
 * Sets up and deploys a script to a VM host that will setup the k3s cluster,
 * connect the cluster to Arc, add cluster admins to the cluster, enable workload identity,
 * along with installing extensions for cluster connect and custom locations.
 */

locals {
  cluster_server_url = var.cluster_server_ip != null ? "https://${var.cluster_server_ip}:6443" : null

  # Common environment variable shared between 'server' or 'agent' k3s node setup.
  common_env_var = {
    ENVIRONMENT             = var.environment
    ARC_RESOURCE_GROUP_NAME = var.aio_resource_group.name
    ARC_RESOURCE_NAME       = var.arc_resource_name

    K3S_URL     = coalesce(local.cluster_server_url, "$${K3S_URL}")
    K3S_TOKEN   = try(coalesce(var.cluster_server_token, random_string.cluster_server_token[0].result), "$${K3S_TOKEN}")
    K3S_VERSION = "$${K3S_VERSION}"

    // TODO: Support AKV in Terraform for token secrets, must add role assignments for AKV to arc onboarding identity.
    AKV_NAME             = "$${AKV_NAME}"
    AKV_K3S_TOKEN_SECRET = "$${AKV_K3S_TOKEN_SECRET}"

    AKV_DEPLOY_SAT_SECRET = "$${AKV_DEPLOY_SAT_SECRET}" // Skip assuming ARM DeploymentScripts will not be used with Terraform.
    ARC_AUTO_UPGRADE      = coalesce(var.should_enable_arc_auto_upgrade, lower(var.environment) != "prod")
    ARC_SP_CLIENT_ID      = coalesce(try(var.arc_onboarding_sp.client_id, null), "$${ARC_SP_CLIENT_ID}")
    ARC_SP_SECRET         = coalesce(try(var.arc_onboarding_sp.client_secret, null), "$${ARC_SP_SECRET}")
    ARC_TENANT_ID         = var.arc_tenant_id
    AZ_CLI_VER            = "$${AZ_CLI_VER}"
    AZ_CONNECTEDK8S_VER   = "$${AZ_CONNECTEDK8S_VER}"
    CUSTOM_LOCATIONS_OID  = var.custom_locations_oid
    DEVICE_USERNAME       = var.cluster_server_host_machine_username
    SKIP_INSTALL_AZ_CLI   = var.should_skip_installing_az_cli ? "true" : "$${SKIP_INSTALL_AZ_CLI}"
    SKIP_AZ_LOGIN         = var.should_skip_az_cli_login ? "true" : "$${SKIP_AZ_LOGIN}"
    SKIP_INSTALL_K3S      = "$${SKIP_INSTALL_K3S}"
    SKIP_INSTALL_KUBECTL  = "$${SKIP_INSTALL_KUBECTL}"
    SKIP_DEPLOY_SAT       = "true" // Skip assuming ARM DeploymentScripts will not be used with Terraform.
  }

  # Server specific environment variables for the k3s node setup.
  server_env_var = {
    K3S_NODE_TYPE     = "server"
    CLUSTER_ADMIN_OID = coalesce(var.cluster_admin_oid, "$${CLUSTER_ADMIN_OID}")
    CLUSTER_ADMIN_UPN = coalesce(var.cluster_admin_upn, "$${CLUSTER_ADMIN_UPN}")
    SKIP_ARC_CONNECT  = "$${SKIP_ARC_CONNECT}"
  }

  # Agent specific environment variables for the k3s node setup.
  node_env_var = {
    K3S_NODE_TYPE     = "agent"
    CLUSTER_ADMIN_OID = "$${CLUSTER_ADMIN_OID}"
    CLUSTER_ADMIN_UPN = "$${CLUSTER_ADMIN_UPN}"
    SKIP_ARC_CONNECT  = "true"
  }

  # Read in script file and remove any carriage returns then split on separator in file '###\n' for parameters.
  script_file = split("###\n", replace(file("${path.module}/../../../scripts/k3s-device-setup.sh"), "\r", ""))

  ## Server
  # Apply Terraform templated variables to the parameters part of the script file.
  script_server_parameters = templatestring(local.script_file[0], merge(local.common_env_var, local.server_env_var))
  # Join the script back together with the rendered parameters along with the rest of the file.
  script_server_rendered = join("###\n", concat([
    local.script_server_parameters
  ], slice(local.script_file, 1, length(local.script_file))))

  ## Agent
  # Apply Terraform templated variables to the parameters part of the script file.
  script_node_parameters = templatestring(local.script_file[0], merge(local.common_env_var, local.node_env_var))
  # Join the script back together with the rendered parameters along with the rest of the file.
  script_node_rendered = join("###\n", concat([
    local.script_node_parameters
  ], slice(local.script_file, 1, length(local.script_file))))
}

resource "random_string" "cluster_server_token" {
  count = var.should_generate_cluster_server_token ? 1 : 0

  length  = 24
  special = false
  numeric = true
  upper   = true
  lower   = true
}

resource "local_sensitive_file" "cluster_server_setup_script" {
  count = var.should_output_cluster_server_script ? 1 : 0

  filename        = coalesce(var.script_output_filepath, "${path.root}/out/${var.arc_resource_name}-server-setup.sh")
  content         = local.script_server_rendered
  file_permission = "755"
}

resource "local_sensitive_file" "cluster_node_setup_script" {
  count = var.should_output_cluster_node_script ? 1 : 0

  filename        = coalesce(var.script_output_filepath, "${path.root}/out/${var.arc_resource_name}-node-setup.sh")
  content         = local.script_node_rendered
  file_permission = "755"
}

/*
 * Key Vault Secrets
 */

// Create Key Vault Secret for Server Script
resource "azurerm_key_vault_secret" "server_script" {
  count = var.should_upload_to_key_vault ? 1 : 0

  name         = "ubuntu-k3s-server-script"
  value        = local.script_server_rendered
  key_vault_id = var.key_vault.id
}

// Create Key Vault Secret for Node Script
resource "azurerm_key_vault_secret" "node_script" {
  count = var.should_upload_to_key_vault ? 1 : 0

  name         = "ubuntu-k3s-node-script"
  value        = local.script_node_rendered
  key_vault_id = var.key_vault.id
}
