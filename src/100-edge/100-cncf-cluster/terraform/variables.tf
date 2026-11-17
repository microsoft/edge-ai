/*
 * Required Variables
 */

variable "should_get_custom_locations_oid" {
  type        = bool
  description = <<-EOF
  Whether to get Custom Locations Object ID using Terraform's azuread provider. (Otherwise, provided by
  'custom_locations_oid' or `az connectedk8s enable-features` for custom-locations on cluster setup if not provided.)
  EOF
}

/*
 * Optional Variables
 */

variable "should_use_script_from_secrets_for_deploy" {
  type        = bool
  description = "Whether to use the deploy-script-secrets.sh script to fetch and execute deployment scripts from Key Vault"
  default     = true
}

variable "key_vault_script_secret_prefix" {
  type        = string
  description = "Optional prefix for the Key Vault script secret name when should_use_script_from_secrets_for_deploy is true."
  default     = ""
}

variable "should_deploy_script_to_vm" {
  type        = bool
  description = "Should deploy the scripts to the provided Azure VMs."
  default     = true
}

variable "script_output_filepath" {
  type        = string
  description = "The location of where to write out the script file. (Otherwise, '{path.root}/out')"
  default     = null
}

variable "should_output_cluster_node_script" {
  type        = bool
  description = "Whether to write out the script for setting up cluster node host machines. (Needed for multi-node clusters)"
  default     = false
}

variable "should_output_cluster_server_script" {
  type        = bool
  description = "Whether to write out the script for setting up the cluster server host machine."
  default     = false
}

variable "should_deploy_arc_machines" {
  type        = bool
  description = "Should deploy to Arc-connected servers instead of Azure VMs. When true, machine_id refers to an Arc-connected server ID."
  default     = false
}

variable "should_deploy_arc_agents" {
  type        = bool
  description = "Should deploy arc agents using helm charts instead of Azure CLI."
  default     = false
}

variable "should_deploy_over_ssh" {
  type        = bool
  description = "Should deliver the setup script over 'az ssh arc' instead of a CustomScript extension. Requires Azure CLI with the 'ssh' extension where Terraform runs."
  default     = false
}

variable "ssh_local_user" {
  type        = string
  description = "Local account on the Arc-connected machines used for SSH delivery; must have passwordless sudo."
  default     = null
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path on the machine running Terraform to the private key authorized for 'ssh_local_user'."
  default     = null
}

variable "should_create_ssh_endpoint" {
  type        = bool
  description = "Whether SSH delivery creates the Hybrid Connectivity default endpoint and SSH service configuration. Needed for the Azure Local non-AKS flow where these do not already exist."
  default     = false
}

variable "should_assign_roles" {
  description = "Whether to assign Key Vault roles to identity or service principal."
  type        = bool
  default     = true
}

/*
 * Optional - Key Vault Parameters
 */

variable "should_upload_to_key_vault" {
  type        = bool
  description = "Whether to upload the scripts to Key Vault as secrets."
  default     = true
}

/*
 * Optional - Azure Arc Parameters
 */

variable "custom_locations_oid" {
  type        = string
  description = <<-EOF
  The object id of the Custom Locations Entra ID application for your tenant.
  If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.

  ```sh
  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
  ```
  EOF
  default     = null
}

variable "should_enable_arc_auto_upgrade" {
  type        = bool
  description = "Enable or disable auto-upgrades of Arc agents. (Otherwise, 'false' for 'env=prod' else 'true' for all other envs)."
  default     = null
}

variable "http_proxy" {
  type        = string
  description = "HTTP proxy URL"
  default     = null
}

/*
 * Optional - Cluster and Host Machine Parameters
 */

variable "cluster_admin_oid" {
  type        = string
  description = "The Object ID that will be given cluster-admin permissions with the new cluster. (Otherwise, current logged in user Object ID if 'should_add_current_user_cluster_admin=true')"
  default     = null
}

variable "cluster_admin_oid_type" {
  type        = string
  description = "The principal type of cluster_admin_oid for Azure RBAC assignments. Ignored when using current user (defaults to 'User')"
  default     = "User"
  validation {
    condition     = contains(["User", "Group", "ServicePrincipal"], var.cluster_admin_oid_type)
    error_message = "Must be one of: User, Group, ServicePrincipal"
  }
}

variable "cluster_admin_upn" {
  type        = string
  description = "The User Principal Name that will be given cluster-admin permissions with the new cluster. (Otherwise, current logged in user UPN if 'should_add_current_user_cluster_admin=true')"
  default     = null
}

variable "cluster_admin_group_oid" {
  type        = string
  description = "The Entra ID group Object ID that will be given cluster-admin permissions and Azure Arc RBAC access for 'az connectedk8s proxy'"
  default     = null
}

variable "cluster_server_ip" {
  type        = string
  description = "The IP Address for the cluster server that the cluster nodes will use to connect."
  default     = null
}

variable "cluster_server_token" {
  type        = string
  description = "The token that will be given to the server for the cluster or used by the agent nodes to connect them to the cluster. (ex. <https://docs.k3s.io/cli/token>)"
  default     = null
  sensitive   = true
}

variable "should_generate_cluster_server_token" {
  type        = bool
  description = "Should generate token used by the server. ('cluster_server_token' must be null if this is 'true')"
  default     = false
}

variable "cluster_server_host_machine_username" {
  type        = string
  description = <<-EOF
  Username used for the host machines that will be given kube-config settings on setup.
  (Otherwise, 'resource_prefix' if it exists as a user)
  EOF
  default     = null
}

variable "should_add_current_user_cluster_admin" {
  type        = bool
  description = "Gives the current logged in user cluster-admin permissions with the new cluster."
  default     = true
}

variable "should_skip_az_cli_login" {
  type        = bool
  description = "Should skip login process with Azure CLI on the server. (Skipping assumes 'az login' has been completed prior to script execution)"
  default     = false
}

variable "should_skip_installing_az_cli" {
  type        = bool
  description = "Should skip downloading and installing Azure CLI on the server. (Skipping assumes the server will already have the Azure CLI)"
  default     = false
}

variable "az_mode" {
  type        = string
  description = "How Azure CLI is provided on the host: 'auto' resolves to an existing host CLI, then a container runtime, then a package install; 'container' requires a container runtime; 'host' requires the CLI on the host."
  default     = null

  validation {
    condition     = var.az_mode == null || contains(["auto", "container", "host"], coalesce(var.az_mode, "auto"))
    error_message = "The 'az_mode' must be one of 'auto', 'container', or 'host'."
  }
}

variable "az_cli_image" {
  type        = string
  description = "The Azure CLI container image used when 'az_mode' resolves to 'container'. (Digest-pinned references are recommended for production)"
  default     = null
}
