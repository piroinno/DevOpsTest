resource "azurerm_network_security_group" "nsg" {
   name = var.Nsg.Name
   resource_group_name = "${azurerm_resource_group.test.name}"
   location = "West US"
}