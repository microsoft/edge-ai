variable "cluster_id" {
  type        = string
  description = "AKS cluster resource ID"
}

variable "command" {
  type        = string
  description = "kubectl/helm command to execute (nullable; null -> empty string)"
}

variable "file_path" {
  type        = string
  description = "Path to a single file to attach"
}

variable "folder_path" {
  type        = string
  description = "Path to a single folder whose contents are attached"
}

variable "timeout_minutes" {
  type        = number
  description = "Execution timeout (minutes)"
}

