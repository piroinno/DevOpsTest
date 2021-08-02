terraform {
  #backend "azurerm" {}
  required_providers {
    azurerm = ">2.0.0"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name     = "q2-rg"
  location = var.location

  tags = {
    environment = "q2"
  }
}

resource "azurerm_management_lock" "resource_group_lock" {
  name       = "q2-rg-lock"
  scope      = azurerm_resource_group.resource_group.id
  lock_level = "CanNotDelete"
  notes      = "This Resource Group cannot be deleted"
}
resource "azurerm_storage_account" "storage_account" {
  name                     = "q2storageacct"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "q2"
  }
}

resource "azurerm_storage_container" "vm_disks" {
  name                  = "vmdisks"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "q2-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4"]

  subnet {
    name           = "subnet_one"
    address_prefix = "10.0.1.0/24"
  }

  subnet {
    name           = "subnet_two"
    address_prefix = "10.0.2.0/24"
  }

  tags = {
    environment = "q2"
  }
}

locals {
  subnet_map = {
    for i in azurerm_virtual_network.virtual_network.subnet :
    i.name => i.id
  }
}
resource "azurerm_network_security_group" "nsg" {
  name                = "q2-nsg"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
}

resource "azurerm_network_security_rule" "rule_one" {
  name                        = "port80"
  resource_group_name         = azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "VirtualNetwork"
}

resource "azurerm_network_security_rule" "rule_two" {
  name                        = "port80"
  resource_group_name         = azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "VirtualNetwork"
}

resource "azurerm_network_interface" "net_interface_one" {
  name                = "q2-net-one"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = lookup(local.subnet_map, "subnet_one")
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "net_interface_two" {
  name                = "q2-net-two"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = lookup(local.subnet_map, "subnet_two")
    private_ip_address_allocation = "Dynamic"
  }
}

resource "random_string" "vm-admin-pass" {
  length  = 12
  upper   = true
  number  = true
  special = true
}

# Added as an answer to question 5
data "azurerm_client_config" "current" {
}
resource "azurerm_key_vault" "kv" {
  name                = "q2-kv"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete"
    ]
  }

  enabled_for_disk_encryption = true
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting" {
  name               = "kvdiags"
  target_resource_id = azurerm_key_vault.kv.id
  storage_account_id = azurerm_storage_account.storage_account.id

  log {

    category = "AuditEvent"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 7
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_key_vault_secret" "admin_pass_vault_secret" {
  name         = "vm-admin-passwd"
  value        = random_string.vm-admin-pass.result
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_virtual_machine" "vm_one" {
  name                  = "q2-vm-one"
  resource_group_name   = azurerm_resource_group.resource_group.name
  location              = var.location
  network_interface_ids = ["${azurerm_network_interface.net_interface_one.id}"]
  vm_size               = "Standard_B2ms"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name          = "os"
    vhd_uri       = "${azurerm_storage_account.storage_account.primary_blob_endpoint}${azurerm_storage_container.vm_disks.name}/os-vm-one.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  storage_data_disk {
    name          = "data"
    vhd_uri       = "${azurerm_storage_account.storage_account.primary_blob_endpoint}${azurerm_storage_container.vm_disks.name}/data-vm-one.vhd"
    disk_size_gb  = "255"
    create_option = "empty"
    lun           = 0
  }

  os_profile {
    computer_name  = "q2-vm-one"
    admin_username = "q2-vm-one"
    admin_password = random_string.vm-admin-pass.result
  }

  os_profile_windows_config {}
}

resource "azurerm_virtual_machine" "vm_two" {
  name                  = "q2-vm-two"
  resource_group_name   = azurerm_resource_group.resource_group.name
  location              = var.location
  network_interface_ids = ["${azurerm_network_interface.net_interface_two.id}"]
  vm_size               = "Standard_B2ms"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name          = "os"
    vhd_uri       = "${azurerm_storage_account.storage_account.primary_blob_endpoint}${azurerm_storage_container.vm_disks.name}/os-vm-two.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  storage_data_disk {
    name          = "data"
    vhd_uri       = "${azurerm_storage_account.storage_account.primary_blob_endpoint}${azurerm_storage_container.vm_disks.name}/data-vm-two.vhd"
    disk_size_gb  = "255"
    create_option = "empty"
    lun           = 0
  }

  os_profile {
    computer_name  = "q2-vm-two"
    admin_username = "q2-vm-two"
    admin_password = random_string.vm-admin-pass.result
  }

  os_profile_windows_config {}
}
