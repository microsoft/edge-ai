output "scripts" {
  value = {
    files : local.trust_script_files
    environment : local.trust_script_env_vars
  }
}