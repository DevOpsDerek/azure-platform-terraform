#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$(mktemp)"
trap 'rm -f "${OUTPUT_FILE}"' EXIT

FIXTURE_DIR="${SCRIPT_DIR}/non_compliant_exemption"

cd "${FIXTURE_DIR}"

terraform init -backend=false -input=false -no-color > /dev/null

set +e
terraform validate -no-color >"${OUTPUT_FILE}" 2>&1
status=$?
set -e

if [[ ${status} -eq 0 ]]; then
  echo "Expected terraform validate to fail for non-compliant required-tags input."
  cat "${OUTPUT_FILE}"
  exit 1
fi

if ! grep -q "required_tags must include both 'owner' and 'costCenter'" "${OUTPUT_FILE}"; then
  echo "Terraform failed, but not for the expected required-tags baseline validation rule."
  cat "${OUTPUT_FILE}"
  exit 1
fi

echo "Negative validation succeeded: non-compliant required-tags baseline was rejected."
