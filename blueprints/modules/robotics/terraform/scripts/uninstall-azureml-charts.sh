#!/usr/bin/env bash

set -euo pipefail

###
# AzureML Charts Removal
###

echo "Removing AzureML charts..."

# Uninstall the Volcano Scheduler from the cluster
echo "Uninstalling Volcano Scheduler..."
helm uninstall --wait volcano -n azureml || echo "Volcano Scheduler not found"

echo "AzureML chart cleanup complete."
