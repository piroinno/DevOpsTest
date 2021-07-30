locals {
   kv_secret_access_policies_map =  {
      for i in var.KeyVaults :
      i.name => {
         secret_permissions = split(",", i.secrets_access_policy.permissions)
         object_id = i.secrets_access_policy.object_id
         tenant_id = i.secrets_access_policy.tenant_id
      }
   }
}
resource "azurerm_key_vault" "kv" {
   count = length(var.KeyVaults)
  name                = var.KeyVaults[count].name
  location            = var.KeyVaults[count].location
  resource_group_name = var.KeyVaults[count].resource_group_name
  sku_name            = var.KeyVaults[count].sku_name
  tenant_id           = var.KeyVaults[count].tenant_id

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = lookup(local.kv_secret_access_policies_map, var.KeyVaults[count].name).secret_permissions
  }

  enabled_for_disk_encryption = var.KeyVaults[count].enabled_for_disk_encryption
}