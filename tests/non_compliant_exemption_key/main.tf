terraform {
  required_version = "= 1.9.8"
}

module "governance" {
  source          = "../.."
  subscription_id = "00000000-0000-0000-0000-000000000000"

  policy_exemptions = {
    "invalid key" = {
      assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/example"
      display_name  = "Invalid key format"
      requested_by  = "platform.engineering@example.com"
      justification = "Key contains spaces"
      review_by     = "security.review@example.com"
      expires_on    = "2027-01-01T00:00:00Z"
    }
  }
}
