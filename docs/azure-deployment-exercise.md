# BG-014 approved Azure deployment exercise

The exercise is a separate Terraform root at `exercises/azure-deployment`. It
creates one empty, Standard LRS StorageV2 account in an **owner-created,
dedicated resource group**, checks it, destroys it, and checks that no resources
tagged for that workflow run remain. It does not create a resource group, AKS,
policy assignments, or subscription-scoped resources. Terraform state remains
on the ephemeral hosted runner and is not uploaded as an artifact.

## Disabled-by-default approval gates

The workflow has only a manual `workflow_dispatch` trigger. It can proceed only
when all of these are true:

- The run is dispatched from the protected repository default branch.
- The `AZURE_EXERCISE_ENABLED` repository variable is exactly `true`; leave it
  unset or set it to `false` to keep the exercise disabled.
- The dispatcher explicitly confirms the exercise and the £25 budget.
- The `azure-deployment-exercise` GitHub environment is configured with required
  human reviewers. Prevent self-approval and do not authorize bot/coding-agent
  identities as reviewers.

The workflow requests `id-token: write` only for this gated job. Pull-request
validation remains credential-free and does not plan or apply against Azure.
Coding agents must not receive environment approval or Azure credentials.
Approval is required again for each dispatch because this is an environment
protection rule, not a stored deployment credential. Azure Login allows login
when the identity cannot enumerate subscriptions while retaining the
owner-supplied subscription ID. Terraform and Azure CLI resource queries target
that subscription explicitly; the identity remains scoped to the dedicated
resource group.

## Owner-created Azure prerequisites

No Azure identity, federation, role assignment, resource group, budget, or
environment protection is created by this repository change. Before enabling
the repository variable, an Azure/repository owner must:

1. Create an Entra application or user-assigned managed identity and its
   federated credential. Use issuer
   `https://token.actions.githubusercontent.com`, audience
   `api://AzureADTokenExchange`, and subject
   `repo:DevOpsDerek/azure-platform-terraform:environment:azure-deployment-exercise`.
2. Create an empty resource group dedicated to this exercise. Set the protected
   environment variables `AZURE_SUBSCRIPTION_ID`, `AZURE_TENANT_ID`,
   `AZURE_CLIENT_ID`, `AZURE_EXERCISE_RESOURCE_GROUP`, and
   `AZURE_EXERCISE_LOCATION` to the real values. Set the location to its
   canonical Azure slug (for example, `uksouth`), not a display name such as
   `UK South`; do not commit IDs or use a client secret.
3. Assign only `Reader` and `Storage Account Contributor` to the federated
   identity, scoped to that dedicated resource group. Do not grant subscription
   `Contributor`, `Owner`, policy-management, or role-assignment permissions.
   Pre-register the `Microsoft.Storage` resource provider in the subscription
   using the owner's normal administrative process. The workflow sets
   `ARM_SKIP_PROVIDER_REGISTRATION=true` and the identity has no provider
   registration rights. Terraform and the Azure CLI use Azure Resource Manager
   management-plane operations only; the workflow does not read or write blobs
   or containers and does not need storage data-plane roles.
4. Configure the protected environment with at least one required human
   reviewer, disallow self-review, and limit who can approve. Require protection
   on the default branch and keep the enable variable false until all
   prerequisites and the estimate have been reviewed.
5. Confirm that £25 is an acceptable Azure spend target for one exercise. Only
   an authorized owner should enable the repository variable and dispatch the
   run.

The exact identities, subscription, resource group, region, environment
protection, and role assignments are intentionally left for the owner to
provide and verify. Do not substitute placeholder IDs.

## Cost estimate and verification

**Planning estimate/approval budget: £25 per exercise** for Azure charges, for
one empty Standard LRS storage account in the owner-selected region, no uploaded
data, and a run lasting at most 40 minutes. No live retail-price quote for this
exact short-lived, empty-resource scenario was verified while implementing this
change, so £25 is an approval envelope rather than a predicted bill. Storage
capacity, transactions, region, taxes, delayed metering, orphaned resources, and
GitHub-hosted runner billing can change the actual bill. The owner must approve
the £25 target before enabling the workflow and confirm it in the dispatch
inputs before each run.

Budget alerts are notifications, **not a hard cap**: they do not stop
deployment or prevent additional charges. This workflow does not create or
change budget alerts.

The workflow times Terraform operations, limits the job to 40 minutes, checks
the created account's region, SKU, TLS, public-access/shared-key settings and
run tag, runs `terraform destroy` even after an apply/check failure, and queries
the dedicated resource group for resources tagged with the run ID. A failed
destroy or residual check fails the run and requires immediate owner cleanup.
If the job is cancelled or the hosted runner is terminated before teardown, the
Terraform state on the ephemeral runner may be unavailable; the owner must
inspect the dedicated resource group and remove any `exercise_id=BG-014`
resources, then verify it is empty before another exercise.

The residual check inspects **all** resources in the dedicated exercise group,
not only the current run or attempt, so an orphan from an earlier rerun blocks
success as well. A failed teardown or residual check requires immediate owner
cleanup. After each run, the owner must independently inspect the dedicated
resource group for any remaining resources and review Azure Cost Management
after metering has had time to settle (typically 24-48 hours). Record the actual
amount against the £25 target before authorizing another exercise. This
post-run owner review is required even when the workflow reports successful
teardown and an empty resource group.

## Pull-request checks

Pull requests run the ordinary Terraform validation only. They do not invoke
this workflow, request an OIDC token, access Azure, or apply changes. The
Terraform code and safeguards are statically checked in hosted CI; this
repository change does not perform a live deployment or claim live Azure
verification.
