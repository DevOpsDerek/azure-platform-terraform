# Azure Platform Terraform Reference (AKS)

This repository provides a composable, version-pinned Terraform reference for a minimal Azure platform footprint and AKS target.

## What this deploys

- Resource group
- Virtual network with AKS subnet
- Log Analytics workspace
- AKS cluster (system-assigned managed identity)

## Quick start (safe, no credentials committed)

```bash
cp examples/safe.tfvars terraform.tfvars
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
```

> The `examples/safe.tfvars` file intentionally uses placeholders and non-sensitive defaults.

## Inputs

Key parameters are documented in `variables.tf`, including:
- region (`location`)
- naming (`name_prefix`)
- environment (`environment`)
- sizing (`node_count`, `node_vm_size`)
- API server restriction (`authorized_ip_ranges`, default empty and must be set for restricted production access)

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
terraform destroy -var-file=examples/safe.tfvars
```

Always confirm no shared/critical resources are attached before destroy.

## ADRs

Unresolved design choices are tracked in:
- `docs/adr/0001-aks-reference-unresolved-decisions.md`