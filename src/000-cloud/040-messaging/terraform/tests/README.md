---
title: Testing Terraform
description: Tests for the Terraform implementation of the messaging component
author: Edge AI Team
ms.date: 06/07/2025
ms.topic: reference
keywords:
  - testing
  - terraform
  - messaging
  - event hub
  - event grid
  - azure cli
  - integration testing
estimated_reading_time: 1
---

## Testing Terraform

To read more about how testing works in terraform, see [Tests | Terraform](https://developer.hashicorp.com/terraform/language/tests).

To run the tests navigate to the directory above this `/tests` directory and run the following command:

```sh
# Required by the azurerm terraform provider
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
# Runs the tests if there is a tests folder in the same directory
terraform test
```

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
