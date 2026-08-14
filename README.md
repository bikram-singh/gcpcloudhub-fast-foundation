# gcpcloudhub-fast-foundation
GCP organization bootstrap and landing zone, inspired by Google Cloud's Fabric FAST design, written from scratch in Terraform

## Security Scanning

This project is scanned with [Checkov](https://www.checkov.io/) for IaC misconfigurations.

**Current state**: 46 passed, 15 accepted findings.

**Fixed**: default networks removed, open SSH/RDP firewall rules deleted, VPC Flow Logs enabled, Private Google Access enabled, bucket public access prevention enforced.

**Accepted trade-offs** (documented, not fixed): broad `roles/editor` and `roles/iam.securityAdmin` bindings are intentional for a demo landing zone; production would use least-privilege custom roles.

**Deferred to a future `04-security` stage**: centralized audit logging and bucket access logging.

## Architecture

A hand-built GCP Organization landing zone, inspired by Google's Fabric FAST framework, using department + environment folder segmentation instead of a flat environment-only hierarchy.

## Architecture

A hand-built GCP Organization landing zone, inspired by Google's Fabric FAST framework, using department + environment folder segmentation instead of a flat environment-only hierarchy.

gcpcloudhub.in (Organization)
- 00-bootstrap: seed automation project, GCS state bucket, automation SA, Workload Identity Federation for GitHub Actions
- 01-org-policies: org-wide guardrails - no default networks, no VM public IPs, no SA keys, no public buckets/SQL, domain-restricted IAM
- 02-resman: department folders (HR, Finance, IT, Sales, AI) each with Prod/NonProd sub-folders, org and folder IAM bound to Google Groups
- 03-networking: shared VPC host project under IT/Prod, Prod and NonProd subnets, Cloud NAT, IAP-only SSH firewall, flow logs and private Google access enabled

## Design decisions

- Groups over individual users for IAM: every admin role is bound to a Google Group, not an individual account, matching real enterprise practice.
- WIF over service account keys: GitHub Actions authenticates via Workload Identity Federation scoped to this exact repo. No long-lived JSON keys exist anywhere in this project.
- Org policies before resource hierarchy: guardrails are applied in stage 01, before folders (02) and networking (03), so nothing gets created without constraints already active.
- Department plus environment folders: chosen over a flat Prod/NonProd-only structure to reflect how larger orgs segment budget and access boundaries.
- Remote state per stage: each stage has isolated Terraform state in the same GCS bucket under a different prefix.

## Prerequisites to reproduce

- A GCP Organization via Cloud Identity Free or Google Workspace
- A billing account linked to that org
- Four Google Groups created in advance: gcp-organization-admins, gcp-billing-admins, gcp-security-admins, gcp-devops
- Terraform >= 1.5, gcloud CLI authenticated with Organization Administrator access

## Stage execution order

cd 00-bootstrap && terraform init && terraform apply
cd ../01-org-policies && terraform init && terraform apply
cd ../02-resman && terraform init && terraform apply
cd ../03-networking && terraform init && terraform apply

## Roadmap

- 04-project-factory: workload projects per department, attached to shared VPC
- 05-security: centralized audit logging, bucket access logging
- CI/CD via GitHub Actions using the WIF setup from Stage 0
