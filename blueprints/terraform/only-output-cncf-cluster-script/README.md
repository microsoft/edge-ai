# CNCF Cluster Script Output Blueprint

## Overview

This directory contains Terraform configurations that generate scripts for setting up and configuring CNCF-compatible Kubernetes clusters. Unlike the full deployment blueprint, this option only outputs the necessary scripts without executing them.

## Contents

- Terraform configurations for generating cluster setup scripts
- Output templates for CNCF cluster configuration
- Variable definitions for customizing script generation

## Usage

Use these Terraform configurations when you want to:

1. Generate scripts for manual deployment of CNCF clusters
2. Customize the cluster setup process
3. Review and modify the deployment steps before execution

The generated scripts can be executed separately in your target environment.

## Related Resources

- See the [full-single-cluster](../full-single-cluster/) blueprint for a complete deployment option
- Refer to the [main documentation](../../../docs/) for detailed information on CNCF clusters
