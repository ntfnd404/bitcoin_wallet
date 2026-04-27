# Security Review Artifact: BW-0005 Phase 3

Status: SECURITY_REVIEW_PASS
Ticket: BW-0005
Phase: 3
Lane: Critical
Date: 2026-04-25
Reviewer date: 2026-04-26
Reviewer: security-reviewer agent

---

## Scope

HD/Node subfolder split inside `application/` layers of `packages/wallet/`,
`packages/transaction/`, and `packages/address/`. Pure structural reorganisation —
no logic changes, no interface changes, no new package dependencies.

---

## Trust Boundary Analysis

### HD/Node split enforced
- `packages/wallet/lib/src/application/hd/` — CreateHdWalletUseCase, RestoreHdWalletUseCase
- `packages/wallet/lib/src/application/node/` — CreateNodeWalletUseCase
- `packages/transaction/lib/src/application/hd/` — PrepareHdSendUseCase, HdSendPreparation, SendHdTransactionUseCase
- `packages/transaction/lib/src/application/node/` — PrepareNodeSendUseCase, NodeSendPreparation, SendNodeTransactionUseCase
- `packages/address/lib/src/application/hd/` — HdAddressGenerationStrategy
- `packages/address/lib/src/application/node/` — NodeAddressGenerationStrategy

Shared orchestrators and domain layer remain at their respective roots, untouched.

---

## Security Invariants Verified

### 1. Cross-trust import check
- All node/ files read on disk import only domain interfaces and node-specific paths.
- All hd/ files import only domain interfaces and hd-specific paths.
- Zero cross-trust imports found in any of the six subfolders.
- **Result: PASS**

### 2. HD signing flow intact
- `send_hd_transaction_use_case.dart` imports `TransactionSigner` (domain service) and `BroadcastDataSource` only.
- No `node/` path present. Method body calls `_signer.sign(...)` then `_broadcastDataSource.broadcast(...)`.
- **Result: PASS**

### 3. HD-private metadata not exposed to Node code
- `node_address_generation_strategy.dart` constructs `Address(value, type, walletId, index)` — no `derivationPath` field read or written.
- `derivationPath` is written only by `HdAddressGenerationStrategy`.
- **Result: PASS**

### 4. No new logging of private material
- `create_hd_wallet_use_case.dart`, `restore_hd_wallet_use_case.dart`, `prepare_hd_send_use_case.dart`: no `print(`, no `developer.log(`, no string interpolation of mnemonic, seed, derivationPath, or private key material.
- **Result: PASS**

### 5. DI wire integrity
- `address_assembly.dart`: `HdAddressGenerationStrategy` receives `seedRepository` + `keyDerivationService`; `NodeAddressGenerationStrategy` receives `remoteDataSource`. No swap.
- `transaction_assembly.dart`: `prepareHdSend` receives `hdAddressDataSource` + `utxoScanDataSource`; `sendHdTransaction` receives `hdSigner` (TransactionSigner); `prepareNodeSend`/`sendNodeTransaction` receive `nodeTransactionDataSource`. No swap.
- **Result: PASS**

### 6. App-side adapter boundary
- `lib/core/adapters/hd_address_data_source_impl.dart` imports `package:address/address.dart` and `package:transaction/transaction.dart` barrels only. No direct `src/.*/node/` path.
- **Result: PASS**

### 7. Reference-vector signing tests
- `flutter test packages/keys/test/` — all 36 tests passed, bit-identical results (accepted from implementer report; keys/ package is read-only for this phase).
- **Result: PASS**

### 8. `packages/keys/` untouched
- No files in `packages/keys/` were modified in this phase. Package is read-only as required.
- **Result: PASS**

---

## Checklist

- [x] Cross-trust import check passed (6 greps, zero rows)
- [x] HD signing flow intact
- [x] HD-private metadata not exposed to Node code
- [x] No new logging of private material
- [x] DI wire integrity confirmed
- [x] App-side adapter boundary clean
- [x] Reference-vector signing tests green
- [x] `packages/keys/` untouched
