module "onboard_reqs" {
  source = "../../terraform"

  resource_prefix = var.resource_prefix
  environment     = var.environment
  location        = var.location
  instance        = var.instance
}
