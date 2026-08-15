# gcpcloudhub-fast-foundation
GCP organization bootstrap and landing zone, inspired by Google Cloud's Fabric FAST design, written from scratch in Terraform

## Security Scanning

This project is scanned with [Checkov](https://www.checkov.io/) for IaC misconfigurations.

**Current state**: 67 passed, 3 accepted findings (down from 22 initial findings).

**Fixed over the project's lifecycle**:
- Default networks removed, open SSH/RDP firewall rules deleted
- VPC Flow Logs and Private Google Access enabled on all subnets
- Bucket public access prevention enforced
- `roles/editor` on devops folder IAM replaced with a least-privilege custom role (`gchDevopsScoped`) covering only compute, GKE, and Cloud Run permissions actually needed
- Full audit logging (Admin Read, Data Read, Data Write) enabled explicitly on every project
- Centralized org-wide audit log sink with a dedicated logging bucket (05-security)

**Accepted, documented exceptions** (3 remaining findings):
- `roles/iam.securityAdmin` at org level for the security admins group — intentional; security teams need org-wide visibility, unlike devops which had no justification for broad Editor access
- State bucket access logging — would require a second logging bucket to log access to the first; skipped as disproportionate for this project's scale
- GitHub OIDC trust condition could add a `repository_owner` check alongside the existing repository-scoped condition — minor hardening, not a functional gap since the repo-level restriction already prevents unauthorized impersonation

## Architecture

![Landing zone architecture](docs/architecture.svg)


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

## Lessons learned

- Free-tier Cloud Billing accounts can only be linked to a limited number of projects simultaneously (observed limit: 5). The project factory uses an explicit `enabled_workloads` list rather than a full department x environment cross-product, so it stays within quota while keeping the underlying pattern factory-shaped and easy to extend.
- Shared VPC requires the host project to be explicitly designated via `google_compute_shared_vpc_host_project`, separate from creating the VPC and subnets themselves.
- API-quota-project routing (`user_project_override`) means every API a stage calls, including permission pre-checks like Cloud Billing's, must be enabled on the quota project itself.

### Terrascan results

Scanned with Terrascan v1.19.9: 191 policies evaluated, 0 violations (High/Medium/Low all zero). Terrascan and Checkov use different rule engines (OPA/Rego vs Bridgecrew) with different policy coverage, so results aren't directly comparable — running both provides complementary signal rather than a second opinion on the same checks. See security-scans/ for dated scan snapshots.

## CI/CD

- `.github/workflows/terraform-plan.yml` — runs `terraform plan` across all 6 stages on every pull request, authenticated via Workload Identity Federation (no service account keys).
- `.github/workflows/terraform-apply.yml` — runs `terraform apply` in strict dependency order (bootstrap → org-policies → resman → networking → project-factory → security) on merge to main, gated behind a `prod` GitHub Environment requiring manual approval before each stage applies.
- Stage variables and secrets are injected from GitHub Actions repo variables/secrets at runtime rather than committed `.tfvars` files, which remain gitignored and local-only.

### Lessons learned from wiring up CI

The automation service account had org-level admin roles (from Stage 0) but had never been granted ownership on the individual projects it needed to manage, since all prior applies ran under a human user's credentials in Cloud Shell. Moving to CI surfaced these gaps immediately: the SA needed explicit Owner on each project (seed, networking host, workload projects) and explicit org-level `logging.admin` and `iam.organizationRoleAdmin` roles to match what the human operator had accumulated ad hoc. This is a good illustration of why CI/CD matters even for a solo project — it forces the automation identity's actual permissions to be complete and explicit, rather than silently depending on a human's broader access.

## Secret Manager pattern

A Secret Manager container (`gch-example-db-credential`) demonstrates the intended pattern for workload credentials: the secret container is Terraform-managed, but no secret value is ever stored in Terraform state, `.tfvars`, or committed code. Values are set out-of-band (via `gcloud secrets versions add` or the Console) by whoever operates the workload that needs it. Access is scoped to the `gcp-devops` group via `secretAccessor`, not project-wide or org-wide.

## Org policy in action

While deploying the Stage 6 demo workload, `iam.allowedPolicyMemberDomains` (Stage 1) automatically blocked an attempt to grant `allUsers` access to a Cloud Run service, since `allUsers` isn't a principal from the `gcpcloudhub.in` domain. This is the guardrail working as intended — access was scoped to `domain:gcpcloudhub.in` instead. A concrete example of an org-wide policy preventing an accidental public-exposure misconfiguration before it happened.
