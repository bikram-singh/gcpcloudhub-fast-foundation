# gcpcloudhub-fast-foundation

<div align="center">

![monthly cost](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bikram-singh/5e15a2c50f65a4436ed0b99c1e673ae7/raw/gcpcloudhub-cost-badge.json&style=for-the-badge)
![license](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)
![checkov](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bikram-singh/5e15a2c50f65a4436ed0b99c1e673ae7/raw/gcpcloudhub-checkov-badge.json&style=for-the-badge)

</div>

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

## Reusable module (template, not yet adopted)

`modules/gcp-project` extracts the common pattern used across 00-bootstrap, 03-networking, and 04-project-factory: project creation, standard labels, API enablement, and full audit logging. It exists as a reference for future stages rather than a retrofit of existing ones — refactoring live, working infrastructure to adopt a module means new Terraform state addresses for every resource, which carries real risk (destroy-and-recreate without careful `terraform state mv`) against no functional benefit. The module demonstrates the DRY pattern; existing stages remain as-is since they work correctly and touching them wouldn't improve anything users or the org actually experience.

## Known limitation: Infracost on Dependabot PRs

GitHub restricts repository secrets from workflows triggered by Dependabot PRs as a security measure, so the Infracost cost-estimation job fails on Dependabot's own PRs (missing `INFRACOST_API_KEY`). This is expected and does not affect PRs opened by a human, where the secret is available normally.

## Known limitation: Billing export activation is manual

Terraform can create the BigQuery dataset for billing export (07-cost-visibility), but Google's Cloud Billing API does not expose a Terraform resource for actually linking billing export to that dataset. This is a one-time Console step (Billing > Billing export > Enable detailed export), not automatable via IaC as of this provider version.

## Using the billing export

Verified table: `gch_billing_export.gcp_billing_export_resource_v1_012E9C_0D5AF1_5575CE` (name includes billing account ID, confirmed via `INFORMATION_SCHEMA.TABLES`). As of this writing, the table exists with the correct schema but has 0 rows - Google's daily export batch had not yet completed its first run. Query actual spend by department/environment once data lands using `07-cost-visibility/queries/cost-by-department.sql`, which groups cost by the `department` label nested in `project.labels` (confirmed against the real schema, not assumed).

Run it directly in the BigQuery Console, or via the `bq query` CLI:

```
bq query --use_legacy_sql=false < 07-cost-visibility/queries/cost-by-department.sql
```

## Documentation generation

Each stage's README.md includes an auto-generated variable/output/resource table via terraform-docs, wired into pre-commit. The initial attempt used a Go-compile-based hook which failed on Cloud Shell's toolchain; switched to the prebuilt-binary hook from the same pre-commit-terraform repo already used for fmt/validate/checkov, which resolved it without requiring any compilation.

## Testing

Native Terraform tests (`terraform test`, requires Terraform 1.6+) validate key assertions for `01-org-policies` (policy configuration correctness) and `02-resman` (folder structure counts). Tests run automatically on every pull request via the plan workflow. Coverage is intentionally partial — a fuller test suite covering every stage is a natural next step, consciously scoped down here in favor of breadth across the rest of the landing zone (security, cost visibility, CI/CD) within reasonable project scope.

## Teardown

To tear down completely, destroy in reverse dependency order:

cd 08-vpc-sc && terraform destroy
cd ../07-cost-visibility && terraform destroy
cd ../06-workload-demo && terraform destroy
cd ../05-security && terraform destroy
cd ../04-project-factory && terraform destroy
cd ../03-networking && terraform destroy
cd ../02-resman && terraform destroy
cd ../01-org-policies && terraform destroy
cd ../00-bootstrap && terraform destroy

Notes:
- 00-bootstrap's seed project has deletion_policy = "PREVENT" on the google_project resource, requiring it be changed to "DELETE" or deleted manually via gcloud before terraform destroy fully removes it.
- The GCS state bucket is destroyed as part of 00-bootstrap's teardown, so run this stage last and expect to lose remote state history.
- Org policies revert to Google defaults once destroyed; no manual cleanup needed.
- The custom IAM role (gchDevopsScoped) enters a soft-delete state for approximately 7 days after destroy, per GCP's default retention for custom roles.
- The VPC-SC access policy (08-vpc-sc) must be destroyed before 03-networking, since the perimeter references networking project numbers.
