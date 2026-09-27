#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$(mktemp)"
trap 'rm -f "${OUTPUT_FILE}"' EXIT

run_expected_failure() {
  local fixture_dir="$1"
  local expected_error="$2"

  cd "${fixture_dir}"
  terraform init -backend=false -input=false -no-color > /dev/null

  set +e
  terraform validate -no-color >"${OUTPUT_FILE}" 2>&1
  local status=$?
  set -e

  if [[ ${status} -eq 0 ]]; then
    echo "Expected terraform validate to fail for fixture: ${fixture_dir}"
    cat "${OUTPUT_FILE}"
    exit 1
  fi

  if ! grep -q "${expected_error}" "${OUTPUT_FILE}"; then
    echo "Terraform failed for fixture ${fixture_dir}, but not for the expected rule."
    cat "${OUTPUT_FILE}"
    exit 1
  fi
}

run_expected_failure "${SCRIPT_DIR}/non_compliant_exemption" "required_tags must include both 'owner' and 'costCenter'"
run_expected_failure "${SCRIPT_DIR}/non_compliant_exemption_timestamp" "Each policy exemption must include a valid RFC3339 expires_on value"

echo "Negative validation succeeded: non-compliant governance fixtures were rejected."
