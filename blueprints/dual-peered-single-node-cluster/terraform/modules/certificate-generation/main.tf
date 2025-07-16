/**
 * # Certificate Generation Module
 *
 * This module handles the generation of TLS certificates using the Step CLI.
 * It runs the certs.sh script with the server VM's private IP address as the Subject Alternative Name (SAN).
 */

resource "terraform_data" "generate_certificates" {
  # Re-run when VM IP changes or script changes
  triggers_replace = {
    server_vm_private_ip = var.server_vm_private_ip
    script_hash          = filesha256(var.certs_script_path)
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Check if step CLI is available
      if ! command -v step >/dev/null 2>&1; then
        echo "ERROR: 'step' CLI tool is required but not found in PATH"
        echo "Please install step CLI: https://smallstep.com/docs/step-cli/installation/"
        exit 1
      fi

      # Ensure certs directory exists
      mkdir -p "${var.certs_output_directory}"

      # Make script executable
      chmod +x "${var.certs_script_path}"

      # Run certificate generation with server VM's private IP as SAN
      echo "Generating certificates with SAN: ${var.server_vm_private_ip}"
      "${var.certs_script_path}" \
        "${var.certs_output_directory}" \
        "${var.server_vm_private_ip}"

      echo "Certificate generation completed successfully"
    EOT
  }
}
