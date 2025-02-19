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
