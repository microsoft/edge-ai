# CNCF Cluster Script Output Blueprint

## Overview

This directory contains Terraform configurations that generate scripts for setting up and configuring CNCF-compatible Kubernetes clusters. Unlike the full deployment blueprint, this option only outputs the necessary scripts without executing them.

## Terraform Structure

This blueprint is structured as follows:

- **Main Configuration** (`main.tf`): Generates script templates based on input variables
- **Variables** (`variables.tf`): Configurable parameters for script customization
- **Outputs** (`outputs.tf`): Returns paths to generated script files
- **Templates** (`templates/`): Contains templated scripts used for generation

### Resource Types Used

- `local_file` resources for script generation
- `template_file` data sources for template processing
- `null_resource` for any additional processing

## Input Variables

| Variable             | Description                         | Default          | Required |
|----------------------|-------------------------------------|------------------|:--------:|
| `cluster_name`       | Name of the Kubernetes cluster      | `"k3s-cluster"`  |    no    |
| `node_count`         | Number of worker nodes              | `1`              |    no    |
| `kubernetes_version` | Version of Kubernetes to deploy     | `"v1.26.0+k3s1"` |    no    |
| `operating_system`   | Target OS for scripts (ubuntu/rhel) | `"ubuntu"`       |    no    |
| ...                  | ...                                 | ...              |   ...    |

## Generated Scripts

This blueprint produces the following scripts:

1. **Cluster Setup** (`setup-cluster.sh`): Creates the CNCF-compatible Kubernetes cluster
2. **Configuration** (`configure-cluster.sh`): Applies post-installation configuration
3. **Validation** (`validate-cluster.sh`): Verifies successful cluster deployment

## Usage

Use these Terraform configurations when you want to:

1. Generate scripts for manual deployment of CNCF clusters
2. Customize the cluster setup process
3. Review and modify the deployment steps before execution

The generated scripts can be executed separately in your target environment.

```bash
# Initialize Terraform
terraform init

# Preview the generated scripts
terraform plan

# Generate the scripts
terraform apply

# Execute the scripts manually
cd generated-scripts/
chmod +x setup-cluster.sh
./setup-cluster.sh
```

## Script Customization

The generated scripts can be customized by modifying the Terraform variables:

```hcl
# Example terraform.tfvars
cluster_name = "production-cluster"
node_count = 3
kubernetes_version = "v1.27.3+k3s1"
```

## Contents

- Terraform configurations for generating cluster setup scripts
- Output templates for CNCF cluster configuration
- Variable definitions for customizing script generation

## Related Resources

- See the [full-single-cluster](../full-single-cluster/README.md) blueprint for a complete deployment option
