output "rancher_guest_cluster" {
  description = "Details of the newly created cluster"
  value       = rancher2_cluster_v2.rancher_guest_cluster
  sensitive   = true
}