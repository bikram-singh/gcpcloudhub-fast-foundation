# Well-Architected Framework Alignment

This landing zone is designed against Google Cloud's Architecture Framework. Below is an honest mapping of what applies at the landing-zone layer versus what is a workload-level concern.

## Security, Privacy & Compliance
- Org-wide policy guardrails (01-org-policies): no default networks, no public VM IPs, no downloadable SA keys, no public buckets/SQL, domain-restricted IAM
- Group-based IAM throughout, zero individual-user bindings for admin roles
- Workload Identity Federation for CI/CD - zero long-lived credentials
- Static analysis via Checkov and Terrascan, findings triaged and documented
- Planned: centralized audit log sink, least-privilege custom IAM roles (05-security)

## Cost Optimization
- Billing budget alert at 50/90/100% thresholds
- Resource labels (department, environment, cost-center) for spend attribution
- Explicit enabled_workloads gating in the project factory to respect free-tier billing quotas rather than blindly provisioning

## Performance Optimization
- Region selected for proximity to primary users (asia-south1)
- Shared VPC architecture leaves room for regional expansion without re-architecting
- Full performance tuning (autoscaling, caching, instance sizing) is intentionally deferred to the workload layer, since it depends on what gets deployed

## Reliability
- All infrastructure is code-defined and reproducible; no manual console changes
- GCP-managed networking components (Cloud NAT, Shared VPC) are inherently HA
- Subnets are currently single-region by design, to control free-tier cost
- Backup/DR strategy is a workload-level decision once actual data-bearing resources exist

## Operational Excellence
- Full IaC across every stage, isolated Terraform state per stage in GCS
- Design decisions documented in README.md as they were made, including trade-offs
- Static analysis integrated into the workflow (Checkov + Terrascan)
- Planned: CI/CD pipeline via GitHub Actions using the WIF trust already established in Stage 0

## Multi-region readiness (not implemented, documented for future extension)

Current state: single region (asia-south1) for cost control on a free-tier account. To extend to multi-region:
- 03-networking would need a second regional subnet pair (prod/nonprod) in the new region, added to the existing shared VPC (VPCs are global; subnets are regional)
- Cloud NAT and Cloud Router would need per-region instances
- Org policies (01), folder hierarchy (02), and IAM (02, 05) remain unchanged since they are region-agnostic
- Workload projects (04) would attach to whichever regional subnet fits their latency needs, without changing the project factory pattern itself

## Multi-region readiness (not implemented, documented for future extension)

Current state: single region (asia-south1) for cost control on a free-tier account. To extend to multi-region:
- 03-networking would need a second regional subnet pair (prod/nonprod) in the new region, added to the existing shared VPC (VPCs are global; subnets are regional)
- Cloud NAT and Cloud Router would need per-region instances
- Org policies (01), folder hierarchy (02), and IAM (02, 05) remain unchanged since they are region-agnostic
- Workload projects (04) would attach to whichever regional subnet fits their latency needs, without changing the project factory pattern itself

## VPC Service Controls (implemented, dry-run mode)

08-vpc-sc creates an Access Context Manager policy and a service perimeter around all workload and networking projects, restricting storage.googleapis.com, bigquery.googleapis.com, and secretmanager.googleapis.com. The perimeter runs in dry-run mode (use_explicit_dry_run_spec = true) - violations are logged in Cloud Logging without actually blocking traffic, which was the deliberate choice given live workloads (06-workload-demo) were already running when this stage was added.

To graduate to enforced mode: review dry-run violation logs for false positives over an observation period (commonly 1-2 weeks in production), adjust the resource/service list based on findings, then set use_explicit_dry_run_spec = false and move the spec block's contents into status. This is a one-line config flip once the dry-run period confirms no unexpected blocks.
