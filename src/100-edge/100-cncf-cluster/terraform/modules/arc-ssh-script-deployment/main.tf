/**
 * # Arc SSH Script Deployment
 *
 * Delivers a cluster setup script to an Azure Arc-connected machine over `az ssh arc` rather than a
 * CustomScript extension. Required for hosts where the extension handler environment cannot run the
 * script, and for resource groups whose deny assignments make extension resources undeletable.
 *
 * Requires Azure CLI with the `ssh` extension on the machine running Terraform.
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

  // Matches the extension delivery path: shebang first, then runtime env vars for identity-based onboarding.
  rendered_script_to_deploy = join("\n", [
    "#!/usr/bin/env bash",
    local.env_vars_string,
    var.should_use_script_from_secrets_for_deploy ? local.deploy_script_secrets : var.script_content,
  ])

  // 'az ssh arc' addresses the machine by name and resource group rather than by resource ID.
  machine_id_parts   = split("/", var.arc_machine_id)
  machine_name       = element(local.machine_id_parts, length(local.machine_id_parts) - 1)
  machine_group_name = element(local.machine_id_parts, 4)
}

/*
 * Hybrid Connectivity SSH Enablement
 */

resource "azapi_resource" "ssh_endpoint" {
  count = var.should_create_ssh_endpoint ? 1 : 0

  type      = "Microsoft.HybridConnectivity/endpoints@2023-03-15"
  name      = "default"
  parent_id = var.arc_machine_id
  body = {
    properties = {
      type = "default"
    }
  }
}

resource "azapi_resource" "ssh_service_configuration" {
  count = var.should_create_ssh_endpoint ? 1 : 0

  type      = "Microsoft.HybridConnectivity/endpoints/serviceConfigurations@2023-03-15"
  name      = "SSH"
  parent_id = azapi_resource.ssh_endpoint[0].id
  body = {
    properties = {
      serviceName = "SSH"
      port        = var.ssh_port
    }
  }
}

/*
 * Script Delivery
 */

resource "terraform_data" "ssh_script_deployment" {
  depends_on = [azapi_resource.ssh_service_configuration]

  // The script digest reveals nothing about its contents, and triggers_replace cannot hold a sensitive value.
  triggers_replace = {
    arc_machine_id = var.arc_machine_id
    script_hash    = nonsensitive(sha256(local.rendered_script_to_deploy))
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      SCRIPT_B64 = base64encode(local.rendered_script_to_deploy)
    }

    command = <<-EOT
      set -euo pipefail
      az ssh arc --resource-group '${local.machine_group_name}' --name '${local.machine_name}' --local-user '${var.ssh_local_user}' --private-key-file '${var.ssh_private_key_path}' -- -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o LogLevel=ERROR "echo $SCRIPT_B64 | base64 -d | sudo bash"
    EOT
  }
}
