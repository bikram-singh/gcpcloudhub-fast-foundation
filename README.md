# gcpcloudhub-fast-foundation
GCP organization bootstrap and landing zone, inspired by Google Cloud's Fabric FAST design, written from scratch in Terraform

## Security Scanning

This project is scanned with [Checkov](https://www.checkov.io/) for IaC misconfigurations.

**Current state**: 46 passed, 15 accepted findings.

**Fixed**: default networks removed, open SSH/RDP firewall rules deleted, VPC Flow Logs enabled, Private Google Access enabled, bucket public access prevention enforced.

**Accepted trade-offs** (documented, not fixed): broad `roles/editor` and `roles/iam.securityAdmin` bindings are intentional for a demo landing zone; production would use least-privilege custom roles.

**Deferred to a future `04-security` stage**: centralized audit logging and bucket access logging.
