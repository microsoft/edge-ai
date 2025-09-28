/**
 * # Azure Machine Learning Arc Extension
 *
 * Installs Azure Machine Learning extension on Arc-enabled Kubernetes cluster
 * with TLS configuration for secure inference endpoints. Provides edge-specific
 * ML capabilities including distributed training and model deployment.
 */

/*
 * Azure ML Arc Extension Module
 */

module "inference_cluster_integration" {
  source = "./modules/inference-cluster-integration"

  extension_name                      = var.extension_name
  resource_prefix                     = var.resource_prefix
  environment                         = var.environment
  instance                            = var.instance
  cluster_id                          = var.connected_cluster.id
  cluster_name                        = var.connected_cluster.name
  enable_training                     = var.should_enable_training
  enable_inference                    = var.should_enable_inference
  inference_router_ha                 = var.should_enable_inference_router_ha
  inference_router_service_type       = var.inference_router_service_type
  should_install_dcgm_exporter        = var.should_install_dcgm_exporter
  should_install_nvidia_device_plugin = var.should_install_nvidia_device_plugin
  should_install_prom_op              = var.should_install_prom_op
  should_install_volcano              = var.should_install_volcano
  ssl_cname                           = var.ssl_cname
  ssl_cert_pem                        = var.ssl_cert_pem
  ssl_key_pem                         = var.ssl_key_pem
  workspace_identity_principal_id     = var.workspace_identity_principal_id
  machine_learning_workspace_id       = var.machine_learning_workspace.id
  location                            = var.location
  compute_target_name                 = var.arc_compute_target_name
  cluster_purpose                     = var.arc_cluster_purpose
  cluster_resource_group_id           = var.resource_group.id
  system_tolerations                  = var.system_tolerations
  workload_tolerations                = var.workload_tolerations
  ml_workload_identity                = var.ml_workload_identity
  ml_workload_subjects                = var.ml_workload_subjects
  resource_group_name                 = var.resource_group.name

  // Kubernetes compute configuration
  default_instance_type            = var.cluster_integration_default_instance_type
  extension_instance_release_train = var.cluster_integration_extension_instance_release_train
  instance_types = coalesce(var.cluster_integration_instance_types, {
    defaultinstancetype = {
      nodeSelector = null
      resources = {
        limits = {
          cpu              = "2"
          memory           = "8Gi"
          "nvidia.com/gpu" = null
        }
        requests = {
          cpu              = "0.1"
          memory           = "500Mi"
          "nvidia.com/gpu" = null
        }
      }
    }
  })
  kubernetes_namespace  = var.cluster_integration_kubernetes_namespace
  workspace_identity_id = var.cluster_integration_workspace_identity_id
  vc_name               = var.cluster_integration_vc_name
  description           = coalesce(var.cluster_integration_description, "Azure ML Arc compute target for ${var.resource_prefix}-${var.environment}-${var.instance}")
  disable_local_auth    = var.cluster_integration_disable_local_auth
}
