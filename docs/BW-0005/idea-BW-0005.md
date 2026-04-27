# Idea: Architecture Refactor + Package Documentation (BW-0005)

Status: `IDEA_READY`
Ticket: BW-0005
Phase: feature
Lane: Critical
Workflow Version: 3
Owner: Product / Architect
Date: 2026-04-24
Depends On: [BW-0003]
Blocked Until: none

---

## Problem

The codebase carries four architectural debts that will compound as soon as BW-0004 unified-send adds new HD/Node branching and new node consumers:

1. **`bitcoin_node/lib/src/` is flat.** Eleven files sit side-by-side instead of being split into `application/data/domain` (or by consumer module). Navigation is hard, and there is nothing structural to enforce the dependency direction inside the package.
2. **`transaction/HdAddressEntry` duplicates a subset of `address/Address`.** It is an Interface Segregation smell, not a cycle-breaker — there is no architectural cycle that justifies it. Every change to `Address` forces a sync update in `transaction`, and the duplication will silently grow as more transaction code reaches for "just enough" address data.
3. **HD vs Node logic is interleaved inside `wallet/`, `transaction/`, `address/` packages.** Both trust models live in the same files even though every single flow has to branch on type. There is no folder-level boundary, so cross-trust imports cannot be detected by structure alone.
4. **Nine workspace packages, zero `README.md` files.** Onboarding requires reading source. The `docs/project/architecture.md` overview is stale: it omits the `transaction` package, shows an outdated `bitcoin_node` snapshot, and the dependency graph no longer matches reality.

The longer this stays, the more BW-0004 (and every ticket after it) will inherit and reinforce the smell.

---

## Business Goal

Establish a clean DDD/hexagonal foundation **before BW-0004 unified-send begins implementation**, so the new feature lands on a structure that:

- Makes HD vs Node trust boundaries enforceable at the package layout level
- Removes redundant value objects so domain types stay single-source-of-truth
- Lets contributors and the analyst/planner agents understand each package without reading source
- Keeps the architecture document in sync with the actual code graph

---

## Scope

The work is split into four sequential phases. Each phase ships and is reviewed independently.

| # | Goal | Lane | Risk |
|---|------|------|------|
| 1 | Reorganise `bitcoin_node/lib/src/` into 5 consumer-aligned subfolders (`wallet/`, `address/`, `transaction/`, `utxo/`, `block/`) — file moves + import updates only | Professional | Low |
| 2 | Remove `transaction/HdAddressEntry`, add `transaction → address` dependency, switch transaction code to use `Address` directly | Critical | Medium |
| 3 | Introduce HD/Node subfolders in `wallet/`, `transaction/`, `address/` packages (data + application layers) — split by trust model | Critical | Medium |
| 4 | Author `README.md` for all 9 workspace packages + rewrite `docs/project/architecture.md` (add `transaction`, refresh `bitcoin_node`, fix dependency graph) | Professional | Low |

### Non-goals

- No new user-facing features
- No behavioural change — pure structure + documentation
- No changes to keys layer internals (only its consumers' organisation)
- BW-0004 unified-send remains paused on its branch until BW-0005 ships

---

## User Stories

- As a **contributor**, I want each workspace package to ship a README so that I can understand its purpose and public API without reading source.
- As an **architect**, I want HD and Node code to live in separate subfolders so that cross-trust imports show up as structural violations, not just review nits.
- As a **planner agent**, I want the `docs/project/architecture.md` graph to match the real package layout so that I can plan new features against accurate constraints.
- As a **future feature owner**, I want `Address` to be the single source of truth so that I do not have to keep `HdAddressEntry` in sync when extending wallet metadata.

---

## Dependencies

- **Hard depends on:** BW-0003 (key derivation + signing) merged to `main` (✅ done at `c17e816`)
- **Blocks:** BW-0004 unified-send — resumes after BW-0005 ships
- **External:** none — internal refactor only

---

## Acceptance Criteria

| Criterion | Verification |
|-----------|--------------|
| All four phases pass `/aidd-run-checks` with no `skip` markers | `aidd-checks.sh` exit 0 per phase; manual grep for `skip:` in test files |
| No cyclic dependencies between workspace packages | `dart pub deps` clean for every package; manual graph review |
| `HdAddressEntry` removed from `transaction/`; `Address` used directly | `grep -r "HdAddressEntry" packages/` returns no matches outside removal commit |
| `transaction → address` dependency declared in `transaction/pubspec.yaml` | Manual inspection + `dart pub get` clean |
| Every package under `packages/` has a `README.md` covering: purpose, public API entry points, dependencies, when-to-add-here vs elsewhere | `ls packages/*/README.md` returns 9 files |
| `docs/project/architecture.md` lists `transaction` package, current `bitcoin_node` layout, and accurate dependency graph | Manual diff against actual `packages/` tree |
| HD vs Node subfolders enforced in `wallet/`, `transaction/`, `address/` (data + application) | Folder layout review; HD code does not import Node code and vice versa within the same package |
| Each Critical phase carries a security-reviewer artifact under `docs/BW-0005/security/` | File presence check |

---

## Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Phase 2 import churn touches signing-call sites | Medium | Critical lane → security-reviewer gate; reference vector tests must remain green |
| Phase 3 introduces accidental cross-trust imports (HD code importing Node code or vice versa) | Medium | Reviewer checklist explicitly verifies subfolder boundaries; consider `dart_code_metrics` rule if available |
| Phase 4 README content drifts from code immediately | Medium | Add README maintenance to project conventions: any layer change requires README touch in same PR |
| Refactor accidentally changes behaviour | Low | All existing tests must pass per phase; no test additions allowed in Phases 1–3 except those covering the refactored boundaries |
| BW-0004 work on its parallel branch diverges and creates merge pain | Low | BW-0004 stays paused; if it must move, rebase BW-0004 onto BW-0005 phase-by-phase as they merge |

---

## Open Questions

- [ ] Should the four phases ship as four separate PRs to `main`, or as one PR per pair of phases? Default proposal: four PRs (smallest reversibility unit). Confirm during planner stage.
- [x] **Resolved 2026-04-25.** Phase 3 splits only `data/` and `application/` into `hd/` / `node/`. `domain/` layers stay shared across trust models in all three packages.
- [ ] Should READMEs in Phase 4 be authored by the implementer or the analyst agent? Default proposal: implementer drafts, reviewer validates against real code.
