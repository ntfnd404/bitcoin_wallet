# Development Workflow

AIDD (AI-Driven Development) process for bitcoin-wallet.
LLM acts as a team of specialized roles. Each feature follows a full artifact lifecycle.

---

## Feature lifecycle

```
IDEA_READY → PRD_READY → RESEARCH_DONE → PLAN_APPROVED → TASKLIST_READY
→ (per phase) IMPLEMENT_STEP_OK → REVIEW_OK → QA_PASS
→ RELEASE_READY → DOCS_UPDATED
```

Each status lives in the header of its document. A status is the gate — the next agent cannot start until it is set.

---

## Two-layer docs structure

**`docs/project/`** — persistent, stays in master forever:
- `conventions.md`, `workflow.md`, `guidelines.md`, `code-style-guide.md`
- `adr/` — Architecture Decision Records
- `templates/` — abstract templates for all document types
- `project-prd/` — project-level roadmap (phases overview, not AIDD artifacts)

**`docs/BW-000N/`** — branch workspace, **never merged to master**:
- Each feature gets its own folder named after the ticket ID (e.g. `docs/BW-0001/`)
- Lives only in branch `BW-000N-<description>` (e.g. `BW-0001-wallet-creation`)
- `idea-TICKET.md`, `vision-TICKET.md`, `tasklist-TICKET.md`
- `TICKET-phase-N-summary.md` (root level, one per completed phase)
- `phase/TICKET/phase-N.md` — session briefs
- `plan/TICKET-phase-N.md` — implementation plans
- `prd/TICKET-phase-N.prd.md` — formal requirements
- `research/TICKET-phase-N.md` — research notes
- `qa/TICKET-phase-N.md` — QA records

---

## Agent roles

| Agent | Input | Output | Gate advanced |
|-------|-------|--------|---------------|
| `analyst` | `docs/BW-000N/idea-TICKET.md` | `docs/BW-000N/prd/TICKET-phase-N.prd.md` | `IDEA_READY → PRD_READY` |
| `researcher` | `idea.md` + `prd/` | `docs/BW-000N/vision-TICKET.md` + `research/TICKET-phase-N.md` | `PRD_READY → RESEARCH_DONE` |
| `planner` | `vision.md` + `prd/` + `research/` | `docs/BW-000N/plan/TICKET-phase-N.md` + `phase/TICKET/phase-N.md` | `RESEARCH_DONE → PLAN_APPROVED → TASKLIST_READY` |
| `implementer` | `docs/BW-000N/phase/TICKET/phase-N.md` + `plan/TICKET-phase-N.md` | code + tasklist `[x]` | `TASKLIST_READY → IMPLEMENT_STEP_OK` |
| `reviewer` | diff + plan + prd + phase/ | `docs/BW-000N/TICKET-phase-N-summary.md` + verdict | `IMPLEMENT_STEP_OK → REVIEW_OK` |
| `qa` | prd + phase/ + plan/ | `docs/BW-000N/qa/TICKET-phase-N.md` | `REVIEW_OK → QA_PASS / QA_FAIL` |

---

## Skill commands

| Skill | Usage | What it does |
|-------|-------|-------------|
| `/new-ticket` | `/new-ticket BW-0002` | Creates `docs/BW-0002/idea-BW-0002.md` stub + sets `.active_ticket` |
| `/new-phase` | `/new-phase 3` | Scaffolds stubs in `phase/`, `plan/`, `prd/`, `research/` |
| `/start-phase` | `/start-phase 3` | Loads and summarizes context; proposes first task |
| `/complete-phase` | `/complete-phase 3` | Verifies all tasks `[x]`, runs checks, prompts for review |
| `/run-checks` | `/run-checks` | `dart format` + `flutter analyze` + `flutter test` |
| `/ship-feature` | `/ship-feature` | Produces CHANGELOG entry + pre-merge cleanup checklist |

---

## Phase lifecycle (per phase)

```
1. Planner writes phase/TICKET/phase-N.md (TASKLIST_READY) + plan/TICKET-phase-N.md
2. /start-phase N       → load context, see first task
3. implementer          → propose → OK → implement → [x] → show diff → stop
4. /complete-phase N    → verify checklist + run-checks
5. reviewer agent       → produces TICKET-phase-N-summary.md (REVIEW_OK)
6. qa agent             → produces qa/TICKET-phase-N.md (QA_PASS / QA_FAIL)
7. QA_FAIL              → implementer fixes → back to step 4
```

---

## Implementer rules

1. **Propose first** — describe the plan with code snippets, wait for explicit OK
2. **One task at a time** — one checklist item per iteration
3. **Follow conventions.md** — architecture, style, prohibitions
4. **Update tasklist** — mark `[x]` in phase brief AND `tasklist-TICKET.md`
5. **Show diff** — explain what changed and why
6. **Stop and wait** — pause after each task, wait for confirmation
7. **Run analyze** — `flutter analyze` clean before marking done

---

## Quality gates reference

| Gate | Status set in | Condition |
|------|---------------|-----------|
| `IDEA_READY` | `idea-TICKET.md` | Problem statement + user stories + acceptance criteria complete |
| `PRD_READY` | `prd/TICKET-phase-N.prd.md` | Goals, stories, scenarios, metrics defined; no blocking questions |
| `RESEARCH_DONE` | `research/TICKET-phase-N.md` + `vision-TICKET.md` | Codebase explored, dependencies verified, risks documented |
| `PLAN_APPROVED` | `plan/TICKET-phase-N.md` | Architecture described, exact files/changes specified, risks addressed |
| `TASKLIST_READY` | `phase/TICKET/phase-N.md` | Tasks are small and independent, each has acceptance criteria |
| `IMPLEMENT_STEP_OK` | (per task) | Code written, `[x]` marked, `flutter analyze` clean |
| `REVIEW_OK` | `TICKET-phase-N-summary.md` | No blocking findings, conventions followed |
| `QA_PASS` / `QA_FAIL` | `qa/TICKET-phase-N.md` | All PS/NE/MC/IV scenarios verified |
| `RELEASE_READY` | `tasklist-TICKET.md` | All phases `QA_PASS` |
| `DOCS_UPDATED` | `tasklist-TICKET.md` | CHANGELOG updated, feature workspace cleaned |

---

## Team agents (parallel execution)

When multiple phases are in progress simultaneously:

```
Orchestrator (main context) reads tasklist-TICKET.md
  ├── Agent: Planner(phase N+1)      ← prepares phase/plan/prd while Implementer works on N
  ├── Agent: Implementer(phase N)    ← reads phase/ + plan/
  └── Agent: QA(phase N-1)           ← verifies while Implementer works on N
```

Use `Agent` tool with `subagent_type=general-purpose` and role context from `.claude/agents/`.

---

## Starting a new feature

```sh
git checkout -b BW-0002-<description>   # create feature branch first
/new-ticket BW-0002                      # creates docs/BW-0002/ + idea stub + .active_ticket
# Fill docs/BW-0002/idea-BW-0002.md
# Run analyst agent → PRDs
# Run researcher agent → vision + research
# Run planner agent → phase briefs + plans
/new-phase 1                             # verify stubs exist or create them
/start-phase 1                           # load context, begin implementation
```

> **Branch convention:** `BW-000N-<kebab-case-description>` (e.g. `BW-0001-wallet-creation`).
> `docs/BW-000N/` lives only in the feature branch — excluded from the merge to master.

---

## References

- [conventions.md](./conventions.md) — architecture and code rules (read first)
- [guidelines.md](./guidelines.md) — Flutter/Dart AI guidelines
- [code-style-guide.md](./code-style-guide.md) — Dart style
- [CLAUDE.md](../../CLAUDE.md) — Claude Code project instructions
