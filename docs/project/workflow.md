# Development Workflow

Claude-Native Enterprise AIDD for complex products built with Claude Code.

- `docs/project/` is the persistent source of truth
- `docs/BW-000N/` is the branch-local feature workspace

Workflow document version: `3.3` (minor).

Artifact metadata `Workflow Version:` field stays at `3` — contracts and validator regex are unchanged.

## Defaults

The default mode is intentionally professional. Process quality comes from clear artifact contracts, role separation, hooks, and deterministic checks, not from collapsing review or QA.

| Lane | Use when | Required path |
|------|----------|---------------|
| `Trivial` | typo, rename, tiny local fix | implement → review |
| `Professional` | medium/large feature, multi-file refactor, user-visible behavior change | full pipeline |
| `Critical` | wallet, seed, keys, auth, crypto, signing, storage migration, API contract, cross-cutting architecture | full pipeline + security review |

Repository default: `Professional`  
Security-sensitive default: `Critical`

### Trivial lane — canonical reference

Canonical definition lives in the AIDD methodology vault: `Methodology/Lanes.md`. Project text reproduces the entry criteria from `Methodology/Lanes.md:3-10` (translated to English to match project documentation language):

> ## Trivial
>
> Use only for:
> - Typo fixes
> - Renames
> - Minor configuration changes
> - Local single-file changes without architectural impact
>
> Flow: `edit → review`
>
> Do NOT use Trivial if any of the following applies:
> - Public behavior changes
> - Multiple modules are affected
> - There is regression risk
> - There are security/privacy/storage consequences

Commit-trace rule: every Trivial commit must carry the `trivial:` prefix OR an issue link in the commit message. Without one of those two markers the short path is not auditable and the commit must be reclassified to `Professional`.

## Runtime Sources Of Truth

Claude Code runtime for this repository is defined by:

- `.claude/settings.json`
- `.claude/agents/*.md`
- `.claude/skills/aidd-*/SKILL.md` — workflow skills (manual)
- `.claude/skills/{flutter,dart}-*/SKILL.md` — external skills (auto)
- `.claude/skills/<domain>/SKILL.md` — domain skills (path-scoped)
- `CLAUDE.md`

Local overrides belong in `.claude/settings.local.json` and must not redefine the shared workflow.

## Gate Model

```text
IDEA_READY → PRD_READY → SPEC_CRITIQUED → RESEARCH_DONE → VISION_APPROVED → PLAN_APPROVED
→ TASKLIST_READY → IMPLEMENT_STEP_OK → REVIEW_OK
→ SECURITY_REVIEW_OK (Critical only) → QA_PASS
→ RELEASE_READY → DOCS_UPDATED
```

Each gate is blocking. The next role starts only after the current gate is satisfied.

`SPEC_CRITIQUED` is an enforced gate. After the `analyst` produces a PRD, the `spec-critic` agent runs against that PRD file (and only that file) and emits a critique with at least three observations. The PRD `Status` header flips from `PRD_READY` to `SPEC_CRITIQUED` only when the critic returns a positive verdict. A `SPEC_BLOCKED` verdict — triggered by any Blocking observation — sends the PRD back to the analyst for revision and a critic re-run. The `researcher` MUST refuse a PRD that is still at `PRD_READY`; `RESEARCH_DONE` is only reachable from `SPEC_CRITIQUED`.

## Spec-critic

Two passes (`SPEC_BLOCKED → revision → SPEC_CRITIQUED`) is the expected cadence for PRDs under Critical or Professional lane. It is not a sign of low-quality PRD authoring; it is the gate working as designed. Spec-critic findings on pass 1 surface predicted-shape mismatches, AC durability nits, and exclusion-pattern hygiene gaps that the analyst could not anticipate without a second adversarial read. Tickets that pass on a single sweep are the exception, not the target.

### Gate → external skill mapping

External skills (Flutter/Dart) execute *inside* a gate; they never replace the role that closes it.

| Gate | Closing role | AIDD skill | Optional external skills |
|------|--------------|------------|--------------------------|
| `IDEA_READY → PRD_READY` | analyst | `/aidd-new-ticket`, `/aidd-new-phase` | — |
| `PRD_READY → SPEC_CRITIQUED` | spec-critic | — | — |
| `SPEC_CRITIQUED → RESEARCH_DONE` | researcher | — | `flutter-apply-architecture-best-practices` |
| `RESEARCH_DONE → VISION_APPROVED` | researcher | — | `flutter-apply-architecture-best-practices` |
| `VISION_APPROVED → PLAN_APPROVED` | planner | — | `dart-resolve-package-conflicts`, `flutter-setup-declarative-routing`, `flutter-setup-localization` |
| `PLAN_APPROVED → TASKLIST_READY` | planner | `/aidd-new-phase` | — |
| `TASKLIST_READY → IMPLEMENT_STEP_OK` | implementer | `/aidd-start-phase`, `/aidd-run-checks` | `flutter-add-widget-test`, `flutter-add-widget-preview`, `flutter-build-responsive-layout`, `flutter-fix-layout-issues`, `flutter-implement-json-serialization`, `dart-add-unit-test`, `dart-generate-test-mocks`, `dart-use-pattern-matching`, `dart-fix-runtime-errors`, `dart-run-static-analysis` |
| `IMPLEMENT_STEP_OK → REVIEW_OK` | reviewer | — | `dart-run-static-analysis` |
| `REVIEW_OK → SECURITY_REVIEW_OK` | security-reviewer | — | — (no external skill substitutes for security review) |
| `… → QA_PASS` | qa | `/aidd-complete-phase` | `flutter-add-integration-test`, `dart-collect-coverage` (Critical), `dart-add-unit-test` |
| `QA_PASS → RELEASE_READY → DOCS_UPDATED` | orchestrator | `/aidd-ship-feature`, `/aidd-validate` | — |

External skill output must be recorded in the phase summary when invoked in a `Critical` phase.

## Branch Strategy

One ticket = one feature branch. No exceptions.

### Rules

- Branch is created from `main` at the start of a new ticket: `git checkout -b BW-XXXX-short-name`
- `docs/BW-XXXX/` is created on the feature branch — it lives there and **never merges into `main`**
- `main` only ever contains `docs/project/` (persistent docs) — never `docs/BW-XXXX/` (branch-local)
- Code changes are committed to the feature branch throughout implementation
- The ticket is closed by merging the feature branch into `main`

### Docs-sync rule (manual gate at merge)

Before merging a feature branch into `main`, the implementer/reviewer must
verify: did the implementation introduce, remove, or change behavior that is
documented in `docs/project/` (conventions, code-style, architecture,
workflow, guidelines, ADRs)? If yes, the corresponding `docs/project/` file
MUST be updated in the same PR. The check is recorded in the phase summary's
§Docs-sync row (PASS / N/A) and is part of the `REVIEW_OK` exit.

### Ticket lifecycle

```text
git checkout -b BW-XXXX-short-name   ← ticket opens
  → /aidd-new-ticket                 ← creates docs/BW-XXXX/ on the branch
  → implement phases                 ← commits on BW-XXXX branch
  → all phases done, QA pass
  → git checkout main && git merge BW-XXXX-short-name --no-ff
  → delete docs/BW-XXXX/ from main   ← branch-local docs do not land in main
  → update docs/project/phases/progress.md
  → ticket closed
```

### Commit convention

```
feat(BW-XXXX): short description
fix(BW-XXXX): short description
chore(BW-XXXX): short description
```

### What lands in `main`

| Lands in `main` | Does NOT land in `main` |
|---|---|
| All feature code (`lib/`, `packages/`, `test/`) | `docs/BW-XXXX/` workspace |
| `docs/project/` updates | Phase plans, PRDs, research, tasklists |
| `progress.md` update (phase → completed) | |

---

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
- `phase/phase-N.md`
- `plan/TICKET-phase-N.md`
- `prd/TICKET-phase-N.prd.md`
- `research/TICKET-phase-N.md`
- `qa/TICKET-phase-N.md`
- `security/TICKET-phase-N.md` for `Critical`
- `critique/TICKET-phase-N-critique.md`   (spec-critic output)
- `discovery/TICKET-phase-N-discovery.md` (optional)
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

### Discovery artifact

A `discovery` artifact is **purely optional**. Analysts may produce one
during the Clarification round (or earlier exploration) to record rejected
alternatives, but neither the validator nor the workflow gates require it.
Authored by `analyst`; lives at
`docs/<TICKET>/discovery/<TICKET>-phase-<N>-discovery.md`. When present, the
PRD links to it from `## Alternatives` (or equivalent). Existing tickets
that pre-date Phase 3 do NOT retroactively need a discovery file.

## Verifiable AC

Every PRD acceptance criterion ships as a `test:` / `command:` / `manual:` shell-evaluable predicate. The patterns below codify the durable shapes that emerged from spec-critic feedback.

### Verifiable AC — anti-patterns

Literal-token-grep is the dominant anti-pattern: an AC that asserts the presence of a specific word, header, or section name will break on any harmless rename or rewording, even when the artifact still satisfies the underlying intent. The BW-META-001 Phase 3 spec-critic cycle hit this directly — the original `AC-1`, `AC-2`, `AC-5`, and `AC-18` all encoded section names verbatim and required a Route-2 PRD revision before the gate could close.

Replace literal-token-grep with one of three durable shapes:

- **count-based** — assert a structural count rather than a specific token. Example: `grep -c "^## " docs/project/vision.md` ≥ N. Survives section renames.
- **file-existence** — assert that an artifact lives at a contract path. Example: `test -f docs/<TICKET>/discovery/<TICKET>-phase-<N>-discovery.md`. Survives content edits.
- **semantic comparison** — assert that two sets are equal (or one is contained in the other) via `comm`. Example: `comm -23 <(printf '%s\n' <expected sections> | sort) <(grep "^## " <file> | sed 's/^## //' | sort)` returns empty. Names the missing element when it fails.

### Anti-leak AC — canonical shape

The anti-leak AC for any vault- or cross-repository diff sweep MUST be expressed as two legs under `set -e`:

```sh
set -e
# keyword leg — forbidden domain tokens
git diff <SHA> | grep -iE "^\+.*(bitcoin|wallet|satoshi|seed|btc)" | wc -l   # MUST be 0
# ticket leg — allowlisted ticket placeholders only
git diff <SHA> | grep -v -E "<allowlist>" | grep -E "\bBW-[0-9A-Z]+\b" | wc -l   # MUST be 0
```

Both the **keyword leg** and the **ticket leg** must each return a zero count independently. A single-pipe compound form (`... | grep keywords | grep tickets`) is forbidden: it lets a non-ticket keyword leak escape because the final ticket grep drops the line. The **two-leg** shape is the only acceptable form for anti-leak ACs.

### Exclusion-pattern hygiene

When an AC uses `grep -v` to carve out historical or intentionally-retained references, the exclusion patterns MUST anchor each filename to its enclosing directory segment. Use `/phase/phase-3.md`, NOT bare `/phase-3.md` — the unanchored form will also match `phase-30.md`, `phase-3.md.bak`, or any stray `phase-3.md` placed under an unintended subdirectory later.

Exclusion list is exhaustive; if a stale reference surfaces under a non-excluded subdir, fix the artifact rather than widen the exclusion. Operator drift toward broader exclusions hides regressions that the AC was built to catch.

### AC remediation routes

When a `command:` AC fails on first sweep, ask: did the implementation drift, or did the AC predict the wrong shape? Route 1 (edit content to match AC) if AC describes the intended shape and the artifact missed it. Route 2 (revise the AC) if the artifact is correct and the AC was over-specified. Route 1 is the default; Route 2 requires a one-line rationale in the critique trail so the revision history stays auditable and future authors can see which ACs were tightened versus loosened.

## Roles

| Agent | Input | Output | Gate |
|-------|-------|--------|------|
| `analyst` | `idea` | `prd` | `IDEA_READY → PRD_READY` |
| `spec-critic` | `prd` | spec critique | `PRD_READY → SPEC_CRITIQUED` |
| `researcher` | `idea`, `prd`, codebase | `vision`, `research` | `SPEC_CRITIQUED → RESEARCH_DONE / VISION_APPROVED` |
| `planner` | `vision`, `prd`, `research` | `plan`, `phase`, `tasklist` | `RESEARCH_DONE → PLAN_APPROVED → TASKLIST_READY` |
| `implementer` | `phase`, `plan`, `prd` | code + task updates | `TASKLIST_READY → IMPLEMENT_STEP_OK` |
| `reviewer` | diff + `plan` + `prd` + `phase` | phase summary | `IMPLEMENT_STEP_OK → REVIEW_OK` |
| `security-reviewer` | diff + `plan` + `prd` + review summary | security record | `REVIEW_OK → SECURITY_REVIEW_OK` |
| `qa` | `prd` + `phase` + `plan` + review/security artifacts | QA record | `REVIEW_OK / SECURITY_REVIEW_OK → QA_PASS / QA_FAIL` |

`reviewer`, `qa`, and `security-reviewer` are read-mostly roles — no code edits.

## Execution Stack

| Mechanism | Status | Purpose | Invocation |
|-----------|--------|---------|------------|
| `AIDD skills` | Mandatory | explicit workflow commands (`/aidd-*`) | manual (`disable-model-invocation: true`) |
| `External skills` | Optional, recommended | task-specific recipes for Flutter / Dart work | auto (Claude selects by description) |
| `Domain skills` | Selective | project-specific (e.g. `bitcoin-rpc-learning`) | by `paths:` glob |
| `Project subagents` | Mandatory | SDLC role separation | role-driven |
| `Claude hooks` | Mandatory | guardrails, blocking, context reinjection | event-driven |
| `MCP` | Mandatory when available | deterministic tooling: format, analyze, test, lookup | tool-call |
| `Agent teams` | Selective | multi-stream orchestration for large or critical work | flag-driven (`AIDD_TEAM_MODE=1`) |

Rules:

- MCP handles deterministic operations, not architecture or review reasoning
- subagents are for bounded independent work only
- team mode stays off by default
- use team mode only for 3+ phases or cleanly separable workstreams
- keep the critical implementation path in the main context
- external skills execute *inside* a gate — they never close it; the role does

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

Three skill layers coexist under `.claude/skills/`:

| Layer | Prefix | Auto-invoke | Source of truth |
|-------|--------|-------------|------------------|
| AIDD workflow | `aidd-*` | no — manual via `/aidd-*` | this workflow |
| External (vendor) | `flutter-*`, `dart-*` | yes | `github.com/flutter/skills`, `github.com/dart-lang/skills` |
| Domain | project-specific (`bitcoin-*`, `regtest-*`, …) | by `paths:` glob | this repository |

### AIDD workflow skills

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

## External Agent Skills

Vendor-maintained recipes for stack-specific tasks from `flutter/skills` and `dart-lang/skills`.

### Active set in this repository

19 skills installed: 10 Flutter + 9 Dart. Per-skill applicability is documented in the AIDD vault at `Tech Adaptors/Flutter-Dart/external-skills-overlay.md`. Highlights for this project:

- **Core set** (always applicable): `dart-run-static-analysis`, `dart-add-unit-test`, `dart-generate-test-mocks`, `dart-collect-coverage`, `dart-fix-runtime-errors`, `dart-use-pattern-matching`, `flutter-add-widget-test`, `flutter-add-integration-test`, `flutter-build-responsive-layout`, `flutter-fix-layout-issues`.
- **One-shot** (used once, then irrelevant): `flutter-setup-declarative-routing`, `flutter-setup-localization`.
- **Constrained**: `flutter-implement-json-serialization` — never for signed transactions, keys, or any sensitive payload; only for plain DTO mapping.
- **Not applicable to this repo**: `flutter-use-http-package` (use `rpc_client` workspace package), `dart-build-cli-app` (Flutter app, not CLI), `dart-migrate-to-checks-package` (project uses `package:test`).

### Conflict resolution

When an external skill conflicts with project conventions, the project wins. Priority order:

1. `docs/project/conventions.md`
2. `docs/project/adr/*`
3. `docs/project/code-style-guide.md`
4. External skill
5. Framework default

The implementer must apply project post-processing on top of any skill output: no relative imports (`code-style-guide.md:19`), empty line before `return`, BLoC-only state management, test helpers in separate files under `test/helpers/`, selective catches in use cases.

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

Run it after workflow changes and before declaring the process updated.

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

- scope creep mid-phase: create a new phase
- architecture uncertainty: create ADR, then update vision and plan

`RELEASE_READY` requires:

- all phases closed
- every `Professional` phase at `QA_PASS`
- every `Critical` phase at `SECURITY_REVIEW_OK` and `QA_PASS`
- validator clean
- docs sync completed
