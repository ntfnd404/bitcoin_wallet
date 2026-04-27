# Phase 4: Package READMEs + Rewrite `architecture.md`

Status: `TASKLIST_READY`
Ticket: BW-0005
Phase: 4
Lane: Professional
Workflow Version: 3
Owner: Implementer
Goal: Author nine package READMEs and rewrite `docs/project/architecture.md` to reflect post-Phases-1-3 state; add README-touch process rule to `conventions.md`.

Session brief — execution packet only. Do not repeat full architecture rationale here.

---

## Current Batch

Three sequential batches. Start with Batch A; do not begin Batch B until
all nine READMEs are written and the file-count check passes.

### Batch A — Nine package READMEs

Create `README.md` at the root of each workspace package. Author in this
order (simplest to most complex): `shared_kernel`, `rpc_client`, `keys`,
`storage`, `wallet`, `address`, `transaction`, `bitcoin_node`, `ui_kit`.

Each README must contain five sections in order:
1. **Purpose** — one paragraph.
2. **Public API** — barrel file(s), assembly class (if any), prose summary of exports. Verify every symbol against the real barrel file before writing.
3. **Dependencies** — workspace `path:` deps from `pubspec.yaml` and why. Leaf packages state "no workspace dependencies" explicitly.
4. **When to add code here** — up to four bullet-point heuristics.
5. **Layer layout** — brief folder tree of `domain/`, `application/`, `data/` and any `hd/`/`node/` subfolders.

Package-specific notes:
- `ui_kit`: barrel exports are currently commented out. Describe today's honest state: "placeholder design system; no exports yet."
- `transaction`: note that `HdAddressEntry` was removed in Phase 2 and that `address` was added as a dependency in Phase 2.
- `bitcoin_node`: layer layout must show post-Phase-1 consumer-aligned subfolders (`wallet/`, `address/`, `transaction/`, `utxo/`, `block/`).
- `wallet`, `address`, `transaction`: layer layout must show post-Phase-3 `application/hd/` and `application/node/` subfolders.

Batch A verification:
```
ls packages/*/README.md | wc -l   # must return 9
```

---

### Batch B — Rewrite `docs/project/architecture.md`

Apply all changes listed in the plan. Key areas:

1. **Dependency Graph**: replace with full nine-package graph derived from `packages/*/pubspec.yaml`.
2. **Project Structure — `packages/` section**: add `transaction/` tree; update `bitcoin_node/` to show eight `*Impl` exports across five consumer-aligned subfolders; update `keys/` to show `application/` use cases; update `wallet/` and `address/` trees to reflect post-Phase-3 state (mappers, `hd/`/`node/` subfolders).
3. **Ownership Table**: add `transaction` row; update `bitcoin_node` and `wallet` rows.
4. **ISP section**: expand interface table to include all post-Phase-2 data-source interfaces; note `HdAddressDataSource` now returns `List<Address>`.
5. **Avoiding Cycles**: add `transaction → shared_kernel, address` to the DAG.
6. **DI / Bootstrap Graph**: add `TransactionAssembly` and its adapters; include `transaction` in `AppDependencies` container.
7. **Trust-boundary note** (new subsection after "Module Internal Structure"): describe `hd/`/`node/` subfolder invariants; reference ADR-002.

All graph edges must match real `pubspec.yaml` entries. All tree entries must match real `lib/src/` directories.

Batch B verification:
```
grep -n "transaction" docs/project/architecture.md        # shows new section
# manual diff: bitcoin_node subfolders vs ls packages/bitcoin_node/lib/src/
# manual diff: dependency graph edges vs each packages/*/pubspec.yaml
# manual diff: HD/Node subfolders vs ls packages/{wallet,transaction,address}/lib/src/{application,data}/
```

---

### Batch C — Update `docs/project/conventions.md`

Two changes:

1. Add README-touch process rule. Insert near the existing Prohibited section (or in a new "Process Rules" subsection before Prohibited):
   > Any change to a package's layer structure (subfolder add, remove, or rename under `domain/`, `application/`, or `data/`) must touch that package's `README.md` in the same PR. This is a process rule; no CI check enforces it.

2. Update the stale dependency graph block (lines 74–83) so it no longer contradicts `architecture.md`. Either update it to the real nine-package edges or replace it with a reference: "See [architecture.md — Dependency Graph](./architecture.md#dependency-graph)."

Batch C verification:
```
grep -n "README" docs/project/conventions.md   # shows the new rule
```

---

### Final checks

```
ls packages/*/README.md | wc -l                      # 9
flutter analyze --fatal-infos --fatal-warnings       # 0 (no source changed)
flutter test                                          # green
```

---

## Constraints

- No source code modified in this phase. Runtime behaviour is invariant.
- All `.md` files are English-only (CLAUDE.md `feedback_language` rule).
- Every documented symbol must exist in the real barrel file — verify before writing.
- Dependency graph edges in `architecture.md` derived from `pubspec.yaml` only — no aspirational edges.
- Prefer prose over code snippets in READMEs. If a snippet is used, keep it minimal and attribute the source file path.
- Do not introduce Mermaid or any diagram-generation tooling — ASCII trees and prose only.
- Security review is not required (Professional lane).

---

## Execution Checklist

- [x] 4.1 Author `packages/shared_kernel/README.md`
- [x] 4.2 Author `packages/rpc_client/README.md`
- [x] 4.3 Author `packages/keys/README.md`
- [x] 4.4 Author `packages/storage/README.md`
- [x] 4.5 Author `packages/wallet/README.md`
- [x] 4.6 Author `packages/address/README.md`
- [x] 4.7 Author `packages/transaction/README.md`
- [x] 4.8 Author `packages/bitcoin_node/README.md`
- [x] 4.9 Author `packages/ui_kit/README.md`
- [x] 4.10 Verify: `ls packages/*/README.md | wc -l` returns 9
- [x] 4.11 Rewrite `docs/project/architecture.md` (all seven change areas)
- [x] 4.12 Verify architecture.md: `grep -n "transaction"` non-empty; manual diffs pass
- [x] 4.13 Update `docs/project/conventions.md` (README-touch rule + dependency graph block)
- [x] 4.14 Verify: `grep -n "README" docs/project/conventions.md` non-empty
- [x] 4.15 Run `/aidd-run-checks` — format, analyze, test all green
- [x] 4.16 Update `docs/BW-0005/tasklist-BW-0005.md` Phase 4 row to Done

---

## Stop Conditions

- architecture deviation
- blocker (e.g., barrel file missing an expected symbol)
- risk discovery (e.g., post-Phase-3 directory does not match expected structure)
- batch complete

---

## Acceptance

- `ls packages/*/README.md | wc -l` returns exactly 9
- Each README contains the five required sections with no invented symbols
- `docs/project/architecture.md` lists the `transaction` package section
- `architecture.md` dependency graph matches all nine `packages/*/pubspec.yaml` entries
- `architecture.md` reflects post-Phase-1 `bitcoin_node` consumer-aligned layout and post-Phase-3 HD/Node subfolders
- `docs/project/conventions.md` contains the README-touch process rule
- All documents are English-only
- `flutter analyze --fatal-infos --fatal-warnings` exits 0
- `flutter test` exits 0
