/*
 * Optional Variables
 */

# ref: https://en.wikipedia.org/wiki/ISO_8601#Durations
# ref: https://learn.microsoft.com/azure/azure-monitor/containers/container-insights-data-collection-configure?tabs=portal#configure-dcr-with-azure-portal
# valid values are between 1m and 30m (PT1M and PT30M)
variable "scrape_interval" {
  description = "Interval to scrape metrics from the cluster"
  type        = string
  default     = "PT1M"
}
