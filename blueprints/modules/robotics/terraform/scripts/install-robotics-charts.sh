#!/usr/bin/env bash

set -euo pipefail

###
# Namespace and Service Account Bootstrap
###

kubectl create namespace osmo --dry-run=client -o yaml | kubectl apply -f -

kubectl create serviceaccount osmo-workload \
	--namespace osmo --dry-run=client -o yaml | kubectl apply -f -

###
# Helm Repo Add
###

# Helm repo for NVIDIA GPU Operator
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia

helm repo update

###
# Helm Upgrade -i
###

# Install the NVIDIA GPU Operator into the cluster
helm upgrade -i --wait gpu-operator -n gpu-operator --version 24.9.1 \
	--create-namespace nvidia/gpu-operator --disable-openapi-validation \
	-f ./values/nvidia-gpu-operator-values.yaml

###
# GPU Metrics Monitoring
###
kubectl apply -f ./manifests/gpu-podmonitor.yaml
kubectl get podmonitor -n kube-system nvidia-dcgm-exporter

# Install KAI Scheduler into the cluster for NVIDIA OSMO
helm fetch oci://ghcr.io/nvidia/kai-scheduler/kai-scheduler --version v0.5.5
helm upgrade -i --wait -n kai-scheduler kai-scheduler kai-scheduler-v0.5.5.tgz \
	--create-namespace --values ./values/kai-scheduler-values.yaml
