/**
 * # Arc Server Script Deployment
 *
 * This module handles script deployment to Azure Arc-connected servers, with the option
 * to either deploy a script directly, or deploy the deploy-script-secrets.sh script
 * which will fetch the real script from Key Vault and execute it.
 *
 * Note: Windows support will be added in a future update.
 */

locals {
  deploy_script_secrets = file("${path.module}/../../../scripts/deploy-script-secrets.sh")

  script_env_vars = {
    CLIENT_ID          = try(var.arc_onboarding_identity.client_id, "")
    KEY_VAULT_NAME     = try(coalesce(var.key_vault.name), "")
    KUBERNETES_DISTRO  = var.kubernetes_distro
    NODE_TYPE          = var.node_type
    SECRET_NAME_PREFIX = var.secret_name_prefix
  }
  env_vars_string = join("\n", [for k, v in local.script_env_vars : "${k}=\"${v}\"" if v != ""])

  // Always prepend a bash shebang and the runtime env vars (CLIENT_ID, etc.) so identity-based
  // onboarding works in both the inline (script_content) and Key Vault (deploy_script_secrets)
  // delivery paths. The shebang must be line 1, otherwise the CustomScript extension falls back
  // to /bin/sh and the bash-only onboarding script fails on [[ and set -o pipefail.
  rendered_script_to_deploy = join("\n", [
    "#!/usr/bin/env bash",
    local.env_vars_string,
    var.should_use_script_from_secrets_for_deploy ? local.deploy_script_secrets : var.script_content,
  ])
}

// Arc Machine Extension for Linux Arc-connected servers
// Ref: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_machine_extension
resource "azurerm_arc_machine_extension" "linux_script_deployment" {
  count = var.os_type == "linux" ? 1 : 0

  name                      = var.extension_name
  arc_machine_id            = var.arc_machine_id
  location                  = var.location
  publisher                 = "Microsoft.Azure.Extensions"
  type                      = "CustomScript"
  type_handler_version      = "2.1"
  automatic_upgrade_enabled = false
  protected_settings = jsonencode({
    "script" = base64encode(local.rendered_script_to_deploy)
  })
}
