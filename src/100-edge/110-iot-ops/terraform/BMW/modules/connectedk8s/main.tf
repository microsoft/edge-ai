data "external" "public_key" {
  program = ["bash", "-c", "python3 -m pip install pycryptodome 1>/dev/null && python3 ${path.module}/convert_to_pub_key.py \"${var.private_key_pem}\""]
}

resource "azapi_resource" "arc" {
  type      = "Microsoft.Kubernetes/connectedClusters@2024-12-01-preview"
  name      = "arck-${var.cluster_name}"
  parent_id = var.azure_resource_group.id
  location  = var.azure_resource_group.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      agentPublicKeyCertificate = data.external.public_key.result.public_key
      oidcIssuerProfile = {
        enabled = true
      }
      securityProfile = {
        workloadIdentity = {
          enabled = true
        }
      }
    }
  }

  replace_triggers_refs = [
    "properties.agentPublicKeyCertificate"
  ]

  response_export_values = [
    "properties.oidcIssuerProfile.issuerUrl"
  ]
}
