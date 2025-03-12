// Variables for the storage account module

variable "instance" {
  type        = string
  description = "The instance identifier for the deployment"
}

variable "environment" {
  type        = string
  description = "The environment name (e.g., dev, staging, prod)"
}

# Private Endpoint Variables
variable "enable_private_endpoint" {
  description = "Whether to create a private endpoint for the storage account"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "ID of the subnet to deploy the private endpoint"
  type        = string
  default     = ""
}