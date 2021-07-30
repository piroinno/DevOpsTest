terraform {
  backend "azurerm" {}
  required_providers {
    azurerm = ">2.0.0"
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

module "resource_groups" {
  source           = "./modules/resource_groups"
  ResourceGroups             = var.ResourceGroups
  dummy_depends_on = [module.resource_groups.resource_groups_output]
}

module "nsgs" {
  source           = "./modules/nsgs"
  Nsgs             = var.Nsgs
  dummy_depends_on = [module.resource_groups.resource_groups_output, module.vnets.vnets_output]
}

module "storage_accounts" {
  source           = "./modules/storage_accounts"
  StorageAccount             = var.StorageAccount
  dummy_depends_on = [module.resource_groups.resource_groups_output]
}

module "vnets" {
  source           = "./modules/vnets"
  VNets             = var.VNets
  dummy_depends_on = [module.resource_groups.resource_groups_output]
}

module "windows_vms" {
  source           = "./modules/windows_vms"
  WindowsVm             = var.WindowsVms
  dummy_depends_on = [module.resource_groups.resource_groups_output]
}