# Custom Script Deployment Test Plan

## Overview

This test plan validates the custom script deployment functionality added to the dual-peered-single-node-cluster blueprint.

## Test Variables

To test the script deployment, use these variables in your `terraform.tfvars`:

```hcl
# Enable custom script deployment
should_deploy_custom_scripts = true

# Or enable individual scripts
should_deploy_server_central_script = true     # Deploy to Cluster A
should_deploy_client_technology_script = true  # Deploy to Cluster B
```

## Expected Behavior

### 1. Script Preparation

- Certificates are base64-encoded and embedded in wrapper scripts
- Kubernetes manifests are base64-encoded and embedded in wrapper scripts
- Scripts are uploaded to Key Vault secrets

### 2. VM Extension Deployment

- `server-central-script-deployment` extension is created on Cluster A VM
- `client-technology-script-deployment` extension is created on Cluster B VM
- Extensions execute after IoT Operations deployment completes

### 3. Script Execution

- **Cluster A (Server Central)**:
  - Creates `/tmp/certs/` and `/tmp/resources/` directories
  - Extracts certificates (l4-server-*.crt/key, l4-client-root-ca.crt)
  - Extracts Kubernetes manifests (broker authentication and listener)
  - Executes server-central.sh script
  - Cleans up temporary files

- **Cluster B (Client Technology)**:
  - Creates `/tmp/certs/` and `/tmp/resources/` directories
  - Extracts certificates (l4-client-*.crt/key, l4-server-root-ca.crt)
  - Extracts Kubernetes manifests (broker listener, endpoints, routes)
  - Executes client-technology.sh script
  - Cleans up temporary files

## Validation Steps

1. **Terraform Deployment**:

   ```bash
   terraform plan -var="should_deploy_custom_scripts=true"
   terraform apply
   ```

2. **Check VM Extensions**:

   ```bash
   # List extensions on Cluster A VM
   az vm extension list --resource-group <cluster-a-rg> --vm-name <cluster-a-vm>

   # List extensions on Cluster B VM
   az vm extension list --resource-group <cluster-b-rg> --vm-name <cluster-b-vm>
   ```

3. **Verify Kubernetes Resources**:

   ```bash
   # Connect to Cluster A
   kubectl get brokerlistener -n azure-iot-operations
   kubectl get brokerauthentication -n azure-iot-operations
   kubectl get configmap client-ca -n azure-iot-operations
   kubectl get secret broker-server-cert -n azure-iot-operations

   # Connect to Cluster B
   kubectl get brokerlistener -n azure-iot-operations
   kubectl get mqttbridgeconnector -n azure-iot-operations
   kubectl get secret client-secret -n azure-iot-operations
   kubectl get configmap tls-ca-configmap -n azure-iot-operations
   ```

4. **Check Script Logs**:

   ```bash
   # View extension logs on VMs
   sudo journalctl -u walinuxagent.service
   # Or check in /var/log/azure/custom-script/
   ```

## Troubleshooting

### Common Issues

1. **Script fails to execute**: Check that IoT Operations is fully deployed before script runs
2. **Certificate errors**: Verify all certificate files exist in the certs/ folder
3. **Kubernetes manifest errors**: Ensure all YAML files are valid in the scripts/ folder

### Debug Commands

```bash
# Check VM extension status
az vm extension show --resource-group <rg> --vm-name <vm> --name server-central-script-deployment

# Check Key Vault secrets
az keyvault secret list --vault-name <vault-name>
az keyvault secret show --vault-name <vault-name> --name server-central-script
```

## Expected Outputs

After successful deployment, these outputs will be available:

- `server_central_script_deployment`: VM extension details for Cluster A
- `client_technology_script_deployment`: VM extension details for Cluster B
