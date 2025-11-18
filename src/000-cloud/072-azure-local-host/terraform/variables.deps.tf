
variable "resource_group" {
  type = object({
    name = string
    id   = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
}
