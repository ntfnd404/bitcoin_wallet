# Idea: <Feature Name> (<TICKET-ID>)

Status: `IDEA_READY`
Ticket: <TICKET-ID>
Phase: feature
Lane: Professional
Workflow Version: 3
Workflow Minor: 3.2
Owner: Product / Architect
Date: YYYY-MM-DD
Depends On: []
Blocked Until: none

---

## Problem

<!-- What is broken, missing, or required? Why does it matter now? -->

---

## Business Goal

<!-- What outcome should the feature produce if successful? -->

---

## Scope

- <!-- In-scope capability -->

### Non-goals

- <!-- Explicitly out of scope -->

---

## User Stories

- As a <role>, I want <action> so that <value>.

---

## Dependencies

- <!-- Other features, external systems, platform constraints -->

---

## Acceptance Criteria

<!--
Verification format rule (Workflow Minor 3.2):
Every Verification cell MUST start with one of three prefixes:
  - `test:`     - automated test name or path
  - `command:`  - shell command that produces a verifiable result
  - `manual:`   - human-executed check with recorded evidence
Prose verifications ("works correctly", "looks good") are forbidden and will
be flagged FAIL by `.claude/bin/aidd_validate.sh`.
-->

| Criterion | Verification |
|-----------|--------------|
| Example AC | command: `grep -q foo file.txt` |
| | |

---

## Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| | | |

---

## Open Questions

- [ ] <!-- Question that must be resolved before implementation -->
