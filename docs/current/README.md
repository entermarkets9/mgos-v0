# Current documentation

Current guidance is separated from historical evidence. A product requirement,
source implementation, isolated test, authenticated user journey, live provider
receipt, and deployed release are different kinds of evidence.

## Read in this order

| Document | Purpose |
| --- | --- |
| [Project and product](01-project-and-product.md) | Intended scope and source-visible surfaces |
| [Architecture](02-architecture.md) | Ownership, storage, worker, and custom-UI boundaries |
| [Current status](03-current-status.md) | Compact evidence status, not a chronological work log |
| [Operations](04-operations-runbook.md) | Local operation and runtime boundaries |
| [Codebase map](05-codebase-map.md) | Source entry points |
| [Open work](06-open-work.md) | Blockers and inherited decisions requiring an owner |
| [Decisions and safety](07-decisions-and-rules.md) | Standing constraints and scope rules |
| [Documentation inventory](08-doc-inventory.md) | Maintained references, exceptions, and archives |
| [CI/CD pipeline](09-ci-cd-pipeline.md) | Merge gate and release behavior |

## Supporting references

- [Release and runtime state inventory](11-release-state-inventory.md) and the
  [sh2 dev stack](13b-sh2-dev-stack.md): what is deployed and how to operate it.
- [Domain glossary](GLOSSARY.md): one canonical vocabulary for the fork.
- [Plan lifecycle](plans/README.md): draft → explicit approval → implementation evidence.
- [Session notes](notes/): dated operational evidence (worker activation, password reset).

## Maintenance rule

Update the relevant current statement instead of prepending another dated
narrative. Preserve the old snapshot under the corresponding path in
[`docs/plans/`](../plans/) or a dated archive. Archival does not mean an issue
was fixed, a proposal approved, or a feature removed.

This fork inherits upstream Twenty's history and license; current docs describe
the MGOS fork's state, not upstream's.