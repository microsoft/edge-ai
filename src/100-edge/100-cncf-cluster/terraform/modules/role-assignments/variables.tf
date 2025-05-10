/*
 * Required Variables
 */

variable "arc_onboarding_principal_ids" {
  type        = list(string)
  description = "The Principal IDs for the identity or service principal that will be used for onboarding the cluster to Arc."
}

variable "should_upload_to_key_vault" {
  type        = bool
  description = "Whether to upload the scripts to Key Vault as secrets."
}
