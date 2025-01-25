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

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc..."
  default     = "001"
}

variable "resource_group_name" {
  type        = string
  description = "The name for the resource group. (Otherwise, 'rg-{var.resource_prefix}-{var.environment}-{var.instance}')"
  default     = null
}

variable "vm_username" {
  type        = string
  description = "Name for the VM user to create on the target VM. If left empty, a random name will be generated"
  default     = null
}

variable "linux_virtual_machine_name" {
  type        = string
  description = "The name for the Linux Virtual Machine resource. (Otherwise, '{var.resource_prefix}-aio-edge-vm')"
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

variable "arc_auto_upgrade" {
  type        = bool
  description = "Enable or disable auto-upgrades of Arc agents. (Meant for dev environments, avoid auto-upgrade in prod)."
  default     = true
}

variable "add_current_entra_user_cluster_admin" {
  type        = bool
  description = "Adds the current user as cluster-admin cluster role binding"
  default     = true
}

variable "arc_onboarding_sp_client_id" {
  type        = string
  description = "The Service Principal Client ID with 'Kubernetes Cluster - Azure Arc Onboarding' permissions."
  default     = null
}

variable "arc_onboarding_sp_client_secret" {
  type        = string
  description = "The Service Principal Client Secret use for automation."
  sensitive   = true
  default     = null
}
