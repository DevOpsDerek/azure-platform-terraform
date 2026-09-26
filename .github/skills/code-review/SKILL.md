---
name: code-review
description: Review pull requests in this repository for Azure Terraform, AKS, and GitHub Actions changes. Use when asked to review a pull request, diff, or branch in this repository.
---

# Code review for Azure Terraform and AKS

Use these instructions when reviewing changes in this repository. Base findings
on the repository's actual files and available review evidence; do not assume
policies, owners, infrastructure, or checks that are not present.

## Understand the intent and context

- Read the linked issue, when one exists, and the pull request title and
  description. Summarize the intended outcome before assessing whether the
  changes deliver it. If an issue is not linked or available, say so rather
  than inventing requirements.
- Read the changed files and relevant surrounding code, configuration, and
  dependencies. Check whether the diff introduces unrelated changes or fails
  to deliver its stated intent.

## Verify evidence for the current change

- Check CI results for the pull request's current head commit. Do not use
  results from older commits as evidence that the current change passes.
- Distinguish verified results from claims in the pull request. Report missing
  evidence as missing or unavailable, never as a passing check.
- For Terraform, inspect available `fmt`, `validate`, static-analysis, and
  plan results. Treat plan output as evidence only when an actual plan or
  trustworthy artifact is available; do not require credentialed Azure plans
  for ordinary pull requests or run a plan that needs cloud credentials.
- Do not claim a check ran if its result cannot be verified.

## Report actionable findings

- Report only high-confidence issues. Anchor each finding to the affected file
  and line, explain the concrete impact, and suggest an actionable correction.
- Prioritize correctness, security, policy, and infrastructure impact. Omit
  speculative concerns and style-only feedback unless requested.
- Keep the review concise. Separate findings from verified evidence and
  unavailable evidence, and state whether human owner approval is required.

## Protect secrets and disclose vulnerabilities safely

- If sensitive material appears in a change, identify its type and location
  without repeating its value. Recommend removal and rotation where
  applicable.
- Do not include credentials, private identifiers, or actionable exploit
  details in public review comments. Describe security issues only to the
  extent needed to explain impact and remediation; use an appropriate private
  reporting path for details that should not be public.

## Require human approval for sensitive changes

- Explicitly require human owner approval for changes affecting policy or
  security controls, or changes that can deploy to or modify production
  infrastructure.
- Never approve a change on your own authority or imply that your review
  replaces required human approval.
- Do not infer ownership or approval rules from paths unless this repository
  documents them.

## Azure Terraform and AKS checks

- Check Terraform formatting and available validation/static-analysis
  evidence. Review provider and module version constraints, backend and remote
  state configuration, and whether state or infrastructure details are
  improperly hardcoded or exposed.
- Check that authentication avoids committed credentials, favors OIDC or
  federated identity where applicable, and uses least-privilege Azure roles.
  Flag broad role assignments, exposed secrets, and unsafe trust boundaries.
- Review AKS networking and exposure, including public endpoints, network
  policy, ingress, and access paths. Check Kubernetes and Azure RBAC for
  excessive permissions and unintended privilege escalation.
- Examine available plan evidence for replacements, destroys, data loss, and
  unexpected scope. Consider cost, availability, and recovery implications;
  explain material destroy or cost impacts rather than assuming they are
  acceptable.
- Ensure pull-request or push workflows do not automatically apply Terraform
  or deploy to Azure. Any deployment path must not expose cloud credentials
  and must have appropriate human approval and safeguards.

## GitHub Actions checks

- Check workflow and job `permissions` for least privilege. Require
  justification for write permissions and prefer read-only access by default.
- Check third-party actions are pinned to full commit SHAs. Review untrusted
  pull-request inputs, checkout behavior, and secret exposure to forks and
  logs.
- Verify new or changed checks against actual workflow configuration and
  current-head run results; do not assume a check is required or passing
  without evidence.

## Conclude the review

State the intended outcome, what evidence was verified, what evidence is
missing or unavailable, findings by severity, and whether explicit human owner
approval is required. Recommend approve, request changes, or comment, with a
brief reason; do not recommend approval when a required human approval is
still outstanding.
