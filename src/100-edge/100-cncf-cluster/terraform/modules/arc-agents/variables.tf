variable "cluster_name" {
  type        = string
  description = "Name of the created ARC K8s cluster"
}

variable "http_proxy" {
  type        = string
  description = "HTTP proxy URL"
}

variable "custom_locations_oid" {
  type        = string
  description = <<-EOF
  The object id of the Custom Locations Entra ID application for your tenant.
  If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.
  
  ```sh
  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
  ```
  EOF
}
