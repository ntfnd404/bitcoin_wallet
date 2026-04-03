# Documentation

This repository uses two documentation layers:

- `docs/project/` — persistent process and architecture knowledge
- `docs/BW-000N/` — branch-local feature workspace

Workflow version: `3`

---

## Claude-Native Runtime

Runtime source of truth for the workflow:

- `.claude/settings.json` — Claude hooks and runtime guardrails
- `.claude/agents/` — project subagents
- `.claude/skills/` — project slash commands and domain skills
- `CLAUDE.md` — project memory and default rules

---

## `docs/project/` — persistent

| Path | Purpose |
|------|---------|
| `conventions.md` | Architecture and non-negotiable code rules |
| `workflow.md` | Claude-Native Enterprise AIDD v3 operating model |
| `guidelines.md` | Flutter/Dart interaction guidance |
| `code-style-guide.md` | Formatting, naming, imports |
| `adr/` | Durable architecture decisions |
| `templates/` | Canonical feature and phase document templates |
| `phases/` | Project roadmap and product-level progress |

### Templates

| Template | Used for |
|----------|----------|
| `idea.md` | Feature problem statement, scope, dependencies, lane |
| `vision.md` | Feature-level architecture and durable decisions |
| `tasklist.md` | Phase progress index and release checklist |
| `phase_prd.md` | Phase deliverables, scenarios, metrics |
| `phase_research.md` | Existing codebase truth, constraints, risks |
| `phase_plan.md` | Exact implementation design |
| `phase_brief.md` | Current execution packet for the implementer |
| `phase_summary.md` | Reviewer output and review verdict |
| `phase_qa.md` | QA evidence and verdict |
| `phase_security_review.md` | Security review evidence for `Critical` work |
| `adr.md` | Durable architecture decision record |

---

## `docs/BW-000N/` — branch-local feature workspace

One ticket per branch. The workspace is not merged back to `master`.

```text
docs/BW-000N/
├── .active_ticket
├── idea-TICKET.md
├── vision-TICKET.md
├── tasklist-TICKET.md
├── TICKET-phase-N-summary.md
├── metrics.log
├── phase/TICKET/phase-N.md
├── plan/TICKET-phase-N.md
├── prd/TICKET-phase-N.prd.md
├── research/TICKET-phase-N.md
├── qa/TICKET-phase-N.md
└── security/TICKET-phase-N.md          # Critical lane only
```

---

## Rules Of Thumb

- `Professional` is the default lane
- `Critical` is mandatory for wallet, seed, keys, auth, crypto, signing, storage migration, and API contract changes
- use templates as the only source for document shape and metadata
- move durable learnings into `docs/project/`; keep feature-local detail in `docs/BW-000N/`
- prefer Claude hooks and validator as the workflow guardrail stack
