output "certificate_generation_result" {
  description = "Result of the certificate generation process."
  value = {
    status          = "completed"
    server_vm_ip    = var.server_vm_private_ip
    certs_directory = var.certs_output_directory
    execution_id    = terraform_data.generate_certificates.id
    script_path     = var.certs_script_path
  }
}

output "certificate_dependency" {
  description = "Dependency object for other modules to wait on certificate generation."
  value       = terraform_data.generate_certificates
}
