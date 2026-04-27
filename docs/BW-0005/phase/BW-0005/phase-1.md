# Phase 1: Reorganise `bitcoin_node` by Consumer Module

Status: `TASKLIST_READY`
Ticket: BW-0005
Phase: 1
Lane: Professional
Workflow Version: 3
Owner: Implementer
Goal: Relocate the eleven flat `*.dart` files in `packages/bitcoin_node/lib/src/` into five consumer-aligned subfolders (`wallet/`, `address/`, `transaction/`, `utxo/`, `block/`) and update every import, while preserving the public barrel symbol set exactly.

Session brief — execution packet only. Architectural rationale lives in the plan and the PRD.

---

## Current Batch

### Batch 1 — File relocation, internal import fixup, barrel rewrite

Move the eleven files into the five new subfolders, rewrite the public barrel
to the new paths (preserving the exported symbol set exactly), and update the
three known intra-package `package:bitcoin_node/src/...` imports to their new
subfolder locations. Then run `flutter analyze --fatal-infos --fatal-warnings`
and resolve any unresolved-import errors before moving to Batch 2.

After Batch 1 closes cleanly, proceed to:

### Batch 2 — Cross-repo consumer sweep and verification

Sweep the entire repo for any direct `package:bitcoin_node/src/...` imports
outside `bitcoin_node/` itself (research expects none); if found, rewrite to
the public barrel. Then run the full check matrix (analyzer, tests, layout
greps, barrel symbol-set diff, `dart pub deps`, `/aidd-run-checks`).

Refer to the plan (`docs/BW-0005/plan/BW-0005-phase-1.md`) **File Changes** and
**Sequencing** sections for the exact mapping and ordered steps.

---

## Constraints

- Pure structural change. No behaviour change. No public API change. No domain
  logic touched.
- Public barrel `packages/bitcoin_node/lib/bitcoin_node.dart` must export the
  same eight `*Impl` class names as today — no additions, no removals. The
  three internal helpers (`AddressTypeRpc`, `AddressTypeRpcMapper`,
  `TransactionDirectionRpcMapper`) must remain non-exported.
- No `*.dart` file may remain directly under `packages/bitcoin_node/lib/src/`
  after Batch 1 — only the five subfolders may exist there.
- All imports must remain `package:`-style (no relative imports), per
  `conventions.md` Prohibited list.
- No new tests added; no existing test deleted or marked `skip`. Test count
  before == test count after.
- No `print`, no `dynamic`, no null assertion (`!`) appears in moved files.
  These are pre-existing constraints; do not regress them.
- No edit to `packages/bitcoin_node/pubspec.yaml`. No new package dependency.
- No README authored in this phase (Phase 4 deliverable).
- No HD/Node subfolder split inside `wallet/`, `address/`, `transaction/`
  (Phase 3 deliverable).
- Lane: **Professional** — no security-reviewer artifact required.

---

## Execution Checklist

### Batch 1 — Move and barrel rewrite

- [x] 1.1 Capture the pre-move `grep -rn "package:bitcoin_node/src/" packages/ lib/ test/` baseline
- [x] 1.2 Create five empty subfolders under `packages/bitcoin_node/lib/src/`: `wallet/`, `address/`, `transaction/`, `utxo/`, `block/`
- [x] 1.3 Move all eleven `*.dart` files into the matching subfolder per the plan's **File Changes** table
- [x] 1.4 Rewrite `packages/bitcoin_node/lib/bitcoin_node.dart` to export the eight files at their new subfolder paths (preserve order; do not export the three internal helpers)
- [x] 1.5 Update the three intra-package `package:bitcoin_node/src/...` imports to their new subfolder locations
- [x] 1.6 Run `flutter analyze --fatal-infos --fatal-warnings` — pre-existing info in `lib/common/extensions/address_type_display.dart:22` (flutter_style_todos, unrelated to this batch); zero errors, zero warnings; no new issues introduced

### Batch 2 — Verify and close

- [x] 1.7 Run `grep -rn "package:bitcoin_node/src/" packages/ lib/ test/` — every result must be inside `packages/bitcoin_node/lib/src/<subfolder>/`; if any consumer outside `bitcoin_node/` imports `src/...` directly, rewrite it to the public barrel
- [x] 1.8 Run `find packages/bitcoin_node/lib/src/ -maxdepth 1 -name '*.dart'` — must return zero rows
- [x] 1.9 Run `ls packages/bitcoin_node/lib/src/` — must list exactly `address  block  transaction  utxo  wallet`
- [x] 1.10 Diff the public-export symbol set of the barrel against the baseline (the eight `*Impl` class names) — must be identical
- [x] 1.11 Run `dart pub deps` for `bitcoin_node` and the app — dependency graph unchanged
- [x] 1.12 Run `/aidd-run-checks` — must exit 0; test count unchanged from baseline; no `skip:` markers added
- [x] 1.13 Update `docs/BW-0005/tasklist-BW-0005.md` Phase 1 row and this brief's status as the workflow gate dictates

---

## Stop Conditions

- architecture deviation (e.g., a file does not fit any of the five consumer subfolders, or moving it breaks the consumer-alignment invariant)
- blocker (analyzer error after Batch 1 step 6 that cannot be resolved by an import path fix)
- risk discovery (a previously-hidden cross-package cycle surfaces in `dart pub deps`; or the barrel symbol-set diff shows drift; or a reference-vector signing test fails)
- batch complete

---

## Acceptance

- `ls packages/bitcoin_node/lib/src/` lists exactly five subfolders and zero `*.dart` files
- `find packages/bitcoin_node/lib/src/ -maxdepth 1 -name '*.dart'` returns no rows
- Public barrel exports exactly the same eight `*Impl` class names as before the phase; the three internal helpers remain non-exported
- `grep -rn "package:bitcoin_node/src/" packages/ lib/ test/` returns only paths under one of the five subfolders, all inside `packages/bitcoin_node/lib/src/`
- `flutter analyze --fatal-infos --fatal-warnings` exits 0
- `flutter test` (or `/aidd-run-checks`) passes; test count unchanged
- `dart pub deps` for `bitcoin_node` and the app shows the dependency graph unchanged
- `/aidd-run-checks` exits 0
