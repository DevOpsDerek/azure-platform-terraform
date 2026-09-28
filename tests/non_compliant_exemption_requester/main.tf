terraform {
  required_version = "= 1.9.8"
}

module "governance" {
  source          = "../.."
  subscription_id = "00000000-0000-0000-0000-000000000000"

  policy_exemptions = {
    missing-requester = {
      assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/example"
      display_name  = "Missing requester metadata"
      requested_by  = "   "
      justification = "Approved exception without requester should fail validation"
      review_by     = "security.review@example.com"
      expires_on    = "2027-01-01T00:00:00Z"
    }
  }
}
