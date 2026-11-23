# Plan lifecycle

## Draft

Create new proposals at `docs/plans/drafts/<slug>.md` (or `docs/current/plans/drafts/`
for lifecycle-bound plans). Include:

- **Status:** Draft.
- **Owner and context:** who must decide, and which source was inspected.
- **Goal and acceptance criteria:** observable outcomes, not just a list of edits.
- **Scope and non-goals:** files or domains allowed to change, plus protected behavior.
- **Approach, risks, and verification:** distinguish source checks, isolated regression checks, runtime activation, and live-provider evidence.
- **Open decisions:** explicit unknowns; do not fill them with assumed approval.

A plan is not permission to execute it. Do not label a proposal approved because
it was written, discussed, or copied from an older handoff.

## Approval

After explicit approval, record its scope and evidence, then use `git mv` to
move the same file to `docs/plans/approved/<slug>.md` (or
`docs/current/plans/approved/`). Do not leave a second draft that can diverge.
Approval is not implementation, successful testing, publication, or provider
acceptance. Scope changes need new approval when they enlarge behavior, external
effects, or destructive operations.

## Completion, withdrawal, and replacement

Once its acceptance criteria and final disposition are recorded, move the plan
to the matching path under `docs/plans/legacy/<date>/` (or a dated archive).
Preserve bytes and Git history; record its replacement or completion evidence in
the current index. Completed, withdrawn, and superseded are different outcomes.

## Existing plan set

`docs/plans/` holds the handoff, rebrand plan, single-VM megaplan, sh5b
runbook, custom-UI preflight, and the 16-file `nabra-on-mgos/` tree. The Phase
0 exit gate (all 7 decisions PASS or BLOCKED with a named owner) must pass
before Phases 1–8 start. See `docs/plans/nabra-on-mgos/PHASE-0-readiness.md`.