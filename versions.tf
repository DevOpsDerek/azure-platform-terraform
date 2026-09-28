terraform {
  required_version = "= 1.9.8"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.44.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias = "governance"
  features {}
  subscription_id = var.subscription_id == null ? null : replace(var.subscription_id, "/subscriptions/", "")
}
