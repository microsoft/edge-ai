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

variable "cluster_admin_oid" {
  type        = string
  description = "The Object ID that will be given cluster-admin permissions with the new cluster. (Otherwise, current logged in user if 'should_add_current_user_cluster_admin=true')"
  default     = null
}

variable "should_output_cluster_server_script" {
  type        = string
  description = "Whether to write out the script for setting up the cluster server host machine."
  default     = true
}

variable "should_output_cluster_node_script" {
  type        = string
  description = "Whether to write out the script for setting up cluster node host machines. (Needed for multi-node clusters)"
  default     = false
}

variable "script_output_filepath" {
  type        = string
  description = "The location of where to write out the script file. (Otherwise, '{path.root}/out')"
  default     = null
}
