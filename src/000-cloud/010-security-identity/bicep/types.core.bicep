metadata name = 'Core Types for Security and Identity Component'
metadata description = 'Contains core type definitions used across the Security and Identity component modules.'

@export()
@description('Common settings for the components.')
type Common = {
  @description('Prefix for all resources in this module.')
  resourcePrefix: string

  @description('Location for all resources in this module.')
  location: string

  @description('Environment for all resources in this module: dev, test, or prod.')
  environment: string

  @description('Instance identifier for naming resources: 001, 002, etc...')
  instance: string
}
