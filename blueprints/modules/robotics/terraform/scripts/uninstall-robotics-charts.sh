#!/usr/bin/env bash

set -euo pipefail

###
# Robotics Charts Removal
###

echo "Removing robotics charts..."

# Remove GPU PodMonitor
echo "Removing PodMonitor for GPU metrics..."
kubectl delete podmonitor nvidia-dcgm-exporter -n kube-system --ignore-not-found=true || echo "GPU PodMonitor not found"

# Uninstall the NVIDIA GPU Operator from the cluster
echo "Uninstalling GPU Operator..."
helm uninstall --wait gpu-operator -n gpu-operator || echo "GPU Operator not found"

# Uninstall KAI Scheduler
echo "Uninstalling KAI Scheduler..."
helm uninstall --wait kai-scheduler -n kai-scheduler || echo "KAI Scheduler not found"

echo "Robotics chart cleanup complete."
