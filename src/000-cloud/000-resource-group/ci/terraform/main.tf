module "ci" {
  source = "../../terraform"

  resource_prefix = var.resource_prefix
  environment     = var.environment
  location        = var.location
  instance        = var.instance

  // Optional parameters for existing resource group functionality
  use_existing_resource_group = var.use_existing_resource_group
  resource_group_name         = var.resource_group_name
}
