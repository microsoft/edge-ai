---
title: Testing Terraform
description: Tests for the Terraform implementation of the VPN Gateway component
author: Edge AI Team
ms.date: 2026-07-28
ms.topic: reference
keywords:
  - testing
  - terraform
  - vpn gateway
  - point-to-site
  - azure cli
  - integration testing
estimated_reading_time: 1
---

## Testing Terraform

To read more about how testing works in terraform, see [Tests | Terraform](https://developer.hashicorp.com/terraform/language/tests).

To run the tests navigate to the directory above this `/tests` directory and run the following command:

```sh
terraform test
```

## Coverage Notes

The tests here cover the default Azure AD (Microsoft Entra ID) authentication path and the
optional site-to-site connections module, both of which only create resources and do not read
existing data, so they run safely with a fabricated `command = plan` fixture.

Certificate-based authentication (`should_use_azure_ad_auth = false` with `should_generate_ca = false`)
is intentionally **not** covered here: that path reads an existing certificate from Key Vault via
`data "azurerm_key_vault_secret"`, which requires a real, populated Key Vault and cannot be satisfied
by a fabricated fixture. Validate that path manually against a deployed
[Only Network VPN Gateway](../../../../../blueprints/only-network-vpn-gateway/README.md) blueprint instance.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
