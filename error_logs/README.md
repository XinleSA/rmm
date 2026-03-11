# error_logs/

This directory contains install logs automatically pushed by `01_master_setup.sh`.

| Filename pattern | Meaning |
|---|---|
| `install-success-YYYYMMDD-HHMMSS.log` | Successful deployment log |
| `install-failure-YYYYMMDD-HHMMSS.log` | Failed deployment with rollback log |

All logs are automatically sanitized — passwords, PSKs, and secrets are
replaced with `<REDACTED>` before being committed.

Logs are useful for post-mortem analysis and remediation of failed deployments.
