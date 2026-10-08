/*
 * Required Machine Variables
 */

variable "arc_machine_id" {
  type        = string
  description = "The ID of the Azure Arc-connected machine to deploy the script to."
}

/*
 * SSH Connection Variables
 */

variable "ssh_local_user" {
  type        = string
  description = "Local account on the Arc-connected machine used for the SSH session; must have passwordless sudo."
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path on the machine running Terraform to the private key authorized for 'ssh_local_user'."
}

variable "should_create_ssh_endpoint" {
  type        = bool
  description = "Whether to create the Hybrid Connectivity default endpoint and SSH service configuration for this machine."
  default     = false
}

variable "ssh_port" {
  type        = number
  description = "Port advertised by the SSH service configuration when 'should_create_ssh_endpoint' is true."
  default     = 22
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

/*
 * Authentication Variables
 */

variable "arc_onboarding_identity" {
  type = object({
    id           = string
    client_id    = string
    principal_id = string
  })
  description = "User Assigned Managed Identity object for Arc onboarding with Key Vault access"
  default     = null
}
