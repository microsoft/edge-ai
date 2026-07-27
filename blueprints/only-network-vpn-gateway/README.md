---
title: Only Network VPN Gateway Blueprint
description: Standalone virtual network and Point-to-Site VPN Gateway deployment used as Step 1 of a two-step pattern that lets later blueprints reuse existing networking and connect securely before disabling public network access
author: Edge AI Team
ms.date: 2026-07-27
ms.topic: reference
keywords:
  - vpn gateway
  - point-to-site
  - virtual network
  - two-step deployment
  - network security perimeter
  - terraform
estimated_reading_time: 6
---

## Only Network VPN Gateway Blueprint

This blueprint deploys a standalone resource group, virtual network, and Point-to-Site VPN Gateway. It creates no Key Vault, Storage Account, or Azure IoT Operations resources by itself (a Key Vault is created only when certificate-based VPN authentication is selected, solely to store the generated CA/client certificates).

It exists to support a two-step deployment pattern for environments where subscription policy blocks public network access on Key Vault or Storage:

1. **Step 1 (this blueprint)**: Deploy the virtual network and VPN Gateway first, while public network access still defaults to enabled on any resources this blueprint creates.
2. **Connect**: Download the VPN client profile from this blueprint's outputs and connect over VPN.
3. **Step 2**: Deploy `full-multi-node-cluster` (or another component/blueprint) with `use_existing_networking = true` to reuse this blueprint's virtual network, then safely disable public network access on Key Vault/Storage now that the deployer is connected over the private network.

Please follow general blueprint deployment and recommendations from blueprints [README.md](../README.md).

## Architecture

This blueprint deploys:

- **Resource Group**: New or existing (`use_existing_resource_group`)
- **Virtual Network and Subnet**: Via the `050-networking` component, including optional Azure Private Resolver and NAT gateway for managed outbound access
- **Key Vault** (conditional): Created only when `vpn_gateway_should_use_azure_ad_auth = false`, to store the VPN Gateway's auto-generated or existing CA certificate
- **VPN Gateway**: Point-to-Site gateway supporting either Azure AD (Microsoft Entra ID) authentication (default) or certificate-based authentication, plus optional site-to-site connections

## Prerequisites

### Required Tools

- Terraform >= 1.12.0
- Azure CLI authenticated and initialized (`source ./scripts/az-sub-init.sh`)

### Required Providers

- `hashicorp/azurerm` >= 4.51.0
- `Azure/azapi` >= 2.3.0

## Usage

### Basic Deployment (Azure AD Authentication - Default)

```hcl
module "only_network_vpn_gateway" {
  source = "./blueprints/only-network-vpn-gateway/terraform"

  environment     = "dev"
  location        = "westeurope"
  resource_prefix = "mycompany"
  instance        = "001"
}
```

### Certificate-Based Authentication

```hcl
module "only_network_vpn_gateway" {
  source = "./blueprints/only-network-vpn-gateway/terraform"

  environment     = "dev"
  location        = "westeurope"
  resource_prefix = "mycompany"
  instance        = "001"

  vpn_gateway_should_use_azure_ad_auth = false
  vpn_gateway_should_generate_ca       = true
}
```

## Variables

### Required Variables

| Name              | Description                                       | Type     |
|-------------------|---------------------------------------------------|----------|
| `environment`     | Environment for all resources: dev, test, or prod | `string` |
| `location`        | Location for all resources                        | `string` |
| `resource_prefix` | Prefix for all resources                          | `string` |

### Optional Variables

| Name                                    | Description                                                            | Type     | Default                         |
|-----------------------------------------|------------------------------------------------------------------------|----------|---------------------------------|
| `instance`                              | Instance identifier for naming resources                               | `string` | `"001"`                         |
| `resource_group_name`                   | Name of the resource group to create or use                            | `string` | computed                        |
| `use_existing_resource_group`           | Whether to use an existing resource group                              | `bool`   | `false`                         |
| `virtual_network_config`                | Address space and subnet prefix for the virtual network                | `object` | `10.0.0.0/16` / `10.0.1.0/24`   |
| `should_enable_private_resolver`        | Whether to enable Azure Private Resolver for VPN client DNS resolution | `bool`   | `false`                         |
| `resolver_subnet_address_prefix`        | Address prefix for the private resolver subnet                         | `string` | `10.0.9.0/28`                   |
| `should_enable_managed_outbound_access` | Whether to enable managed outbound egress via NAT gateway              | `bool`   | `true`                          |
| `nat_gateway_idle_timeout_minutes`      | Idle timeout in minutes for NAT gateway connections                    | `number` | `4`                             |
| `nat_gateway_public_ip_count`           | Number of public IPs associated with the NAT gateway                   | `number` | `1`                             |
| `nat_gateway_zones`                     | Availability zones for NAT gateway resources                           | `list`   | `[]`                            |
| `vpn_gateway_config`                    | SKU, generation, client address pool, and protocols                    | `object` | `VpnGw1AZ` / `192.168.200.0/24` |
| `vpn_gateway_subnet_address_prefixes`   | Address prefixes for the GatewaySubnet                                 | `list`   | `["10.0.2.0/27"]`               |
| `vpn_gateway_should_use_azure_ad_auth`  | Whether to use Azure AD authentication instead of certificates         | `bool`   | `true`                          |
| `vpn_gateway_should_generate_ca`        | Whether to generate a new CA certificate                               | `bool`   | `true`                          |
| `existing_certificate_name`             | Name of the existing certificate in Key Vault                          | `string` | `null`                          |
| `certificate_validity_days`             | Validity period in days for auto-generated certificates                | `number` | `365`                           |
| `certificate_subject`                   | Subject information for auto-generated certificates                    | `object` | see `variables.tf`              |
| `vpn_site_connections`                  | Site-to-site VPN connection definitions                                | `list`   | `[]`                            |
| `vpn_site_default_ipsec_policy`         | Fallback IPsec parameters for site connections                         | `object` | `null`                          |
| `vpn_site_shared_keys`                  | Pre-shared keys for site connections                                   | `map`    | `{}`                            |
| `tags`                                  | Tags to apply to all resources that support tags                       | `map`    | `{}`                            |

## Outputs

| Name                         | Description                                                               |
|------------------------------|---------------------------------------------------------------------------|
| `resource_group`             | The resource group containing the networking and VPN gateway resources    |
| `virtual_network`            | The virtual network object (`id`, `name`)                                 |
| `subnet_id`                  | The ID of the subnet used for private endpoints and workloads             |
| `vpn_gateway`                | The VPN Gateway configuration and details                                 |
| `vpn_gateway_public_ip`      | The public IP address of the VPN Gateway                                  |
| `vpn_client_connection_info` | Client address pool, protocols, and public IP needed to configure clients |

## Downloading the VPN Client Profile

Once this blueprint has been applied, use the `az network vnet-gateway vpn-client` commands with the deployed gateway's `name` (`vpn_gateway.name` output) and `resource_group.name` output to generate and download the client configuration package:

```bash
# Generate a new VPN client configuration package and print a download URL
az network vnet-gateway vpn-client generate \
  --resource-group <resource_group.name output> \
  --name <vpn_gateway.name output>

# Retrieve a previously generated client configuration package URL
az network vnet-gateway vpn-client show-url \
  --resource-group <resource_group.name output> \
  --name <vpn_gateway.name output>
```

- With the default Azure AD (Microsoft Entra ID) authentication, the downloaded zip contains an `AzureVPN` folder with `azurevpnconfig.xml`; import this profile into the [Azure VPN Client](https://learn.microsoft.com/azure/vpn-gateway/point-to-site-entra-vpn-client-windows) app.
- With certificate-based authentication (`vpn_gateway_should_use_azure_ad_auth = false`), the zip contains native OS client packages (for example a Windows installer) generated from the CA stored in the conditional Key Vault; add `--authentication-method EAPTLS` if the gateway requires it.

## Two-Step Deployment Example

The following worked example shows Step 1 (this blueprint), connecting over VPN, then Step 2 layering `full-multi-node-cluster` on top of the existing virtual network using its forthcoming `use_existing_networking` toggle (added alongside the `050-networking` `use_existing_virtual_network` support).

### Step 1: Deploy This Blueprint

```hcl
# blueprints/only-network-vpn-gateway/terraform/terraform.tfvars
environment     = "dev"
location        = "westeurope"
resource_prefix = "mycompany"
instance        = "001"
```

```bash
cd blueprints/only-network-vpn-gateway/terraform
terraform init
terraform apply -var-file="terraform.tfvars"
```

### Step 2 (Connect)

Download and import the client profile as described above, then connect using the Azure VPN Client (or your native OS client for certificate-based auth).

### Step 3: Layer `full-multi-node-cluster` on the Existing Networking

Once connected, layer `full-multi-node-cluster` on top of this blueprint's virtual network and disable public network access now that the deployer reaches private endpoints over VPN.

**Same resource group** (the second blueprint reuses this blueprint's resource group directly):

```hcl
# blueprints/full-multi-node-cluster/terraform/terraform.tfvars
environment     = "dev"
location        = "westeurope"
resource_prefix = "mycompany"
instance        = "001"

use_existing_resource_group = true
resource_group_name         = "rg-mycompany-dev-001"

use_existing_networking = true

should_enable_key_vault_public_network_access = false
should_enable_storage_public_network_access   = false
```

**Separate resource group** (the second blueprint creates its own resource group, but looks up the existing virtual network in Step 1's resource group):

```hcl
# blueprints/full-multi-node-cluster/terraform/terraform.tfvars
environment     = "dev"
location        = "westeurope"
resource_prefix = "mycompany2"
instance        = "001"

use_existing_networking                 = true
existing_networking_resource_group_name = "rg-mycompany-dev-001"
virtual_network_name                    = "vnet-mycompany-dev-001"
subnet_name                             = "snet-mycompany-dev-001"

should_enable_key_vault_public_network_access = false
should_enable_storage_public_network_access   = false
```

```bash
cd blueprints/full-multi-node-cluster/terraform
terraform init
terraform apply -var-file="terraform.tfvars"
```

## Troubleshooting

### Common Issues

1. **Client profile download link expired or empty**: Re-run `vpn-client generate` to produce a fresh URL; `show-url` only retrieves a previously generated package.
2. **Certificate authentication client cannot connect**: Confirm `vpn_gateway_should_use_azure_ad_auth = false` was set on this blueprint's apply and that the client machine trusts the generated root certificate.
3. **Step 2 blueprint cannot find the existing virtual network**: Verify `existing_resource_group_name`/`virtual_network_name`/`subnet_name` (or the equivalent same-resource-group `resource_group_name`) exactly match the names produced by this blueprint's `resource_group` and `virtual_network` outputs.
