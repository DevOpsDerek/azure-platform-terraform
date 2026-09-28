variable "name_prefix" {
  description = "Short prefix used in resource names."
  type        = string
  default     = "ref"
}

variable "environment" {
  description = "Environment identifier (for example: dev, test, prod)."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for all deployed resources."
  type        = string
  default     = "eastus"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version."
  type        = string
  default     = "1.32.9"
}

variable "node_count" {
  description = "Number of system nodes for the default node pool."
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "VM SKU for the AKS default node pool."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "address_space" {
  description = "Address space for the platform VNet."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "aks_subnet_cidr" {
  description = "Subnet CIDR for AKS nodes."
  type        = string
  default     = "10.10.0.0/24"
}

variable "service_cidr" {
  description = "CIDR used by Kubernetes services inside the AKS cluster."
  type        = string
  default     = "10.240.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address used by the Kubernetes DNS service (must be inside service_cidr)."
  type        = string
  default     = "10.240.0.10"
}

variable "authorized_ip_ranges" {
  description = "Allowed CIDR ranges for AKS API server access (replace the default placeholder CIDR before deployment)."
  type        = list(string)
  default     = ["198.51.100.10/32"]
}

variable "tags" {
  description = "Tags applied to all resources. The module always applies baseline environment, managed_by, owner, and costcenter tags; set matching keys here to override the default owner/costcenter values."
  type        = map(string)
  default     = {}
}

variable "subscription_id" {
  description = "Optional Azure subscription ID override for governance policy assignments and exemptions. This must match the AzureRM provider subscription because custom policy definitions are created at subscription scope."
  type        = string
  default     = null
  nullable    = true
}

variable "required_tags" {
  description = "Tag keys that every resource must include."
  type        = set(string)
  default     = ["owner", "costcenter"]

  validation {
    condition     = contains(var.required_tags, "owner") && contains(var.required_tags, "costcenter")
    error_message = "required_tags must include both 'owner' and 'costcenter' to maintain the platform metadata baseline."
  }

  validation {
    condition = alltrue([
      for tag in var.required_tags : can(regex("^[a-z0-9-]+$", tag))
    ])
    error_message = "Each required_tags value must use lowercase letters, numbers, and hyphens only."
  }
}

variable "enforcement_mode" {
  description = "Policy assignment enforcement mode: Default (enforced) or DoNotEnforce (evaluate only)."
  type        = string
  default     = "Default"

  validation {
    condition     = contains(["Default", "DoNotEnforce"], var.enforcement_mode)
    error_message = "enforcement_mode must be 'Default' or 'DoNotEnforce'."
  }
}

variable "policy_exemptions" {
  description = "Optional time-bounded policy exemption requests."
  type = map(object({
    assignment_id = string
    display_name  = string
    requested_by  = string
    justification = string
    review_by     = string
    expires_on    = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for exemption in values(var.policy_exemptions) :
      can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", exemption.expires_on)) &&
      can(timecmp(exemption.expires_on, exemption.expires_on))
    ])
    error_message = "Each policy exemption must include a valid RFC3339 UTC expires_on value (YYYY-MM-DDTHH:MM:SSZ)."
  }

  validation {
    condition = alltrue([
      for exemption in values(var.policy_exemptions) :
      length(trimspace(exemption.requested_by)) > 0 &&
      length(trimspace(exemption.review_by)) > 0 &&
      length(trimspace(exemption.justification)) > 0
    ])
    error_message = "Each policy exemption must include non-empty requested_by, justification, and review_by values."
  }

  validation {
    condition = alltrue([
      for key in keys(var.policy_exemptions) : can(regex("^[a-z0-9-]+$", key))
    ])
    error_message = "Each policy_exemptions key must use lowercase letters, numbers, and hyphens only."
  }

  validation {
    condition = alltrue([
      for exemption in values(var.policy_exemptions) :
      can(regex("^/subscriptions/[^/]+/providers/Microsoft.Authorization/policyAssignments/[^/]+$", exemption.assignment_id))
    ])
    error_message = "Each policy exemption assignment_id must reference a subscription policy assignment ID."
  }
}
