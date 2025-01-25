mock_data "azurerm_resource_group" {
   defaults = {
   name = "test_name"
   id   = "/subscriptions/00000000-0000-0000-0000-000000000000"
   }
}
mock_data "azurerm_subscription" {
   defaults = {
   id = "/subscriptions/00000000-0000-0000-0000-000000000000"
   }
}
mock_data "azurerm_virtual_machine" {
   defaults = {
   name = "test_name"
   id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-resource-group/providers/Microsoft.Compute/virtualMachines/vmName"
   }
   
}
