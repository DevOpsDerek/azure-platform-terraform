locals {
  base_name = "${var.name_prefix}-${var.environment}"
  tags = merge(
    {
      environment = var.environment
      managed_by  = "terraform"
      owner       = "platform-team"
      costcenter  = "shared-platform"
    },
    var.tags
  )

  governance_subscription_id = coalesce(var.subscription_id, data.azurerm_client_config.current.subscription_id)
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "platform" {
  name     = "rg-${local.base_name}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "platform" {
  name                = "vnet-${local.base_name}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  address_space       = var.address_space
  tags                = local.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.platform.name
  address_prefixes     = [var.aks_subnet_cidr]
}

resource "azurerm_log_analytics_workspace" "platform" {
  name                = "log-${local.base_name}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_kubernetes_cluster" "platform" { #tfsec:ignore:azure-container-limit-authorized-ips Provider v4 uses api_server_access_profile instead of the legacy top-level argument. #tfsec:ignore:azure-container-configured-network-policy Network policy mode is intentionally left open pending ADR decisions.
  name                              = "aks-${local.base_name}"
  location                          = azurerm_resource_group.platform.location
  resource_group_name               = azurerm_resource_group.platform.name
  dns_prefix                        = "dns-${local.base_name}"
  kubernetes_version                = var.kubernetes_version
  role_based_access_control_enabled = true
  sku_tier                          = "Free"
  tags                              = local.tags

  default_node_pool {
    name           = "system"
    node_count     = var.node_count
    vm_size        = var.node_vm_size
    vnet_subnet_id = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.platform.id
  }

  network_profile {
    network_plugin    = "azure"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = "standard"
  }

  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }
}

resource "azurerm_policy_definition" "required_tags" {
  for_each = var.required_tags

  name         = "require-tag-${substr(each.value, 0, 40)}-${substr(sha1(each.value), 0, 8)}"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require ${each.value} tag on resources"
  description  = "Deny resource creation when the required tag '${each.value}' is missing."

  metadata = jsonencode({
    category = "Platform Governance"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field   = "type"
          notLike = "Microsoft.Resources/subscriptions/resourceGroups"
        },
        {
          field  = "[concat('tags[', '${each.value}', ']')]"
          exists = false
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_policy_definition" "storage_https_only" {
  name         = "storage-require-https-only"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require HTTPS-only for storage accounts"
  description  = "Deny storage accounts that do not enforce HTTPS-only traffic."

  metadata = jsonencode({
    category = "Platform Governance"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          field     = "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly"
          notEquals = true
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "required_tags" {
  for_each = azurerm_policy_definition.required_tags

  name                 = "required-tag-${substr(each.key, 0, 40)}-${substr(sha1(each.key), 0, 8)}"
  subscription_id      = local.governance_subscription_id
  policy_definition_id = each.value.id
  display_name         = "Require ${each.key} tag"
  enforce              = var.enforcement_mode == "Default"

  lifecycle {
    precondition {
      condition     = var.subscription_id == null || var.subscription_id == data.azurerm_client_config.current.subscription_id
      error_message = "subscription_id must match the AzureRM provider subscription when creating subscription-scoped custom policy definitions and assignments."
    }
  }
}

resource "azurerm_subscription_policy_assignment" "storage_https_only" {
  name                 = "require-storage-https-only"
  subscription_id      = local.governance_subscription_id
  policy_definition_id = azurerm_policy_definition.storage_https_only.id
  display_name         = "Require HTTPS-only for storage accounts"
  enforce              = var.enforcement_mode == "Default"

  lifecycle {
    precondition {
      condition     = var.subscription_id == null || var.subscription_id == data.azurerm_client_config.current.subscription_id
      error_message = "subscription_id must match the AzureRM provider subscription when creating subscription-scoped custom policy definitions and assignments."
    }
  }
}

locals {
  policy_assignment_ids = merge(
    { for tag, assignment in azurerm_subscription_policy_assignment.required_tags : "required_tag_${tag}" => assignment.id },
    { storage_https_only = azurerm_subscription_policy_assignment.storage_https_only.id }
  )
}

resource "azurerm_subscription_policy_exemption" "this" {
  for_each = var.policy_exemptions

  name                 = "exemption-${substr(each.key, 0, 40)}-${substr(sha1(each.key), 0, 8)}"
  subscription_id      = local.governance_subscription_id
  policy_assignment_id = each.value.assignment_id
  exemption_category   = "Waiver"
  display_name         = each.value.display_name
  expires_on           = each.value.expires_on

  metadata = jsonencode({
    requested_by  = each.value.requested_by
    justification = each.value.justification
    review_by     = each.value.review_by
  })

  lifecycle {
    precondition {
      condition     = lower(split("/", trimprefix(each.value.assignment_id, "/"))[1]) == lower(local.governance_subscription_id)
      error_message = "Each policy exemption assignment_id must reference a policy assignment in the same subscription as the module's governance resources."
    }
  }
}
