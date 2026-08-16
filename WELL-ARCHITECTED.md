# 🧭 Well-Architected Framework Alignment

This landing zone is designed against Google Cloud's Architecture Framework. Every claim below maps to a specific stage, file, or verified piece of evidence — not just a checklist item.

---

## 📊 Summary

| Pillar | Status | Confidence |
|---|---|---|
| 🔐 Security, Privacy & Compliance | Implemented | High — verified via 2 independent scanners, live-tested |
| 💰 Cost Optimization | Implemented | High — real predicted *and* real actual cost, both proven |
| ⚡ Performance Optimization | Partially addressed | Medium — foundation laid, full tuning deferred by design |
| 🛠️ Reliability | Implemented | High — daily automated drift detection confirms it |
| 🚀 Operational Excellence | Implemented | High — full IaC, gated CI/CD, tested |

---

## 🔐 Security, Privacy & Compliance

| Practice | Implementation | Where |
|---|---|---|
| Org-wide policy guardrails | 6 policies: no default networks, no public VM IPs, no downloadable SA keys, no public buckets/SQL, domain-restricted IAM, no public Cloud SQL | `01-org-policies` |
| Group-based IAM | Every admin role bound to a Google Group, zero individual-user bindings | `02-resman` |
| Zero long-lived credentials | Workload Identity Federation for all CI/CD auth | `00-bootstrap` |
| Static analysis (dual scanner) | Checkov (78 passed, 5 accepted findings) + Terrascan (191 policies, 0 violations) | pre-commit + CI |
| Least-privilege IAM | Custom `gchDevopsScoped` role replacing broad `roles/editor`, driven directly by a Checkov finding | `02-resman`, `05-security` |
| Centralized audit logging | Org-wide log sink into a dedicated logging bucket; Admin Read/Data Read/Data Write explicitly enabled on every project | `05-security` |
| Secrets management | Secret Manager container-only pattern — no secret values ever in state or `.tfvars` | `05-security` |
| Runtime security posture | Security Command Center, Standard tier, enabled at org level | `00-bootstrap` |
| Network perimeter | VPC Service Controls, real perimeter in dry-run mode (see dedicated section below) | `08-vpc-sc` |

**Proven, not just configured**: the `iam.allowedPolicyMemberDomains` org policy automatically blocked a real attempt to grant `allUsers` public access to a Cloud Run service during `06-workload-demo`'s deployment — the guardrail working exactly as designed, caught live, not in a review.

---

## 💰 Cost Optimization

| Practice | Implementation | Where |
|---|---|---|
| Budget alerting | Billing budget alert at 50/90/100% thresholds | `00-bootstrap` |
| Spend attribution | `department`, `environment`, `cost-center`, `managed-by` labels on every project | `04-project-factory` |
| Quota-aware provisioning | Explicit `enabled_workloads` list instead of a full department × environment cross-product — built *after* hitting a real free-tier billing-account project-link quota wall | `04-project-factory` |
| Predicted cost (pre-deploy) | Infracost — PR comments, dashboard, live-updating badge | `terraform-plan.yml`, `terraform-apply.yml` |
| Actual cost (post-deploy) | Native Google Cloud billing export to BigQuery, real detailed-usage-cost data | `07-cost-visibility` |
| FinOps tagging compliance | `service` / `stage` labels added specifically to satisfy Infracost's own governance policy checks | `04-project-factory` |

**Proven, not just configured**: the predicted-cost badge shows a real, non-zero dollar figure ($7.82/month) because a priced e2-micro VM was deliberately added in `06-workload-demo` — correctly priced for `asia-south1`, which sits outside GCP's Always-Free region list. This wasn't left as a theoretical $0 project; the whole cost pipeline was proven against something real. The actual-spend side (BigQuery billing export) was independently re-verified against the live schema after an initial assumption about the table name and label structure turned out to be wrong — corrected, not left stale.

---

## ⚡ Performance Optimization

| Practice | Implementation | Where |
|---|---|---|
| Region selection | `asia-south1`, chosen for proximity to primary users | All stages |
| Extensible network topology | Shared VPC architecture leaves room for regional expansion without re-architecting | `03-networking` |
| Deferred workload-level tuning | Autoscaling, caching, and instance sizing are intentionally left to the workload layer — these depend entirely on what gets deployed, and tuning them in advance of a real workload would be guesswork | N/A by design |

This is the one pillar addressed at the *foundation* level only — performance optimization is fundamentally a workload-layer concern, and the landing zone's job here is to not get in the way, not to pre-solve a problem that doesn't exist yet.

---

## 🛠️ Reliability

| Practice | Implementation | Where |
|---|---|---|
| Full IaC, zero manual changes | Every resource in every stage is Terraform-managed; no console-driven configuration | All stages |
| Inherently HA managed components | Cloud NAT, Shared VPC — GCP-managed, no single point of failure introduced by this design | `03-networking` |
| Daily drift verification | Scheduled `drift-detection.yml` runs a read-only plan across all 9 stages every day, auto-filing a GitHub issue on any mismatch | `.github/workflows/drift-detection.yml` |
| Isolated blast radius per stage | Each stage has its own Terraform state (same GCS bucket, different prefix) — a mistake in one stage's state can't corrupt another's | All stages |
| Backup/DR | Deliberately deferred to the workload layer — a generic landing zone shouldn't presume backup requirements for data that doesn't exist yet | N/A by design |

**Proven, not just configured**: drift detection has been run manually multiple times throughout this project's build, including immediately after Dependabot dependency bumps — every run has returned clean across all 9 stages.

---

## 🚀 Operational Excellence

| Practice | Implementation | Where |
|---|---|---|
| Full IaC | 9 sequential Terraform stages, no exceptions | `00` through `08` |
| Gated, automated deployment | GitHub Actions apply chain, held behind manual approval on the `prod` environment | `terraform-apply.yml` |
| Native testing | `terraform test` assertions for `01-org-policies` and `02-resman`, run on every PR | `terraform-plan.yml` |
| Documentation as a first-class artifact | Auto-generated variable/output tables (terraform-docs) per stage, 4 formal Architecture Decision Records, this document | `docs/decisions/`, per-stage `README.md` |
| Dependency currency | Dependabot tracking both Terraform providers and GitHub Actions versions | `.github/dependabot.yml` |
| Reproducibility | `.tfvars.example` provided for every stage, so the project can genuinely be rebuilt by someone else | Every stage folder |
| Reusable patterns without destabilizing production | A `modules/gcp-project` module was extracted once duplication became clear, but deliberately **not** retrofitted into existing, working stages — avoiding real state-migration risk for zero functional gain | `modules/gcp-project`, [ADR 0004](docs/decisions/0004-module-as-template-not-retrofit.md) |

---

## 🌐 Multi-Region Readiness (Not Implemented — Documented Extension Path)

Current state: single region (`asia-south1`), a deliberate choice for cost control on a free-tier account.

To extend to multi-region:
- `03-networking` would need a second regional subnet pair (Prod/NonProd) in the new region, added to the existing Shared VPC — VPCs are global, subnets are regional, so this doesn't require rebuilding the VPC itself
- Cloud NAT and Cloud Router would need per-region instances
- `01-org-policies` and `02-resman` (folder hierarchy, IAM) remain **unchanged** — both are region-agnostic by nature
- `04-project-factory` workload projects would attach to whichever regional subnet best fits their latency needs, without changing the factory pattern itself

---

## 🚧 VPC Service Controls (Implemented — Dry-Run Mode)

`08-vpc-sc` creates a real Access Context Manager policy and service perimeter around every workload and networking project, restricting `storage.googleapis.com`, `bigquery.googleapis.com`, and `secretmanager.googleapis.com`.

**Why dry-run, not enforced**: `06-workload-demo`'s Cloud Run service and VM were already live when this stage was added. `use_explicit_dry_run_spec = true` means violations are logged in Cloud Logging without actually blocking traffic — the correct, safe rollout pattern for adding a perimeter around infrastructure that's already serving real traffic, rather than risking an outage from a misconfigured rule.

**Path to enforcement**: review dry-run violation logs for false positives over an observation period (1-2 weeks is typical in production), adjust the resource/service list based on findings, then flip `use_explicit_dry_run_spec = false` and move the `spec` block's contents into `status`. This is a one-line config change once the dry-run period confirms no unexpected blocks — the hard design work is already done, only the activation step remains.

---

## 🧪 What's Genuinely Proven vs. What's Configured

A landing zone can look complete on paper without ever being tested against reality. Here's what was actually verified, not just written:

| Claim | How It Was Verified |
|---|---|
| Org policies work | Live-blocked a real `allUsers` grant attempt during deployment |
| Drift detection works | Run manually multiple times, confirmed clean across all 9 stages, including after dependency updates |
| Cost badges are real | Both survived a `dynamic-badges-action` version bump without breaking |
| CI/CD auth is genuinely keyless | The automation SA's actual permission gaps were discovered *by CI itself failing*, not by manual review — proving no human credentials were silently covering for it |
| Billing export configuration is correct | Independently re-checked against the real BigQuery `INFORMATION_SCHEMA`, not assumed — an initial query was found wrong and corrected |
| Security scanning findings are current | Re-run after every major stage addition (including Stage 08), confirmed no drift between documented and actual pass/fail counts |
