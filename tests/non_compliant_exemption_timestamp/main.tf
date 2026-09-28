terraform {
  required_version = "= 1.9.8"
}

module "governance" {
  source          = "../.."
  subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000000"

  required_tags = ["owner", "costcenter"]

  policy_exemptions = {
    bad_timestamp = {
      assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/example"
      display_name  = "Bad timestamp waiver"
      requested_by  = "platform.engineering@example.com"
      justification = "Timestamp format should fail validation"
      review_by     = "security.review@example.com"
      expires_on    = "not-a-rfc3339-value"
    }
  }
}
