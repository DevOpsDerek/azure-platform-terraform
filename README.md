# Azure Platform Terraform Reference (AKS + Governance)

This repository provides a composable, version-pinned Terraform reference for a minimal Azure platform footprint and AKS target, plus a scoped Azure Policy governance contract.

## What this deploys

- Resource group
- Virtual network with AKS subnet
- Log Analytics workspace
- AKS cluster (system-assigned managed identity)
- Subscription-level Azure Policy assignments for required metadata tags and storage HTTPS-only enforcement

## Quick start (safe, no credentials committed)

```bash
cp examples/safe.tfvars terraform.tfvars
terraform init -backend=false -input=false -lockfile=readonly
terraform fmt -check -recursive
terraform validate
```

> The `examples/safe.tfvars` file intentionally uses non-sensitive baseline defaults, including override-ready placeholder values for the enforced `owner` and `costcenter` tags.

## Inputs

Key AKS parameters are documented in `variables.tf`, including:
- region (`location`)
- naming (`name_prefix`)
- environment (`environment`)
- sizing (`node_count`, `node_vm_size`)
- cluster service networking (`service_cidr`, `dns_service_ip`)
- API server restriction (`authorized_ip_ranges`, default placeholder CIDR that must be replaced before deployment)

Governance inputs include:
- optional subscription override (`subscription_id`) for governance resources, using either a bare GUID or `/subscriptions/<guid>`
- required tags baseline (`required_tags`, default includes `owner` and `costcenter`)
- policy assignment enforcement mode (`enforcement_mode`)
- structured exemptions (`policy_exemptions`)

## Governance contract (explicitly scoped)

Controls are intentionally limited and not a full compliance baseline:
- required resource metadata tags
- storage accounts requiring HTTPS-only traffic

Policy assignments are created at subscription scope and support:
- `Default` (enforced)
- `DoNotEnforce` (evaluate without deny enforcement)

Exemption input validation enforces:
- RFC3339 UTC timestamp format plus semantic timestamp parsing
- non-empty exemption metadata (`requested_by`, `review_by`, `justification`)
- key format (`^[a-z0-9-]+$`)
- subscription policy assignment ID shape
- same-subscription checks against `subscription_id` when an override is provided
- runtime same-subscription safeguards against the effective governance provider subscription during planning/apply

## Policy testing

Run standard checks:

```bash
terraform init -backend=false -input=false -lockfile=readonly
terraform validate
```

Run negative governance fixtures:

```bash
bash ./tests/validate_non_compliant.sh
```

The negative suite verifies non-compliant examples are rejected before merge.

## Remote state requirements (before live deployment)

Configure a remote backend (for example, Azure Storage) before any shared/live use. Typical setup:

- dedicated state resource group and storage account
- private container for state file
- state locking enabled (Azure Blob lease)
- restricted access (private endpoints/firewall as needed)

Example backend block (fill with your own values):

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "REPLACE_ME"
    storage_account_name = "REPLACE_ME"
    container_name       = "tfstate"
    key                  = "platform/aks.tfstate"
  }
}
```

## Identity assumptions

- CI validation on pull requests is credential-free and does **not** apply.
- Optional plan generation can use Azure federated identity (OIDC) on `workflow_dispatch`.
- The plan job is opt-in (`run_plan=true`) and requires repository variables `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID`.
- Live deployment is intentionally out of scope for routine CI and must be human-approved.

## Central automation and human review

The `automation-validation` job in the existing `terraform` workflow uses the central
`DevOpsDerek/workflows` validator to lint Actions and compile gh-aw sources with
CLI **v0.89.21**, checking that committed locks are current. It needs only
`contents: read` and does not inherit repository secrets.

`ci-failure-diagnosis.md` imports the central CI diagnosis component with
`inlined-imports: true`; its compiled lock contains the reviewed instructions,
so runtime does not fetch mutable shared prompts. Both central references are
pinned to `dac4b81c298cb3ea6821ea312efa5375f42d5ccb` in their configuration.
Commit source and generated lock together; regenerate with:

```bash
gh aw compile --validate --actionlint --no-check-update
```

Diagnosis is restricted to failed, completed runs of `terraform` and
`Terraform governance validation` originating from same-repository pull requests.
Fork PRs and manual runs are excluded, particularly the credentialed opt-in plan.
Feature-branch PR checks are intentionally eligible, so no `main`-only head-branch
filter is used; the compiler's branch-filter warning is expected.
The agent has read-only contents, Actions, and issue tools; GitHub writes are
limited to the compiler's isolated, bounded diagnostic-issue safe output.
It cannot change code, rerun checks, apply/destroy infrastructure, deploy, merge,
or bypass human review. Diagnostic issues are proposals, not approvals or proof
that infrastructure is safe.

Before enabling diagnosis after merge, configure the Copilot engine's
`COPILOT_GITHUB_TOKEN` as described in the
[gh-aw engine documentation](https://github.github.com/gh-aw/reference/engines/#github-copilot-default).
Do not give the agent Azure credentials, an OIDC permission, plan artifacts, or
write-capable GitHub tool-token overrides. No agent run or credentialed plan is
needed to compile and validate this configuration.

The existing Terraform job/check names, Terraform **1.9.8**, AzureRM **4.44.0**,
recursive fmt, backend-disabled init/validate, TFLint **v0.56.0**, hard-fail tfsec,
and eight negative governance fixtures are retained. The central runtime helper
is not a complete replacement: its Terraform initialization does not enforce
the root's readonly lockfile, and it does not cover fmt, lint, security scanning,
or the negative-fixture harness. There is no verified central plan-reporting
interface in the adopted catalog; the existing plan remains manually requested
and separate from diagnosis.

At adoption, the GitHub API reported no protection on `main`, no repository
rulesets, and only the unprotected `copilot` environment; `terraform-plan` was
absent. The current plan job's protected-default-branch gate therefore does not
permit a live plan. Administrators must deliberately configure branch protection,
required checks, an approval-protected `terraform-plan` environment, and a
read-only Azure federated identity before human-authorized planning. This
adoption does not provision credentials or change repository protections.

## Network and security assumptions

- AKS runs in a dedicated subnet in a dedicated VNet.
- Baseline NSG/UDR/policy hardening is expected to be layered in environment-specific compositions.
- The reference is intentionally minimal and should be extended for production controls (private cluster, network policies, workload identity, policy enforcement).

## Cost considerations

Main recurring drivers:
- AKS node pool VM size/count
- Log Analytics ingestion/retention
- Regional pricing variance

Use conservative node sizing defaults first and tune upward based on measured workloads.

## Teardown

For non-production environments only:

```bash
terraform init -input=false # include backend config flags when using remote state
terraform destroy -var-file=examples/safe.tfvars
```

Always confirm no shared/critical resources are attached before destroy.

## ADRs

Design decisions and unresolved choices are tracked in:
- `docs/adr/0002-governance-policy-contract.md`
- `docs/adr/0001-aks-reference-unresolved-decisions.md`
