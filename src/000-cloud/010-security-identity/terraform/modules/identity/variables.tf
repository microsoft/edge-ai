variable "onboard_identity_type" {
  type        = string
  description = <<-EOF
    Identity type to use for onboarding the cluster to Azure Arc.

    Allowed values:

    - id
    - sp
    - skip
EOF
}

variable "should_create_aks_identity" {
  type        = bool
  description = "Whether to create a user-assigned identity for AKS cluster when using custom private DNS zones."
}

variable "should_create_secret_sync_identity" {
  type        = bool
  description = "Whether to create a user-assigned identity for Secret Sync Extension."
}

variable "should_create_aio_identity" {
  type        = bool
  description = "Whether to create a user-assigned identity for Azure IoT Operations."
}

variable "should_create_ml_workload_identity" {
  type        = bool
  description = "Whether to create a user-assigned identity for AzureML workloads."
}
