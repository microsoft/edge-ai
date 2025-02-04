/*
 * Optional Variables
 */

variable "vm_username" {
  type        = string
  description = "Name for the VM user to create on the target VM. If left empty, a random name will be generated"
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
