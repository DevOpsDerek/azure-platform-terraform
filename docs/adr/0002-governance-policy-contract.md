# ADR 0002: Terraform-managed Azure governance policy contract

## Status

Accepted

## Context

We need a small, explicit, testable governance baseline that is enforced as platform code. The goal is to set a clear platform contract without claiming full regulatory coverage.

## Decision

We define and assign a deliberately small set of custom Azure Policies at subscription scope:

1. **Required metadata**: deny resources that do not include required tags (`owner`, `costcenter` by default).
2. **Secure configuration**: deny storage accounts that do not enforce HTTPS-only traffic.

Assignments are created with configurable enforcement mode:

- `Default`: deny is enforced.
- `DoNotEnforce`: policy compliance is evaluated, but deny is not enforced.

## Exception model

Exceptions are managed through Terraform as `azurerm_subscription_policy_exemption` resources.

Each exemption request must include:

- target `assignment_id`
- `requested_by`
- `justification`
- `review_by`
- `expires_on`

`expires_on` and exemption metadata are validated as:

- valid RFC3339 UTC timestamp (`YYYY-MM-DDTHH:MM:SSZ`)
- exemption metadata includes requester, review, and justification fields

This implements a time-bounded waiver model with explicit review metadata.
Operationally, exemption requests should use future expiries and are expected to be limited to 90 days, with renewal requiring review.

## Policy evaluation and testing

Policy evaluation is provided by Azure Policy on assignment scope. Deny controls block non-compliant resource creates/updates when enforcement is enabled.

Testing includes:

- standard Terraform validation
- negative validation examples that fail when required baseline metadata tags are weakened or exemption expiry format is invalid

The negative test is executed by `tests/validate_non_compliant.sh` and intended for pre-merge CI checks.

## Consequences

- The platform has an explicit, versioned governance contract.
- Controls are intentionally limited in scope and should be expanded in future ADRs/issues as needed.
