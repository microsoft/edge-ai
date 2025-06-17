variable "http_proxy" {
  type        = string
  description = "HTTP proxy URL for the Rancher cluster."
}

variable "image_name" {
  type        = string
  description = "The name of the image to use for the Rancher cluster. Default is 'harvester-public/edge-2025q1r1'."
  default     = "harvester-public/edge-2025q1r1"
}