/*
 * Required Variables
 */

variable "arc_onboarding_principal_id" {
  type        = string
  description = "The Principal ID for the identity or service principal that will be used for onboarding the cluster to Arc."
}

variable "server_script_secret_name" {
  type        = string
  description = "The name of the key vault secret containing the server script."
}

variable "node_script_secret_name" {
  type        = string
  description = "The name of the key vault secret containing the node script."
}
