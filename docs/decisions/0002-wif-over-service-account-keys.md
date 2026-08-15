# ADR 0002: Workload Identity Federation for CI/CD authentication

## Status
Accepted

## Context
GitHub Actions needs to authenticate to GCP to run Terraform. The traditional approach is a downloaded service account JSON key stored as a GitHub secret.

## Decision
Use Workload Identity Federation instead: a WIF pool and provider scoped to this exact GitHub repository, letting Actions runners obtain short-lived tokens by presenting a signed GitHub OIDC token, with zero long-lived credentials ever created or stored.

## Consequences
- No key rotation, no risk of a leaked key file, no key stored in GitHub secrets at all.
- Slightly more setup complexity upfront (pool, provider, attribute condition, IAM binding) compared to just pasting a key into a secret.
- The `iam.disableServiceAccountKeyCreation` org policy (ADR 0003) makes key-based auth impossible org-wide anyway, so this was the only viable path once that guardrail existed.
