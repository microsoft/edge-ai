@export()
@description('The common component configuration.')
type Common = {
  @description('The environment for all resources. Example values: dev, test, prod.')
  environment: string

  @description('The prefix for all resources.')
  resourcePrefix: string

  @description('The location/region for all resources.')
  location: string

  @description('The instance identifier for naming resources. Example values: 001, 002, etc.')
  instance: string
}
