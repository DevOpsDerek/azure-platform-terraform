terraform {
  required_version = "= 1.9.8"
}

module "governance" {
  source          = "../.."
  subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000000"

  required_tags = ["owner", "costcenter"]

  policy_exemptions = {
    bad-semantic-time = {
      assignment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyAssignments/example"
      display_name  = "Semantically invalid timestamp"
      requested_by  = "platform.engineering@example.com"
      justification = "Date components are impossible"
      review_by     = "security.review@example.com"
      expires_on    = "2026-99-99T25:61:61Z"
    }
  }
}
