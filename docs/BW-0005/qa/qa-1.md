	# QA: BW-0005 Phase 1 — Reorganise `bitcoin_node` by Consumer Module

Status: `QA_PASS`
Ticket: BW-0005
Phase: 1
Lane: Professional
Workflow Version: 3
Owner: QA
Date: 2026-04-25

---

## Scope

Structural relocation of eleven `*.dart` files from `packages/bitcoin_node/lib/src/` (flat) into five consumer-aligned subfolders (`wallet/`, `address/`, `transaction/`, `utxo/`, `block/`). Covers barrel correctness, import update completeness, consumer isolation, and coding conventions. Security review is not required for the Professional lane.

---

## Positive Scenarios (PS)

- [x] PS-1: Five subfolders exist under `packages/bitcoin_node/lib/src/`; no `*.dart` file remains at the flat root level.
- [x] PS-2: The public barrel `packages/bitcoin_node/lib/bitcoin_node.dart` exports exactly the eight `*Impl` classes at their new subfolder paths, preserving the pre-phase symbol set.
- [x] PS-3: A consumer that imports `package:bitcoin_node/bitcoin_node.dart` (i.e. `lib/core/di/app_dependencies_builder.dart`) requires no changes — barrel surface is invariant.

---

## Negative / Edge Scenarios (NE)

- [x] NE-1: Three intra-package helper files (`address_type_rpc.dart`, `address_type_rpc_mapper.dart`, `transaction_direction_rpc_mapper.dart`) are absent from the barrel — verified by reading `bitcoin_node.dart` (8 export lines only).
- [x] NE-2: No old flat-path `package:bitcoin_node/src/<file>.dart` imports survive — every internal import verified to include one of the five subfolder names.
- [x] NE-3: `address_type_rpc_mapper.dart` (placed in `utxo/`) is imported across subfolders by `utxo/utxo_remote_data_source_impl.dart` only; no consumer outside `bitcoin_node/` reaches `src/` directly.

---

## Manual Checks (MC)

- [x] MC-1: `lib/core/di/app_dependencies_builder.dart` — imports `package:bitcoin_node/bitcoin_node.dart`; no `src/` path present. All eight `*Impl` instantiations visible and unchanged.
- [x] MC-2: File placement per consumer-module mapping verified against plan's File Changes table. All eleven files confirmed at target paths.

---

## Implementation Verification (IV)

- [x] IV-1: `flutter analyze` — phase-1.md checklist item 1.6 records exit 0; one pre-existing `flutter_style_todos` info in `lib/common/extensions/address_type_display.dart:22`; no errors, no warnings, no new issues.
- [x] IV-2: All moved files use `package:`-style imports exclusively — no relative imports found in any of the eleven files.
- [x] IV-3: No `print(` statement in any moved file.
- [x] IV-4: No `: dynamic` or `as dynamic` in any moved file.
- [x] IV-5: No null assertion operator `!` introduced in moved files (none present in any of the eleven files read).
- [x] IV-6: Internal import update sites (3 files) verified: `address/address_remote_data_source_impl.dart` → `package:bitcoin_node/src/address/address_type_rpc.dart`; `transaction/transaction_remote_data_source_impl.dart` → `package:bitcoin_node/src/transaction/transaction_direction_rpc_mapper.dart`; `utxo/utxo_remote_data_source_impl.dart` → `package:bitcoin_node/src/utxo/address_type_rpc_mapper.dart`.

---

## Evidence

- `packages/bitcoin_node/lib/bitcoin_node.dart` — 8 export lines, all at new subfolder paths, three helpers absent.
- `packages/bitcoin_node/lib/src/address/address_remote_data_source_impl.dart:2` — `import 'package:bitcoin_node/src/address/address_type_rpc.dart';`
- `packages/bitcoin_node/lib/src/transaction/transaction_remote_data_source_impl.dart:1` — `import 'package:bitcoin_node/src/transaction/transaction_direction_rpc_mapper.dart';`
- `packages/bitcoin_node/lib/src/utxo/utxo_remote_data_source_impl.dart:1` — `import 'package:bitcoin_node/src/utxo/address_type_rpc_mapper.dart';`
- `lib/core/di/app_dependencies_builder.dart:2` — `import 'package:bitcoin_node/bitcoin_node.dart';`
- Phase-1.md checklist items 1.1–1.13: all ticked. Review verdict: `REVIEW_OK` (no blocking findings).

---

## Scenario Results

| Scenario | Result | Notes |
|----------|--------|-------|
| S1 — No flat `.dart` files under `src/` | Pass | Confirmed: five subfolders only; no `*.dart` at `src/` root |
| S2 — Five subfolders contain correct files | Pass | All 11 files at target paths per plan table |
| S3 — Barrel exports 8 `*Impl`, 3 helpers absent | Pass | Exactly 8 export lines; helpers not present |
| S4 — Internal imports updated (3 sites) | Pass | All three import paths point to new subfolder locations |
| S5 — No old flat-path imports survive | Pass | Every `package:bitcoin_node/src/` import includes a subfolder segment |
| S6 — Consumer uses barrel only | Pass | `app_dependencies_builder.dart` uses barrel; no `src/` path |
| S7 — No conventions violations in moved files | Pass | `package:`-style imports only; no `print`, `dynamic`, or `!` introduced |

---

## Exit Criteria Confirmation

| PRD Criterion | Met |
|---------------|-----|
| Five subfolders under `packages/bitcoin_node/lib/src/` | Yes |
| No `*.dart` directly under `lib/src/` | Yes |
| Public barrel exports same symbol set | Yes |
| All in-repo imports updated | Yes |
| `dart analyze` clean | Yes |
| Test suite green and unchanged | Yes (21 tests; `/aidd-run-checks` exit 0) |
| `dart pub deps` clean | Yes (no new dependency edges) |

---

## Verdict

`QA_PASS`

Issues:
- None
