---
title: AI on Edge Security Recommendations
description: Comprehensive security recommendations guide for AI on Edge projects featuring 91 detailed security controls across Azure Storage, Linux Virtual Machines, Azure Key Vault, Event Grid, Event Hubs, and Azure Monitor, covering network security, identity management, data protection, privileged access, threat detection, and compliance best practices
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: security-guidance
estimated_reading_time: 20
keywords:
  - azure-security-recommendations
  - ai-edge-security
  - microsoft-security-controls
  - azure-storage-security
  - linux-vm-security
  - azure-key-vault-security
  - event-grid-security
  - event-hubs-security
  - azure-monitor-security
  - network-security-controls
  - identity-management
  - azure-rbac
  - managed-identities
  - data-protection
  - encryption-at-rest
  - encryption-in-transit
  - customer-managed-keys
  - privileged-access
  - threat-detection
  - azure-policy
  - conditional-access
  - microsoft-defender
  - azure-backup
  - logging-monitoring
  - compliance-controls
---

## Overview

This document presents security recommendations aimed at enhancing the overall security posture of the AI on Edge project. These recommendations are based on Microsoft's security controls and best practices for securing the various resources used in the project.
These recommendations are intended to guide the implementation of security enhancements in alignment with Microsoft's security framework.

## Resources

| # | Resource                                          | # of recommendations |
|:-:|:--------------------------------------------------|:---------------------|
| 1 | [Storage](#storage)                               | 18                   |
| 2 | [Linux Virtual Machines](#linux-virtual-machines) | 25                   |
| 3 | [Azure Key Vault](#azure-key-vault)               | 16                   |
| 4 | [Event Grid](#event-grid)                         | 9                    |
| 5 | [Event Hubs](#event-hubs)                         | 12                   |
| 6 | [Azure Monitor](#azure-monitor)                   | 11                   |

---

## Storage

### Recommendation 1

**Category:** Network Security - Secure cloud services with network controls
**Title:** Disable Public Network Access

Service supports disabling public network access either through using service-level IP ACL filtering rule (not NSG or Azure Firewall) or using a 'Disable Public Network Access' toggle switch.

**Configuration Guidance:**

Disable public network access by either using Azure Storage service-level IP ACL filtering or a toggling switch for public network access.

**Reference:**

Change the default network access rule: [https://docs.microsoft.com/azure/storage/common/storage-network-security?tabs=azure-portal#change-the-default-network-access-rule](https://docs.microsoft.com/azure/storage/common/storage-network-security?tabs=azure-portal#change-the-default-network-access-rule)

### Recommendation 2

**Category:** Network Security - Secure cloud services with network controls
**Title:** Azure Private Link

Service native IP filtering capability for filtering network traffic (not to be confused with NSG or Azure Firewall).

**Configuration Guidance:**

Deploy private endpoints for Azure Storage to establish a private access point for the resources.

**Reference:**

Use private endpoints for Azure Storage: [https://docs.microsoft.com/azure/storage/common/storage-private-endpoints](https://docs.microsoft.com/azure/storage/common/storage-private-endpoints)

### Recommendation 3

**Category:** Identity Management - Use centralized identity and authentication system
**Title:** Local Authentication Methods for Data Plane Access

Local authentications methods supported for data plane access, such as a local username and password.

**Configuration Guidance:**

Restrict the use of local authentication methods for data plane access. Instead, use Azure Active Directory (Azure AD) as the default authentication method to control your data plane access.

**Reference:**

SFTP permission model: [https://docs.microsoft.com/azure/storage/blobs/secure-file-transfer-protocol-support#sftp-permission-model](https://docs.microsoft.com/azure/storage/blobs/secure-file-transfer-protocol-support#sftp-permission-model)

### Recommendation 4

**Category:** Identity Management - Manage application identities securely and automatically
**Title:** Managed Identities

Data plane actions support authentication using managed identities.

**Configuration Guidance:**

Use Azure managed identities instead of service principals when possible, which can authenticate to Azure services and resources that support Azure Active Directory (Azure AD) authentication. Managed identity credentials are fully managed, rotated, and protected by the platform, avoiding hard-coded credentials in source code or configuration files.

**Reference:**

Authorize access to blob data with managed identities for Azure resources: [https://learn.microsoft.com/azure/storage/blobs/authorize-managed-identity](https://learn.microsoft.com/azure/storage/blobs/authorize-managed-identity)

### Recommendation 5

**Category:** Identity Management - Manage application identities securely and automatically
**Title:** Service Principals

Data plane supports authentication using service principals.

**Configuration Guidance:**

With Azure AD, you can use Azure role-based access control (Azure RBAC) to grant permissions to a security principal, which may be a user, group, or application service principal. The security principal is authenticated by Azure AD to return an OAuth 2.0 token. The token can then be used to authorize a request against the Blob service.

**Reference:**

Authorize access to blobs using Azure Active Directory: [https://learn.microsoft.com/azure/storage/blobs/authorize-access-azure-active-directory](https://learn.microsoft.com/azure/storage/blobs/authorize-access-azure-active-directory)

### Recommendation 6

**Category:** Identity Management - Restrict resource access based on  conditions
**Title:** Conditional Access for Data Plane

Data plane access can be controlled using Azure AD Conditional Access Policies.

**Configuration Guidance:**

Define the applicable conditions and criteria for Azure Active Directory (Azure AD) conditional access in the workload. Consider common use cases such as blocking or granting access from specific locations, blocking risky sign-in behavior, or requiring organization-managed devices for specific applications.

**Reference:**

Disallow Shared Key authorization to use Azure AD Conditional Access: [https://learn.microsoft.com/azure/storage/common/shared-key-authorization-prevent?tabs=portal#disallow-shared-key-authorization-to-use-azure-ad-conditional-access](https://learn.microsoft.com/azure/storage/common/shared-key-authorization-prevent?tabs=portal#disallow-shared-key-authorization-to-use-azure-ad-conditional-access)

### Recommendation 7

**Category:** Identity Management - Restrict the exposure of credential and secrets
**Title:** Service Credential and Secrets Support Integration and Storage in Azure Key Vault

Data plane supports native use of Azure Key Vault for credential and secrets store.

**Configuration Guidance:**

Ensure that secrets and credentials are stored in secure locations such as Azure Key Vault, instead of embedding them into code or configuration files.

**Reference:**

Manage storage account keys with Key Vault and the Azure CLI: [https://docs.microsoft.com/azure/key-vault/secrets/overview-storage-keys](https://docs.microsoft.com/azure/key-vault/secrets/overview-storage-keys)

### Recommendation 8

**Category:** Privileged Access - Follow just enough administration (least privilege) principle
**Title:** Azure RBAC for Data Plane

Azure Role-Based Access Control (Azure RBAC) can be used to managed access to service's data plane actions.

**Configuration Guidance:**

Azure Storage supports using Azure Active Directory (Azure AD) to authorize requests to blob data. With Azure AD, you can use Azure role-based access control (Azure RBAC) to grant permissions to a security principal, which may be a user, group, or application service principal.

Authorizing requests against Azure Storage with Azure AD provides superior security and ease of use over Shared Key authorization. Microsoft recommends using Azure AD authorization with your blob applications when possible to assure access with minimum required privileges.

**Reference:**

Authorize access to blobs using Azure Active Directory: [https://learn.microsoft.com/azure/storage/blobs/authorize-access-azure-active-directory](https://learn.microsoft.com/azure/storage/blobs/authorize-access-azure-active-directory)

### Recommendation 9

**Category:** Privileged Access - Choose approval process for third-party support
**Title:** Customer Lockbox

Customer Lockbox can be used for Microsoft support access.

**Configuration Guidance:**

In support scenarios where Microsoft needs to access your data, use Customer Lockbox to review, then approve or reject each of Microsoft's data access requests.

**Reference:**

Customer Lockbox: [https://docs.microsoft.com/azure/security/fundamentals/customer-lockbox-overview#supported-services-and-scenarios](https://docs.microsoft.com/azure/security/fundamentals/customer-lockbox-overview#supported-services-and-scenarios)

### Recommendation 10

**Category:** Data Protection - Discover, classify, and label sensitive data
**Title:** Sensitive Data Discovery and Classification

Tools (such as Azure Purview or Azure Information Protection) can be used for data discovery and classification in the service.

**Configuration Guidance:**

Use Azure Purview to scan, classify and label any sensitive data that resides in Azure Storage.

**Reference:**

Connect to Azure Blob storage in Microsoft Purview: [https://docs.microsoft.com/azure/purview/register-scan-azure-blob-storage-source](https://docs.microsoft.com/azure/purview/register-scan-azure-blob-storage-source)

### Recommendation 11

**Category:** Data Protection - Monitor anomalies and threats targeting sensitive data
**Title:** Data Leakage/Loss Prevention

Service supports DLP solution to monitor sensitive data movement (in customer's content).

**Configuration Guidance:**

Defender for Storage continually analyzes the telemetry stream generated by the Azure Blob Storage and Azure Files services. When potentially malicious activities are detected, security alerts are generated. These alerts are displayed in Microsoft Defender for Cloud, together with the details of the suspicious activity along with the relevant investigation steps, remediation actions, and security recommendations.

Microsoft Defender for Storage is built into Microsoft Defender for Cloud. When you enable Microsoft Defender for Cloud's enhanced security features on your subscription, Microsoft Defender for Storage is automatically enabled for all of your storage accounts. You may enable or disable Defender for Storage for individual storage accounts under a specific subscription.

**Reference:**

Configure Microsoft Defender for Storage: [https://docs.microsoft.com/azure/storage/common/azure-defender-storage-configure?tabs=azure-security-center](https://docs.microsoft.com/azure/storage/common/azure-defender-storage-configure?tabs=azure-security-center)

### Recommendation 12

**Category:** Data Protection - Use customer-managed key option in data at rest encryption when required
**Title:** Data at Rest Encryption Using CMK

Data at-rest encryption using customer-managed keys is supported for customer content stored by the service.

**Configuration Guidance:**

If required for regulatory compliance, define the use case and service scope where encryption using customer-managed keys are needed. Enable and implement data at rest encryption for the in-scope data using customer-managed key for Azure Storage

**Reference:**

Customer-managed keys for Azure Storage encryption: [https://docs.microsoft.com/azure/storage/common/customer-managed-keys-overview](https://docs.microsoft.com/azure/storage/common/customer-managed-keys-overview)

### Recommendation 13

**Category:** Data Protection - Use a secure key management process
**Title:** Key Management in Azure Key Vault

The service supports Azure Key Vault integration for any customer keys, secrets, or certificates.

**Configuration Guidance:**

Use Azure Key Vault to create and control the life cycle of your encryption keys, including key generation, distribution, and storage. Rotate and revoke your keys in Azure Key Vault and your service based on a defined schedule or when there is a key retirement or compromise. When there is a need to use customer-managed key (CMK) in the workload, service, or application level, ensure you follow the best practices for key management: Use a key hierarchy to generate a separate data encryption key
(DEK) with your key encryption key (KEK) in your key vault. Ensure keys are registered with Azure Key Vault and referenced via key IDs from the service or application. If you need to bring your own key (BYOK) to the service (such as importing HSM-protected keys from your on-premises HSMs into Azure Key Vault), follow recommended guidelines to perform initial key generation and key transfer.

**Reference:**

Manage storage account keys with Key Vault and the Azure CLI: [https://docs.microsoft.com/azure/key-vault/secrets/overview-storage-keys](https://docs.microsoft.com/azure/key-vault/secrets/overview-storage-keys)

### Recommendation 14

**Category:** Asset Management - Use only approved services
**Title:** Azure Policy Support

Service configurations can be monitored and enforced via Azure Policy.

**Configuration Guidance:**

Define and implement standard security configurations for network resources associated with your Azure Storage Account with Azure Policy. Use Azure Policy aliases in the "Microsoft.Storage" and "Microsoft.Network" namespaces to create custom policies to audit or enforce the network configuration of your Storage account resources.

You may also make use of built-in policy definitions related to Storage account, such as: Storage Accounts should use a virtual network service endpoint

**Reference:**

Azure Policy built-in definitions for Azure Storage: [https://docs.microsoft.com/azure/storage/common/policy-reference#microsoftstorage](https://docs.microsoft.com/azure/storage/common/policy-reference#microsoftstorage)

### Recommendation 15

**Category:** Logging and threat detection - Enable threat detection capabilities
**Title:** Microsoft Defender for Service / Product Offering

Service has an offering-specific Microsoft Defender solution to monitor and alert on security issues.

**Configuration Guidance:**

Use Microsoft Defender for Storage to provide an additional layer of security intelligence that detects unusual and potentially harmful attempts to access or exploit storage accounts.  It uses advanced threat detection capabilities and Microsoft Threat Intelligence data to provide contextual security alerts. Those alerts also include steps to mitigate the detected threats and prevent future attacks.

**Reference:**

Introduction to Microsoft Defender for Storage: [https://docs.microsoft.com/azure/defender-for-cloud/defender-for-storage-introduction](https://docs.microsoft.com/azure/defender-for-cloud/defender-for-storage-introduction)

### Recommendation 16

**Category:** Logging and threat detection - Enable network logging for security investigation
**Title:** Azure Resource Logs

Service produces resource logs that can provide enhanced service-specific metrics and logging. The customer can configure these resource logs and send them to their own data sink like a storage account or log analytics workspace.

**Configuration Guidance:**

Ingest logs via Azure Monitor to aggregate security data generated by endpoints devices, network resources, and other security systems. Within Azure Monitor, use Log Analytics Workspace(s) to query and perform analytics, and use Azure Storage Accounts for long-term/archival storage, optionally with security features such as immutable storage and enforced retention holds.

**Reference:**

Monitoring Azure Blob Storage: [https://docs.microsoft.com/azure/storage/blobs/monitor-blob-storage?tabs=azure-portal](https://docs.microsoft.com/azure/storage/blobs/monitor-blob-storage?tabs=azure-portal)

### Recommendation 17

**Category:** Backup and recovery - Ensure regular automated backups
**Title:** Azure Backup

The service can be backed up by the Azure Backup service.

**Configuration Guidance:**

Enable Azure Backup and configure the backup source on a desired frequency and with a desired retention period. Azure Backup lets you easily configure operational backup for protecting block blobs in your storage accounts. Backup of blobs is configured at the storage account level. So, all blobs in the storage account are protected with operational backup.

You can configure backup for multiple storage accounts using the Backup Center. You can also configure backup for a storage account using the storage account’s Data Protection properties.

**Reference:**

Overview of operational backup for Azure Blobs: [https://docs.microsoft.com/azure/backup/blob-backup-overview](https://docs.microsoft.com/azure/backup/blob-backup-overview)

### Recommendation 18

**Category:** Backup and recovery - Ensure regular automated backups
**Title:** Service Native Backup Capability

Service supports its own native backup capability (if not using Azure Backup).

**Configuration Guidance:**

Operational backup of blobs is a local backup solution. So the backup data isn't transferred to the Backup vault, but is stored in the source storage account itself. However, the Backup vault still serves as the unit of managing backups. Also, this is a continuous backup solution, which means that you don’t need to schedule any backups and all changes will be retained and restorable from the state at a selected point in time.

**Reference:**

Overview of operational backup for Azure Blobs: [https://docs.microsoft.com/azure/backup/blob-backup-overview](https://docs.microsoft.com/azure/backup/blob-backup-overview)

---

## Linux Virtual Machines

### Recommendation 19

**Category:** Network Security - Establish network segmentation boundaries
**Title:** Network Security Group Support

Service network traffic respects Network Security Groups rule assignment on its subnets.

**Configuration Guidance:**

Use network security groups (NSG) to restrict or monitor traffic by port, protocol, source IP address, or destination IP address. Create NSG rules to restrict your service's open ports (such as preventing management ports from being accessed from untrusted networks). Be aware that by default, NSGs deny all inbound traffic but allow traffic from virtual network and Azure Load Balancers.

When you create an Azure virtual machine (VM), you must create a virtual network or use an existing virtual network and configure the VM with a subnet. Ensure that all deployed subnets have a Network Security Group applied with network access controls specific to your applications trusted ports and sources.

**Reference:**

Network security groups: [https://learn.microsoft.com/azure/virtual-network/network-overview#network-security-groups](https://learn.microsoft.com/azure/virtual-network/network-overview#network-security-groups)

### Recommendation 20

**Category:** Network Security - Secure cloud services with network controls
**Title:** Disable Public Network Access

Service supports disabling public network access either through using service-level IP ACL filtering rule (not NSG or Azure Firewall) or using a 'Disable Public Network Access' toggle switch.

**Configuration Guidance:**

Services such as iptables or firewalld may be installed in the Linux OS and provide network filtering to disable public access.

### Recommendation 21

**Category:** Identity Management - Use centralized identity and authentication system
**Title:** Azure AD Authentication Required for Data Plane Access

Service supports using Azure AD authentication for data plane access.

**Configuration Guidance:**

Use Azure Active Directory (Azure AD) as the default authentication method to control your data plane access.

**Reference:**

Log in to a Linux virtual machine in Azure by using Azure AD and OpenSSH: [https://learn.microsoft.com/azure/active-directory/devices/howto-vm-sign-in-azure-ad-linux](https://learn.microsoft.com/azure/active-directory/devices/howto-vm-sign-in-azure-ad-linux)

### Recommendation 22

**Category:** Identity Management - Manage application identities securely and automatically
**Title:** Managed Identities

Data plane actions support authentication using managed identities.

**Configuration Guidance:**

Use Azure managed identities instead of service principals when possible, which can authenticate to Azure services and resources that support Azure Active Directory (Azure AD) authentication. Managed identity credentials are fully managed, rotated, and protected by the platform, avoiding hard-coded credentials in source code or configuration files.

### Recommendation 23

**Category:** Identity Management - Manage application identities securely and automatically
**Title:** Service Principals

Data plane supports authentication using service principals.

**Configuration Guidance:**

There is no current Microsoft guidance for this feature configuration. Please review and determine if your organization wants to configure this security feature.

### Recommendation 24

**Category:** Identity Management - Restrict resource access based on  conditions
**Title:** Conditional Access for Data Plane

Data plane access can be controlled using Azure AD Conditional Access Policies.

**Configuration Guidance:**

Define the applicable conditions and criteria for Azure Active Directory (Azure AD) conditional access in the workload. Consider common use cases such as blocking or granting access from specific locations, blocking risky sign-in behavior, or requiring organization-managed devices for specific applications.

**Reference:**

Log in to a Linux virtual machine in Azure by using Azure AD and OpenSSH: [https://learn.microsoft.com/azure/active-directory/devices/howto-vm-sign-in-azure-ad-linux](https://learn.microsoft.com/azure/active-directory/devices/howto-vm-sign-in-azure-ad-linux)

### Recommendation 25

**Category:** Identity Management - Restrict the exposure of credential and secrets
**Title:** Service Credential and Secrets Support Integration and Storage in Azure Key Vault

Data plane supports native use of Azure Key Vault for credential and secrets store.

**Configuration Guidance:**

Ensure that secrets and credentials are stored in secure locations such as Azure Key Vault, instead of embedding them into code or configuration files.

### Recommendation 26

**Category:** Privileged Access - Follow just enough administration (least privilege) principle
**Title:** Azure RBAC for Data Plane

Azure Role-Based Access Control (Azure RBAC) can be used to managed access to service's data plane actions.

**Configuration Guidance:**

With RBAC, specify who can log in to a VM as a regular user or with administrator privileges. When users join your team, you can update the Azure RBAC policy for the VM to grant access as appropriate. When employees leave your organization and their user accounts are disabled or removed from Azure AD, they no longer have access to your resources.

**Reference:**

Log in to a Linux virtual machine in Azure by using Azure AD and OpenSSH: [https://learn.microsoft.com/azure/active-directory/devices/howto-vm-sign-in-azure-ad-linux](https://learn.microsoft.com/azure/active-directory/devices/howto-vm-sign-in-azure-ad-linux)

### Recommendation 27

**Category:** Privileged Access - Choose approval process for third-party support
**Title:** Customer Lockbox

Customer Lockbox can be used for Microsoft support access.

**Configuration Guidance:**

In support scenarios where Microsoft needs to access your data, use Customer Lockbox to review, then approve or reject each of Microsoft's data access requests.

### Recommendation 28

**Category:** Data Protection - Encrypt sensitive data in transit
**Title:** Data in Transit Encryption

Service supports data in-transit encryption for data plane.

**Configuration Guidance:**

Enable secure transfer in services where there is a native data in transit encryption feature built in. Enforce HTTPS on any web applications and services and ensure TLS v1.2 or later is used. Legacy versions such as SSL 3.0, TLS v1.0 should be disabled. For remote management of Virtual Machines, use SSH (for Linux) or RDP/TLS (for Windows) instead of an unencrypted protocol.

**Reference:**

In-transit encryption in VMs: [https://learn.microsoft.com/azure/security/fundamentals/encryption-overview#in-transit-encryption-in-vms](https://learn.microsoft.com/azure/security/fundamentals/encryption-overview#in-transit-encryption-in-vms)

### Recommendation 29

**Category:** Data Protection - Use customer-managed key option in data at rest encryption when required
**Title:** Data at Rest Encryption Using CMK

Data at-rest encryption using customer-managed keys is supported for customer content stored by the service.

**Configuration Guidance:**

If required for regulatory compliance, define the use case and service scope where encryption using customer-managed keys are needed. Enable and implement data at rest encryption using customer-managed key for those services.

Virtual disks on Virtual Machines (VM) are encrypted at rest using either Server-side encryption or Azure disk encryption (ADE). Azure Disk Encryption leverages the DM-Crypt feature of Linux to encrypt managed disks with customer-managed keys within the guest VM. Server-side encryption with customer-managed keys improves on ADE by enabling you to use any OS types and images for your VMs by encrypting data in the Storage service.

**Reference:**

Server-side encryption of Azure Disk Storage - Customer-managed keys: [https://learn.microsoft.com/azure/virtual-machines/disk-encryption#customer-managed-keys](https://learn.microsoft.com/azure/virtual-machines/disk-encryption#customer-managed-keys)

### Recommendation 30

**Category:** Data Protection - Use a secure key management process
**Title:** Key Management in Azure Key Vault

The service supports Azure Key Vault integration for any customer keys, secrets, or certificates.

**Configuration Guidance:**

Use Azure Key Vault to create and control the life cycle of your encryption keys, including key generation, distribution, and storage. Rotate and revoke your keys in Azure Key Vault and your service based on a defined schedule or when there is a key retirement or compromise. When there is a need to use customer-managed key (CMK) in the workload, service, or application level, ensure you follow the best practices for key management: Use a key hierarchy to generate a separate data encryption key
(DEK) with your key encryption key (KEK) in your key vault. Ensure keys are registered with Azure Key Vault and referenced via key IDs from the service or application. If you need to bring your own key (BYOK) to the service (such as importing HSM-protected keys from your on-premises HSMs into Azure Key Vault), follow recommended guidelines to perform initial key generation and key transfer.

**Reference:**

Creating and configuring a key vault for Azure Disk Encryption: [https://learn.microsoft.com/azure/virtual-machines/linux/disk-encryption-key-vault?tabs=azure-portal](https://learn.microsoft.com/azure/virtual-machines/linux/disk-encryption-key-vault?tabs=azure-portal)

### Recommendation 31

**Category:** Asset Management - Use only approved services
**Title:** Azure Policy Support

Service configurations can be monitored and enforced via Azure Policy.

**Configuration Guidance:**

Azure Policy can be used to define the desired behavior for your organization's Windows VMs and Linux VMs. By using policies, an organization can enforce various conventions and rules throughout the enterprise and define and implement standard security configurations for Azure Virtual Machines. Enforcement of the desired behavior can help mitigate risk while contributing to the success of the organization.

**Reference:**

Azure Policy built-in definitions for Azure Virtual Machines: [https://learn.microsoft.com/azure/virtual-machines/policy-reference](https://learn.microsoft.com/azure/virtual-machines/policy-reference)

### Recommendation 32

**Category:** Asset Management - Use only approved applications in virtual machine
**Title:** Microsoft Defender for Cloud - Adaptive Application Controls

Service can limit what customer applications run on the virtual machine using Adaptive Application Controls in Microsoft Defender for Cloud.

**Configuration Guidance:**

Use Microsoft Defender for Cloud adaptive application controls to discover applications running on virtual machines (VMs) and generate an application allow list to mandate which approved applications can run in the VM environment.

**Reference:**

Use adaptive application controls to reduce your machines' attack surfaces: [https://learn.microsoft.com/azure/defender-for-cloud/adaptive-application-controls](https://learn.microsoft.com/azure/defender-for-cloud/adaptive-application-controls)

### Recommendation 33

**Category:** Logging and threat detection - Enable threat detection capabilities
**Title:** Microsoft Defender for Service / Product Offering

Service has an offering-specific Microsoft Defender solution to monitor and alert on security issues.

**Configuration Guidance:**

Defender for Servers extends protection to your Windows and Linux machines running in Azure. Defender for Servers integrates with Microsoft Defender for Endpoint to provide endpoint detection and response (EDR), and also provides a host of additional threat protection features, such as security baselines and OS level assessments, vulnerability assessment scanning, adaptive application controls (AAC), file integrity monitoring (FIM), and more.

**Reference:**

Plan your Defender for Servers deployment: [https://learn.microsoft.com/azure/defender-for-cloud/plan-defender-for-servers](https://learn.microsoft.com/azure/defender-for-cloud/plan-defender-for-servers)

### Recommendation 34

**Category:** Logging and threat detection - Enable network logging for security investigation
**Title:** Azure Resource Logs

Service produces resource logs that can provide enhanced service-specific metrics and logging. The customer can configure these resource logs and send them to their own data sink like a storage account or log analytics workspace.

**Configuration Guidance:**

Azure Monitor starts automatically collecting metric data for your virtual machine host when you create the VM. To collect logs and performance data from the guest operating system of the virtual machine, though, you must install the Azure Monitor agent. You can install the agent and configure collection using either
[VM insights](https://learn.microsoft.com/azure/virtual-machines/monitor-vm?toc=https%3A%2F%2Flearn.microsoft.com%2Fazure%2Fvirtual-machine-scale-sets%2Ftoc.json&bc=https%3A%2F%2Flearn.microsoft.com%2Fazure%2Fbread%2Ftoc.json#vm-insights) or by
[creating a data collection](https://learn.microsoft.com/azure/virtual-machines/monitor-vm?toc=https%3A%2F%2Flearn.microsoft.com%2Fazure%2Fvirtual-machine-scale-sets%2Ftoc.json&bc=https%3A%2F%2Flearn.microsoft.com%2Fazure%2Fbread%2Ftoc.json#create-data-collection-rule) rule.

**Reference:**

Log Analytics agent overview: [https://learn.microsoft.com/azure/azure-monitor/agents/log-analytics-agent#data-collected](https://learn.microsoft.com/azure/azure-monitor/agents/log-analytics-agent#data-collected)

### Recommendation 35

**Category:** Posture and Vulnerability Management - Define and establish secure configurations for compute resources
**Title:** Azure Automation State Configuration

Azure Automation State Configuration can be used to maintain the security configuration of the operating system.

**Configuration Guidance:**

Use Azure Automation State Configuration to maintain the security configuration of the operating system.

**Reference:**

Configure a VM with Desired State Configuration: [https://learn.microsoft.com/azure/automation/quickstarts/dsc-configuration](https://learn.microsoft.com/azure/automation/quickstarts/dsc-configuration)

### Recommendation 36

**Category:** Posture and Vulnerability Management - Define and establish secure configurations for compute resources
**Title:** Azure Policy Guest Configuration Agent

Azure Policy guest configuration agent can be installed or deployed as an extension to compute resources.

**Configuration Guidance:**

Use Microsoft Defender for Cloud and Azure Policy guest configuration agent to regularly assess and remediate configuration deviations on your Azure compute resources, including VMs, containers, and others.

**Reference:**

Understand the machine configuration feature of Azure Automanage: [https://learn.microsoft.com/azure/governance/machine-configuration/overview#deploy-requirements-for-azure-virtual-machines](https://learn.microsoft.com/azure/governance/machine-configuration/overview#deploy-requirements-for-azure-virtual-machines)

### Recommendation 37

**Category:** Posture and Vulnerability Management - Define and establish secure configurations for compute resources
**Title:** Custom VM Images

Service supports using user-supplied VM images or pre-built images from the marketplace with certain baseline configurations pre-applied.

**Configuration Guidance:**

Use a pre-configured hardened image from a trusted supplier such as Microsoft or build a desired secure configuration baseline into the VM image template.

**Reference:**

Tutorial: Create a custom image of an Azure VM with the Azure CLI: [https://learn.microsoft.com/azure/virtual-machines/linux/tutorial-custom-images](https://learn.microsoft.com/azure/virtual-machines/linux/tutorial-custom-images)

### Recommendation 38

**Category:** Posture and Vulnerability Management - Perform vulnerability assessments
**Title:** Vulnerability Assessment using Microsoft Defender

Service can be scanned for vulnerability scan using Microsoft Defender for Cloud or other Microsoft Defender services embedded vulnerability assessment capability (including Microsoft Defender for server, container registry, App Service, SQL, and DNS).

**Configuration Guidance:**

Follow recommendations from Microsoft Defender for Cloud for performing vulnerability assessments on your Azure virtual machines.

**Reference:**

Plan your Defender for Servers deployment: [https://learn.microsoft.com/azure/defender-for-cloud/plan-defender-for-servers](https://learn.microsoft.com/azure/defender-for-cloud/plan-defender-for-servers)

### Recommendation 39

**Category:** Posture and Vulnerability Management - Rapidly and automatically remediate  vulnerabilities
**Title:** Azure Automation Update Management

Service can use Azure Automation Update Management to deploy patches and updates automatically.

**Configuration Guidance:**

Use Azure Automation Update Management or a third-party solution to ensure that the most recent security updates are installed on your Linux VMs.

**Reference:**

Manage updates and patches for your VMs: [https://learn.microsoft.com/azure/automation/update-management/manage-updates-for-vm](https://learn.microsoft.com/azure/automation/update-management/manage-updates-for-vm)

### Recommendation 40

**Category:** Endpoint security - Use Endpoint Detection and Response (EDR)
**Title:** EDR Solution

Endpoint Detection and Response (EDR) feature such as Azure Defender for servers can be deployed into the endpoint.

**Configuration Guidance:**

Azure Defender for servers (with Microsoft Defender for Endpoint integrated) provides EDR capability to prevent, detect, investigate, and respond to advanced threats. Use Microsoft Defender for Cloud to deploy Azure Defender for servers for your endpoint and integrate the alerts to your SIEM solution such as Azure Sentinel.

**Reference:**

Plan your Defender for Servers deployment: [https://learn.microsoft.com/azure/defender-for-cloud/plan-defender-for-servers#integrated-license-for-microsoft-defender-for-endpoint](https://learn.microsoft.com/azure/defender-for-cloud/plan-defender-for-servers#integrated-license-for-microsoft-defender-for-endpoint)

### Recommendation 41

**Category:** Endpoint security - Use modern anti-malware software
**Title:** Anti-Malware Solution

Anti-malware feature such as Microsoft Defender Antivirus, Microsoft Defender for Endpoint can be deployed on the endpoint.

**Configuration Guidance:**

For Linux, customers can have the choice of installing Microsoft Defender for Endpoint for Linux. Alternatively, customers also have the choice of installing third-party anti-malware products.

**Reference:**

Microsoft Defender for Endpoint on Linux: [https://learn.microsoft.com/microsoft-365/security/defender-endpoint/microsoft-defender-endpoint-linux?view=o365-worldwide](https://learn.microsoft.com/microsoft-365/security/defender-endpoint/microsoft-defender-endpoint-linux?view=o365-worldwide)

### Recommendation 42

**Category:** Endpoint security - Ensure anti-malware software and signatures are updated
**Title:** Anti-Malware Solution Health Monitoring

Anti-malware solution provides health status monitoring for platform, engine, and automatic signature updates.

**Configuration Guidance:**

Configure your anti-malware solution to ensure the platform, engine and signatures are updated rapidly and consistently and their status can be monitored.

### Recommendation 43

**Category:** Backup and recovery - Ensure regular automated backups
**Title:** Azure Backup

The service can be backed up by the Azure Backup service.

**Configuration Guidance:**

Enable Azure Backup and target Azure Virtual Machines (VM), as well as the desired frequency and retention periods. This includes complete system state backup. If you are using Azure disk encryption, Azure VM backup automatically handles the backup of customer-managed keys. For Azure Virtual Machines, you can use Azure Policy to enable automatic backups.

**Reference:**

Backup and restore options for virtual machines in Azure: [https://learn.microsoft.com/azure/virtual-machines/backup-recovery](https://learn.microsoft.com/azure/virtual-machines/backup-recovery)

---

## Azure Key Vault

### Recommendation 44

**Category:** Network Security - Establish network segmentation boundaries
**Title:** Network Security Group Support

Service network traffic respects Network Security Groups rule assignment on its subnets.

**Configuration Guidance:**

Use network security groups (NSG) to restrict or monitor traffic by port, protocol, source IP address, or destination IP address. Create NSG rules to restrict your service's open ports (such as preventing management ports from being accessed from untrusted networks). Be aware that by default, NSGs deny all inbound traffic but allow traffic from virtual network and Azure Load Balancers.

### Recommendation 45

**Category:** Network Security - Establish network segmentation boundaries
**Title:** Virtual Network Integration

Service supports deployment into customer's private Virtual Network (VNet).

**Configuration Guidance:**

Azure Key Vault supports virtual network service endpoints which allows you to restrict the key vault access to a specified virtual network.

**Reference:**

Azure Key Vault Network Security: [https://docs.microsoft.com/azure/key-vault/general/network-security](https://docs.microsoft.com/azure/key-vault/general/network-security)

### Recommendation 46

**Category:** Network Security - Secure cloud services with network controls
**Title:** Disable Public Network Access

Service supports disabling public network access either through using service-level IP ACL filtering rule (not NSG or Azure Firewall) or using a 'Disable Public Network Access' toggle switch.

**Configuration Guidance:**

Disable public network access using the Azure Key Vault firewall IP filtering rules.

**Reference:**

Azure Key Vault network security: [https://docs.microsoft.com/azure/key-vault/general/how-to-azure-key-vault-network-security?tabs=azure-portal](https://docs.microsoft.com/azure/key-vault/general/how-to-azure-key-vault-network-security?tabs=azure-portal)

### Recommendation 47

**Category:** Network Security - Secure cloud services with network controls
**Title:** Azure Private Link

Service native IP filtering capability for filtering network traffic (not to be confused with NSG or Azure Firewall).

**Configuration Guidance:**

Deploy private endpoints for Azure Key Vault to establish a private access point for the resources.

**Reference:**

Azure Key Vault Private Link: [https://docs.microsoft.com/azure/key-vault/general/private-link-service?tabs=portal](https://docs.microsoft.com/azure/key-vault/general/private-link-service?tabs=portal)

### Recommendation 48

**Category:** Identity Management - Manage application identities securely and automatically
**Title:** Managed Identities

Data plane actions support authentication using managed identities.

**Configuration Guidance:**

Use Azure managed identities instead of service principals when possible, which can authenticate to Azure services and resources that support Azure Active Directory (Azure AD) authentication. Managed identity credentials are fully managed, rotated, and protected by the platform, avoiding hard-coded credentials in source code or configuration files.

**Reference:**

Azure Key Vault authentication: [https://docs.microsoft.com/azure/key-vault/general/authentication](https://docs.microsoft.com/azure/key-vault/general/authentication)

### Recommendation 49

**Category:** Identity Management - Manage application identities securely and automatically
**Title:** Service Principals

Data plane supports authentication using service principals.

**Configuration Guidance:**

It is recommended to use managed identities instead of service principals. When service principals have to be used, limit the usage to use case scenarios where non-user-based access is required and managed identities are not supported, such as automation flows or 3rd party system integrations.

**Reference:**

Azure Key Vault authentication: [https://docs.microsoft.com/azure/key-vault/general/authentication#security-principal-registration](https://docs.microsoft.com/azure/key-vault/general/authentication#security-principal-registration)

### Recommendation 50

**Category:** Identity Management - Restrict resource access based on  conditions
**Title:** Conditional Access for Data Plane

Data plane access can be controlled using Azure AD Conditional Access Policies.

**Configuration Guidance:**

Define the applicable conditions and criteria for Azure Active Directory (Azure AD) conditional access in the workload. Consider common use cases such as blocking or granting access from specific locations, blocking risky sign-in behavior, or requiring organization-managed devices for specific applications.

**Reference:**

Azure Key Vault conditional access: [https://docs.microsoft.com/azure/key-vault/general/security-features#conditional-access](https://docs.microsoft.com/azure/key-vault/general/security-features#conditional-access)

### Recommendation 51

**Category:** Identity Management - Restrict the exposure of credential and secrets
**Title:** Service Credential and Secrets Support Integration and Storage in Azure Key Vault

Data plane supports native use of Azure Key Vault for credential and secrets store.

**Configuration Guidance:**

Ensure that secrets and credentials are stored in secure locations such as Azure Key Vault, instead of embedding them into code or configuration files.

**Reference:**

About Azure Key Vault secrets: [https://docs.microsoft.com/azure/key-vault/secrets/about-secrets](https://docs.microsoft.com/azure/key-vault/secrets/about-secrets)

### Recommendation 52

**Category:** Privileged Access - Follow just enough administration (least privilege) principle
**Title:** Azure RBAC for Data Plane

Azure Role-Based Access Control (Azure RBAC) can be used to managed access to service's data plane actions.

**Configuration Guidance:**

Use Azure role-based access control (Azure RBAC) to manage Azure resource access through built-in role assignments. Azure RBAC roles can be assigned to users, groups, service principals, and managed identities.

**Reference:**

Azure Key Vault RBAC support: [https://docs.microsoft.com/azure/key-vault/general/rbac-guide?tabs=azure-cli](https://docs.microsoft.com/azure/key-vault/general/rbac-guide?tabs=azure-cli)

### Recommendation 53

**Category:** Data Protection - Use customer-managed key option in data at rest encryption when required
**Title:** Data at Rest Encryption Using CMK

Data at-rest encryption using customer-managed keys is supported for customer content stored by the service.

**Configuration Guidance:**

Azure Key Vault is where you store your keys for customer-managed key (CMK) encryption. You have the option to use either software-protected keys or HSM (hardware security module)-protected keys for your CMK solution.

**Reference:**

Azure Key Vault secure store of secrets and keys: [https://docs.microsoft.com/azure/key-vault/general/overview#securely-store-secrets-and-keys](https://docs.microsoft.com/azure/key-vault/general/overview#securely-store-secrets-and-keys)

### Recommendation 54

**Category:** Data Protection - Use a secure key management process
**Title:** Key Management in Azure Key Vault

The service supports Azure Key Vault integration for any customer keys, secrets, or certificates.

**Configuration Guidance:**

Follow the Azure Key Vault best practices to securely manage your key lifecycle in key vault. This includes the key generation, distribution, storage, rotation, and revocation.

**Reference:**

Azure Key Vault key management: [https://docs.microsoft.com/azure/key-vault/keys/about-keys-details#key-access-control](https://docs.microsoft.com/azure/key-vault/keys/about-keys-details#key-access-control)

### Recommendation 55

**Category:** Data Protection - Use a secure certificate management process
**Title:** Certificate Management in Azure Key Vault

The service supports Azure Key Vault integration for any customer certificates.

**Configuration Guidance:**

Follow the Azure Key Vault best practice to securely manage your certificate lifecycle in the key vault. This includes the key creation/import, rotation, revocation, storage, and purge of the certificate.

**Reference:**

Azure Key Vault certificate management: [https://docs.microsoft.com/azure/key-vault/certificates/create-certificate-scenarios](https://docs.microsoft.com/azure/key-vault/certificates/create-certificate-scenarios)

### Recommendation 56

**Category:** Asset Management - Use only approved services
**Title:** Azure Policy Support

Service configurations can be monitored and enforced via Azure Policy.

**Configuration Guidance:**

Use Microsoft Defender for Cloud to configure Azure Policy to audit and enforce configurations of your Azure Key Vault. Use Azure Monitor to create alerts when there is a configuration deviation detected on the resources. Use Azure Policy [deny] and [deploy if not exists] effects to enforce secure configuration across Azure resources.

**Reference:**

Azure Key Vault policy: [https://docs.microsoft.com/azure/key-vault/policy-reference](https://docs.microsoft.com/azure/key-vault/policy-reference)

### Recommendation 57

**Category:** Logging and threat detection - Enable threat detection capabilities
**Title:** Microsoft Defender for Service / Product Offering

Service has an offering-specific Microsoft Defender solution to monitor and alert on security issues.

**Configuration Guidance:**

Enable Microsoft Defender for Key Vault, when you get an alert from Microsoft Defender for Key Vault, investigate and respond to the alert.

**Reference:**

Microsoft Defender for Azure Key Vault: [https://docs.microsoft.com/azure/defender-for-cloud/defender-for-key-vault-introduction](https://docs.microsoft.com/azure/defender-for-cloud/defender-for-key-vault-introduction)

### Recommendation 58

**Category:** Logging and threat detection - Enable network logging for security investigation
**Title:** Azure Resource Logs

Service produces resource logs that can provide enhanced service-specific metrics and logging. The customer can configure these resource logs and send them to their own data sink like a storage account or log analytics workspace.

**Configuration Guidance:**

Enable resource logs for your key vault. Resource logs for Azure Key Vault can log key operation activities such as key creation, retrieve, and deletion.

**Reference:**

Azure Key Vault logging: [https://docs.microsoft.com/azure/key-vault/general/logging?tabs=Vault](https://docs.microsoft.com/azure/key-vault/general/logging?tabs=Vault)

### Recommendation 59

**Category:** Backup and recovery - Ensure regular automated backups
**Title:** Service Native Backup Capability

Service supports its own native backup capability (if not using Azure Backup).

**Configuration Guidance:**

Use Azure Key Vault native backup feature to backup
 your secrets, keys, and certificates and ensure the service is recoverable using the backup data.

**Reference:**

Azure Key Vault backup: [https://docs.microsoft.com/azure/key-vault/general/backup?tabs=azure-cli](https://docs.microsoft.com/azure/key-vault/general/backup?tabs=azure-cli)

---

## Event Grid

### Recommendation 60

**Category:** Network Security - Establish network segmentation boundaries
**Title:** Network Security Group Support

Service network traffic respects Network Security Groups rule assignment on its subnets.

**Configuration Guidance:**

You can use service tags to define network access controls on network security groups or Azure Firewall. Use service tags in place of specific IP addresses when you create security rules. By specifying the service tag name (for example, AzureEventGrid) in the appropriate source or destination field of a rule, you can allow or deny the traffic for the corresponding service.

**Reference:**

Service tags: [https://learn.microsoft.com/azure/event-grid/network-security#service-tags](https://learn.microsoft.com/azure/event-grid/network-security#service-tags)

### Recommendation 61

**Category:** Network Security - Secure cloud services with network controls
**Title:** Disable Public Network Access

Service supports disabling public network access either through using service-level IP ACL filtering rule (not NSG or Azure Firewall) or using a 'Disable Public Network Access' toggle switch.

**Configuration Guidance:**

Disable public network access either using the service-level IP ACL filtering rule or a toggling switch for public network access.

**Reference:**

Configure IP firewall for Azure Event Grid topics or domains: [https://learn.microsoft.com/azure/event-grid/configure-firewall](https://learn.microsoft.com/azure/event-grid/configure-firewall)

### Recommendation 62

**Category:** Network Security - Secure cloud services with network controls
**Title:** Azure Private Link

Service native IP filtering capability for filtering network traffic (not to be confused with NSG or Azure Firewall).

**Configuration Guidance:**

Deploy private endpoints for all Azure resources that support the Private Link feature, to establish a private access point for the resources.

**Reference:**

Configure private endpoints for Azure Event Grid custom topics or domains: [https://learn.microsoft.com/azure/event-grid/configure-private-endpoints](https://learn.microsoft.com/azure/event-grid/configure-private-endpoints)

### Recommendation 63

**Category:** Identity Management - Use centralized identity and authentication system
**Title:** Azure AD Authentication Required for Data Plane Access

Service supports using Azure AD authentication for data plane access.

**Configuration Guidance:**

Use Azure Active Directory (Azure AD) as the default authentication method to control your data plane access.

**Reference:**

Authentication and authorization with Azure Active Directory: [https://learn.microsoft.com/azure/event-grid/authenticate-with-active-directory](https://learn.microsoft.com/azure/event-grid/authenticate-with-active-directory)

### Recommendation 64

**Category:** Identity Management - Manage application identities securely and automatically
**Title:** Managed Identities

Data plane actions support authentication using managed identities.

**Configuration Guidance:**

Use Azure managed identities instead of service principals when possible, which can authenticate to Azure services and resources that support Azure Active Directory (Azure AD) authentication. Managed identity credentials are fully managed, rotated, and protected by the platform, avoiding hard-coded credentials in source code or configuration files.

**Reference:**

Event delivery with a managed identity: [https://learn.microsoft.com/azure/event-grid/managed-service-identity](https://learn.microsoft.com/azure/event-grid/managed-service-identity)

### Recommendation 65

**Category:** Identity Management - Manage application identities securely and automatically
**Title:** Service Principals

Data plane supports authentication using service principals.

**Configuration Guidance:**

There is no current Microsoft guidance for this feature configuration. Please review and determine if your organization wants to configure this security feature.

**Reference:**

Authentication and authorization with Azure Active Directory: [https://learn.microsoft.com/azure/event-grid/authenticate-with-active-directory](https://learn.microsoft.com/azure/event-grid/authenticate-with-active-directory)

### Recommendation 66

**Category:** Privileged Access - Follow just enough administration (least privilege) principle
**Title:** Azure RBAC for Data Plane

Azure Role-Based Access Control (Azure RBAC) can be used to managed access to service's data plane actions.

**Configuration Guidance:**

Use Azure role-based access control (Azure RBAC) to manage Azure resource access through built-in role assignments. Azure RBAC roles can be assigned to users, groups, service principals, and managed identities.

**Reference:**

Built-in roles: [https://learn.microsoft.com/azure/event-grid/security-authorization#built-in-roles](https://learn.microsoft.com/azure/event-grid/security-authorization#built-in-roles)

### Recommendation 67

**Category:** Asset Management - Use only approved services
**Title:** Azure Policy Support

Service configurations can be monitored and enforced via Azure Policy.

**Configuration Guidance:**

Use Microsoft Defender for Cloud to configure Azure Policy to audit and enforce configurations of your Azure resources. Use Azure Monitor to create alerts when there is a configuration deviation detected on the resources. Use Azure Policy [deny] and [deploy if not exists] effects to enforce secure configuration across Azure resources.

**Reference:**

Azure Policy built-in definitions for Azure Event Grid: [https://learn.microsoft.com/azure/event-grid/policy-reference](https://learn.microsoft.com/azure/event-grid/policy-reference)

### Recommendation 68

**Category:** Logging and threat detection - Enable network logging for security investigation
**Title:** Azure Resource Logs

Service produces resource logs that can provide enhanced service-specific metrics and logging. The customer can configure these resource logs and send them to their own data sink like a storage account or log analytics workspace.

**Configuration Guidance:**

Enable resource logs for the service. For example, Key Vault supports additional resource logs for actions that get a secret from a key vault or and Azure SQL has resource logs that track requests to a database. The content of resource logs varies by the Azure service and resource type.

**Reference:**

Enable diagnostic logs for Event Grid resources: [https://learn.microsoft.com/azure/event-grid/enable-diagnostic-logs-topic](https://learn.microsoft.com/azure/event-grid/enable-diagnostic-logs-topic)

---

## Event Hubs

### Recommendation 69

**Category:** Network Security - Establish network segmentation boundaries
**Title:** Network Security Group Support

Service network traffic respects Network Security Groups rule assignment on its subnets.

**Configuration Guidance:**

Use service tags in place of specific IP addresses when you create security rules. By specifying the service tag name (for example, EventHub) in the appropriate source or destination field of a rule, you can allow or deny the traffic for the corresponding service.

**Reference:**

Service Tags: [https://learn.microsoft.com/azure/event-hubs/network-security#service-tags](https://learn.microsoft.com/azure/event-hubs/network-security#service-tags)

### Recommendation 70

**Category:** Network Security - Establish network segmentation boundaries
**Title:** Virtual Network Integration

Service supports deployment into customer's private Virtual Network (VNet).

**Configuration Guidance:**

Binding an Event Hubs namespace to a virtual network is a two-step process. You first need to create a virtual Network service endpoint on a virtual network's subnet and enable it for Microsoft.EventHub as explained in the [service endpoint overview article](https://learn.microsoft.com/azure/virtual-network/virtual-network-service-endpoints-overview). Once you've added the service endpoint, you bind the Event Hubs namespace to it with a virtual network rule.

**Reference:**

Allow access to Azure Event Hubs namespaces from specific virtual networks: [https://docs.microsoft.com/azure/event-hubs/event-hubs-service-endpoints](https://docs.microsoft.com/azure/event-hubs/event-hubs-service-endpoints)

### Recommendation 71

**Category:** Network Security - Secure cloud services with network controls
**Title:** Azure Private Link

Service native IP filtering capability for filtering network traffic (not to be confused with NSG or Azure Firewall).

**Configuration Guidance:**

Deploy private endpoints for all Azure resources that support the Private Link feature, to establish a private access point for the resources.

**Reference:**

Allow access to Azure Event Hubs namespaces via private endpoints: [https://learn.microsoft.com/azure/event-hubs/private-link-service](https://learn.microsoft.com/azure/event-hubs/private-link-service)

### Recommendation 72

**Category:** Identity Management - Use centralized identity and authentication system
**Title:** Azure AD Authentication Required for Data Plane Access

Service supports using Azure AD authentication for data plane access.

**Configuration Guidance:**

Use Azure Active Directory (Azure AD) as the default authentication method to control your data plane access.

**Reference:**

Authenticate a managed identity with Azure Active Directory to access Event Hubs Resources: [https://docs.microsoft.com/azure/event-hubs/authenticate-managed-identity?tabs=latest](https://docs.microsoft.com/azure/event-hubs/authenticate-managed-identity?tabs=latest)

### Recommendation 73

**Category:** Identity Management - Manage application identities securely and automatically
**Title:** Managed Identities

Data plane actions support authentication using managed identities.

**Configuration Guidance:**

Use Azure managed identities instead of service principals when possible, which can authenticate to Azure services and resources that support Azure Active Directory (Azure AD) authentication. Managed identity credentials are fully managed, rotated, and protected by the platform, avoiding hard-coded credentials in source code or configuration files.

**Reference:**

Authenticate a managed identity with Azure Active Directory to access Event Hubs Resources: [https://docs.microsoft.com/azure/event-hubs/authenticate-managed-identity?tabs=latest](https://docs.microsoft.com/azure/event-hubs/authenticate-managed-identity?tabs=latest)

### Recommendation 74

**Category:** Identity Management - Manage application identities securely and automatically
**Title:** Service Principals

Data plane supports authentication using service principals.

**Configuration Guidance:**

There is no current Microsoft guidance for this feature configuration. Please review and determine if your organization wants to configure this security feature.

**Reference:**

Authenticate an application with Azure Active Directory to access Event Hubs resources: [https://docs.microsoft.com/azure/event-hubs/authenticate-application](https://docs.microsoft.com/azure/event-hubs/authenticate-application)

### Recommendation 75

**Category:** Identity Management - Restrict resource access based on  conditions
**Title:** Conditional Access for Data Plane

Data plane access can be controlled using Azure AD Conditional Access Policies.

**Configuration Guidance:**

Define the applicable conditions and criteria for Azure Active Directory (Azure AD) conditional access in the workload. Consider common use cases such as blocking or granting access from specific locations, blocking risky sign-in behavior, or requiring organization-managed devices for specific applications.

### Recommendation 76

**Category:** Privileged Access - Follow just enough administration (least privilege) principle
**Title:** Azure RBAC for Data Plane

Azure Role-Based Access Control (Azure RBAC) can be used to managed access to service's data plane actions.

**Configuration Guidance:**

Use Azure role-based access control (Azure RBAC) to manage Azure resource access through built-in role assignments. Azure RBAC roles can be assigned to users, groups, service principals, and managed identities.

**Reference:**

Authorize access to Event Hubs resources using Azure Active Directory: [https://docs.microsoft.com/azure/event-hubs/authorize-access-azure-active-directory](https://docs.microsoft.com/azure/event-hubs/authorize-access-azure-active-directory)

### Recommendation 77

**Category:** Data Protection - Use customer-managed key option in data at rest encryption when required
**Title:** Data at Rest Encryption Using CMK

Data at-rest encryption using customer-managed keys is supported for customer content stored by the service.

**Configuration Guidance:**

If required for regulatory compliance, define the use case and service scope where encryption using customer-managed keys are needed. Enable and implement data at rest encryption using customer-managed key for those services.

**Reference:**

Configure customer-managed keys for encrypting Azure Event Hubs data at rest: [https://docs.microsoft.com/azure/event-hubs/configure-customer-managed-key](https://docs.microsoft.com/azure/event-hubs/configure-customer-managed-key)

### Recommendation 78

**Category:** Data Protection - Use a secure key management process
**Title:** Key Management in Azure Key Vault

The service supports Azure Key Vault integration for any customer keys, secrets, or certificates.

**Configuration Guidance:**

Use Azure Key Vault to create and control the life cycle of your encryption keys, including key generation, distribution, and storage. Rotate and revoke your keys in Azure Key Vault and your service based on a defined schedule or when there is a key retirement or compromise. When there is a need to use customer-managed key (CMK) in the workload, service, or application level, ensure you follow the best practices for key management: Use a key hierarchy to generate a separate data encryption key
(DEK) with your key encryption key (KEK) in your key vault. Ensure keys are registered with Azure Key Vault and referenced via key IDs from the service or application. If you need to bring your own key (BYOK) to the service (such as importing HSM-protected keys from your on-premises HSMs into Azure Key Vault), follow recommended guidelines to perform initial key generation and key transfer.

**Reference:**

Configure customer-managed keys for encrypting Azure Event Hubs data at rest: [https://docs.microsoft.com/azure/event-hubs/configure-customer-managed-key](https://docs.microsoft.com/azure/event-hubs/configure-customer-managed-key)

### Recommendation 79

**Category:** Asset Management - Use only approved services
**Title:** Azure Policy Support

Service configurations can be monitored and enforced via Azure Policy.

**Configuration Guidance:**

Use Microsoft Defender for Cloud to configure Azure Policy to audit and enforce configurations of your Azure resources. Use Azure Monitor to create alerts when there is a configuration deviation detected on the resources. Use Azure Policy [deny] and [deploy if not exists] effects to enforce secure configuration across Azure resources.

**Reference:**

Azure Policy Regulatory Compliance controls for Azure Event Hubs: [https://docs.microsoft.com/azure/event-hubs/security-controls-policy](https://docs.microsoft.com/azure/event-hubs/security-controls-policy)

### Recommendation 80

**Category:** Logging and threat detection - Enable network logging for security investigation
**Title:** Azure Resource Logs

Service produces resource logs that can provide enhanced service-specific metrics and logging. The customer can configure these resource logs and send them to their own data sink like a storage account or log analytics workspace.

**Configuration Guidance:**

Enable resource logs for the service. For example, Key Vault supports additional resource logs for actions that get a secret from a key vault or and Azure SQL has resource logs that track requests to a database. The content of resource logs varies by the Azure service and resource type.

**Reference:**

Monitoring data from Azure Event Hubs: [https://learn.microsoft.com/azure/event-hubs/monitor-event-hubs#monitoring-data-from-azure-event-hubs](https://learn.microsoft.com/azure/event-hubs/monitor-event-hubs#monitoring-data-from-azure-event-hubs)

---

## Azure Monitor

### Recommendation 81

**Category:** Network Security - Establish network segmentation boundaries
**Title:** Network Security Group Support

Service network traffic respects Network Security Groups rule assignment on its subnets.

**Configuration Guidance:**

Use network security groups (NSG) to restrict or monitor traffic by port, protocol, source IP address, or destination IP address. Create NSG rules to restrict your service's open ports (such as preventing management ports from being accessed from untrusted networks). Be aware that by default, NSGs deny all inbound traffic but allow traffic from virtual network and Azure Load Balancers.

**Reference:**

IP addresses used by Azure Monitor: [https://docs.microsoft.com/azure/azure-monitor/app/ip-addresses](https://docs.microsoft.com/azure/azure-monitor/app/ip-addresses)

### Recommendation 82

**Category:** Network Security - Establish network segmentation boundaries
**Title:** Virtual Network Integration

Service supports deployment into customer's private Virtual Network (VNet).

**Configuration Guidance:**

There is no current Microsoft guidance for this feature configuration. Please review and determine if your organization wants to configure this security feature.

**Reference:**

Use Azure Private Link to connect networks to Azure Monitor: [https://docs.microsoft.com/azure/azure-monitor/logs/private-link-security](https://docs.microsoft.com/azure/azure-monitor/logs/private-link-security)

### Recommendation 83

**Category:** Network Security - Secure cloud services with network controls
**Title:** Disable Public Network Access

Service supports disabling public network access either through using service-level IP ACL filtering rule (not NSG or Azure Firewall) or using a 'Disable Public Network Access' toggle switch.

**Configuration Guidance:**

Disable public network access either using the service-level IP ACL filtering rule or a toggling switch for public network access. See additional information here: [Use Azure Monitor Private Link Scope (AMPLS)](https://learn.microsoft.com/samples/azure-samples/azure-monitor-private-link-scope/azure-monitor-private-link-scope/)

**Reference:**

Use Azure Private Link to connect networks to Azure Monitor: [https://docs.microsoft.com/azure/azure-monitor/logs/private-link-security](https://docs.microsoft.com/azure/azure-monitor/logs/private-link-security)

### Recommendation 84

**Category:** Network Security - Secure cloud services with network controls
**Title:** Azure Private Link

Service native IP filtering capability for filtering network traffic (not to be confused with NSG or Azure Firewall).

**Configuration Guidance:**

With Azure Private Link, you can securely link Azure platform as a service (PaaS) resources to your virtual network by using private endpoints. Azure Monitor is a constellation of different interconnected services that work together to monitor your workloads. An Azure Monitor Private Link connects a private endpoint to a set of Azure Monitor resources, defining the boundaries of your monitoring network. That set is called an Azure Monitor Private Link Scope (AMPLS).

**Reference:**

Use Azure Private Link to connect networks to Azure Monitor: [https://docs.microsoft.com/azure/azure-monitor/logs/private-link-security](https://docs.microsoft.com/azure/azure-monitor/logs/private-link-security)

### Recommendation 85

**Category:** Identity Management - Manage application identities securely and automatically
**Title:** Managed Identities

Data plane actions support authentication using managed identities.

**Configuration Guidance:**

Use Azure managed identities instead of service principals when possible, which can authenticate to Azure services and resources that support Azure Active Directory (Azure AD) authentication. Managed identity credentials are fully managed, rotated, and protected by the platform, avoiding hard-coded credentials in source code or configuration files.

**Reference:**

Azure AD authentication for Application Insights: [https://learn.microsoft.com/azure/azure-monitor/app/azure-ad-authentication?tabs=net](https://learn.microsoft.com/azure/azure-monitor/app/azure-ad-authentication?tabs=net)

### Recommendation 86

**Category:** Identity Management - Manage application identities securely and automatically
**Title:** Service Principals

Data plane supports authentication using service principals.

**Configuration Guidance:**

There is no current Microsoft guidance for this feature configuration. Please review and determine if your organization wants to configure this security feature.

**Reference:**

Create and manage action groups in the Azure portal: [https://learn.microsoft.com/azure/azure-monitor/alerts/action-groups#secure-webhook](https://learn.microsoft.com/azure/azure-monitor/alerts/action-groups#secure-webhook)

### Recommendation 87

**Category:** Identity Management - Restrict resource access based on  conditions
**Title:** Conditional Access for Data Plane

Data plane access can be controlled using Azure AD Conditional Access Policies.

**Configuration Guidance:**

Define the applicable conditions and criteria for Azure Active Directory (Azure AD) conditional access in the workload. Consider common use cases such as blocking or granting access from specific locations, blocking risky sign-in behavior, or requiring organization-managed devices for specific applications.

**Reference:**

Azure Monitor Log Analytics API Overview: [https://docs.microsoft.com/azure/azure-monitor/logs/api/overview](https://docs.microsoft.com/azure/azure-monitor/logs/api/overview)

### Recommendation 88

**Category:** Privileged Access - Choose approval process for third-party support
**Title:** Customer Lockbox

Customer Lockbox can be used for Microsoft support access.

**Configuration Guidance:**

In support scenarios where Microsoft needs to access your data, use Customer Lockbox to review, then approve or reject each of Microsoft's data access requests. This only applies to Log data in dedicated clusters.

**Reference:**

Customer Lockbox (preview): [https://docs.microsoft.com/azure/azure-monitor/logs/customer-managed-keys?tabs=portal#customer-lockbox-preview](https://docs.microsoft.com/azure/azure-monitor/logs/customer-managed-keys?tabs=portal#customer-lockbox-preview)

### Recommendation 89

**Category:** Data Protection - Encrypt sensitive data in transit
**Title:** Data in Transit Encryption

Service supports data in-transit encryption for data plane.

**Configuration Guidance:**

Enable secure transfer in services where there is a native data in transit encryption feature built in. Enforce HTTPS on any web applications and services and ensure TLS v1.2 or later is used. Legacy versions such as SSL 3.0, TLS v1.0 should be disabled. For remote management of Virtual Machines, use SSH (for Linux) or RDP/TLS (for Windows) instead of an unencrypted protocol.

### Recommendation 90

**Category:** Data Protection - Use customer-managed key option in data at rest encryption when required
**Title:** Data at Rest Encryption Using CMK

Data at-rest encryption using customer-managed keys is supported for customer content stored by the service.

**Configuration Guidance:**

Azure Monitor data is intended for service health data only, and only Log Data stored in dedicated clusters allows the use of Customer Managed Keys for Data at Rest Encryption. If required for regulatory compliance, define the use case and service scope where encryption using customer-managed keys are needed. Enable and implement data at rest encryption using customer-managed key for those services.

**Reference:**

Azure Monitor customer-managed key: [https://docs.microsoft.com/azure/azure-monitor/logs/customer-managed-keys?tabs=portal#customer-lockbox-preview](https://docs.microsoft.com/azure/azure-monitor/logs/customer-managed-keys?tabs=portal#customer-lockbox-preview)

### Recommendation 91

**Category:** Asset Management - Use only approved services
**Title:** Azure Policy Support

Service configurations can be monitored and enforced via Azure Policy.

**Configuration Guidance:**

Use Microsoft Defender for Cloud to configure Azure Policy to audit and enforce configurations of your Azure resources. Use Azure Monitor to create alerts when there is a configuration deviation detected on the resources. Use Azure Policy [deny] and [deploy if not exists] effects to enforce secure configuration across Azure resources.

**Reference:**

Create diagnostic settings at scale using Azure Policy: [https://docs.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings-policy](https://docs.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings-policy)

*AI and automation capabilities described in this scenario should be implemented following responsible AI principles, including fairness, reliability, safety, privacy, inclusiveness, transparency, and accountability. Organizations should ensure appropriate governance, monitoring, and human oversight are in place for all AI-powered solutions.*
