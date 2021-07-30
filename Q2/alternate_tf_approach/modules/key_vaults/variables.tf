variable "KeyVaults" {
  default = []
  type = list(
    object({
      name                        = string
      location                    = string
      resource_group_name         = string
      sku_name                    = string
      tenant_id                   = string
      secrets_access_policy       = map(string)
      enabled_for_disk_encryption = bool
    })
  )
}
