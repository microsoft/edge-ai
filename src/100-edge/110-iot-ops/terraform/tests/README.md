---
title: Testing Terraform
description: Tests for the Terraform implementation of the IoT Operations component
author: Edge AI Team
ms.date: 06/07/2025
ms.topic: reference
keywords:
  - testing
  - terraform
  - iot operations
  - iot ops
  - azure iot operations
  - edge computing
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

## Test Coverage

The tests cover the following scenarios:

### Main Functionality Tests (`iot-ops.tftest.hcl`)

- **Default configuration**: Tests basic IoT Operations deployment with SelfSigned trust source
- **Trust configuration options**: Tests various trust configurations including CustomerManagedGenerateIssuer and CustomerManagedByoIssuer
- **Feature toggles**: Tests enabling/disabling specific features like OPC UA simulator, OpenTelemetry collector, and broker listeners
- **ADR namespace integration**: Tests deployment with and without Azure Device Registry namespace configuration

### Variable Validation Tests (`variable_validation.tftest.hcl`)

- **Input validation**: Tests all input variable validation rules
- **Error conditions**: Ensures proper error handling for invalid configurations
- **ADR namespace validation**: Tests valid and null ADR namespace configurations

All tests include support for Azure Device Registry namespace functionality, ensuring comprehensive coverage of the component's capabilities.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
