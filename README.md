# Azure platform Terraform governance baseline

This repository defines a deliberately small Azure Policy contract in Terraform:

- **Required metadata**: resources must include required tags.
- **Secure configuration**: storage accounts must enforce HTTPS-only traffic.

This is intentionally not a full compliance baseline.

## Policy scope, effects, and enforcement

All policies are assigned at the **subscription scope** (`var.subscription_id`).

| Control | Scope | Effect |
| --- | --- | --- |
| Required tags (`owner`, `costcenter` by default) | Subscription | `deny` |
| Storage HTTPS-only | Subscription | `deny` |

Assignments support `var.enforcement_mode`:

- `Default` → enforced
- `DoNotEnforce` → audit/simulation mode while still evaluating compliance

## Exception model (time-bounded)

Use `var.policy_exemptions` to request exemptions with:

- `assignment_id`
- `requested_by`
- `justification`
- `review_by`
- `expires_on`

Terraform validation enforces that exemptions:

- have a valid RFC3339 UTC timestamp (`YYYY-MM-DDTHH:MM:SSZ`)
- include justification and review owner metadata

Exception process requirement:

- requests should set a future `expires_on` (**manual operational review check**, not Terraform input validation)
- expiry should be limited to 90 days (**manual operational review check**; renewal requires new review/approval)

Exemptions are created as `azurerm_subscription_policy_exemption` resources and carry request/review metadata.

## Policy evaluation

Azure Policy continuously evaluates assigned resources and new deployments against the assignments. Deny effects block non-compliant creates/updates. In `DoNotEnforce` mode, compliance is still evaluated without blocking.

## Testing

### Standard validation

```bash
terraform init -backend=false
terraform validate
```

### Negative validation (non-compliant example)

The fixtures include intentionally non-compliant changes:

- `tests/non_compliant_exemption/main.tf` removes `costcenter` from required metadata tags.
- `tests/non_compliant_exemption_timestamp/main.tf` uses an invalid exemption expiry timestamp.
- `tests/non_compliant_exemption_semantic_timestamp/main.tf` uses an impossible date/time despite matching timestamp shape.
- `tests/non_compliant_exemption_metadata/main.tf` uses blank exemption review metadata.
- `tests/non_compliant_exemption_key/main.tf` uses an invalid exemption key format.

Run:

```bash
./tests/validate_non_compliant.sh
```

The script **passes only when Terraform rejects** that invalid input, proving non-compliant governance changes are caught in pre-merge validation.