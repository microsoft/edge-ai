#!/usr/bin/env bash

set -euo pipefail

###
# Namespace and Service Account Bootstrap
###

kubectl create namespace azureml --dry-run=client -o yaml | kubectl apply -f -

kubectl create serviceaccount azureml-workload \
	--namespace azureml --dry-run=client -o yaml | kubectl apply -f -

###
# Helm Repo Add
###

# Helm repo for Volcano Scheduler
helm repo add volcano-sh https://volcano-sh.github.io/helm-charts

helm repo update

###
# Helm Upgrade -i
###

# Install Volcano Scheduler into the cluster for AzureML Extension
helm upgrade -i --wait volcano -n azureml --version 1.12.2 --create-namespace \
	volcano-sh/volcano -f ./values/volcano-sh-values.yaml
