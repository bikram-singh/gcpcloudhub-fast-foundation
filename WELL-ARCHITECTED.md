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
