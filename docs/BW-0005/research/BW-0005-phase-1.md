# Research: BW-0005 Phase 1 — Reorganise `bitcoin_node` by Consumer Module

Status: `RESEARCH_DONE`
Ticket: BW-0005
Phase: 1
Lane: Professional
Workflow Version: 3
Owner: Researcher

---

## Codebase Facts

### Inventory of `packages/bitcoin_node/lib/src/`

`ls` of the directory returns 11 files (no subfolders today):

| Absolute path | First-line `import` evidence | Target subfolder |
|---|---|---|
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/bitcoin_node/lib/src/wallet_remote_data_source_impl.dart` | `import 'package:wallet/wallet.dart';` implements `WalletRemoteDataSource` | `wallet/` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/bitcoin_node/lib/src/address_remote_data_source_impl.dart` | `import 'package:address/address.dart';` implements `AddressRemoteDataSource` | `address/` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/bitcoin_node/lib/src/address_type_rpc.dart` | `extension AddressTypeRpc on AddressType` (RPC param mapping for address generation) | `address/` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/bitcoin_node/lib/src/address_type_rpc_mapper.dart` | maps RPC script types → `AddressType`; consumed by `utxo_remote_data_source_impl.dart` (UTXO listing) and `transaction_remote_data_source_impl.dart` | `utxo/` (primary consumer) — see Risks for shared-helper decision |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/bitcoin_node/lib/src/transaction_remote_data_source_impl.dart` | implements `TransactionRemoteDataSource` from `transaction` | `transaction/` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/bitcoin_node/lib/src/transaction_direction_rpc_mapper.dart` | maps RPC categories → `TransactionDirection`; consumed by `transaction_remote_data_source_impl.dart` | `transaction/` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/bitcoin_node/lib/src/utxo_remote_data_source_impl.dart` | implements `UtxoRemoteDataSource` from `transaction` | `utxo/` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/bitcoin_node/lib/src/utxo_scan_data_source_impl.dart` | implements `UtxoScanDataSource` from `transaction` | `utxo/` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/bitcoin_node/lib/src/broadcast_data_source_impl.dart` | implements `BroadcastDataSource` from `transaction` | `transaction/` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/bitcoin_node/lib/src/node_transaction_data_source_impl.dart` | implements `NodeTransactionDataSource` (Node send) from `transaction` | `transaction/` |
| `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/bitcoin_node/lib/src/block_generation_data_source_impl.dart` | implements `BlockGenerationDataSource` (regtest mining) from `transaction` | `block/` |

Total files to relocate: **11**.

### Internal cross-imports inside `bitcoin_node/lib/src/`

`grep "package:bitcoin_node/src/"` returns three intra-package imports:

- `address_remote_data_source_impl.dart:2` → `package:bitcoin_node/src/address_type_rpc.dart`
- `transaction_remote_data_source_impl.dart:1` → `package:bitcoin_node/src/transaction_direction_rpc_mapper.dart`
- `utxo_remote_data_source_impl.dart:1` → `package:bitcoin_node/src/address_type_rpc_mapper.dart`

Every internal `package:bitcoin_node/src/...` import path will change.

### Public barrel snapshot (`packages/bitcoin_node/lib/bitcoin_node.dart`)

Exports today (must remain byte-equivalent in symbol set after the move):

```
export 'src/address_remote_data_source_impl.dart';
export 'src/block_generation_data_source_impl.dart';
export 'src/broadcast_data_source_impl.dart';
export 'src/node_transaction_data_source_impl.dart';
export 'src/transaction_remote_data_source_impl.dart';
export 'src/utxo_remote_data_source_impl.dart';
export 'src/utxo_scan_data_source_impl.dart';
export 'src/wallet_remote_data_source_impl.dart';
```

Note: the three RPC-mapping helpers (`address_type_rpc.dart`,
`address_type_rpc_mapper.dart`, `transaction_direction_rpc_mapper.dart`)
are **not** exported from the barrel today; they are intra-package only.
Phase 1 must preserve that — do not re-export them.

### Consumers of the barrel

`grep "package:bitcoin_node/bitcoin_node.dart"` returns exactly one
consumer outside the package:

- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/lib/core/di/app_dependencies_builder.dart:2`

This file (the composition root) instantiates every `*Impl` symbol exported
from the barrel. As long as the barrel symbol set is preserved, this file
needs no change.

### Tests touching `bitcoin_node`

`grep "import .*bitcoin_node"` returns no test file. There is currently no
test directly under `packages/bitcoin_node/test/` (the directory does not
exist). Test mirroring is therefore a non-issue for Phase 1.

### Existing `bitcoin_node` dependencies (`packages/bitcoin_node/pubspec.yaml`)

`address`, `rpc_client`, `shared_kernel`, `transaction`, `wallet` (path
deps). Phase 1 must not change this list.

---

## External Facts

- Dart workspace resolution mode is in use (root `pubspec.yaml` lists every
  package under `workspace:`); each `packages/*/pubspec.yaml` declares
  `resolution: workspace`. Imports remain `package:`-style by convention
  (`conventions.md` Prohibited list).
- No platform constraint is touched — the Phase is pure file-relocation.
- `flutter analyze --fatal-infos --fatal-warnings` and `flutter test`
  are the relevant commands per `/aidd-run-checks`.

---

## Risks

| Risk | Impact | Recommendation |
|------|--------|----------------|
| `address_type_rpc_mapper.dart` is a shared helper used by both `utxo_remote_data_source_impl.dart` and `transaction_remote_data_source_impl.dart` | If placed in `utxo/`, the `transaction/` adapter has to import across subfolder boundaries | Place under the primary consumer subfolder (`utxo/`); the cross-subfolder import inside the same package is acceptable per `conventions.md` (intra-package imports are not restricted), but the planner must call it out so the choice is reviewed |
| A file is placed in the wrong subfolder | Misleading future navigation; possible accidental cross-trust import once Phase 3 introduces `hd/`/`node/` | Reviewer checklist explicitly verifies each file's consumer module against the table above |
| Internal `package:bitcoin_node/src/<old>` paths missed during update | Compile error, surfaces at `dart analyze` | Three known sites listed above; grep `package:bitcoin_node/src/` after the move must return only new paths |
| Barrel re-export change accidentally widens the public API by exporting one of the three internal helpers | Public surface drift | Diff the exported identifier list before and after; the helper names (`AddressTypeRpc`, `AddressTypeRpcMapper`, `TransactionDirectionRpcMapper`) must not appear in the after-diff |
| The composition-root file `lib/core/di/app_dependencies_builder.dart` instantiates eight symbols from the barrel | Any missed re-export breaks app startup | Symbol-set check is the gate; if all eight `*Impl` re-exports survive, the consumer file requires no edit |

---

## Design Pressure

- The eleven files split cleanly into five consumer-aligned buckets (5
  `transaction/` candidates, 2 `utxo/`, 2 `address/`, 1 `wallet/`, 1
  `block/`). The PRD-specified five-folder layout is the right shape.
- `bitcoin_node` continues to depend on `wallet`, `address`, `transaction`
  — the new layout reflects existing import edges; no new package
  dependency is needed.
- Existing tests do not mirror `bitcoin_node` source, so test relocation
  is not a Phase 1 concern. Consumer tests at `test/feature/...` import
  use cases via the public package barrel and are unaffected.
- The three intra-package helper imports are the only edit risk.
- No HD/Node subfolder exists yet inside `bitcoin_node`; that distinction
  is a follow-up consideration if a future trust model (e.g. an HD-only
  scan endpoint) lands in the adapter layer. Not a Phase 1 concern.

---

## References

- Phase 1 PRD: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/BW-0005/prd/BW-0005-phase-1.prd.md`
- Architecture rules: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/project/conventions.md` (Prohibited list, DataSource ownership)
- Composition root: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/lib/core/di/app_dependencies_builder.dart`
- Public barrel: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/bitcoin_node/lib/bitcoin_node.dart`
- Recommended verification commands the implementer should run:
  - `ls packages/bitcoin_node/lib/src/` → exactly five subfolders, zero `*.dart`
  - `find packages/bitcoin_node/lib/src/ -maxdepth 1 -name '*.dart'` → empty
  - `grep -r "package:bitcoin_node/src/" packages/ lib/ test/` → all paths under one of the five subfolders
  - `flutter analyze --fatal-infos --fatal-warnings` → exit 0
  - `flutter test` → green; test count unchanged
  - `dart pub deps` for `bitcoin_node` and the app → no new edges
