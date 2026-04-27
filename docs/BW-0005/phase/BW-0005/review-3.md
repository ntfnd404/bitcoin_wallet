# Review: BW-0005 Phase 3

Status: `REVIEW_OK`
Ticket: BW-0005
Phase: 3
Lane: Critical
Date: 2026-04-26
Reviewer: reviewer agent

---

## Verdict

REVIEW_OK — all code and structural checks passed. No blocking findings.
One process deviation (DEV-1: checklist items 3.1–3.28 unticked) was corrected
before QA by the main session.

---

## Checklist

1. Folder layout — all required `hd/` and `node/` subfolders exist with correct files in `packages/wallet/`, `packages/transaction/`, `packages/address/` application layers. PASS.
2. Shared files at layer root — `broadcast_transaction_use_case.dart`, `get_transaction_detail_use_case.dart`, `get_transactions_use_case.dart`, `get_utxos_use_case.dart`, `scan_utxos_use_case.dart`, `address_generation_strategy.dart`, `generate_address_use_case.dart` all remain at layer roots. PASS.
3. Barrel exports — `wallet.dart`, `transaction.dart`, `address.dart` export correct `hd/` and `node/` paths; symbol sets match plan. PASS.
4. Assembly imports — `wallet_assembly.dart`, `transaction_assembly.dart`, `address_assembly.dart` import from correct `hd/` and `node/` sub-paths; no stale old paths. PASS.
5. DI wire integrity — `address_assembly.dart`: `HdAddressGenerationStrategy` receives `SeedRepository` + `KeyDerivationService`; `NodeAddressGenerationStrategy` receives `AddressRemoteDataSource`. No wire swap. PASS.
6. Internal imports in moved files — `prepare_hd_send_use_case.dart` imports `hd/hd_send_preparation.dart`; `send_hd_transaction_use_case.dart` imports `hd/hd_send_preparation.dart`; `prepare_node_send_use_case.dart` imports `node/node_send_preparation.dart`; `send_node_transaction_use_case.dart` imports `node/node_send_preparation.dart`. PASS.
7. Cross-trust boundary — no `hd/` file imports from `node/` and vice versa in any package. PASS.
8. Test relocation — `hd/create_hd_wallet_use_case_test.dart`, `hd/restore_hd_wallet_use_case_test.dart`, `node/create_node_wallet_use_case_test.dart` exist. Relative fixture imports use `../fakes/` and `../mocks/`. PASS.
9. Convention compliance — all reviewed files use `package:` imports only; no `print`, no `dynamic`, no new `!` null assertions. PASS.
10. HD-private metadata — `NodeAddressGenerationStrategy` does not read or write `derivationPath`. PASS.
