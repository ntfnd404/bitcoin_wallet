# Development Workflow

Claude-Native Enterprise AIDD for complex products built with Claude Code.

- `docs/project/` is the persistent source of truth
- `docs/BW-000N/` is the branch-local feature workspace

Workflow version: `3`

## Defaults

The default mode is intentionally professional. Process quality comes from clear artifact contracts, role separation, hooks, and deterministic checks, not from collapsing review or QA.

| Lane | Use when | Required path |
|------|----------|---------------|
| `Trivial` | typo, rename, tiny local fix | implement → review |
| `Professional` | medium/large feature, multi-file refactor, user-visible behavior change | full pipeline |
| `Critical` | wallet, seed, keys, auth, crypto, signing, storage migration, API contract, cross-cutting architecture | full pipeline + security review |

Repository default: `Professional`  
Security-sensitive default: `Critical`

## Runtime Sources Of Truth

Claude Code runtime for this repository is defined by:

- `.claude/settings.json`
- `.claude/agents/*.md`
- `.claude/skills/*/SKILL.md`
- `CLAUDE.md`

Local overrides belong in `.claude/settings.local.json` and must not redefine the shared workflow.

## Gate Model

```text
IDEA_READY → PRD_READY → RESEARCH_DONE → VISION_APPROVED → PLAN_APPROVED
→ TASKLIST_READY → IMPLEMENT_STEP_OK → REVIEW_OK
→ SECURITY_REVIEW_OK (Critical only) → QA_PASS
→ RELEASE_READY → DOCS_UPDATED
```

Each gate is blocking. The next role starts only after the current gate is satisfied.

## Documentation Model

### Persistent docs: `docs/project/`

- `conventions.md` — non-negotiable architecture rules
- `workflow.md` — operating model and gates
- `guidelines.md` — framework guidance
- `code-style-guide.md` — style rules
- `adr/` — durable decisions
- `templates/` — canonical artifact shapes

### Feature workspace: `docs/BW-000N/`

- `.active_ticket`
- `idea-TICKET.md`
- `vision-TICKET.md`
- `tasklist-TICKET.md`
- `phase/TICKET/phase-N.md`
- `plan/TICKET-phase-N.md`
- `prd/TICKET-phase-N.prd.md`
- `research/TICKET-phase-N.md`
- `qa/TICKET-phase-N.md`
- `security/TICKET-phase-N.md` for `Critical`
- `TICKET-phase-N-summary.md`
- `metrics.log`

### Metadata contract

Every feature and phase artifact must include:

- `Status`
- `Ticket`
- `Phase`
- `Lane`
- `Workflow Version`
- `Owner`

Optional when relevant:

- `Depends On`
- `Blocked Until`
- `Date`

Templates in `docs/project/templates/` are the canonical shape.

## Artifact Contracts

One artifact owns one responsibility.

| Artifact | Owns | Must not own |
|----------|------|--------------|
| `idea` | problem, scope, intent, dependencies, acceptance | implementation design |
| `phase PRD` | phase deliverables and verification targets | file-by-file solution |
| `research` | codebase truth, constraints, risks, unknowns | final implementation plan |
| `vision` | feature architecture and durable decisions | execution checklist |
| `plan` | exact implementation shape and sequencing | repeated business context |
| `phase brief` | current execution packet | full design rationale |
| `review summary` | review findings and verdict | QA evidence |
| `security review` | security findings and go/no-go | generic style review |
| `qa` | scenario evidence and pass/fail | architecture redesign |
| `tasklist` | cross-phase progress and release readiness | plan prose |

## Roles

| Agent | Input | Output | Gate |
|-------|-------|--------|------|
| `analyst` | `idea` | `prd` | `IDEA_READY → PRD_READY` |
| `researcher` | `idea`, `prd`, codebase | `vision`, `research` | `PRD_READY → RESEARCH_DONE / VISION_APPROVED` |
| `planner` | `vision`, `prd`, `research` | `plan`, `phase`, `tasklist` | `RESEARCH_DONE → PLAN_APPROVED → TASKLIST_READY` |
| `implementer` | `phase`, `plan`, `prd` | code + task updates | `TASKLIST_READY → IMPLEMENT_STEP_OK` |
| `reviewer` | diff + `plan` + `prd` + `phase` | phase summary | `IMPLEMENT_STEP_OK → REVIEW_OK` |
| `security-reviewer` | diff + `plan` + `prd` + review summary | security record | `REVIEW_OK → SECURITY_REVIEW_OK` |
| `qa` | `prd` + `phase` + `plan` + review/security artifacts | QA record | `REVIEW_OK / SECURITY_REVIEW_OK → QA_PASS / QA_FAIL` |

Role rules:

- `implementer` is the primary write-capable execution role
- `reviewer`, `qa`, and `security-reviewer` are read-mostly roles
- `researcher` may run in the background
- `security-reviewer` is mandatory only for `Critical`

## Execution Stack

| Mechanism | Status | Purpose |
|-----------|--------|---------|
| `Skills` | Mandatory | explicit workflow commands |
| `Project subagents` | Mandatory | SDLC role separation |
| `Claude hooks` | Mandatory | guardrails, blocking, context reinjection |
| `MCP` | Mandatory when available | deterministic tooling: format, analyze, test, lookup |
| `Agent teams` | Selective | multi-stream orchestration for large or critical work |

Rules:

- MCP handles deterministic operations, not architecture or review reasoning
- subagents are for bounded independent work only
- team mode stays off by default
- use team mode only for 3+ phases or cleanly separable workstreams
- keep the critical implementation path in the main context

## Claude Hook Layer

Claude hooks are the primary guardrail layer.

Hook rules:

- deterministic
- transparent
- idempotent
- `command` hooks only
- no silent mutation of tracked files

Required events:

- `InstructionsLoaded`
- `SessionStart` with `compact`
- `PreToolUse` for `Write|Edit|MultiEdit`
- `PostToolUse` for `Write|Edit|MultiEdit` — auto-format `.dart` files
- `PostCompact` — reinject active ticket, phase, lane, goal after context compaction
- `FileChanged`
- `ConfigChange`
- `SubagentStart`
- `SubagentStop`
- `TaskCreated`, `TaskCompleted`, `TeammateIdle` for team mode only

Implementation:

- config: `.claude/settings.json`
- hook commands: `.claude/hooks/*.sh`
- the only shell backend intentionally kept in the workflow is `.claude/bin/aidd_validate.sh`

## Skills

Workflow commands are namespaced and manual-first:

- `/aidd-new-ticket`
- `/aidd-new-phase`
- `/aidd-start-phase`
- `/aidd-run-checks`
- `/aidd-complete-phase`
- `/aidd-validate`
- `/aidd-ship-feature`
- `/aidd-init`

Workflow control commands must remain explicit-use only. `/aidd-init` is the bootstrap entry point for new projects or workflow upgrades.

## Execution Cadence

Implementation is batch-based.

Batch rules:

- one batch is one coherent bounded change set
- a batch may contain 2-5 related tasks if they form one logical unit
- `Critical` work uses smaller batches than `Professional`
- stop only on a meaningful boundary:
  - batch complete
  - architecture deviation
  - blocker
  - risk discovery

Per-batch loop:

1. Read current `phase`, `plan`, `prd`, and project rules
2. Propose the next batch
3. Wait for explicit approval
4. Implement the batch
5. Run `/aidd-run-checks`
6. Update `phase` and `tasklist`
7. Show the diff and explain the completed batch
8. Stop on the next meaningful boundary

## Validator

`/aidd-validate` is the required process guard.

It verifies:

- shared Claude runtime files exist
- required agents, skills, hooks, and templates exist
- templates carry workflow-v3 metadata
- stale legacy paths do not remain
- stale legacy slash commands do not remain
- docs and Claude runtime stay aligned

It does not verify:

- application business logic
- feature architecture quality
- test depth
- release content outside the workflow layer

Run it after workflow changes and before declaring the process updated.

## Lane Flows

`Professional`

```text
idea → analyst → researcher → planner
→ implement batches → reviewer → qa
```

`Critical`

```text
idea → analyst → researcher → planner
→ implement batches → reviewer → security-reviewer → qa
```

`Trivial`

```text
direct edit → review
```

`Trivial` is the exception path, not the default engineering mode.

## Team Mode

Team mode enables parallel multi-agent orchestration for large features with 3+ phases or cleanly separable workstreams.

### Activation

Team mode is off by default. Enable it with the environment variable:

```sh
export AIDD_TEAM_MODE=1
```

When `AIDD_TEAM_MODE=0` (default), the `TaskCreated`, `TaskCompleted`, and `TeammateIdle` hooks suppress their output silently.

### When to use

- 3+ phases are in progress or ready for parallel work
- phases have no cross-dependencies (e.g. phase N+1 does not depend on phase N output)
- separate workstreams: one agent plans while another implements a different phase

### How it works

```text
Orchestrator (main context) reads tasklist-TICKET.md
  |-- Agent: Planner(phase N+1)      -- prepares plan while Implementer works on N
  |-- Agent: Implementer(phase N)    -- reads phase/ + plan/
  +-- Agent: QA(phase N-1)           -- verifies while Implementer works on N
```

Use `Agent` tool with `subagent_type` matching the role and pass full context from `docs/BW-000N/`.

### Rules

- the orchestrator stays in the main context window
- each teammate gets a disjoint workstream — no two agents write the same files
- do not create busywork when a teammate goes idle
- all gate requirements still apply: reviewer → security-reviewer (Critical) → QA
- integrate teammate results explicitly before advancing gates
- if a teammate discovers an architecture deviation, escalate to orchestrator immediately

### Hook behavior

| Event | `AIDD_TEAM_MODE=0` | `AIDD_TEAM_MODE=1` |
|-------|---------------------|---------------------|
| `TaskCreated` | suppressed | advisory: keep orchestrator in lead |
| `TaskCompleted` | suppressed | advisory: integrate results, respect gates |
| `TeammateIdle` | suppressed | advisory: rebalance only with clear workstream |

## Recovery And Release Rules

Recovery:

- `QA_FAIL`: fix, re-run checks, and re-enter review if design changed
- repeated `QA_FAIL`: reopen plan or research the broken assumption
- blocked security review: do not continue to QA until resolved or re-scoped
- scope creep mid-phase: create a new phase
- architecture uncertainty: create ADR, then update vision and plan

`RELEASE_READY` requires:

- all phases closed
- every `Professional` phase at `QA_PASS`
- every `Critical` phase at `SECURITY_REVIEW_OK` and `QA_PASS`
- validator clean
- docs sync completed
