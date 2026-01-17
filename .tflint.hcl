# TFLint Configuration
# See: https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/config.md

plugin "azurerm" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

plugin "terraform" {
  enabled = true
  version = "0.13.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

# Temporarily disabled rules

# TODO: Re-enable after adding lifecycle prevent_destroy blocks
# Tracked by: https://github.com/microsoft/edge-ai/issues/104
# Reference: https://github.com/terraform-linters/tflint-ruleset-azurerm/blob/v0.30.0/docs/rules/azurerm_resources_missing_prevent_destroy.md
rule "azurerm_resources_missing_prevent_destroy" {
  enabled = false
}

# TODO: Re-enable after adding provider version constraints to internal modules
# Tracked by: https://github.com/microsoft/edge-ai/issues/106
# Reference: https://github.com/terraform-linters/tflint-ruleset-terraform/blob/v0.13.0/docs/rules/terraform_required_providers.md
rule "terraform_required_providers" {
  enabled = false
}
