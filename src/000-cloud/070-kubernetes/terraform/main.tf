/**
 * # Azure Kubernetes Service (AKS)
 *
 * Deploys Azure Kubernetes Service resources
 */

module "network" {
  source = "./modules/network"

  // Resource dependencies first
  resource_group         = var.resource_group
  network_security_group = var.network_security_group
  virtual_network        = var.virtual_network

  // Core parameters next
  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance

  // Optional parameters
  subnet_address_prefixes_aks     = var.subnet_address_prefixes_aks
  subnet_address_prefixes_aks_pod = var.subnet_address_prefixes_aks_pod
}

module "aks_cluster" {
  count = var.should_create_aks ? 1 : 0

  source = "./modules/aks-cluster"

  // Resource dependencies first
  resource_group = var.resource_group
  snet_aks       = module.network.snet_aks
  snet_aks_pod   = module.network.snet_aks_pod
  acr            = var.acr

  // Core parameters next
  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance

  // optional parameters
  node_count   = var.node_count
  node_vm_size = var.node_vm_size
  dns_prefix   = var.dns_prefix
}

module "arc_cluster_instance" {
  count = var.should_create_arc_cluster_instance ? 1 : 0

  source = "./modules/connectedk8s"

  // Resource dependencies first
  resource_group = var.resource_group

  // Core parameters next
  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance
}
