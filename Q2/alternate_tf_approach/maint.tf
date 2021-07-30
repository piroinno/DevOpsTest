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
  ResourceGroups   = var.ResourceGroups
}

module "key_vaults" {
  source           = "./modules/key_vaults"
  KeyVaults        = var.KeyVaults
  dummy_depends_on = [module.resource_groups.resource_groups_output]
}
