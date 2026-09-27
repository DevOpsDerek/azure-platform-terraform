variable "subscription_id" {
  description = "Azure subscription ID for policy assignments and exemptions."
  type        = string
}

variable "required_tags" {
  description = "Tag keys that every resource must include."
  type        = set(string)
  default     = ["owner", "costCenter"]

  validation {
    condition     = contains(var.required_tags, "owner") && contains(var.required_tags, "costCenter")
    error_message = "required_tags must include both 'owner' and 'costCenter' to maintain the platform metadata baseline."
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
      can(formatdate("YYYY-MM-DD", exemption.expires_on)) &&
      length(trimspace(exemption.review_by)) > 0 &&
      length(trimspace(exemption.justification)) > 0
    ])
    error_message = "Each policy exemption must include a valid RFC3339 expires_on value, a non-empty justification, and a non-empty review_by."
  }
}
