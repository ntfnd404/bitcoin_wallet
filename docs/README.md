# Documentation

This folder is structured into two layers: persistent project-level docs and a per-branch feature workspace.

---

## docs/project/ — persistent (stays in master)

| Path | Purpose |
|------|---------|
| `conventions.md` | Architecture, wallet types, code rules — the constitution |
| `workflow.md` | AIDD process: phase lifecycle, agent roles, skill commands, quality gates |
| `guidelines.md` | Flutter/Dart AI interaction guidelines |
| `code-style-guide.md` | Dart formatting and naming conventions |
| `adr/` | Architecture Decision Records (cross-feature decisions) |
| `templates/` | Abstract templates for all AIDD document types |
| `phases/` | Project-level roadmap: 8 phases + product requirements |
| `app-rpc-contract.md` | Planned contract between Flutter app and Bitcoin Core RPC |
| `learning-goals.md` | Learning objectives for this project |
| `rpc-learning-path.md` | Structured Bitcoin RPC learning path |

### Templates

| Template | Used for |
|----------|---------|
| `idea.md` | Feature idea stub (analyst input) |
| `vision.md` | Technical design (researcher output) |
| `tasklist.md` | Master phase checklist |
| `phase_brief.md` | Session brief for implementer (`phase/TICKET/phase-N.md`) |
| `phase_plan.md` | Implementation plan (`plan/TICKET-phase-N.md`) |
| `phase_prd.md` | Formal requirements (`prd/TICKET-phase-N.prd.md`) |
| `phase_research.md` | Research notes (`research/TICKET-phase-N.md`) |
| `phase_qa.md` | QA record (`qa/TICKET-phase-N.md`) |
| `phase_summary.md` | Completion summary (`TICKET-phase-N-summary.md`) |

---

## docs/feature/ — branch workspace (cleaned before merge)

One active ticket per branch. Ticket ID is in `docs/feature/.active_ticket`.

```
docs/feature/
├── .active_ticket                    ← current ticket ID
├── idea-TICKET.md                    ← IDEA_READY
├── vision-TICKET.md                  ← RESEARCH_DONE
├── tasklist-TICKET.md                ← master progress checklist
├── TICKET-phase-N-summary.md         ← COMPLETE (one per finished phase, root level)
│
├── phase/TICKET/phase-N.md           ← TASKLIST_READY (session brief, implementer reads)
├── plan/TICKET-phase-N.md            ← PLAN_APPROVED (exact files, code, steps)
├── prd/TICKET-phase-N.prd.md         ← PRD_READY (acceptance criteria)
├── research/TICKET-phase-N.md        ← RESEARCH_DONE (per-phase research)
└── qa/TICKET-phase-N.md              ← QA_PASS / QA_FAIL
```

---

## Workflow reference

See [docs/project/workflow.md](./project/workflow.md) for:
- Full quality gate chain
- Agent roles and I/O contracts
- Skill commands (`/new-ticket`, `/new-phase`, `/start-phase`, etc.)
- Team agents parallelism pattern

---

