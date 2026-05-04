# ONVIF Camera Deployment Scripts

Automated deployment scripts for deploying ONVIF cameras to Azure IoT Operations.

## Available Scripts

### Terraform Deployment Script

**File:** `deploy-onvif-camera-terraform.sh`

Automates ONVIF camera deployment using Terraform with interactive prompts.

#### Features

- ✅ Interactive camera information gathering
- ✅ ONVIF endpoint connectivity testing
- ✅ Azure resource discovery and validation
- ✅ Automatic Kubernetes secret creation
- ✅ PTZ capability configuration (Fixed/PT/PTZ/PTZ+Home)
- ✅ Terraform configuration generation
- ✅ Automated deployment with plan review
- ✅ Deployment verification
- ✅ Comprehensive summary with next steps

#### Prerequisites

- Azure CLI installed and authenticated (`az login`)
- kubectl configured for your cluster
- Terraform installed (v1.9.8+)
- Camera accessible on network with known credentials
- Azure IoT Operations deployed with ONVIF Connector

#### Usage

```bash
cd /workspaces/edge-ai/src/100-edge/111-assets/scripts
./deploy-onvif-camera-terraform.sh
```

The script will prompt you for:

1. **Camera Information**
   - Camera name (unique identifier)
   - Camera IP address
   - ONVIF port (default: 80)
   - ONVIF path (default: /onvif/device_service)
   - Camera credentials (username/password)

2. **Azure Resources**
   - Subscription (validates current subscription)
   - Resource group (lists available)
   - Custom location (lists in resource group)
   - ADR namespace (lists available)

3. **PTZ Capabilities**
   - Fixed (no PTZ)
   - Pan/Tilt only
   - Pan/Tilt/Zoom
   - PTZ with Home position

#### Generated Files

- `{component}/terraform/{camera-name}-deployment.tfvars` - Terraform variables file
- `{component}/terraform/{camera-name}.tfplan` - Terraform execution plan

---

### Bicep Deployment Script

**File:** `deploy-onvif-camera-bicep.sh`

Automates ONVIF camera deployment using Bicep with interactive prompts.

#### Bicep Script Features

- ✅ Interactive camera information gathering
- ✅ ONVIF endpoint connectivity testing
- ✅ Azure resource discovery and validation
- ✅ Automatic Kubernetes secret creation
- ✅ PTZ capability configuration (Fixed/PT/PTZ/PTZ+Home)
- ✅ Bicep configuration generation
- ✅ Bicep validation before deployment
- ✅ Automated deployment with confirmation
- ✅ Deployment verification
- ✅ Comprehensive summary with next steps

#### Bicep Script Prerequisites

- Azure CLI installed and authenticated (`az login`)
- kubectl configured for your cluster
- Camera accessible on network with known credentials
- Azure IoT Operations deployed with ONVIF Connector

#### Bicep Script Usage

```bash
cd /workspaces/edge-ai/src/100-edge/111-assets/scripts
./deploy-onvif-camera-bicep.sh
```

The script will prompt you for:

1. **Camera Information**
   - Camera name (unique identifier)
   - Camera IP address
   - ONVIF port (default: 80)
   - ONVIF path (default: /onvif/device_service)
   - Camera credentials (username/password)

2. **Azure Resources**
   - Subscription (validates current subscription)
   - Resource group (lists available)
   - Custom location (lists in resource group)
   - ADR namespace (lists available)
   - Environment name (default: dev)
   - Instance identifier (default: 001)

3. **PTZ Capabilities**
   - Fixed (no PTZ)
   - Pan/Tilt only
   - Pan/Tilt/Zoom
   - PTZ with Home position

#### Bicep Generated Files

- `{component}/bicep/{camera-name}-deployment.bicepparam` - Bicep parameters file

---

## Script Workflow

Both scripts follow the same workflow:

1. **Prerequisite Checks**
   - Verify required tools installed (az, kubectl, base64, terraform/bicep)
   - Verify Azure CLI authentication
   - Verify kubectl cluster access

2. **Camera Information Gathering**
   - Prompt for camera details
   - Construct ONVIF URL
   - Display configuration summary

3. **ONVIF Connection Testing**
   - Test ONVIF endpoint with GetSystemDateAndTime call
   - Warn if test fails but continue (camera may still work)

4. **Azure Resource Discovery**
   - List and validate subscription
   - List and validate resource group
   - List and validate custom location
   - List and validate ADR namespace
   - Get resource IDs for deployment

5. **Kubernetes Secret Creation**
   - Check if secret exists
   - Base64 encode credentials
   - Create secret in azure-iot-operations namespace
   - Verify secret creation

6. **PTZ Capability Configuration**
   - Prompt for camera PTZ type
   - Configure appropriate data points

7. **Configuration Generation**
   - Generate deployment configuration file
   - Include all required parameters
   - Add PTZ data points based on capabilities

8. **Deployment**
   - **Terraform**: Initialize, plan, review, apply
   - **Bicep**: Validate, review, deploy

9. **Verification**
   - Check device in Azure Device Registry
   - Check asset in Azure Device Registry (if PTZ)
   - Check ONVIF connector logs for activity

10. **Summary Display**
    - Show deployed resources
    - Provide next steps
    - Display helpful commands and links

## Common Issues and Troubleshooting

### Script Fails at Prerequisites Check

**Problem:** Missing required tools

**Solution:** Install missing tools:

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Terraform (for Terraform script)
wget https://releases.hashicorp.com/terraform/1.10.3/terraform_1.10.3_linux_amd64.zip
unzip terraform_1.10.3_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### ONVIF Connection Test Fails

**Problem:** Cannot connect to camera endpoint

**Solutions:**

1. Verify camera IP address is correct
2. Check camera is powered on and accessible on network
3. Verify ONVIF port (try 80, 8000, 8080)
4. Check camera ONVIF settings are enabled
5. Try different ONVIF path (/onvif/device_service, /onvif/services)

**Note:** Script will continue even if test fails - camera may still work if credentials are correct.

### Secret Creation Fails

**Problem:** kubectl cannot create secret

**Solutions:**

1. Verify kubectl is configured for correct cluster
2. Check azure-iot-operations namespace exists
3. Verify you have permissions to create secrets

### Deployment Fails

#### Terraform Deployment Failures

**Problem:** Terraform plan or apply fails

**Solutions:**

1. Check Terraform is initialized (`cd terraform && terraform init`)
2. Verify Azure resource IDs are correct
3. Check ADR namespace exists
4. Review Terraform error messages for specific issues

#### Bicep Deployment Failures

**Problem:** Bicep validation or deployment fails

**Solutions:**

1. Check Bicep file exists at expected path
2. Verify Azure resource IDs are correct
3. Check parameter file syntax
4. Review deployment error messages in Azure portal

### Device Not Appearing in Azure

**Problem:** Device deployed but not showing in Device Registry

**Solutions:**

1. Wait 1-2 minutes for provisioning to complete
2. Check deployment logs in Azure portal
3. Verify custom location ID is correct
4. Check ONVIF connector is running: `kubectl get pods -n azure-iot-operations`

### PTZ Commands Not Working

**Problem:** Device deployed but PTZ commands don't work

**Solutions:**

1. Verify camera actually supports PTZ (check specifications)
2. Check ONVIF connector logs for errors
3. Verify camera is not in manual control mode
4. Test PTZ directly via camera web interface first

## Examples

### Example: Deploying a PT Camera with Terraform

```bash
# Run script
./deploy-onvif-camera-terraform.sh

# Respond to prompts:
Camera name: camera-01
Camera IP address: <camera-ip>
ONVIF port: 80
ONVIF path: /onvif/device_service
Camera username: admin
Camera password: [your-password]

# Use current subscription: y
Resource group name: <resource-group>
Custom location name: <custom-location-name>
ADR namespace name: <namespace-name>

# PTZ capabilities: 2 (Pan/Tilt only)

# Review plan and confirm deployment
```

### Example: Deploying a PTZ Camera with Bicep

```bash
# Run script
./deploy-onvif-camera-bicep.sh

# Respond to prompts:
Camera name: camera-02
Camera IP address: <camera-ip>
ONVIF port: 80
ONVIF path: /onvif/device_service
Camera username: admin
Camera password: [your-password]

# Use current subscription: y
Resource group name: <resource-group>
Custom location name: <custom-location-name>
ADR namespace name: <namespace-name>
Environment name: dev
Instance identifier: 001

# PTZ capabilities: 3 (Pan/Tilt/Zoom)

# Confirm deployment
```

### Example: Deploying Multiple Cameras

Run the script multiple times with different camera names and IPs:

```bash
# Camera 1
./deploy-onvif-camera-terraform.sh
# Name: camera-01, IP: <camera-ip-1>

# Camera 2
./deploy-onvif-camera-terraform.sh
# Name: camera-02, IP: <camera-ip-2>

# Camera 3
./deploy-onvif-camera-terraform.sh
# Name: camera-03, IP: <camera-ip-3>
```

Each run creates a separate configuration file and deploys independently.

## Script Output Files

### Terraform Script Outputs

- `../terraform/{camera-name}-deployment.tfvars` - Deployment configuration
- `../terraform/{camera-name}.tfplan` - Terraform execution plan
- Kubernetes secret: `{camera-name}-credentials` in `azure-iot-operations` namespace

### Bicep Script Outputs

- `../bicep/{camera-name}-deployment.bicepparam` - Deployment configuration
- Kubernetes secret: `{camera-name}-credentials` in `azure-iot-operations` namespace
- Azure deployment: `onvif-camera-{camera-name}-{timestamp}` in resource group

## Next Steps After Deployment

1. **Monitor Connector Logs**

   ```bash
   kubectl logs -n azure-iot-operations -l app.kubernetes.io/component=connector -f
   ```

2. **Verify Device in Azure Portal**

   Navigate to your Device Registry namespace → Devices → {camera-name}

3. **Test PTZ Control** (if PTZ camera)

   ```bash
   # Get MQTT broker service
   kubectl get service -n azure-iot-operations | grep mqtt

   # Test pan command
   mosquitto_pub -h <mqtt-broker> -t "cameras/{camera-name}/ptz/pan_left" -m "1"

   # Stop movement
   mosquitto_pub -h <mqtt-broker> -t "cameras/{camera-name}/ptz/stop" -m "1"
   ```

4. **Review Documentation**
   - [ONVIF-CAMERA-QUICKSTART.md](../ONVIF-CAMERA-QUICKSTART.md) - Generic deployment guide
   - [ONVIF-CAMERA-DEPLOYMENT.md](../terraform/ONVIF-CAMERA-DEPLOYMENT.md) - Detailed technical documentation
   - [ONVIF-CAMERA-QUICK-REFERENCE.md](../terraform/ONVIF-CAMERA-QUICK-REFERENCE.md) - Command reference

## Cleaning Up

### Remove Deployed Camera

#### Using Terraform

```bash
cd ../terraform
terraform destroy -var-file="{camera-name}-deployment.tfvars"
```

#### Using Bicep (Manual)

```bash
# Delete device
az resource delete --ids "${ADR_NAMESPACE_ID}/devices/${CAMERA_NAME}"

# Delete asset (if exists)
az resource delete --ids "${ADR_NAMESPACE_ID}/assets/${CAMERA_NAME}-ptz"

# Delete secret
kubectl delete secret ${CAMERA_NAME}-credentials -n azure-iot-operations
```

### Remove Configuration Files

```bash
# Terraform files
rm ../terraform/{camera-name}-deployment.tfvars
rm ../terraform/{camera-name}.tfplan

# Bicep files
rm ../bicep/{camera-name}-deployment.bicepparam
```

## Support

For issues with:

- **Scripts**: Check troubleshooting section above
- **Azure IoT Operations**: Create Azure support ticket
- **Camera compatibility**: Consult camera manufacturer documentation
- **ONVIF protocol**: Visit [ONVIF community forums](https://www.onvif.org/community/)

---

**Script Version:** 1.0.0
**Last Updated:** December 19, 2025
**Tested With:** Azure IoT Operations v1.2.112, Terraform v1.10.3, Bicep latest
