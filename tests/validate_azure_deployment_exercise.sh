#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW="${ROOT_DIR}/.github/workflows/azure-deployment-exercise.yml"
PR_WORKFLOW="${ROOT_DIR}/.github/workflows/terraform.yml"
TERRAFORM="${ROOT_DIR}/exercises/azure-deployment/main.tf"

require_text() {
  local file="$1"
  local text="$2"

  if ! grep -Fq -- "${text}" "${file}"; then
    echo "Missing required exercise safeguard in ${file}: ${text}" >&2
    exit 1
  fi
}

require_text "${WORKFLOW}" "workflow_dispatch:"
require_text "${WORKFLOW}" "default: false"
require_text "${WORKFLOW}" "github.ref_protected"
require_text "${WORKFLOW}" "vars.AZURE_EXERCISE_ENABLED == 'true'"
require_text "${WORKFLOW}" "environment:"
require_text "${WORKFLOW}" "name: azure-deployment-exercise"
require_text "${WORKFLOW}" "id-token: write"
require_text "${WORKFLOW}" "timeout-minutes: 40"
require_text "${WORKFLOW}" "Generate globally unique storage account name"
require_text "${WORKFLOW}" 'GITHUB_REPOSITORY_ID}-${GITHUB_RUN_ID}'
require_text "${WORKFLOW}" 'sha256sum | cut -c1-22'
require_text "${WORKFLOW}" '^bg[a-f0-9]{22}$'
require_text "${WORKFLOW}" "always()"
require_text "${WORKFLOW}" "destroy -input=false -lock=false -auto-approve"
require_text "${WORKFLOW}" "if: \${{ always() && steps.azure-login.outcome == 'success' }}"
require_text "${WORKFLOW}" "az resource list"
require_text "${WORKFLOW}" "minTlsVersion == \"TLS1_2\""
require_text "${WORKFLOW}" "allowBlobPublicAccess == false"
require_text "${WORKFLOW}" "allowSharedKeyAccess == false"
require_text "${WORKFLOW}" "exerciseRunId == \$run_id"
require_text "${WORKFLOW}" "ARM_USE_OIDC: true"
require_text "${WORKFLOW}" "ARM_SKIP_PROVIDER_REGISTRATION: true"
require_text "${WORKFLOW}" 'subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}'
require_text "${WORKFLOW}" "allow-no-subscriptions: true"
require_text "${WORKFLOW}" '--subscription "${AZURE_SUBSCRIPTION_ID}"'
require_text "${WORKFLOW}" 'AZURE_LOCATION}" =~ ^[a-z0-9]+$'
require_text "${WORKFLOW}" '.location == $location'
require_text "${WORKFLOW}" '.sku == "Standard_LRS"'
require_text "${WORKFLOW}" '.httpsOnly == true'
require_text "${WORKFLOW}" '.minTlsVersion == "TLS1_2"'
require_text "${WORKFLOW}" '.allowBlobPublicAccess == false'
require_text "${WORKFLOW}" '.allowSharedKeyAccess == false'
require_text "${WORKFLOW}" '.exerciseRunId == $run_id'
require_text "${WORKFLOW}" '--query "[].id"'
require_text "${WORKFLOW}" 'if [[ -n "${remaining}" ]]'
require_text "${WORKFLOW}" 'exit 1'
require_text "${PR_WORKFLOW}" "pull_request:"

if grep -Eq '^[[:space:]]+pull_request:|AZURE_CLIENT_SECRET|ARM_CLIENT_SECRET' "${WORKFLOW}"; then
  echo "The exercise workflow must not run on pull requests or use client secrets." >&2
  exit 1
fi

if grep -Fq "terraform apply" "${PR_WORKFLOW}"; then
  echo "Pull-request validation must never apply Terraform changes." >&2
  exit 1
fi

if grep -Fq '[?tags.exercise_run_id' "${WORKFLOW}"; then
  echo "Residual verification must cover the dedicated resource group, including prior run attempts." >&2
  exit 1
fi

if grep -B 2 -F "id: residual-check" "${WORKFLOW}" | grep -Fq "steps.terraform-init.outcome"; then
  echo "Residual verification must run after Azure login even if Terraform initialization fails." >&2
  exit 1
fi

if grep -Eq 'az storage (blob|container|file|queue|table)|resource "azurerm_storage_(blob|container|file|queue|table|share|data_lake_gen2)' "${WORKFLOW}" "${TERRAFORM}"; then
  echo "The exercise must not call storage data-plane APIs or create data-plane resources." >&2
  exit 1
fi

require_text "${TERRAFORM}" 'account_replication_type        = "LRS"'
require_text "${TERRAFORM}" "https_traffic_only_enabled      = true"
require_text "${TERRAFORM}" "allow_nested_items_to_be_public = false"
require_text "${TERRAFORM}" 'min_tls_version                 = "TLS1_2"'
require_text "${TERRAFORM}" 'exercise_run_id = "${var.run_id}-${var.run_attempt}"'
require_text "${ROOT_DIR}/docs/azure-deployment-exercise.md" 'Pre-register the `Microsoft.Storage` resource provider'

if grep -Eq 'resource "azurerm_resource_group"|resource "azurerm_subscription_' "${TERRAFORM}"; then
  echo "The exercise must not create resource groups or subscription-scoped resources." >&2
  exit 1
fi

echo "Approved Azure deployment exercise safeguards are present."
