variable "resource_group" {
  type = object({
    id   = string
    name = string
  })
  description = "The resource group where the namespace will be created."
}
