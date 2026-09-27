variable "subscription_id" {
  description = "Azure subscription ID for policy assignments and exemptions."
  type        = string
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
      length(trimspace(exemption.review_by)) > 0 &&
      length(trimspace(exemption.justification)) > 0
    ])
    error_message = "Each policy exemption must include a non-empty justification and a non-empty review_by."
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
