# Research: BW-0005 Phase 3 — HD/Node Subfolders by Trust Model

Status: `RESEARCH_DONE`
Ticket: BW-0005
Phase: 3
Lane: Critical
Workflow Version: 3
Owner: Researcher

---

## Codebase Facts

Phase 3 splits **only** `data/` and `application/` into `hd/` / `node/`
subfolders inside `wallet/`, `transaction/`, `address/`. `domain/` layers
stay shared (resolved 2026-04-25 in PRD §Open Questions). The
classification below is the per-file evidence the planner needs.

### `packages/wallet/lib/src/`

`application/` files (3):

| Absolute path | Trust tag | Evidence |
|---|---|---|
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/wallet/lib/src/application/create_hd_wallet_use_case.dart` | HD-only | depends on `Bip39Service`, `SeedRepository`, `HdWalletRepository`; produces `HdWallet` + `Mnemonic` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/wallet/lib/src/application/restore_hd_wallet_use_case.dart` | HD-only | restores from `Mnemonic`; uses HD-only ports |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/wallet/lib/src/application/create_node_wallet_use_case.dart` | Node-only | delegates to `NodeWalletRepository.createNodeWallet` (Bitcoin Core call) |

`data/` files (3):

| Absolute path | Trust tag | Evidence |
|---|---|---|
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/wallet/lib/src/data/wallet_repository_impl.dart` | **shared (orchestrates both)** | Class `WalletRepositoryImpl implements NodeWalletRepository, HdWalletRepository` — single object handles both trust models. `createNodeWallet` calls `WalletRemoteDataSource`; `saveWallet(HdWallet)` is local-only |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/wallet/lib/src/data/wallet_local_data_source_impl.dart` | shared | persists both `HdWallet` and `NodeWallet` to a single JSON array (the same `_key = 'wallets'`) |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/wallet/lib/src/data/wallet_mapper.dart` | shared | switch on sealed `Wallet` covering both subtypes |

Ambiguity: `WalletRepositoryImpl` implements two contracts. Per PRD
Negative scenario "A use case that orchestrates **both** HD and Node
concerns is classified into one subfolder, creating a forbidden
cross-trust import: such a file must remain at the `application/` layer
root (trust-agnostic)." Same rule applies to `data/`. **Recommended
classification: keep all three `data/` files at `data/` root**, since
splitting `WalletRepositoryImpl` requires either two implementations or a
domain-level repository interface split that is out of scope.

### `packages/transaction/lib/src/`

`application/` files (11):

| Absolute path | Trust tag | Evidence |
|---|---|---|
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/application/prepare_hd_send_use_case.dart` | HD-only | depends on `HdAddressDataSource`, `UtxoScanDataSource` (HD path) |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/application/hd_send_preparation.dart` | HD-only | data class returned by `PrepareHdSendUseCase` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/application/send_hd_transaction_use_case.dart` | HD-only | depends on `TransactionSigner`, consumes `HdSendPreparation` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/application/prepare_node_send_use_case.dart` | Node-only | depends on `UtxoRepository`, `NodeTransactionDataSource` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/application/node_send_preparation.dart` | Node-only | data class returned by `PrepareNodeSendUseCase` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/application/send_node_transaction_use_case.dart` | Node-only | depends on `NodeTransactionDataSource` (Core-side signing) |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/application/broadcast_transaction_use_case.dart` | shared | consumes only `BroadcastDataSource` (no wallet) |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/application/get_transaction_detail_use_case.dart` | shared | reads from `TransactionRepository` only |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/application/get_transactions_use_case.dart` | shared | reads from `TransactionRepository` only |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/application/get_utxos_use_case.dart` | shared | reads from `UtxoRepository` only (works for either trust model) |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/application/scan_utxos_use_case.dart` | shared (HD-leaning) | wraps `UtxoScanDataSource.scanForAddresses`. Today only the HD flow scans by addresses, but the contract itself is trust-agnostic. Planner decision required — see Risks |

`data/` files (2):

| Absolute path | Trust tag | Evidence |
|---|---|---|
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/data/transaction_repository_impl.dart` | shared | wraps `TransactionRemoteDataSource`; trust-agnostic |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/data/utxo_repository_impl.dart` | shared | wraps `UtxoRepository`; trust-agnostic |

`data/` has no HD-only or Node-only file today. Phase 3 will create `hd/`
and `node/` subfolders only if a future implementation needs them; the
PRD permits keeping shared files at the `data/` root.

### `packages/address/lib/src/`

`application/` files (4):

| Absolute path | Trust tag | Evidence |
|---|---|---|
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/lib/src/application/hd_address_generation_strategy.dart` | HD-only | `supports(Wallet w) => w is HdWallet`; uses `SeedRepository`, `KeyDerivationService` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/lib/src/application/node_address_generation_strategy.dart` | Node-only | `supports(Wallet w) => w is NodeWallet`; uses `AddressRemoteDataSource` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/lib/src/application/address_generation_strategy.dart` | shared (interface) | trust-agnostic interface; both strategies implement it |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/lib/src/application/generate_address_use_case.dart` | shared (orchestrator) | dispatches via `firstWhere((s) => s.supports(wallet))`; depends on the interface, not on either strategy directly — Strategy pattern |

`data/` files (3):

| Absolute path | Trust tag | Evidence |
|---|---|---|
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/lib/src/data/address_repository_impl.dart` | shared | trust-agnostic CRUD over `AddressLocalDataSource` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/lib/src/data/address_local_data_source_impl.dart` | shared | persists both HD and Node addresses (one JSON list per `walletId`) |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/lib/src/data/address_mapper.dart` | shared | maps `Address`, including optional `derivationPath` |

`data/` has no HD-only or Node-only file. Same rule: keep at `data/` root,
create subfolders only as new trust-specific impls land.

### Public barrels (must keep symbol set byte-equivalent)

- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/wallet/lib/wallet.dart` — exports three application files
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/transaction.dart` — exports nine application files
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/lib/address.dart` — exports four application files

Each export path will change (e.g.
`src/application/create_hd_wallet_use_case.dart` →
`src/application/hd/create_hd_wallet_use_case.dart`); each exported
identifier must remain the same.

### DI assembly registration sites

`/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/wallet/lib/wallet_assembly.dart`
imports four `src/application/...` paths and three `src/data/...` paths.
Each will need its import path updated if the corresponding source file
moves into `hd/`, `node/`, or stays at root. Public symbol set is
unchanged (`WalletAssembly`, `walletRepository`, `createNodeWallet`,
`createHdWallet`, `restoreHdWallet`).

`/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/transaction_assembly.dart`
imports nine `src/application/...` paths and two `src/data/...` paths.
Each HD/Node-classified file changes import path. Public symbols
unchanged (eleven fields on `TransactionAssembly`).

`/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/lib/address_assembly.dart`
imports four `src/application/...` paths and three `src/data/...` paths.
HD and Node strategies move to subfolders; the orchestrator and the
interface stay at root. Public symbols unchanged
(`AddressAssembly`, `addressRepository`, `generateAddress`).

### App-side adapters and feature scope

- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/lib/core/adapters/hd_address_data_source_impl.dart`
  imports `package:address/address.dart` and `package:transaction/transaction.dart`
  (both via barrels). No deep `src/...` import. Phase 3 requires no edit
  here as long as barrel symbols are preserved.
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/lib/core/adapters/hd_transaction_signer.dart`
  imports the same two barrels plus `package:keys/keys.dart` and
  `package:shared_kernel/shared_kernel.dart`. No deep import. Phase 3
  requires no edit here.
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/lib/feature/send/di/send_scope.dart`
  branches on `wallet is NodeWallet` vs HD and wires
  `prepareNode/sendNode` or `prepareHd/sendHd` from
  `AppDependencies.transaction` (`TransactionAssembly`). No deep import.
  Phase 3 requires no edit here.

### Test mirror state

Existing tests under `test/feature/wallet/domain/usecase/`:

- `create_hd_wallet_use_case_test.dart`
- `create_node_wallet_use_case_test.dart`
- `restore_hd_wallet_use_case_test.dart`
- `fakes/`, `mocks/` shared fixtures

Existing tests under `test/feature/address/domain/usecase/`:

- `generate_address_use_case_test.dart`
- `fakes/`, `mocks/`

`packages/transaction/test/transaction_test.dart` — only domain entity
tests; no application-layer tests.

Per `guidelines.md`: tests must mirror source structure. If
`create_hd_wallet_use_case.dart` moves to `application/hd/`, the test
should move to `test/feature/wallet/domain/usecase/hd/` (or per the
planner's chosen scheme). The existing `test/feature/...` mirror is
labelled "feature" but the contents are use-case tests imported via
package barrels — symbol set is unaffected, only directory placement.

---

## External Facts

- `dart pub deps` for each modified package must show no new edges
  introduced by the move.
- The `keys` package is untouched. Trust-model separation inside `keys/`
  is out of scope for Phase 3.
- The `bitcoin_node` package will already be split by consumer module
  after Phase 1; its layout is not re-touched.

---

## Risks

| Risk | Impact | Recommendation |
|------|--------|----------------|
| `WalletRepositoryImpl` implements both `HdWalletRepository` and `NodeWalletRepository` — placing it in either subfolder creates a forbidden cross-trust import | Refactor blocker | Keep `wallet_repository_impl.dart` at `data/` root; document classification in plan |
| `scan_utxos_use_case.dart` is contract-shared but only HD callers exist today | Future Node use of `scantxoutset` could not import without crossing into `hd/` | Keep at `application/` root; revisit if a Node consumer of `scantxoutset` lands |
| Barrel re-export path changes typo'd (e.g. `src/application/create_hd_wallet_use_case.dart` not updated to `src/application/hd/...`) | Symbol disappears, compile error | Diff `dart analyze` after each barrel touch; run after every package |
| HD code in one package importing from `node/` of the **same** package (the security boundary the phase introduces) | Trust-model leak | Greppable check listed in Phase 3 PRD success metrics; reviewer must run `grep -r "src/application/node/" packages/wallet/lib/src/application/hd/` and equivalents and confirm zero matches |
| Cross-package HD↔Node imports (e.g. `transaction/application/hd/` importing `address/application/node/`) | Subtler trust leak across package boundaries | Add same greppable check across packages: `grep -rn "src/.*/node/" packages/*/lib/src/.*/hd/` returns no rows |
| `HdAddressDataSourceImpl` adapter at `lib/core/adapters/hd_address_data_source_impl.dart` already bridges `address` storage to `transaction` HD code — it is HD-only by name. After Phase 3 it must not also bridge any Node path | Adapter pollution | Phase 3 PRD Negative scenario explicitly forbids it; security review verifies the adapter touches only `hd/` consumers |
| Test relocation in lockstep — moving a use case to `hd/` without moving the test to `test/feature/.../hd/` breaks the `guidelines.md` mirror rule | Test discovery drift | Plan must list test-move alongside source-move for each batch |
| DI assembly silently swaps an HD wire for a Node wire during the import-path edit | Runtime regression on signing path | Reference-vector signing tests catch behavioural drift; the assembly-class symbol set cross-check catches structural drift |

---

## Design Pressure

### Security-sensitive data paths

- HD signing context (seed, derived keys, derivation paths) lives in
  `packages/keys/`. The Phase 3 split must not create any new call site
  outside `hd/` subfolders that touches HD-private inputs.
- The full HD signing flow today runs through:
  `packages/transaction/lib/src/application/prepare_hd_send_use_case.dart`
  → `packages/transaction/lib/src/application/send_hd_transaction_use_case.dart`
  → `lib/core/adapters/hd_transaction_signer.dart`
  → `packages/keys/lib/src/application/sign_transaction_use_case.dart`.
  After Phase 3, the first two move to `application/hd/`; the adapter
  and `keys/` code remain at their current paths.
- `Address.derivationPath` (HD metadata, non-secret but linkable) is
  populated by `hd_address_generation_strategy.dart` (moves to
  `application/hd/` of `address/`) and read only by `keys/`. The Node
  strategy never touches it. The Phase 3 split makes this structural.

### Trust boundaries

- The new `hd/` vs `node/` boundary is the security invariant being
  introduced. Today it is review-only; after Phase 3 it is greppable.
- What must NOT cross after Phase 3:
  - Any file under `packages/<pkg>/lib/src/application/hd/` importing
    from `packages/<pkg>/lib/src/application/node/` and vice versa.
  - Same rule for `data/hd/` and `data/node/`.
  - `node/` subfolders importing HD-private metadata
    (`Address.derivationPath`, mnemonic, derived keys, xpubs).
  - `hd/` subfolders importing Node-only RPC (`NodeTransactionDataSource`,
    `WalletRemoteDataSource`).
- DI registrations are part of the security surface. Wiring an HD
  implementation into a Node use case (or vice versa) is a regression
  even if the symbol set is preserved. Reference-vector signing tests
  are the primary detector.

### Open architectural decisions (potential ADR follow-ups)

- The vision document already recommends an ADR codifying "HD vs Node =
  subfolders inside the same business package, not separate workspace
  packages." Phase 3 is the phase that operationalises that decision and
  is therefore the natural reference for the ADR's "Status: Accepted"
  evidence.
- A second potential ADR: "Shared (trust-agnostic) `data/` and
  `application/` files stay at the layer root, not duplicated into both
  subfolders." This is the rule the PRD enforces; an ADR makes it
  durable.
- Whether to add a `dart_code_metrics` rule (or a custom lint) to enforce
  the cross-trust-import ban after Phase 3 ships. PRD Out-of-Scope
  excludes this from Phase 3; it is a follow-up ticket.

---

## References

- Phase 3 PRD: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/BW-0005/prd/BW-0005-phase-3.prd.md`
- Architecture rules: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/project/conventions.md`
- Test mirror rule: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/project/guidelines.md` §Testing
- Sealed wallet entity: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/wallet/lib/src/domain/entity/wallet.dart` (with parts `hd_wallet.dart`, `node_wallet.dart`)
- Address entity (carries `derivationPath?`): `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/lib/src/domain/entity/address.dart`
- App-side wiring: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/lib/core/di/app_dependencies_builder.dart`, `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/lib/feature/send/di/send_scope.dart`
- Recommended verification commands the implementer should run:
  - `ls packages/wallet/lib/src/application/` → contains `hd/`, `node/`
  - `ls packages/transaction/lib/src/application/` → contains `hd/`, `node/`
  - `ls packages/address/lib/src/application/` → contains `hd/`, `node/`
  - `grep -rn "src/.*/node/" packages/wallet/lib/src/application/hd/ packages/transaction/lib/src/application/hd/ packages/address/lib/src/application/hd/` → empty
  - `grep -rn "src/.*/hd/" packages/wallet/lib/src/application/node/ packages/transaction/lib/src/application/node/ packages/address/lib/src/application/node/` → empty
  - `flutter analyze --fatal-infos --fatal-warnings` → exit 0
  - `flutter test` → green; test count not lower than baseline
  - `flutter test packages/keys/test/` → BW-0003 reference vectors bit-identical
