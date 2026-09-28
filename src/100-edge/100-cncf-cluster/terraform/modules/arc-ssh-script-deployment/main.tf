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
  deploy_script_secrets  = file("${path.module}/../../../scripts/deploy-script-secrets.sh")
  deploy_script_over_ssh = "${path.module}/../../../scripts/deploy-script-over-ssh.sh"

  script_env_vars = {
    CLIENT_ID          = try(var.arc_onboarding_identity.client_id, "")
    KEY_VAULT_NAME     = try(coalesce(var.key_vault.name), "")
    KUBERNETES_DISTRO  = var.kubernetes_distro
    NODE_TYPE          = var.node_type
    SECRET_NAME_PREFIX = var.secret_name_prefix
  }
  env_vars_string = join("\n", [for k, v in local.script_env_vars : "${k}=\"${v}\"" if v != ""])

  script_log_path = "/var/log/edge-ai/k3s-device-setup-${var.node_type}.log"

  // Logging lives in the script rather than the SSH command line, where it would need nested quoting.
  // 'install /dev/null' truncates the log to the current run and fixes its mode before tee opens it.
  script_log_preamble = join("\n", [
    "install -d -m 0750 /var/log/edge-ai",
    "install -m 0600 /dev/null '${local.script_log_path}'",
    "exec > >(tee '${local.script_log_path}') 2>&1",
    "printf '========== Setup started at %s ==========\\n' \"$(date --iso-8601=seconds)\"",
  ])

  // Matches the extension delivery path: shebang first, then runtime env vars for identity-based onboarding.
  rendered_script_to_deploy = join("\n", [
    "#!/usr/bin/env bash",
    local.env_vars_string,
    local.script_log_preamble,
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
    arc_machine_id  = var.arc_machine_id
    script_hash     = nonsensitive(sha256(local.rendered_script_to_deploy))
    script_log_path = local.script_log_path
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash"]

    environment = {
      ARC_RESOURCE_GROUP_NAME = local.machine_group_name
      ARC_RESOURCE_NAME       = local.machine_name
      SCRIPT_B64              = base64encode(local.rendered_script_to_deploy)
      SSH_LOCAL_USER          = var.ssh_local_user
      SSH_PRIVATE_KEY_PATH    = var.ssh_private_key_path
    }

    command = local.deploy_script_over_ssh
  }
}
