/*
 * Microsoft Foundry Account Configuration
 */

variable "ai_foundry_name" {
  type        = string
  default     = null
  description = "Name for the Microsoft Foundry account. If not provided, defaults to 'aif-{resource_prefix}-{environment}-{instance}'"
}

variable "sku" {
  type        = string
  default     = "S0"
  description = "SKU name for the Microsoft Foundry account (S0 is required for AI Services)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources in this module"
}

variable "should_enable_public_network_access" {
  type        = bool
  default     = true
  description = "Whether to enable public network access to the Microsoft Foundry account"
}

variable "should_enable_local_auth" {
  type        = bool
  default     = true
  description = "Whether to enable local (API key) authentication. Set to false for Entra ID only"
}

variable "should_enable_cmk_encryption" {
  type        = bool
  default     = false
  description = "Whether to enable customer-managed key encryption using Key Vault. Requires key_vault variable"
}

variable "cmk_identity_client_id" {
  type        = string
  default     = null
  description = "Client ID of the User Assigned Managed Identity for accessing the Key Vault key. Required when using CMK encryption with User Assigned Identity"
}

/*
 * Private Endpoint Configuration
 */

variable "should_enable_private_endpoint" {
  type        = bool
  default     = false
  description = "Whether to create a private endpoint for the Microsoft Foundry account"
}

variable "private_endpoint_subnet_id" {
  type        = string
  default     = null
  description = "The ID of the subnet for the private endpoint. Required when should_enable_private_endpoint is true"

  validation {
    condition     = var.should_enable_private_endpoint == false || (var.private_endpoint_subnet_id != null && var.private_endpoint_subnet_id != "")
    error_message = "private_endpoint_subnet_id must be provided when should_enable_private_endpoint is true."
  }
}

variable "private_dns_zone_ids" {
  type        = list(string)
  default     = []
  description = <<-EOT
    List of private DNS zone IDs for the Microsoft Foundry private endpoint.
    Required zones for full functionality:
    - privatelink.cognitiveservices.azure.com
    - privatelink.openai.azure.com
    - privatelink.services.ai.azure.com
  EOT
}

/*
 * AI Projects Configuration
 */

variable "ai_projects" {
  type = map(object({
    name         = string
    display_name = string
    description  = string
    sku          = optional(string, "S0")
  }))
  default     = {}
  description = "Map of Microsoft Foundry projects to create. SKU defaults to 'S0' (currently the only supported value)"
}

/*
 * RAI (Responsible AI) Policies Configuration
 */

variable "rai_policies" {
  type = map(object({
    name             = string
    base_policy_name = optional(string, "Microsoft.Default")
    mode             = optional(string, "Blocking")
    content_filters = optional(list(object({
      name               = string
      enabled            = optional(bool, true)
      blocking           = optional(bool, true)
      severity_threshold = optional(string, "Medium")
      source             = string
    })), [])
  }))
  default     = {}
  description = <<-EOT
    Map of Responsible AI (RAI) content filtering policies to create.
    These policies must be created before they can be referenced in model deployments.

    Example:
    ```hcl
    rai_policies = {
      default_v2 = {
        name             = "DefaultV2"
        base_policy_name = "Microsoft.Default"
        mode             = "Blocking"
        content_filters = [
          {
            name               = "Hate"
            enabled            = true
            blocking           = true
            severity_threshold = "Medium"
            source             = "Prompt"
          },
          {
            name               = "Hate"
            enabled            = true
            blocking           = true
            severity_threshold = "Medium"
            source             = "Completion"
          }
        ]
      }
    }
    ```
  EOT
}

/*
 * Model Deployments Configuration
 */

variable "model_deployments" {
  type = map(object({
    name = string
    model = object({
      format  = string
      name    = string
      version = string
    })
    scale = object({
      type     = string
      capacity = number
    })
    rai_policy_name        = optional(string)
    version_upgrade_option = optional(string, "OnceNewDefaultVersionAvailable")
  }))
  default     = {}
  description = <<-EOT
    Map of model deployments to create on the Microsoft Foundry account.

    Example:
    ```hcl
    model_deployments = {
      gpt4o = {
        name = "gpt-4o"
        model = {
          format  = "OpenAI"
          name    = "gpt-4o"
          version = "2024-11-20"
        }
        scale = {
          type     = "GlobalStandard"
          capacity = 10
        }
      }
    }
    ```
  EOT
}
