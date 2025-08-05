/*
 * Required Variables
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
}

/*
 * Optional Variables
 */

variable "aio_resource_group_name" {
  type        = string
  description = <<-EOF
    The name of the Resource Group that will be used to connect the new cluster to Azure Arc.
    (Otherwise, 'rg-{var.resource_prefix}-{var.environment}-{var.instance}' Does not need to exist for output script)"
EOF
  default     = null
}

variable "arc_onboarding_identity_name" {
  description = "The Principal ID for the identity that will be used for onboarding the cluster to Arc."
  type        = string
  default     = null
}

variable "arc_onboarding_sp" {
  type = object({
    client_id     = string
    object_id     = string
    client_secret = string
  })
  sensitive = true
  default   = null
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc..."
  default     = "001"
}

variable "cluster_server_host_machine_username" {
  type        = string
  description = <<-EOF
    Username used for the host machines that will be given kube-config settings on setup.
    (Otherwise, 'resource_prefix' if it exists as a user)
EOF
  default     = null
}

variable "should_get_custom_locations_oid" {
  type        = bool
  description = <<-EOF
    Whether to get Custom Locations Object ID using Terraform's azuread provider. (Otherwise, provided by
    'custom_locations_oid' or `az connectedk8s enable-features` for custom-locations on cluster setup if not provided.)
EOF
  default     = true
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
  default     = null
}

variable "enable_arc_auto_upgrade" {
  type        = bool
  description = "Enable or disable auto-upgrades of Arc agents. (Otherwise, 'false' for 'env=prod' else 'true' for all other envs)."
  default     = null
}

variable "should_add_current_user_cluster_admin" {
  type        = bool
  description = "Gives the current logged in user cluster-admin permissions with the new cluster."
  default     = true
}

variable "should_assign_roles" {
  description = "Whether to assign Key Vault roles to identity or service principal."
  type        = bool
  default     = false
}

variable "cluster_admin_oid" {
  type        = string
  description = "The Object ID that will be given cluster-admin permissions with the new cluster. (Otherwise, current logged in user Object ID if 'should_add_current_user_cluster_admin=true')"
  default     = null
}

variable "cluster_admin_upn" {
  type        = string
  description = "The User Principal Name that will be given cluster-admin permissions with the new cluster. (Otherwise, current logged in user UPN if 'should_add_current_user_cluster_admin=true')"
  default     = null
}

variable "should_output_cluster_server_script" {
  type        = bool
  description = "Whether to write out the script for setting up the cluster server host machine."
  default     = true
}

variable "should_output_cluster_node_script" {
  type        = bool
  description = "Whether to write out the script for setting up cluster node host machines. (Needed for multi-node clusters)"
  default     = false
}

variable "script_output_filepath" {
  type        = string
  description = "The location of where to write out the script file. (Otherwise, '{path.root}/out')"
  default     = null
}

/*
 * Optional - Key Vault Parameters
 */

variable "should_upload_to_key_vault" {
  type        = bool
  description = "Whether to upload the scripts to Key Vault as secrets."
  default     = false
}

variable "key_vault_name" {
  type        = string
  description = "The name of the Key Vault to store script secrets. If not provided, defaults to 'kv-{resource_prefix}-{environment}-{instance}'."
  default     = null
}
