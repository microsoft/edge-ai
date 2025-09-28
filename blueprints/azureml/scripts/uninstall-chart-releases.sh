#!/usr/bin/env bash

# Uninstall the NVIDIA GPU Operator from the cluster
helm uninstall --wait gpu-operator -n gpu-operator

# Uninstall the Volcano Scheduler from the cluster
helm uninstall --wait volcano -n azureml
