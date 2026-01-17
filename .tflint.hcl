# TFLint Configuration
# See: https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/config.md

plugin "azurerm" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Temporarily disabled rules
# TODO: Re-enable and fix - tracked by GitHub issue
# See: https://github.com/terraform-linters/tflint-ruleset-azurerm/blob/v0.30.0/docs/rules/azurerm_resources_missing_prevent_destroy.md
rule "azurerm_resources_missing_prevent_destroy" {
  enabled = false
}
