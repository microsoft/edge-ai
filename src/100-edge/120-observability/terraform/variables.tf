/*
 * Optional Variables
 */

// ref: https://en.wikipedia.org/wiki/ISO_8601#Durations
// ref: https://learn.microsoft.com/azure/azure-monitor/containers/container-insights-data-collection-configure?tabs=portal#configure-dcr-with-azure-portal
variable "scrape_interval" {
  description = "Interval to scrape metrics from the cluster, valid values are between 1m and 30m (PT1M and PT30M)."
  type        = string
  default     = "PT1M"
}
