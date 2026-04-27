# Plan: BW-0005 Phase 1 — Reorganise `bitcoin_node` by Consumer Module

Status: `PLAN_APPROVED`
Ticket: BW-0005
Phase: 1
Lane: Professional
Workflow Version: 3
Owner: Planner / Architect
Date: 2026-04-25

---

## Phase Scope

Pure structural reorganisation of `packages/bitcoin_node/lib/src/`. The current
flat layout (eleven `*.dart` files directly under `src/`) becomes five
consumer-aligned subfolders — `wallet/`, `address/`, `transaction/`, `utxo/`,
`block/` — each containing only the adapters that serve the named consumer
module. The public barrel (`packages/bitcoin_node/lib/bitcoin_node.dart`) is
rewritten to export the new paths while preserving its exported symbol set
exactly. Three intra-package helper imports inside `bitcoin_node` are updated to
the new locations. No consumer code paths change behaviour; the only consumer
that imports the barrel (`lib/core/di/app_dependencies_builder.dart`) requires
no edit because the barrel symbol set is invariant.

This is a **Professional-lane phase** — no key material, no signing logic, no
domain entity is touched. **Security review is NOT required** for this phase
(security review is gated on Phases 2 and 3 only, which sit on the HD signing
hot path).

---

## File Changes

### Files moved (eleven files; no content changes other than internal import path updates)

| Current path (under `packages/bitcoin_node/lib/src/`) | New path (under `packages/bitcoin_node/lib/src/`) | Consumer module |
|------|------|------|
| `wallet_remote_data_source_impl.dart` | `wallet/wallet_remote_data_source_impl.dart` | `wallet` |
| `address_remote_data_source_impl.dart` | `address/address_remote_data_source_impl.dart` | `address` |
| `address_type_rpc.dart` | `address/address_type_rpc.dart` | `address` (extension on `AddressType` for address generation) |
| `transaction_remote_data_source_impl.dart` | `transaction/transaction_remote_data_source_impl.dart` | `transaction` |
| `transaction_direction_rpc_mapper.dart` | `transaction/transaction_direction_rpc_mapper.dart` | `transaction` |
| `broadcast_data_source_impl.dart` | `transaction/broadcast_data_source_impl.dart` | `transaction` |
| `node_transaction_data_source_impl.dart` | `transaction/node_transaction_data_source_impl.dart` | `transaction` |
| `utxo_remote_data_source_impl.dart` | `utxo/utxo_remote_data_source_impl.dart` | `transaction` (UTXO listing) |
| `utxo_scan_data_source_impl.dart` | `utxo/utxo_scan_data_source_impl.dart` | `transaction` (UTXO scanning) |
| `address_type_rpc_mapper.dart` | `utxo/address_type_rpc_mapper.dart` | shared helper, primary consumer is `utxo/utxo_remote_data_source_impl.dart`; secondary consumer `transaction/transaction_remote_data_source_impl.dart` imports it across subfolders (acceptable per `conventions.md` — intra-package imports are not restricted). See Risks. |
| `block_generation_data_source_impl.dart` | `block/block_generation_data_source_impl.dart` | `transaction` (regtest mining) |

### Internal import edits inside `bitcoin_node/lib/src/` (three sites)

| File (post-move path) | Edit |
|------|------|
| `address/address_remote_data_source_impl.dart` | `package:bitcoin_node/src/address_type_rpc.dart` → `package:bitcoin_node/src/address/address_type_rpc.dart` |
| `transaction/transaction_remote_data_source_impl.dart` | `package:bitcoin_node/src/transaction_direction_rpc_mapper.dart` → `package:bitcoin_node/src/transaction/transaction_direction_rpc_mapper.dart`; `package:bitcoin_node/src/address_type_rpc_mapper.dart` (if present in this file) → `package:bitcoin_node/src/utxo/address_type_rpc_mapper.dart` |
| `utxo/utxo_remote_data_source_impl.dart` | `package:bitcoin_node/src/address_type_rpc_mapper.dart` → `package:bitcoin_node/src/utxo/address_type_rpc_mapper.dart` |

Note: the research file confirms exactly three intra-package
`package:bitcoin_node/src/...` import sites today. The implementer must
verify with `grep -r "package:bitcoin_node/src/" packages/bitcoin_node/`
**before** the move and **after** the move; the after-grep must list only
new subfolder paths.

### Barrel rewrite

`packages/bitcoin_node/lib/bitcoin_node.dart` — replace the eight existing
`export 'src/<file>.dart';` lines with the eight equivalent
`export 'src/<subfolder>/<file>.dart';` lines, preserving order:

```dart
export 'src/address/address_remote_data_source_impl.dart';
export 'src/block/block_generation_data_source_impl.dart';
export 'src/transaction/broadcast_data_source_impl.dart';
export 'src/transaction/node_transaction_data_source_impl.dart';
export 'src/transaction/transaction_remote_data_source_impl.dart';
export 'src/utxo/utxo_remote_data_source_impl.dart';
export 'src/utxo/utxo_scan_data_source_impl.dart';
export 'src/wallet/wallet_remote_data_source_impl.dart';
```

The three intra-package helpers (`address_type_rpc.dart`,
`address_type_rpc_mapper.dart`, `transaction_direction_rpc_mapper.dart`) must
**not** be added to the barrel — they were not exported before and must remain
non-exported. Public symbol set must be byte-equivalent.

### Consumer files

| File | Edit needed? | Why |
|------|--------------|-----|
| `lib/core/di/app_dependencies_builder.dart` | **No** | Imports `package:bitcoin_node/bitcoin_node.dart` (the barrel) and instantiates the eight `*Impl` types. Barrel preserves the symbol set, so this file is invariant. |
| Any file under `packages/*/lib/`, `lib/`, `test/` that imports `package:bitcoin_node/src/...` directly | **Yes** if any exist | Research grep returned no such consumers outside `bitcoin_node/` itself. The implementer must re-run `grep -r "package:bitcoin_node/src/" packages/ lib/ test/` before edits to confirm; if any are found, rewrite each to the equivalent new subfolder path **or** to the public barrel. |
| Any file that imports `package:bitcoin_node/bitcoin_node.dart` | **No** | Barrel symbol set unchanged. |

### `pubspec.yaml`

No edit. `packages/bitcoin_node/pubspec.yaml` continues to declare exactly its
current path dependencies (`address`, `rpc_client`, `shared_kernel`,
`transaction`, `wallet`). The phase introduces no new package dependency edge.

---

## Interfaces And Contracts

No interface, no method signature, no class member, no exported symbol changes.
The phase commits to a strict invariance of the public surface:

```dart
// Before and after Phase 1, `package:bitcoin_node/bitcoin_node.dart`
// must export exactly these eight classes (and only these eight):
//   AddressRemoteDataSourceImpl
//   BlockGenerationDataSourceImpl
//   BroadcastDataSourceImpl
//   NodeTransactionDataSourceImpl
//   TransactionRemoteDataSourceImpl
//   UtxoRemoteDataSourceImpl
//   UtxoScanDataSourceImpl
//   WalletRemoteDataSourceImpl
//
// The three intra-package helpers must remain non-exported:
//   AddressTypeRpc        (extension)
//   AddressTypeRpcMapper
//   TransactionDirectionRpcMapper
```

---

## Sequencing

Two coherent batches. The implementer executes Batch 1, runs the file-relocation
checks, then executes Batch 2.

### Batch 1 — File relocation, intra-package import fixup, barrel rewrite

1. From repo root, run the pre-move snapshot grep for traceability:
   `grep -rn "package:bitcoin_node/src/" packages/ lib/ test/` — capture output;
   the post-move grep is compared against this baseline.
2. Create the five empty target subfolders under
   `packages/bitcoin_node/lib/src/`: `wallet/`, `address/`, `transaction/`,
   `utxo/`, `block/`.
3. Move the eleven files into their target subfolders per the table in
   **File Changes** (no content edits in this step beyond what the move tool
   itself produces).
4. Rewrite the public barrel `packages/bitcoin_node/lib/bitcoin_node.dart` to
   the eight `export` lines listed above. Confirm the three internal helpers
   are not added to the barrel.
5. Update the three intra-package `package:bitcoin_node/src/...` imports in
   the moved files (table in **File Changes**). After this step,
   `grep -r "package:bitcoin_node/src/" packages/bitcoin_node/lib/` must
   return only paths that include one of the five subfolders.
6. Run `flutter analyze --fatal-infos --fatal-warnings`. The analyzer must be
   green. If any error indicates a missed import, add it to the fixup list and
   re-run.

### Batch 2 — Cross-repo consumer sweep and verification

1. Run `grep -rn "package:bitcoin_node/src/" packages/ lib/ test/` again.
   Expected: only paths under one of the five subfolders, and only inside
   `packages/bitcoin_node/lib/src/`. If any consumer outside `bitcoin_node/`
   shows up, rewrite each to the new subfolder path; if such a consumer
   reaches into `src/` at all, prefer rewriting it to the public barrel
   (`package:bitcoin_node/bitcoin_node.dart`) per the PRD's negative scenario.
2. Run `find packages/bitcoin_node/lib/src/ -maxdepth 1 -name '*.dart'` —
   must be empty.
3. Run `ls packages/bitcoin_node/lib/src/` — must list exactly five entries:
   `address`, `block`, `transaction`, `utxo`, `wallet` (no `*.dart`).
4. Diff the public-export symbol set against the baseline (the eight class
   names listed in **Interfaces And Contracts**). Any drift fails the phase.
5. Run `dart pub deps` for `bitcoin_node`. Dependency graph must be unchanged
   versus baseline.
6. Run `/aidd-run-checks` — must exit 0, no warnings, no infos, no `skip:`
   markers added.
7. Update `docs/BW-0005/tasklist-BW-0005.md` Phase 1 row to reflect completion
   of the implementation tasks (1.1 through 1.5) and update the phase brief
   (`docs/BW-0005/phase/BW-0005/phase-1.md`) status line per the workflow
   gate (`TASKLIST_READY` → in-progress markers → completion handled by the
   `/aidd-complete-phase` command at end-of-phase, not by this batch).

---

## Error Handling And Edge Cases

- **Missed import → analyzer error.** The `flutter analyze` step at the end of
  Batch 1 is the catch-net for any forgotten internal import update. If
  analyzer reports an unresolved import after the move, locate the offending
  file, rewrite the import to the new subfolder path, and re-run analyzer.
  Do not move on until analyzer is green.
- **Mis-classified file.** If a file lands in the wrong subfolder (e.g., a
  transaction adapter under `wallet/`), the reviewer checklist catches it
  during review. The implementer must cross-reference each move against the
  table in **File Changes** before completing Batch 1; the mapping in that
  table is authoritative.
- **Direct `package:bitcoin_node/src/...` import from a non-`bitcoin_node`
  consumer.** Research found none today. If the Batch 2 grep surfaces one,
  prefer rewriting the consumer to the public barrel
  (`package:bitcoin_node/bitcoin_node.dart`) rather than to the new subfolder
  path — that aligns with the PRD's negative scenario and the convention that
  consumers must not import `src/` directly.
- **Barrel public surface drift.** The barrel rewrite must export exactly the
  same eight class names. If the diff in Batch 2 step 4 surfaces an extra
  symbol (most likely cause: accidentally exporting one of the three internal
  helpers), remove the offending `export` line and re-diff. If the diff
  surfaces a missing symbol, add the corresponding export line.
- **Test count change.** No test is added, removed, or marked `skip` in this
  phase. The pre-move and post-move test counts must match. If they differ,
  investigate immediately — a test file may have been moved or deleted by
  mistake, or a test may have been silently skipped by an unresolved import
  (analyzer would have flagged this earlier).
- **Hidden cycle exposed by reorganisation.** `dart pub deps` must show no
  new edges. The phase introduces no new package dependency, so a cycle is
  not expected; if one appears, stop and surface to the planner — it would
  indicate the move surfaced a previously-hidden cross-import.

---

## Checks

Run all of the following before declaring the phase complete. Order matters
within each batch (analyzer first, then test, then bespoke verification).

| # | Command / verification | Expected result |
|---|------------------------|-----------------|
| 1 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 |
| 2 | `flutter test` (or via `/aidd-run-checks`) | green; test count unchanged from baseline |
| 3 | `find packages/bitcoin_node/lib/src/ -maxdepth 1 -name '*.dart'` | no rows |
| 4 | `ls packages/bitcoin_node/lib/src/` | exactly `address  block  transaction  utxo  wallet` |
| 5 | `grep -rn "package:bitcoin_node/src/" packages/ lib/ test/` | only paths under one of the five subfolders, and only inside `packages/bitcoin_node/lib/src/` |
| 6 | Diff exported symbol set of `packages/bitcoin_node/lib/bitcoin_node.dart` against baseline | identical (eight `*Impl` class names; three helpers absent) |
| 7 | `dart pub deps` for `bitcoin_node` and the app | dependency graph unchanged |
| 8 | `/aidd-run-checks` | exit 0 |

Lane: Professional → no security-review artifact, no QA gate beyond
`/aidd-run-checks`. The phase closes through `/aidd-complete-phase` once all
of the above are green.

---

## Risks

- **Shared helper `address_type_rpc_mapper.dart` placed in `utxo/` is consumed
  from `transaction/`.** This crosses subfolder boundaries inside the same
  package, which `conventions.md` does not prohibit (intra-package imports
  are unrestricted). Recorded explicitly so the reviewer is aware. Alternative
  considered and rejected: introducing a top-level `shared/` subfolder in
  `bitcoin_node/lib/src/` for shared helpers — rejected because the file has
  exactly two consumers and both pass through the public adapter
  implementations; promoting it to a shared folder would over-engineer for a
  one-helper case.
- **Three known intra-package import sites must be updated in lockstep with
  the moves.** The Batch 1 step 5 grep is the verification; Batch 2 step 1
  is the cross-repo confirmation. Missing one surfaces as an analyzer error.
- **Public barrel symbol set is the only public-API contract for
  `bitcoin_node`.** The consumer (the composition-root file) is invariant
  only as long as the eight `*Impl` exports are preserved. Step 6 of the
  checks table is the hard gate.
- **No tests cover `bitcoin_node` directly.** Test mirroring is therefore
  not a Phase 1 concern, but it does mean that a regression introduced by
  the move can only be caught at the consumer level
  (`test/feature/...` integration tests). Reference-vector signing tests
  from BW-0003 should remain bit-identical because no code in the signing
  hot path is touched; if any reference-vector test fails, treat it as
  evidence of an unintended behavioural change and stop.
