---
title: Virtual Machine Host
description: Component for onboarding a new Azure VM for the purposes of installing and testing out an edge deployment including Azure VNet and Azure VM
author: Edge AI Team
ms.date: 06/07/2025
ms.topic: reference
keywords:
  - virtual machine host
  - azure vm
  - azure vnet
  - edge deployment
  - terraform
  - bicep
  - ssh access
  - jit access
estimated_reading_time: 2
---

## Virtual Machine Host

Component for onboarding a new Azure VM for the purposes of installing and testing out
an edge deployment.

This includes the following:

- Azure VNet
- Azure VM

## Terraform

Refer to [Terraform Components - Getting Started](../README.md#terraform-components---getting-started) for
deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

## Access Virtual Machine

1. Navigate to the deployed VM in [Azure portal](https://portal.azure.com) and Enable JIT (Just in time) access for your IP:

   Virtual Machines → Select the VM → Connect → Native SSH → VM Access → Requests JIT access

2. The Terraform output will contain the SSH command needed connect to the VM:

   Use the SSH command to connect to the VM or any preferred SSH client.

   ```sh
   # Private ssh key made on deploy located at ../.ssh/id_rsa as default location
   ssh -i ../.ssh/id_rsa <vm_user_name>@<vm_dns_or_public_ip>
   ```

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
