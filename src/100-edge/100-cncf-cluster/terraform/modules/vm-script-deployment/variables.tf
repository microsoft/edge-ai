/*
 * Required Machine Variables
 */

variable "machine_id" {
  type        = string
  description = "The ID of the machine (VM or Arc-connected server) to deploy the script to."
}


variable "os_type" {
  type        = string
  description = "Operating system type (only linux supported)"
  default     = "linux"

  validation {
    condition     = var.os_type == "linux"
    error_message = "Only 'linux' is currently supported for os_type."
  }
}

variable "extension_name" {
  type        = string
  description = "The name of the Arc machine extension"
}

/*
 * Script Deployment Configuration Variables
 */

variable "should_use_script_from_secrets_for_deploy" {
  type        = bool
  description = "Whether to use the deploy-script-secrets.sh script to fetch and execute deployment scripts from Key Vault"
}

variable "script_content" {
  type        = string
  description = "The content of the script to deploy when not fetching from Key Vault."
  sensitive   = true
  default     = null
}

/*
 * Key Vault Script Variables
 */

variable "kubernetes_distro" {
  type        = string
  description = "The Kubernetes distribution (e.g., 'k3s', 'aks') - Used to construct the Key Vault secret name."
}

variable "node_type" {
  type        = string
  description = "The node type (e.g., 'server', 'node') - Used to construct the Key Vault secret name."
}

variable "secret_name_prefix" {
  type        = string
  description = "Optional prefix for the Key Vault secret name."
}

variable "key_vault" {
  type = object({
    id        = string
    name      = string
    vault_uri = string
  })
  description = "The Key Vault object containing id, name, and vault_uri properties"
  default     = null
}
