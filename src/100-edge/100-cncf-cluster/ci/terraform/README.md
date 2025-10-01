# CNCF cluster CI Terraform module

<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
{
  "header": "",
  "footer": "",
  "inputs": [
    {
      "name": "environment",
      "type": "string",
      "description": "Environment for all resources in this module: dev, test, or prod",
      "default": null,
      "required": true
    },
    {
      "name": "resource_prefix",
      "type": "string",
      "description": "Prefix for all resources in this module",
      "default": null,
      "required": true
    },
    {
      "name": "custom_locations_oid",
      "type": "string",
      "description": "The object id of the Custom Locations Entra ID application for your tenant.\nIf none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.\n\naz ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv",
      "default": null,
      "required": false
    },
    {
      "name": "instance",
      "type": "string",
      "description": "Instance identifier for naming resources: 001, 002, etc",
      "default": "001",
      "required": false
    },
    {
      "name": "key_vault_script_secret_prefix",
      "type": "string",
      "description": "Optional prefix for the Key Vault script secret name when should_use_script_from_secrets_for_deploy is true.",
      "default": "",
      "required": false
    },
    {
      "name": "should_add_current_user_cluster_admin",
      "type": "bool",
      "description": "Gives the current logged in user cluster-admin permissions with the new cluster.",
      "default": true,
      "required": false
    },
    {
      "name": "should_get_custom_locations_oid",
      "type": "bool",
      "description": "Whether to get Custom Locations Object ID using Terraform's azuread provider. (Otherwise, provided by 'custom_locations_oid' or `az connectedk8s enable-features` for custom-locations on cluster setup if not provided.)",
      "default": true,
      "required": false
    },
    {
      "name": "should_use_script_from_secrets_for_deploy",
      "type": "bool",
      "description": "Whether to use the deploy-script-secrets.sh script to fetch and execute deployment scripts from Key Vault",
      "default": true,
      "required": false
    }
  ],
  "modules": [
    {
      "name": "ci",
      "source": "../../terraform",
      "version": "",
      "description": null
    }
  ],
  "outputs": [],
  "providers": [
    {
      "name": "azurerm",
      "alias": null,
      "version": "\u003e= 4.8.0"
    },
    {
      "name": "terraform",
      "alias": null,
      "version": null
    }
  ],
  "requirements": [
    {
      "name": "terraform",
      "version": "\u003e= 1.9.8, \u003c 2.0"
    },
    {
      "name": "azapi",
      "version": "\u003e= 2.3.0"
    },
    {
      "name": "azuread",
      "version": "\u003e= 3.0.2"
    },
    {
      "name": "azurerm",
      "version": "\u003e= 4.8.0"
    }
  ],
  "resources": [
    {
      "type": "data",
      "name": "defer",
      "provider": "terraform",
      "source": "hashicorp/terraform",
      "mode": "managed",
      "version": "latest",
      "description": "Defer computation to prevent `data` objects from querying for state on `terraform plan`. Needed for testing and build system."
    },
    {
      "type": "key_vault",
      "name": "aio",
      "provider": "azurerm",
      "source": "hashicorp/azurerm",
      "mode": "data",
      "version": "latest",
      "description": null
    },
    {
      "type": "resource_group",
      "name": "aio",
      "provider": "azurerm",
      "source": "hashicorp/azurerm",
      "mode": "data",
      "version": "latest",
      "description": null
    },
    {
      "type": "user_assigned_identity",
      "name": "arc",
      "provider": "azurerm",
      "source": "hashicorp/azurerm",
      "mode": "data",
      "version": "latest",
      "description": null
    },
    {
      "type": "virtual_machine",
      "name": "aio",
      "provider": "azurerm",
      "source": "hashicorp/azurerm",
      "mode": "data",
      "version": "latest",
      "description": null
    }
  ]
}
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
