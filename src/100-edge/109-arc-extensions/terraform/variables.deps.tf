variable "arc_connected_cluster" {
  type = object({
    id       = string
    name     = string
    location = string
  })
  description = "Arc-connected Kubernetes cluster object containing id, name, and location"
}
