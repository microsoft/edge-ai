output "cluster_server_token" {
  description = "The token used by the server in the cluster for node authentication. ('null' if the server is responsible for generating the token)"
  value       = try(random_string.cluster_server_token[0].result, var.cluster_server_token)

  sensitive = true
}
