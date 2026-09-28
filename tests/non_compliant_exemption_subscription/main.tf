terraform {
  required_version = "= 1.9.8"
}

module "governance" {
  source          = "../.."
  subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000000"

  required_tags = ["owner", "costcenter"]

  policy_exemptions = {
    wrong-subscription = {
      assignment_id = "/subscriptions/11111111-1111-1111-1111-111111111111/providers/Microsoft.Authorization/policyAssignments/example"
      display_name  = "Wrong subscription assignment"
      requested_by  = "platform.engineering@example.com"
      justification = "Assignment from a different subscription should fail validation"
      review_by     = "security.review@example.com"
      expires_on    = "2027-01-01T00:00:00Z"
    }
  }
}
