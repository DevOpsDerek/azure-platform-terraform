module "governance" {
  source          = "../.."
  subscription_id = "00000000-0000-0000-0000-000000000000"

  policy_exemptions = {
    bad-scope = {
      assignment_id = "/providers/Microsoft.Management/managementGroups/example/providers/Microsoft.Authorization/policyAssignments/example"
      display_name  = "Wrong scope assignment ID"
      requested_by  = "platform.engineering@example.com"
      justification = "Assignment scope is not subscription"
      review_by     = "security.review@example.com"
      expires_on    = "2027-01-01T00:00:00Z"
    }
  }
}
