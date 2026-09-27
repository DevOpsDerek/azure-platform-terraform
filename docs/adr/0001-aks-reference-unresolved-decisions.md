# ADR 0001: AKS reference unresolved design decisions

## Status
Proposed

## Context
This repository intentionally ships a minimal AKS reference baseline. Several production-shaping choices remain open and require environment-owner approval.

## Unresolved decisions

1. **AKS exposure model**: public API server vs. private cluster.
2. **CNI strategy**: Azure CNI Overlay vs. Azure CNI Pod Subnet for scale/IP management.
3. **Identity model**: managed identity with workload identity federation scope and boundary.
4. **Policy baseline**: mandatory Azure Policy set assignments and enforcement mode at platform landing zone scope.
5. **State topology**: single shared state per environment vs. split state domains by concern (network, cluster, policy).

## Consequences
- Current baseline optimizes for clarity and validation, not production hardening.
- A follow-up ADR per decision is required before live deployment.
