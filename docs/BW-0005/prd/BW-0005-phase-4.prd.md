# BW-0005 Phase 4 PRD — Package READMEs + Rewrite `architecture.md`

Status: `PRD_READY`
Ticket: BW-0005
Phase: 4
Lane: Professional
Workflow Version: 3
Owner: Analyst

---

## Phase Intent

The repository ships nine workspace packages under `packages/` and zero of
them carry a `README.md`. Onboarding requires reading source. The
`docs/project/architecture.md` overview is stale: it omits the
`transaction` package entirely, shows an outdated `bitcoin_node` snapshot
(pre-Phase-1 layout), and the dependency graph no longer matches reality.

Phases 1–3 will land structural changes (consumer-aligned `bitcoin_node`,
`HdAddressEntry` removal, HD/Node trust split). This phase captures the
post-refactor state in writing so that future contributors and the
analyst/planner agents can plan against accurate documentation.

It also adds a small process rule to `conventions.md`: any layer-structure
change to a package must touch that package's `README.md` in the same PR,
preventing immediate drift.

This is a **Professional-lane** documentation phase. No code is modified.

---

## Deliverables

1. A `README.md` file at the root of each of the nine workspace packages.
   The current package set is: `address`, `bitcoin_node`, `keys`,
   `rpc_client`, `shared_kernel`, `storage`, `transaction`, `ui_kit`,
   `wallet`. (See Open Questions for the inconsistency between the idea
   and the actual workspace.)
2. Each package `README.md` covers, at minimum:
   - **Purpose** — one-paragraph statement of what the package owns.
   - **Public API entry points** — which barrel(s) and assembly classes
     consumers should import; what they expose at a high level (no
     exhaustive symbol dump).
   - **Dependencies** — which workspace packages this one depends on,
     and why; called-out invariants (e.g. "depends only on
     `shared_kernel`").
   - **When to add code here vs elsewhere** — a short decision
     heuristic so that future contributors and the planner agent can
     route new code correctly.
   - **Layer layout** — a brief tree showing `domain/ application/
     data/` (where applicable) and any trust-model split (`hd/`,
     `node/`) introduced in Phase 3.
3. A rewritten `docs/project/architecture.md` that:
   - Lists the `transaction` package alongside the other business
     modules.
   - Reflects the post-Phase-1 `bitcoin_node` consumer-aligned layout.
   - Reflects the post-Phase-3 HD/Node subfolder split in `wallet/`,
     `transaction/`, `address/`.
   - Contains a dependency graph (text or diagram) that matches the
     real `pubspec.yaml` graph after Phases 1–3.
   - Updates any prose that referenced `HdAddressEntry` or the flat
     `bitcoin_node` layout.
4. An update to `docs/project/conventions.md` adding a rule that any
   change to a package's layer structure (subfolder add/remove/rename)
   must touch that package's `README.md` in the same PR.
5. Phase progress recorded in `docs/BW-0005/tasklist-BW-0005.md` and the
   phase log under `docs/BW-0005/phase/`.

---

## Scenarios

### Positive

- A new contributor cloning the repo opens any
  `packages/<pkg>/README.md` and can answer "what is this package, what
  does it expose, what does it depend on, and when should I add code
  here?" without reading source.
- The planner agent reads `docs/project/architecture.md` and produces a
  dependency graph identical to the one derived from `pubspec.yaml`
  inspection.
- A reader of `architecture.md` finds the `transaction` package
  documented; reading the `bitcoin_node` section yields the
  consumer-aligned subfolder names that match `ls
  packages/bitcoin_node/lib/src/`.
- A reader of `conventions.md` finds the new "README touch" rule
  alongside the existing prohibitions.

### Negative / Edge

- A README is authored before Phases 1–3 land, capturing the pre-refactor
  state: forbidden — Phase 4 must run after Phases 1–3 ship, or each
  README must be re-verified against the post-refactor tree before this
  phase closes.
- A README invents a public symbol or barrel that does not exist:
  forbidden — the planner/implementer must verify each documented entry
  point against the actual barrel file.
- The dependency graph in `architecture.md` lists an edge that does not
  appear in any `pubspec.yaml`, or omits an edge that does: forbidden —
  the graph must be derived from real `pubspec.yaml` entries.
- A README copies a code snippet that drifts from source within weeks:
  prefer prose over code; if a snippet is included, mark its source
  location and minimise it.
- A README is written in Russian or mixed-language: forbidden — all
  project `.md` files are English-only per CLAUDE.md memory.
- The README count after the phase is not exactly nine (one per
  workspace package): forbidden — the success metric is exact-count.

---

## Success Metrics

| Criterion | Verification |
|-----------|--------------|
| Nine package READMEs exist | `ls packages/*/README.md \| wc -l` returns 9 |
| Each README covers the five required sections | Reviewer checklist against the deliverable list |
| `docs/project/architecture.md` lists the `transaction` package | `grep -n "transaction" docs/project/architecture.md` shows the section |
| `architecture.md` reflects the post-Phase-1 `bitcoin_node` layout | Manual diff: subfolder names match `ls packages/bitcoin_node/lib/src/` |
| `architecture.md` reflects the post-Phase-3 HD/Node split | Manual diff: subfolder names match `ls packages/{wallet,transaction,address}/lib/src/{application,data}/` |
| `architecture.md` dependency graph matches reality | Manual cross-check against each `packages/*/pubspec.yaml` `dependencies:` block |
| `conventions.md` carries the new "README touch" rule | `grep -n "README" docs/project/conventions.md` shows the new rule |
| All documents are English-only | Manual review |
| `/aidd-run-checks` passes (markdown lint allowed; code suite untouched) | Exit 0 |

---

## Constraints

- **No source code is modified in this phase.** The repository's runtime
  behaviour is invariant.
- All documentation is English-only (per CLAUDE.md memory and
  `feedback_language` rule).
- All commit messages are English.
- READMEs describe the **post-refactor** state, so this phase must run
  after Phases 1–3 are merged. If any prior phase regresses or is
  reverted, the corresponding README sections must be re-verified before
  Phase 4 closes.
- READMEs prefer prose and folder trees over code snippets. Where a
  snippet is used, it must be small, accurate, and clearly attributed
  to its source file path.
- The dependency graph in `architecture.md` is derived from real
  `pubspec.yaml` entries; no aspirational edges.
- `architecture.md` continues to be the single source of truth referenced
  by `conventions.md`. The two documents must remain consistent.
- The new "README touch" rule in `conventions.md` is a process rule, not
  a tooling rule. No CI check is added in this phase.
- No new third-party Markdown extensions, diagram tools, or doc
  generators are introduced.
- No `print`, no `dynamic`, no `!` — n/a (no code changes), but called
  out for completeness.

---

## Out Of Scope

- Any source code change.
- Reorganising any package layout (Phases 1–3 own that work).
- Authoring user-facing documentation, app store copy, or marketing
  material.
- Adding a CI check that enforces the new "README touch" rule.
- Generating diagrams via tooling — Markdown text or simple ASCII trees
  are sufficient.
- Translating any document into another language.
- Changing `docs/project/code-style-guide.md`, `guidelines.md`, or
  `workflow.md`.

---

## Open Questions

- [x] **Resolved 2026-04-25.** Workspace contains nine packages, not
  ten: `address`, `bitcoin_node`, `keys`, `rpc_client`, `shared_kernel`,
  `storage`, `transaction`, `ui_kit`, `wallet`. Phase 4 authors exactly
  nine READMEs. The tasklist erroneous reference to a `domain` package
  has been corrected; `domain/` is a *layer* inside each package, not a
  separate workspace package.
- [ ] Should READMEs be authored by the implementer or the analyst
  agent? **Default proposal** (carried over from idea): implementer
  drafts, reviewer validates against real code. Confirm during the
  planner stage.
- [ ] Should `architecture.md` include a rendered diagram (e.g.
  Mermaid), or remain text-only? **Default proposal:** text-only ASCII
  graph plus prose, matching the existing style of
  `conventions.md`. Confirm during the planner stage.
