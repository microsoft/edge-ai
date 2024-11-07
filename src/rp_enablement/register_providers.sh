#!/bin/bash

set -e

echo "Registering resource providers required by AIO..."

az provider register -n "Microsoft.ExtendedLocation" --wait
az provider register -n "Microsoft.Kubernetes" --wait
az provider register -n "Microsoft.KubernetesConfiguration" --wait
az provider register -n "Microsoft.IoTOperations" --wait
az provider register -n "Microsoft.DeviceRegistry" --wait
az provider register -n "Microsoft.SecretSyncController" --wait

# Optional: Observability providers

echo "Registering AIO observability resource providers"

az provider register --namespace Microsoft.AlertsManagement --wait
az provider register --namespace Microsoft.Monitor --wait
az provider register --namespace Microsoft.Dashboard --wait
az provider register --namespace Microsoft.Insights --wait
az provider register --namespace Microsoft.OperationalInsights --wait