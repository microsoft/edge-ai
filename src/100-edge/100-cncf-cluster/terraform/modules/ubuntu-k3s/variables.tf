/*
 * Optional
 */

variable "should_deploy_script_to_vm" {
  type        = bool
  description = "Should deploy the scripts to the provided Azure VMs."
}

variable "script_output_filepath" {
  type        = string
  description = "The location of where to write out the script file. (Otherwise, '{path.root}/out')"
}

variable "should_output_cluster_node_script" {
  type        = bool
  description = "Whether to write out the script for setting up cluster node host machines. (Needed for multi-node clusters)"
}

variable "should_output_cluster_server_script" {
  type        = bool
  description = "Whether to write out the script for setting up the cluster server host machine."
}

/*
 * Optional - Key Vault Script Deployment Parameters
 */

variable "should_use_script_from_secrets_for_deploy" {
  type        = bool
  description = "Whether to use the deploy-script-secrets.sh script to fetch and execute deployment scripts from Key Vault."
}

variable "key_vault_script_secret_prefix" {
  type        = string
  description = "Optional prefix for the Key Vault script secret name when should_use_script_from_secrets_for_deploy is true."
}

/*
 * Optional - Key Vault Parameters
 */

variable "should_upload_to_key_vault" {
  type        = bool
  description = "Whether to upload the scripts to Key Vault as secrets."
}

/*
 * Optional - Azure Arc Parameters
 */

variable "arc_resource_name" {
  type        = string
  description = "The name of the new Azure Arc resource."
}

variable "arc_tenant_id" {
  type        = string
  description = "The ID of the Tenant for the new Azure Arc resource."
}

variable "custom_locations_oid" {
  type        = string
  description = <<-EOF
    The object id of the Custom Locations Entra ID application for your tenant.
    If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.

    ```sh
    az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
    ```
EOF
}

variable "should_enable_arc_auto_upgrade" {
  type        = bool
  description = "Enable or disable auto-upgrades of Arc agents. (Otherwise, 'false' for 'env=prod' else 'true' for all other envs)."
}

/*
 * Optional - Cluster and Host Machine Parameters
 */

variable "cluster_admin_oid" {
  type        = string
  description = "The Object ID that will be given cluster-admin permissions with the new cluster. (Otherwise, current logged in user if 'should_add_current_user_cluster_admin=true')"
}

variable "cluster_server_ip" {
  type        = string
  description = "The IP address for the server for the cluster. (Needed for mult-node cluster)"
}

variable "cluster_server_token" {
  type        = string
  description = "The token that will be given to the server for the cluster or used by the agent nodes to connect them to the cluster. (ex. <https://docs.k3s.io/cli/token>)"
  sensitive   = true
}

variable "should_generate_cluster_server_token" {
  type        = bool
  description = "Should generate token used by the server. ('cluster_server_token' must be null if this is 'true')"
  validation {
    condition     = var.cluster_server_token != null ? !var.should_generate_cluster_server_token : true
    error_message = "'should_generate_cluster_server_token' must be false if 'cluster_server_token' has been provided."
  }
}

variable "cluster_server_host_machine_username" {
  type        = string
  description = <<-EOF
    Username used for the host machines that will be given kube-config settings on setup.
    (Otherwise, 'resource_prefix' if it exists as a user)
EOF
}

variable "should_skip_az_cli_login" {
  type        = bool
  description = "Should skip login process with Azure CLI on the server. (Skipping assumes 'az login' has been completed prior to script execution)"
}

variable "should_skip_installing_az_cli" {
  type        = bool
  description = "Should skip downloading and installing Azure CLI on the server. (Skipping assumes the server will already have the Azure CLI)"
}
