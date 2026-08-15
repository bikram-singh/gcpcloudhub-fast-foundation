# ADR 0003: Org policies as an early, dedicated stage

## Status
Accepted

## Context
Org-wide policy constraints (no default networks, no VM public IPs, no SA keys, no public buckets, domain-restricted IAM) could have been folded into the resource management (resman) stage, or applied ad hoc per-project.

## Decision
Org policies get their own stage (01-org-policies), applied immediately after bootstrap and before folder/project creation (02-resman onward).

## Consequences
- Guardrails are active before any folder or project exists, rather than retrofitted afterward.
- Requires its own Terraform state and its own permission grants (orgpolicy.policyAdmin), adding one more moving part to the bootstrap sequence.
- Directly caught a real misconfiguration during Stage 6 (an attempt to grant allUsers public access to a Cloud Run service was blocked automatically), validating the sequencing decision.
