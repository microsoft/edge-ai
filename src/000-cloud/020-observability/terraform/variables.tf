/*
 * Optional Variables
 */

variable "grafana_admin_principal_id" {
  description = "Object id of a user to grant grafana admin access to. Leave blank to not grant access to any users"
  type        = string
  default     = null
}

variable "grafana_major_version" {
  description = "Major version of grafana to use"
  type        = string
  default     = "10"
}

variable "log_retention_in_days" {
  description = "Duration to retain logs in log analytics"
  type        = number
  default     = 30
}

variable "daily_quota_in_gb" {
  description = "Daily quota to write logs in log analytics"
  type        = number
  default     = 10
}

// ref: https://github.com/microsoft/Docker-Provider/blob/4961414fc6fa72d072533cfbcdc9667f82d92f18/scripts/onboarding/aks/onboarding-msi-terraform/variables.tf#L62
variable "logs_data_collection_rule_namespaces" {
  description = "List of cluster namespaces to be exposed in the log analytics workspace"
  type        = list(string)
  default     = ["kube-system", "gatekeeper-system", "azure-arc", "azure-iot-operations"]
}

// ref: https://github.com/microsoft/Docker-Provider/blob/4961414fc6fa72d072533cfbcdc9667f82d92f18/scripts/onboarding/aks/onboarding-msi-terraform/variables.tf#L70
variable "logs_data_collection_rule_streams" {
  description = "List of streams to be enabled in the log analytics workspace"
  type        = list(string)
  default     = ["Microsoft-ContainerLog", "Microsoft-ContainerLogV2", "Microsoft-KubeEvents", "Microsoft-KubePodInventory", "Microsoft-KubeNodeInventory", "Microsoft-KubePVInventory", "Microsoft-KubeServices", "Microsoft-KubeMonAgentEvents", "Microsoft-InsightsMetrics", "Microsoft-ContainerInventory", "Microsoft-ContainerNodeInventory", "Microsoft-Perf"]
}

/*
 * Application Insights Configuration - Optional
 */

variable "app_insights_application_type" {
  type        = string
  description = "The type of application being monitored by Application Insights."
  default     = "web"
}

variable "app_insights_retention_in_days" {
  type        = number
  description = "The retention period in days for Application Insights data."
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default     = {}
}
