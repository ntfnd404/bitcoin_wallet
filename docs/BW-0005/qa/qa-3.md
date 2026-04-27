# QA: BW-0005 Phase 3 — HD/Node Subfolders by Trust Model

Status: `QA_PASS`
Ticket: BW-0005
Phase: 3
Lane: Critical
Workflow Version: 3
Owner: QA
Date: 2026-04-26

---

## Scope

Structural split of `application/` layers in `packages/wallet/`, `packages/transaction/`,
and `packages/address/` into `hd/` and `node/` subfolders. Covers file placement,
barrel exports, assembly imports, internal import paths, test relocation, cross-trust
boundary integrity, and Critical-lane security gate.

Out of scope: `domain/` layer changes, `keys` package, any behavioural change.

---

## Positive Scenarios (PS)

- [x] PS-1: `packages/wallet/lib/src/application/hd/` contains `create_hd_wallet_use_case.dart` and `restore_hd_wallet_use_case.dart`; `node/` contains `create_node_wallet_use_case.dart`. All three files verified on disk.
- [x] PS-2: `packages/transaction/lib/src/application/hd/` contains `prepare_hd_send_use_case.dart`, `hd_send_preparation.dart`, `send_hd_transaction_use_case.dart`; `node/` contains the three node counterparts. All six files verified on disk.
- [x] PS-3: `packages/address/lib/src/application/hd/` contains `hd_address_generation_strategy.dart`; `node/` contains `node_address_generation_strategy.dart`. Both verified on disk.
- [x] PS-4: Shared files remain at layer root: `broadcast_transaction_use_case.dart`, `scan_utxos_use_case.dart`, `address_generation_strategy.dart`, `generate_address_use_case.dart` — all verified in place.
- [x] PS-5: `packages/wallet/lib/wallet.dart` exports `hd/create_hd_wallet_use_case.dart`, `hd/restore_hd_wallet_use_case.dart`, `node/create_node_wallet_use_case.dart`.
- [x] PS-6: `packages/transaction/lib/transaction.dart` exports all 6 moved files at correct `hd/` and `node/` paths plus 5 unchanged shared exports.
- [x] PS-7: `packages/address/lib/address.dart` exports `hd/hd_address_generation_strategy.dart` and `node/node_address_generation_strategy.dart`.
- [x] PS-8: `prepare_hd_send_use_case.dart` imports `package:transaction/src/application/hd/hd_send_preparation.dart` (line 2) — path updated correctly.
- [x] PS-9: `send_hd_transaction_use_case.dart` imports `package:transaction/src/application/hd/hd_send_preparation.dart` (line 2) — correct.
- [x] PS-10: `prepare_node_send_use_case.dart` imports `package:transaction/src/application/node/node_send_preparation.dart` (line 2) — correct.
- [x] PS-11: `send_node_transaction_use_case.dart` imports `package:transaction/src/application/node/node_send_preparation.dart` (line 2) — correct.

---

## Negative / Edge Scenarios (NE)

- [x] NE-1: Cross-trust boundary — `hd/create_hd_wallet_use_case.dart` imports only `package:keys/`, `package:uuid/`, `package:wallet/src/domain/`. No `node/` path present.
- [x] NE-2: Cross-trust boundary — `node/create_node_wallet_use_case.dart` imports only `package:wallet/src/domain/`. No `hd/` path present.
- [x] NE-3: Cross-trust boundary — `node/node_address_generation_strategy.dart` imports `address_generation_strategy.dart` (root, shared interface), `address_remote_data_source.dart`, `address_repository.dart`. No `hd/` path. No `derivationPath` field read or written.
- [x] NE-4: Cross-trust boundary — `hd/hd_address_generation_strategy.dart` imports `address_generation_strategy.dart` (root), `keys`, `shared_kernel`, `wallet`. No `node/` path.
- [x] NE-5: Shared orchestrators (`broadcast_transaction_use_case.dart`, `scan_utxos_use_case.dart`, `address_generation_strategy.dart`, `generate_address_use_case.dart`) were NOT moved into any subfolder — correctly left at layer root.
- [x] NE-6: No new `!` null assertions, `print`, or `dynamic` found in any verified moved file.

---

## Manual Checks (MC)

- [x] MC-1: Test relocation — `test/feature/wallet/domain/usecase/hd/create_hd_wallet_use_case_test.dart` exists; relative fixture imports use `../fakes/` and `../mocks/` (resolves one level up to `usecase/fakes/`).
- [x] MC-2: Test relocation — `test/feature/wallet/domain/usecase/hd/restore_hd_wallet_use_case_test.dart` exists; same relative import pattern verified.
- [x] MC-3: Test relocation — `test/feature/wallet/domain/usecase/node/create_node_wallet_use_case_test.dart` exists; relative imports use `../mocks/`.
- [x] MC-4: Security artifact `docs/BW-0005/security/phase-3-security.md` exists with `Status: SECURITY_REVIEW_PASS` and all 8 checklist items ticked.
- [x] MC-5: Phase checklist items 3.1–3.36 all marked `[x]` in `docs/BW-0005/phase/BW-0005/phase-3.md`.

---

## Implementation Verification (IV)

- [x] IV-1: All imports in moved files are `package:`-style. No relative imports found in `lib/src/`.
- [x] IV-2: No `print`, `dynamic`, or `!` null assertions in any of the 11 moved files.
- [x] IV-3: `hd/` files import no `node/` paths within the same package. `node/` files import no `hd/` paths within the same package. Verified by reading all 11 moved files.
- [x] IV-4: Security gate: `SECURITY_REVIEW_PASS` at `docs/BW-0005/security/phase-3-security.md`; all 8 items: cross-trust import check, HD signing flow, no HD metadata in node code, no logging of private material, DI wire integrity, app-side adapter boundary, reference-vector signing tests, keys package untouched.
- [x] IV-5: Phase checklist 3.1–3.36 complete (verified in phase-3.md). Item 3.37 closed by this QA pass.

---

## PRD Exit Criteria

| Criterion | Status |
|-----------|--------|
| `application/hd/` and `application/node/` exist in all three packages | Pass |
| No HD file imports from `node/` subfolder within same package | Pass |
| No Node file imports from `hd/` subfolder within same package | Pass |
| Public barrels export identical symbol sets (paths updated, symbols preserved) | Pass |
| Shared (trust-agnostic) files remain at layer root | Pass |
| Internal imports updated to new `hd/`/`node/` paths | Pass |
| Test files relocated to mirror source structure; relative imports updated | Pass |
| No `print`, `dynamic`, `!` in modified files | Pass |
| `domain/` layers of all three packages unchanged | Pass |
| Security-reviewer artifact at `docs/BW-0005/security/phase-3-security.md` | Pass |

---

## Scenario Table

| Scenario | Result | Notes |
|----------|--------|-------|
| S1: HD subfolders exist with correct files | Pass | All 11 moved files verified on disk |
| S2: Shared files remain at layer roots | Pass | 4 files confirmed at application/ root |
| S3: Barrel exports correct paths | Pass | All 3 barrels verified |
| S4: Internal imports updated | Pass | 4 files verified; `hd/` and `node/` path segments correct |
| S5: Cross-trust boundary | Pass | No `node/` in `hd/` files; no `hd/` in `node/` files across all 3 packages |
| S6: Test relocation | Pass | 3 test files in `hd/`/`node/` subfolders; relative imports use `../fakes/` and `../mocks/` |
| S7: Security gates closed | Pass | `SECURITY_REVIEW_PASS`; all 8 items ticked |
| S8: Conventions in moved files | Pass | `package:` imports only; no `print`, `dynamic`, `!` |
| S9: Phase checklist complete | Pass | Items 3.1–3.36 all `[x]`; item 3.37 closed by this record |

---

## Evidence

- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/wallet/lib/src/application/hd/create_hd_wallet_use_case.dart`
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/wallet/lib/src/application/node/create_node_wallet_use_case.dart`
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/application/hd/prepare_hd_send_use_case.dart` (line 2: `hd/hd_send_preparation.dart`)
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/application/node/prepare_node_send_use_case.dart` (line 2: `node/node_send_preparation.dart`)
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/lib/src/application/node/node_address_generation_strategy.dart` (no `derivationPath`, no `hd/` import)
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/wallet/lib/wallet.dart`
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/transaction.dart`
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/lib/address.dart`
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/test/feature/wallet/domain/usecase/hd/create_hd_wallet_use_case_test.dart`
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/BW-0005/security/phase-3-security.md`

---

## Verdict

`QA_PASS`

Issues: None
