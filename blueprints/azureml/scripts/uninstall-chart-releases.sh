#!/usr/bin/env bash

set -euo pipefail

###
# GPU Metrics Monitoring Cleanup
###

echo "Removing PodMonitor for GPU metrics..."
kubectl delete podmonitor nvidia-dcgm-exporter -n kube-system --ignore-not-found=true

# Uninstall the NVIDIA GPU Operator from the cluster
helm uninstall --wait gpu-operator -n gpu-operator

# Uninstall the Volcano Scheduler from the cluster
helm uninstall --wait volcano -n azureml
