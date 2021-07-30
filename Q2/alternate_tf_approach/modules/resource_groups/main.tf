resource "azurerm_resource_group" "resource_group" {
   count = length(var.ResourceGroups)
   name = var.ResourceGroups[count].Name
   location = var.ResourceGroups[count].location
}