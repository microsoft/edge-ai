metadata name = 'Observability Component Types'
metadata description = 'Type definitions and defaults for the Observability Component.'

/*
  Observability Settings Type
*/

@export()
@description('Settings for the observability configuration.')
type ObservabilitySettings = {
  @description('Interval to scrape metrics from the cluster, valid values are between 1m and 30m (PT1M and PT30M).')
  scrapeInterval: string
}

@export()
@description('Default settings for the observability configuration.')
var observabilitySettingsDefaults = {
  scrapeInterval: 'PT1M'
}
