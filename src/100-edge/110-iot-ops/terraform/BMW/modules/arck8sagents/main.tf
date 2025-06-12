data "azurerm_subscription" "current" {
}

data "http" "helm_config" {
  url = "https://${var.azure_resource_group.location}.dp.kubernetesconfiguration.azure.com/azure-arc-k8sagents/GetLatestHelmPackagePath?api-version=2019-11-01-preview"

  method = "POST"
  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

locals {
  chart_location_url = "${jsondecode(data.http.helm_config.response_body).repositoryPath}"
  chart_path_parts = split("/", local.chart_location_url)
  chart_name_version = element(local.chart_path_parts, length(local.chart_path_parts) - 1)
  chart_name = split(":", local.chart_name_version)[0]
  chart_version = split(":", local.chart_name_version)[1]
  chart_repository = "oci://${trimsuffix(local.chart_location_url, local.chart_name_version)}/v2"
}

resource "helm_release" "arc_agent" {
  name       = "azure-arc"
  repository = local.chart_repository
  chart      = local.chart_name
  version    = local.chart_version
  namespace  = "azure-arc-release"
  create_namespace = true

  set {
    name  = "global.subscriptionId"
    value = data.azurerm_subscription.current.subscription_id
  }

  set {
    name = "global.tenantId"
    value = data.azurerm_subscription.current.tenant_id
  }

  set {
    name  = "global.kubernetesDistro"
    value = "k3s"
  }

  set {
    name  = "global.kubernetesInfra"
    value = "generic"
  }

  set {
    name  = "global.resourceGroupName"
    value = var.azure_resource_group.name
  }

  set {
    name  = "global.resourceName"
    value = var.cluster_name
  }

  set {
    name  = "global.location"
    value = var.azure_resource_group.location
  }

  set {
    name  = "systemDefaultValues.spnOnboarding"
    value = false
  }

  set {
    name  = "global.azureEnvironment"
    value = "AZUREPUBLICCLOUD"
  }

  set {
    name  = "systemDefaultValues.clusterconnect-agent.enabled"
    value = true
  }

  set {
    name = "systemDefaultValues.azureArcAgents.autoUpdate"
    value = false
  }

  set {
    name  = "systemDefaultValues.customLocations.enabled"
    value = true
  }

  set {
    name  = "systemDefaultValues.customLocations.oid"
    value = var.custom_location_object_id
  }

  set {
    name  = "global.httpProxy"
    value = "${var.http_proxy}"
  }

  set {
    name  = "global.httpsProxy"
    value = "${var.http_proxy}"
  }

  set {
    name  = "global.isProxyEnabled"
    value = true
  }

  set {
    name  = "global.noProxy"
    value = replace("10.0.0.0/8,169.254.169.254/32,kubernetes.default.svc,.svc.cluster.local,.svc", ",", "\\,")
  }

  set_sensitive {
    name  = "global.onboardingPrivateKey"
    value = var.private_key_pem
  }
}
