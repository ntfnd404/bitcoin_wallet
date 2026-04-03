# Security Review: <TICKET-ID> Phase N — <Name>

Status: `SECURITY_REVIEW_OK` | `SECURITY_REVIEW_BLOCKED` | `SKIPPED`
Ticket: <TICKET-ID>
Phase: N
Lane: Critical
Workflow Version: 3
Owner: Security Reviewer
Date: YYYY-MM-DD

---

## Scope

<!-- What security-sensitive behavior or data paths were reviewed. -->

---

## Checks

- [ ] Secrets and sensitive data never logged
- [ ] Private material stays in the correct layer
- [ ] Error handling does not leak security state
- [ ] Storage / network / auth changes match the plan
- [ ] No unsafe fallback or downgrade path was introduced

---

## Findings

- None

---

## Required Follow-ups

- None

---

## Verdict

`SECURITY_REVIEW_OK`
