# Phase 3: HD/Node Subfolders by Trust Model

Status: `TASKLIST_READY`
Ticket: BW-0005
Phase: 3
Lane: Critical
Workflow Version: 3
Owner: Implementer
Goal: Introduce `hd/` and `node/` subfolders in `data/` and `application/` of `wallet/`, `transaction/`, `address/`; update all imports, barrels, and assemblies; verify cross-trust boundary; pass security gate.

Session brief — execution packet only. Do not repeat full architecture rationale here.

---

## Current Batch

Execute the four batches defined in the plan in order: A (wallet), B (address),
C (transaction), D (full suite + security gate). Complete each batch and run its
checks before starting the next.

Full file classification matrix, import changes, barrel edits, assembly edits,
test relocation, and grep commands are in `docs/BW-0005/plan/BW-0005-phase-3.md`.

---

## Constraints

- `domain/` layers of all three packages are not touched.
- `keys`, `bitcoin_node`, `storage`, `rpc_client`, `shared_kernel`, `ui_kit`
  packages are not touched.
- No behavioural change. No new use cases, repositories, or data sources.
- Public barrel symbol sets must be byte-equivalent before and after.
- All imports remain `package:`-style — never relative in `lib/src/`.
- Relative imports in test files are acceptable; verify they resolve after
  test relocation.
- No `print`, no `dynamic`, no `!` null assertion in any modified file.
- No test deleted, renamed away from its scenario, or marked `skip`.
- Test count must not drop.
- `flutter analyze --fatal-infos --fatal-warnings` must pass after each batch.

---

## Execution Checklist

### Batch A — `packages/wallet/`
- [x] 3.1 Create `packages/wallet/lib/src/application/hd/` and `node/`
- [x] 3.2 `git mv` the three application files into their new subfolders (HD: create + restore; Node: create)
- [x] 3.3 No internal import edits needed in the moved files (verified: no cross-application imports)
- [x] 3.4 Update `packages/wallet/lib/wallet.dart` — 3 export paths
- [x] 3.5 Update `packages/wallet/lib/wallet_assembly.dart` — 3 import paths
- [x] 3.6 Create `test/feature/wallet/domain/usecase/hd/` and `node/`; `git mv` three test files; fix any relative fixture imports (`../fakes/`, `../mocks/`)
- [x] 3.7 `flutter analyze --fatal-infos --fatal-warnings`
- [x] 3.8 `flutter test test/feature/wallet/`
- [x] 3.9 Cross-trust grep — wallet (must return zero rows)

### Batch B — `packages/address/`
- [x] 3.10 Create `packages/address/lib/src/application/hd/` and `node/`
- [x] 3.11 `git mv` the two strategy files (HD strategy → `hd/`; Node strategy → `node/`)
- [x] 3.12 Confirm imported `address_generation_strategy.dart` path is unchanged in both moved files (it stays at `application/` root)
- [x] 3.13 Update `packages/address/lib/address.dart` — 2 export paths
- [x] 3.14 Update `packages/address/lib/address_assembly.dart` — 2 import paths
- [x] 3.15 `generate_address_use_case_test.dart` stays in place (its source stays at root)
- [x] 3.16 `flutter analyze --fatal-infos --fatal-warnings`
- [x] 3.17 `flutter test test/feature/address/`
- [x] 3.18 Cross-trust grep — address (must return zero rows)

### Batch C — `packages/transaction/`
- [x] 3.19 Create `packages/transaction/lib/src/application/hd/` and `node/`
- [x] 3.20 `git mv` HD group: `prepare_hd_send_use_case.dart`, `hd_send_preparation.dart`, `send_hd_transaction_use_case.dart` → `application/hd/`
- [x] 3.21 `git mv` Node group: `prepare_node_send_use_case.dart`, `node_send_preparation.dart`, `send_node_transaction_use_case.dart` → `application/node/`
- [x] 3.22 Update internal imports in `prepare_hd_send_use_case.dart` and `send_hd_transaction_use_case.dart`: `hd_send_preparation.dart` path gains `hd/` segment
- [x] 3.23 Update internal imports in `prepare_node_send_use_case.dart` and `send_node_transaction_use_case.dart`: `node_send_preparation.dart` path gains `node/` segment
- [x] 3.24 Update `packages/transaction/lib/transaction.dart` — 6 export paths
- [x] 3.25 Update `packages/transaction/lib/transaction_assembly.dart` — read current file first, update all import paths for moved files (minimum 4 direct class imports; also check for any direct imports of `hd_send_preparation.dart` / `node_send_preparation.dart`)
- [x] 3.26 `flutter analyze --fatal-infos --fatal-warnings`
- [x] 3.27 `flutter test packages/transaction/test/` and `flutter test test/`
- [x] 3.28 Cross-trust grep — transaction (must return zero rows)

### Batch D — Full suite + security gate
- [x] 3.29 Full cross-trust grep (all three packages — see plan for all six commands)
- [x] 3.30 `flutter analyze --fatal-infos --fatal-warnings` (root)
- [x] 3.31 `flutter test` — all tests green; verify count not lower than baseline
- [x] 3.32 `flutter test packages/keys/test/` — BW-0003 reference-vector signing tests green
- [x] 3.33 `dart pub deps` for wallet, transaction, address — no new edges
- [x] 3.34 Verify folder layout: `ls packages/{wallet,transaction,address}/lib/src/application/` shows `hd/` and `node/`
- [x] 3.35 Diff barrel exported identifiers before/after (symbols unchanged)
- [x] 3.36 Author `docs/BW-0005/security/phase-3-security.md` (security-reviewer artifact — Critical-lane gate)
- [x] 3.37 Update `docs/BW-0005/tasklist-BW-0005.md` Phase 3 row to `✅ Done` after security review passes

---

## Stop Conditions

- architecture deviation
- blocker (e.g. unexpected cross-trust import discovered in existing code)
- risk discovery (e.g. a moved file imports from the opposing subfolder)
- batch complete

---

## Acceptance

- `packages/wallet/lib/src/application/` contains `hd/` and `node/` subfolders
- `packages/transaction/lib/src/application/` contains `hd/` and `node/` subfolders
- `packages/address/lib/src/application/` contains `hd/` and `node/` subfolders
- All six cross-trust greps return zero rows
- `flutter analyze --fatal-infos --fatal-warnings` exits 0
- `flutter test` exits 0; test count not lower than pre-phase baseline
- `flutter test packages/keys/test/` exits 0; BW-0003 reference vectors bit-identical
- `dart pub deps` clean for modified packages
- Barrel symbol sets identical before and after
- `docs/BW-0005/security/phase-3-security.md` exists and covers all eight
  security checklist items from the plan
