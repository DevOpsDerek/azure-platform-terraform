module "governance" {
  source          = "../.."
  subscription_id = "00000000-0000-0000-0000-000000000000"

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
