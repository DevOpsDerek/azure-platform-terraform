data "azurerm_resource_group" "exercise" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "exercise" {
  name                            = var.storage_account_name
  resource_group_name             = data.azurerm_resource_group.exercise.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  tags = {
    owner           = "BG-014 exercise owner"
    costcenter      = "training"
    exercise_id     = "BG-014"
    exercise_run_id = "${var.run_id}-${var.run_attempt}"
    managed_by      = "terraform"
  }
}

output "storage_account_id" {
  description = "ID of the temporary BG-014 exercise storage account."
  value       = azurerm_storage_account.exercise.id
}

output "storage_account_name" {
  description = "Name of the temporary BG-014 exercise storage account."
  value       = azurerm_storage_account.exercise.name
}
