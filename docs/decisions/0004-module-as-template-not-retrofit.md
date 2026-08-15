# ADR 0004: Reusable module built as a template, not retrofitted into existing stages

## Status
Accepted

## Context
Project-creation logic (labels, API enablement, audit logging) is duplicated across three existing stages (00-bootstrap, 03-networking, 04-project-factory). A modules/gcp-project module was built to demonstrate the DRY pattern.

## Decision
The module exists as a reference pattern for future stages. Existing stages were deliberately left as-is rather than refactored to call the module.

## Consequences
- Some duplication remains in the current codebase.
- Avoided the real risk of refactoring live, billed infrastructure: adopting a module changes every affected resource's Terraform state address, requiring careful `terraform state mv` operations against a working environment with a live Cloud Run service depending on it, for no functional gain.
- Demonstrates the pattern is understood without destabilizing working infrastructure purely for code aesthetics.
