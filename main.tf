terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

resource "azurerm_policy_definition" "required_tags" {
  for_each = var.required_tags

  name         = "require-tag-${each.value}"
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
  subscription_id      = var.subscription_id
  policy_definition_id = each.value.id
  display_name         = "Require ${each.key} tag"
  enforce              = var.enforcement_mode == "Default"
}

resource "azurerm_subscription_policy_assignment" "storage_https_only" {
  name                 = "require-storage-https-only"
  subscription_id      = var.subscription_id
  policy_definition_id = azurerm_policy_definition.storage_https_only.id
  display_name         = "Require HTTPS-only for storage accounts"
  enforce              = var.enforcement_mode == "Default"
}

locals {
  assignment_ids = merge(
    { for tag, assignment in azurerm_subscription_policy_assignment.required_tags : "required_tag_${tag}" => assignment.id },
    { storage_https_only = azurerm_subscription_policy_assignment.storage_https_only.id }
  )
}

resource "azurerm_subscription_policy_exemption" "this" {
  for_each = var.policy_exemptions

  name                 = "exemption-${substr(each.key, 0, 40)}-${substr(sha1(each.key), 0, 8)}"
  subscription_id      = var.subscription_id
  policy_assignment_id = each.value.assignment_id
  exemption_category   = "Waiver"
  display_name         = each.value.display_name
  expires_on           = each.value.expires_on

  metadata = jsonencode({
    requested_by  = each.value.requested_by
    justification = each.value.justification
    review_by     = each.value.review_by
  })
}

output "policy_assignment_ids" {
  description = "Policy assignment IDs that can be used when creating policy exemptions."
  value       = local.assignment_ids
}
