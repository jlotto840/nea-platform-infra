# nea-platform-infra

**Fictitious sample repository for the OHIP Standards Agentic POC (Step 14, Code & IaC Reviewer).**
Meridian Health Systems and NorthStar Eligibility Analytics (NEA) are invented. No real data,
accounts, or credentials are in this repository; every ARN, account number, and key-like string is fake.

## What is here

| Path | Contents |
|---|---|
| `terraform/` | NEA platform infrastructure: KMS key, data-lake buckets (raw / curated), Aurora PostgreSQL, CloudWatch logging forwarded to the OHIP SIEM, least-privilege ingest role, Snowflake storage integration and stage |
| `app/ingest/` | Member-eligibility ingest pipeline (quality gates, quarantine with rejection reasons, PHI-masked logging) |
| `app/tests/` | Unit tests (coverage gate 80%) |
| `.github/workflows/ci.yml` | Vendor CI: gitleaks secret scan, Trivy dependency scan (fails on Critical/High), tests + coverage gate, Terraform fmt/validate |

## How the POC uses it

- `main` is written to comply with the OHIP standards the reviewer checks.
- Branch `feature/add-reporting-db` adds a reporting database and export job with **deliberate violations**
  (the answer key is held by the standards team, not in this repo).
- Opening a pull request from that branch triggers the OHIP Code & IaC Reviewer, which posts its findings
  to the pull request and fails the check if an open MUST gap is found.
