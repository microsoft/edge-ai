variable "server_vm_private_ip" {
  type        = string
  description = "The private IP address of the server VM to use as Subject Alternative Name (SAN) in certificates."
}

variable "certs_script_path" {
  type        = string
  description = "Path to the certs.sh script for certificate generation."
}

variable "certs_output_directory" {
  type        = string
  description = "Directory where the generated certificates will be stored."
}
