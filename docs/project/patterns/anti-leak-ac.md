# Pattern: Anti-Leak AC

## Problem

AC grep commands that use single-pipe compound expressions silently swallow non-zero exit codes from the first command, making the check appear to pass even when the keyword leg fails. Specifically, a form like `git diff | grep keywords | grep tickets | wc -l` will report 0 even when a domain token leaks, because the ticket grep drops the line before it is counted. This makes the AC untrustworthy as a gate check.

## Context

Used in AIDD v3.3 when writing Verifiable AC shell commands that scan for unwanted tokens in a git diff or file corpus. Applies to any `command:` AC that combines a filter leg with a count leg. Any ticket that touches a vault or cross-repository surface and must verify no domain-sensitive tokens were written to the wrong repository should use this pattern.

## Solution

Split the check into two independent legs, each under `set -e`, rather than one compound pipe.

Leg 1 (keyword) — counts domain tokens in `+` lines:

```sh
set -e
git diff <baseline-tag> | grep -iE "^\+.*(token1|token2|token3)" | wc -l
# expected: 0
```

Leg 2 (ticket) — counts non-allowlisted ticket references in `+` lines:

```sh
set -e
git diff <baseline-tag> | grep -v -E "ALLOWLISTED-TICKET-1|ALLOWLISTED-TICKET-2" | grep -E "\bBW-[0-9A-Z]+\b" | wc -l
# expected: 0
```

Key requirements:
- Use a named tag or commit SHA for `<baseline-tag>`, never `HEAD~1` — a named tag is reproducible after rebases; `HEAD~1` is not.
- Each leg must independently return 0 under `set -e`.
- The compound single-pipe form (`grep keywords | grep tickets`) is forbidden.
- Exclusion patterns in `grep -v` must anchor filenames with their directory segment (e.g. `/phase/phase-3.md`, not bare `phase-3.md`) to avoid matching unintended paths.

## Consequences

- Positive: each leg fails independently; no silent swallowing of keyword failures by the ticket leg.
- Positive: leg failure is unambiguous — keyword leg failure means a domain token leaked; ticket leg failure means an unallowlisted ticket reference was introduced.
- Negative: two commands instead of one; slightly more verbose AC section.
- Invariant: the compound single-pipe form is forbidden in new PRDs (see `workflow.md` § Anti-leak AC).

## Known Uses

- BW-META-001 Phase 3: first use of the two-leg pattern (AC-15 and AC-16).
- BW-META-002 Phase 1: canonicalised in `docs/project/workflow.md` under `### Anti-leak AC — canonical shape` (C2).
- All subsequent Critical-lane tickets with vault or cross-repository diff checks: required by default.
