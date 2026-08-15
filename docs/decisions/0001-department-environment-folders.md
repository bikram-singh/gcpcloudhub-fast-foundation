# ADR 0001: Department + environment folder hierarchy

## Status
Accepted

## Context
The standard FAST reference architecture uses a flat environment-only folder structure (Prod, NonProd, Sandbox) directly under the organization. This project instead needed to model a multi-department org where different teams (HR, Finance, IT, Sales, AI) require separate IAM boundaries and budget visibility.

## Decision
Each department gets its own top-level folder, with Prod and NonProd sub-folders nested inside. This gives: org -> department -> environment -> project, rather than org -> environment -> project.

## Consequences
- IAM and org policies can be scoped per department if needed, not just per environment.
- Folder count roughly doubles compared to the flat model (5 departments x 2 environments = 10 folders vs 2-3 flat folders), adding some complexity to the Terraform for_each logic.
- Matches how larger real-world organizations actually segment budget and access, at the cost of being less directly copy-paste compatible with FAST's own stage READMEs.
