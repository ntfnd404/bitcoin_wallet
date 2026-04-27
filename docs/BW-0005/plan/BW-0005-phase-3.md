# Plan: BW-0005 Phase 3 — HD/Node Subfolders by Trust Model

Status: `PLAN_APPROVED`
Ticket: BW-0005
Phase: 3
Lane: Critical
Workflow Version: 3
Owner: Planner / Architect

---

## Phase Scope

Introduce `hd/` and `node/` subfolders inside the `data/` and `application/`
layers of `packages/wallet/`, `packages/transaction/`, and `packages/address/`.
Move every trust-specific file into the correct subfolder; keep every
trust-agnostic file at the layer root. Update all internal imports, public
barrels, and assembly DI files. Verify that no file under an `hd/` path imports
from a `node/` path within the same package (and vice versa). The `domain/`
layer of all three packages is untouched. No behavioural change. All tests must
remain green.

Reference: `docs/project/adr/ADR-002-trust-model-subfolder-split.md`.

---

## Per-File Classification Matrix

### `packages/wallet/`

#### `application/` — 3 files

| Current path (relative to `lib/src/`) | Trust tag | New path |
|---|---|---|
| `application/create_hd_wallet_use_case.dart` | HD-only | `application/hd/create_hd_wallet_use_case.dart` |
| `application/restore_hd_wallet_use_case.dart` | HD-only | `application/hd/restore_hd_wallet_use_case.dart` |
| `application/create_node_wallet_use_case.dart` | Node-only | `application/node/create_node_wallet_use_case.dart` |

#### `data/` — 3 files

| Current path (relative to `lib/src/`) | Trust tag | New path |
|---|---|---|
| `data/wallet_repository_impl.dart` | shared (implements both `HdWalletRepository` and `NodeWalletRepository`) | stays at `data/wallet_repository_impl.dart` |
| `data/wallet_local_data_source_impl.dart` | shared (persists both subtypes) | stays at `data/wallet_local_data_source_impl.dart` |
| `data/wallet_mapper.dart` | shared (switch on sealed `Wallet`) | stays at `data/wallet_mapper.dart` |

Rationale: `WalletRepositoryImpl` implements two contracts spanning both trust
models. Per ADR-002 §Decision: "Truly trust-agnostic orchestrators stay at the
layer root." Splitting it would require a domain-layer interface split that is
out of scope; keeping it at `data/` root is the correct classification.

### `packages/transaction/`

#### `application/` — 11 files

| Current path (relative to `lib/src/`) | Trust tag | New path |
|---|---|---|
| `application/prepare_hd_send_use_case.dart` | HD-only | `application/hd/prepare_hd_send_use_case.dart` |
| `application/hd_send_preparation.dart` | HD-only | `application/hd/hd_send_preparation.dart` |
| `application/send_hd_transaction_use_case.dart` | HD-only | `application/hd/send_hd_transaction_use_case.dart` |
| `application/prepare_node_send_use_case.dart` | Node-only | `application/node/prepare_node_send_use_case.dart` |
| `application/node_send_preparation.dart` | Node-only | `application/node/node_send_preparation.dart` |
| `application/send_node_transaction_use_case.dart` | Node-only | `application/node/send_node_transaction_use_case.dart` |
| `application/broadcast_transaction_use_case.dart` | shared | stays at `application/broadcast_transaction_use_case.dart` |
| `application/get_transaction_detail_use_case.dart` | shared | stays at `application/get_transaction_detail_use_case.dart` |
| `application/get_transactions_use_case.dart` | shared | stays at `application/get_transactions_use_case.dart` |
| `application/get_utxos_use_case.dart` | shared | stays at `application/get_utxos_use_case.dart` |
| `application/scan_utxos_use_case.dart` | shared (contract is trust-agnostic; only HD callers exist today, but `UtxoScanDataSource` carries no HD-private types) | stays at `application/scan_utxos_use_case.dart` |

`scan_utxos_use_case.dart` classification note: The `UtxoScanDataSource`
interface accepts a list of address strings — no HD metadata, no derivation
paths. The use case is callable from any context. If a Node `scantxoutset`
consumer is ever added, it can import from the root without crossing the boundary.
Keeping it at the layer root is safe and future-proof.

#### `data/` — 2 files

| Current path (relative to `lib/src/`) | Trust tag | New path |
|---|---|---|
| `data/transaction_repository_impl.dart` | shared | stays at `data/transaction_repository_impl.dart` |
| `data/utxo_repository_impl.dart` | shared | stays at `data/utxo_repository_impl.dart` |

No HD-only or Node-only `data/` files exist in this package today. `hd/` and
`node/` subfolders are **not** created under `data/` for `transaction/` in this
phase. They will be added if a future trust-specific implementation requires
them.

### `packages/address/`

#### `application/` — 4 files

| Current path (relative to `lib/src/`) | Trust tag | New path |
|---|---|---|
| `application/hd_address_generation_strategy.dart` | HD-only | `application/hd/hd_address_generation_strategy.dart` |
| `application/node_address_generation_strategy.dart` | Node-only | `application/node/node_address_generation_strategy.dart` |
| `application/address_generation_strategy.dart` | shared (interface, trust-agnostic) | stays at `application/address_generation_strategy.dart` |
| `application/generate_address_use_case.dart` | shared (orchestrator, dispatches via strategy interface) | stays at `application/generate_address_use_case.dart` |

#### `data/` — 3 files

| Current path (relative to `lib/src/`) | Trust tag | New path |
|---|---|---|
| `data/address_repository_impl.dart` | shared | stays at `data/address_repository_impl.dart` |
| `data/address_local_data_source_impl.dart` | shared | stays at `data/address_local_data_source_impl.dart` |
| `data/address_mapper.dart` | shared | stays at `data/address_mapper.dart` |

No HD-only or Node-only `data/` files exist for `address/` today. `hd/` and
`node/` subfolders are **not** created under `data/` for `address/` in this
phase.

---

## Internal Import Updates Per Moved File

All imports use `package:` style (never relative). Only the `src/` path segment
changes for moved files; cross-package imports are unchanged.

### `packages/wallet/lib/src/application/hd/create_hd_wallet_use_case.dart`
No internal `src/application/` import in this file. No change needed beyond file
relocation.

### `packages/wallet/lib/src/application/hd/restore_hd_wallet_use_case.dart`
No internal `src/application/` import in this file. No change needed beyond file
relocation.

### `packages/wallet/lib/src/application/node/create_node_wallet_use_case.dart`
No internal `src/application/` import in this file. No change needed beyond file
relocation.

### `packages/transaction/lib/src/application/hd/prepare_hd_send_use_case.dart`
- Change: `package:transaction/src/application/hd_send_preparation.dart`
  → `package:transaction/src/application/hd/hd_send_preparation.dart`
- All other imports (`domain/`, `shared_kernel`) are unchanged.

### `packages/transaction/lib/src/application/hd/send_hd_transaction_use_case.dart`
- Change: `package:transaction/src/application/hd_send_preparation.dart`
  → `package:transaction/src/application/hd/hd_send_preparation.dart`
- All other imports unchanged.

### `packages/transaction/lib/src/application/hd/hd_send_preparation.dart`
No internal `src/application/` import. No change beyond relocation.

### `packages/transaction/lib/src/application/node/prepare_node_send_use_case.dart`
- Change: `package:transaction/src/application/node_send_preparation.dart`
  → `package:transaction/src/application/node/node_send_preparation.dart`
- All other imports unchanged.

### `packages/transaction/lib/src/application/node/send_node_transaction_use_case.dart`
- Change: `package:transaction/src/application/node_send_preparation.dart`
  → `package:transaction/src/application/node/node_send_preparation.dart`
- All other imports unchanged.

### `packages/transaction/lib/src/application/node/node_send_preparation.dart`
No internal `src/application/` import. No change beyond relocation.

### `packages/address/lib/src/application/hd/hd_address_generation_strategy.dart`
- Change: `package:address/src/application/address_generation_strategy.dart`
  → unchanged (strategy interface stays at `application/` root). No path change
  required for this import.
- All other imports unchanged.

### `packages/address/lib/src/application/node/node_address_generation_strategy.dart`
- `package:address/src/application/address_generation_strategy.dart` — unchanged.
  No path change required.

---

## Barrel Updates

Public barrels must export identical symbol sets; only the `src/` path segments
for moved files change.

### `packages/wallet/lib/wallet.dart`

```dart
// Before (3 application exports):
export 'src/application/create_hd_wallet_use_case.dart';
export 'src/application/create_node_wallet_use_case.dart';
export 'src/application/restore_hd_wallet_use_case.dart';

// After:
export 'src/application/hd/create_hd_wallet_use_case.dart';
export 'src/application/node/create_node_wallet_use_case.dart';
export 'src/application/hd/restore_hd_wallet_use_case.dart';
```

Domain exports (`src/domain/...`) are unchanged.

### `packages/transaction/lib/transaction.dart`

```dart
// Lines to update (6 lines change; 5 shared lines stay):
// HD moves:
export 'src/application/hd/hd_send_preparation.dart';       // was src/application/hd_send_preparation.dart
export 'src/application/hd/prepare_hd_send_use_case.dart';  // was src/application/prepare_hd_send_use_case.dart
export 'src/application/hd/send_hd_transaction_use_case.dart'; // was src/application/send_hd_transaction_use_case.dart
// Node moves:
export 'src/application/node/node_send_preparation.dart';       // was src/application/node_send_preparation.dart
export 'src/application/node/prepare_node_send_use_case.dart';  // was src/application/prepare_node_send_use_case.dart
export 'src/application/node/send_node_transaction_use_case.dart'; // was src/application/send_node_transaction_use_case.dart
```

The 5 shared application exports and all domain exports are unchanged.

### `packages/address/lib/address.dart`

```dart
// Lines to update (2 lines change; 2 shared lines stay):
export 'src/application/hd/hd_address_generation_strategy.dart';   // was src/application/hd_address_generation_strategy.dart
export 'src/application/node/node_address_generation_strategy.dart'; // was src/application/node_address_generation_strategy.dart
```

`address_generation_strategy.dart` and `generate_address_use_case.dart` exports
are unchanged.

---

## DI Assembly Updates

### `packages/wallet/lib/wallet_assembly.dart`

Update 3 import paths (application files that moved); the 3 data-layer imports
are unchanged because no `data/` file moves.

```dart
// Old:
import 'package:wallet/src/application/create_hd_wallet_use_case.dart';
import 'package:wallet/src/application/create_node_wallet_use_case.dart';
import 'package:wallet/src/application/restore_hd_wallet_use_case.dart';

// New:
import 'package:wallet/src/application/hd/create_hd_wallet_use_case.dart';
import 'package:wallet/src/application/node/create_node_wallet_use_case.dart';
import 'package:wallet/src/application/hd/restore_hd_wallet_use_case.dart';
```

Public symbol set (`WalletAssembly`, `walletRepository`, `createNodeWallet`,
`createHdWallet`, `restoreHdWallet`) is unchanged.

Security check: `createHdWallet` and `restoreHdWallet` remain wired to HD
implementations (`Bip39Service`, `SeedRepository`, `HdWalletRepository`).
`createNodeWallet` remains wired to `NodeWalletRepository`. No wire swap.

### `packages/transaction/lib/transaction_assembly.dart`

Update 6 import paths (3 HD + 3 Node application files); the 2 data-layer
imports are unchanged.

```dart
// Old HD:
import 'package:transaction/src/application/prepare_hd_send_use_case.dart';
import 'package:transaction/src/application/send_hd_transaction_use_case.dart';
// (hd_send_preparation.dart is not imported directly in assembly; used via PrepareHdSendUseCase return type)

// New HD:
import 'package:transaction/src/application/hd/prepare_hd_send_use_case.dart';
import 'package:transaction/src/application/hd/send_hd_transaction_use_case.dart';

// Old Node:
import 'package:transaction/src/application/prepare_node_send_use_case.dart';
import 'package:transaction/src/application/send_node_transaction_use_case.dart';

// New Node:
import 'package:transaction/src/application/node/prepare_node_send_use_case.dart';
import 'package:transaction/src/application/node/send_node_transaction_use_case.dart';
```

Note: `hd_send_preparation.dart` and `node_send_preparation.dart` are data
classes referenced via their respective use-case return types. The assembly
creates instances of the use cases, not the preparation classes directly. If the
assembly imports them directly, those import lines must also be updated.

Verify actual `transaction_assembly.dart` imports at implementation time and
update any direct import of `hd_send_preparation.dart` or
`node_send_preparation.dart` accordingly.

Security check: `prepareHdSend` and `sendHdTransaction` remain wired to
`HdAddressDataSource` and `TransactionSigner` (HD context). `prepareNodeSend`
and `sendNodeTransaction` remain wired to `NodeTransactionDataSource`. No wire
swap. The security reviewer must diff all 10 registration lines.

### `packages/address/lib/address_assembly.dart`

Update 2 import paths (HD + Node strategies); the 2 shared application imports
and 3 data-layer imports are unchanged.

```dart
// Old:
import 'package:address/src/application/hd_address_generation_strategy.dart';
import 'package:address/src/application/node_address_generation_strategy.dart';

// New:
import 'package:address/src/application/hd/hd_address_generation_strategy.dart';
import 'package:address/src/application/node/node_address_generation_strategy.dart';
```

Security check: `HdAddressGenerationStrategy` is first in the `strategies` list
and receives `SeedRepository` + `KeyDerivationService`. `NodeAddressGenerationStrategy`
receives `AddressRemoteDataSource`. No wire swap; `generateAddress` dispatches via
`supports()` which is type-checked at runtime against `HdWallet`/`NodeWallet`.

### App-side adapters and feature scope

- `lib/core/adapters/hd_address_data_source_impl.dart` — imports `package:address/address.dart`
  and `package:transaction/transaction.dart` (barrels only). No change required
  as long as barrel exports are preserved.
- `lib/core/adapters/hd_transaction_signer.dart` — same; no change required.
- `lib/feature/send/di/send_scope.dart` — imports `package:transaction/transaction.dart`
  via barrel only. No change required.
- `lib/core/di/app_dependencies_builder.dart` — imports assembly classes via their
  assembly entry points. No change required.

---

## Cross-Trust Import Boundary

Invariant from ADR-002:

- `hd/*` files may import from: `hd/`, layer root (shared), `domain/`, other packages.
- `node/*` files may import from: `node/`, layer root (shared), `domain/`, other packages.
- Cross-imports (`hd/` → `node/` or `node/` → `hd/`) within the same package are forbidden.

Verification greps (run after all moves; must return zero matches):

```bash
# wallet
grep -rn "src/application/node/" packages/wallet/lib/src/application/hd/
grep -rn "src/application/hd/"   packages/wallet/lib/src/application/node/

# transaction
grep -rn "src/application/node/" packages/transaction/lib/src/application/hd/
grep -rn "src/application/hd/"   packages/transaction/lib/src/application/node/

# address
grep -rn "src/application/node/" packages/address/lib/src/application/hd/
grep -rn "src/application/hd/"   packages/address/lib/src/application/node/

# cross-package (belt-and-suspenders)
grep -rn "src/.*/node/" packages/wallet/lib/src/application/hd/ \
                        packages/transaction/lib/src/application/hd/ \
                        packages/address/lib/src/application/hd/
grep -rn "src/.*/hd/"  packages/wallet/lib/src/application/node/ \
                        packages/transaction/lib/src/application/node/ \
                        packages/address/lib/src/application/node/
```

Specific cross-trust risks verified at design time:

1. `hd_address_generation_strategy.dart` imports `address_generation_strategy.dart`
   (shared interface at `application/` root) — allowed.
2. `node_address_generation_strategy.dart` imports `address_generation_strategy.dart`
   (same interface) — allowed.
3. `prepare_hd_send_use_case.dart` imports `hd_send_preparation.dart` (both move to
   `application/hd/`) — allowed (same subfolder).
4. `send_hd_transaction_use_case.dart` imports `hd_send_preparation.dart` (same
   subfolder) — allowed.
5. `prepare_node_send_use_case.dart` imports `node_send_preparation.dart` (both move to
   `application/node/`) — allowed.
6. `send_node_transaction_use_case.dart` imports `node_send_preparation.dart` (same
   subfolder) — allowed.
7. No moved file imports any type from the opposing subfolder. Confirmed by
   inspecting all import lists in the source files above.

---

## Test Relocation

Per `guidelines.md`: test paths must mirror source paths. Existing tests import
symbols via public barrels (`package:wallet/wallet.dart`,
`package:address/address.dart`), so symbol resolution is unaffected by the move.
However, the directory placement must mirror the new source tree.

| Current test path | Mirrors source | New test path |
|---|---|---|
| `test/feature/wallet/domain/usecase/create_hd_wallet_use_case_test.dart` | `application/hd/create_hd_wallet_use_case.dart` | `test/feature/wallet/domain/usecase/hd/create_hd_wallet_use_case_test.dart` |
| `test/feature/wallet/domain/usecase/restore_hd_wallet_use_case_test.dart` | `application/hd/restore_hd_wallet_use_case.dart` | `test/feature/wallet/domain/usecase/hd/restore_hd_wallet_use_case_test.dart` |
| `test/feature/wallet/domain/usecase/create_node_wallet_use_case_test.dart` | `application/node/create_node_wallet_use_case.dart` | `test/feature/wallet/domain/usecase/node/create_node_wallet_use_case_test.dart` |
| `test/feature/address/domain/usecase/generate_address_use_case_test.dart` | `application/generate_address_use_case.dart` (stays at root) | stays at `test/feature/address/domain/usecase/generate_address_use_case_test.dart` |

`fakes/` and `mocks/` shared fixtures under each `usecase/` folder stay at
their current paths (they are support files, not mirroring a specific source
file). Shared fixtures may be referenced by both `hd/` and `node/` test
sub-folders via their current import paths.

---

## Sequenced Batches

### Batch A — `packages/wallet/` split

1. Create directories:
   - `packages/wallet/lib/src/application/hd/`
   - `packages/wallet/lib/src/application/node/`
2. Move (git mv):
   - `application/create_hd_wallet_use_case.dart` → `application/hd/`
   - `application/restore_hd_wallet_use_case.dart` → `application/hd/`
   - `application/create_node_wallet_use_case.dart` → `application/node/`
3. No internal import changes needed in the moved files (they have no
   cross-application-layer imports within `wallet/`).
4. Update `packages/wallet/lib/wallet.dart` barrel: 3 export paths.
5. Update `packages/wallet/lib/wallet_assembly.dart`: 3 import paths.
6. Move tests:
   - `test/feature/wallet/domain/usecase/create_hd_wallet_use_case_test.dart`
     → `test/feature/wallet/domain/usecase/hd/`
   - `test/feature/wallet/domain/usecase/restore_hd_wallet_use_case_test.dart`
     → `test/feature/wallet/domain/usecase/hd/`
   - `test/feature/wallet/domain/usecase/create_node_wallet_use_case_test.dart`
     → `test/feature/wallet/domain/usecase/node/`
7. Check: `flutter analyze --fatal-infos --fatal-warnings` on `packages/wallet/`
8. Check: `flutter test test/feature/wallet/`
9. Check: cross-trust grep (wallet package only)

### Batch B — `packages/address/` split

1. Create directories:
   - `packages/address/lib/src/application/hd/`
   - `packages/address/lib/src/application/node/`
2. Move (git mv):
   - `application/hd_address_generation_strategy.dart` → `application/hd/`
   - `application/node_address_generation_strategy.dart` → `application/node/`
3. Internal import check: both strategies import `address_generation_strategy.dart`
   from the layer root (`package:address/src/application/address_generation_strategy.dart`).
   This path is unchanged — no edit needed in the moved files.
4. Update `packages/address/lib/address.dart` barrel: 2 export paths.
5. Update `packages/address/lib/address_assembly.dart`: 2 import paths.
6. Test: `generate_address_use_case_test.dart` stays in place (its source stays at root).
7. Check: `flutter analyze --fatal-infos --fatal-warnings` on `packages/address/`
8. Check: `flutter test test/feature/address/`
9. Check: cross-trust grep (address package only)

### Batch C — `packages/transaction/` split

1. Create directories:
   - `packages/transaction/lib/src/application/hd/`
   - `packages/transaction/lib/src/application/node/`
2. Move (git mv) — HD group:
   - `application/prepare_hd_send_use_case.dart` → `application/hd/`
   - `application/hd_send_preparation.dart` → `application/hd/`
   - `application/send_hd_transaction_use_case.dart` → `application/hd/`
3. Move (git mv) — Node group:
   - `application/prepare_node_send_use_case.dart` → `application/node/`
   - `application/node_send_preparation.dart` → `application/node/`
   - `application/send_node_transaction_use_case.dart` → `application/node/`
4. Update internal imports:
   - `application/hd/prepare_hd_send_use_case.dart`: update import of
     `hd_send_preparation.dart` to `hd/hd_send_preparation.dart`
   - `application/hd/send_hd_transaction_use_case.dart`: same update
   - `application/node/prepare_node_send_use_case.dart`: update import of
     `node_send_preparation.dart` to `node/node_send_preparation.dart`
   - `application/node/send_node_transaction_use_case.dart`: same update
5. Update `packages/transaction/lib/transaction.dart` barrel: 6 export paths.
6. Update `packages/transaction/lib/transaction_assembly.dart`: update all
   import paths for moved files (minimum 4 direct class imports; verify and
   update any additional direct imports of `hd_send_preparation.dart` or
   `node_send_preparation.dart`).
7. Check: `flutter analyze --fatal-infos --fatal-warnings` on `packages/transaction/`
8. Check: `flutter test packages/transaction/test/` and `flutter test test/`
9. Check: cross-trust grep (transaction package only)

### Batch D — Full suite + security gate

1. Run full cross-trust grep (all three packages, as listed in the boundary
   section above).
2. Run `flutter analyze --fatal-infos --fatal-warnings` (root, all packages).
3. Run `flutter test` (all tests; count must not drop).
4. Run `flutter test packages/keys/test/` — BW-0003 reference-vector signing
   tests must be green and bit-identical.
5. Run `dart pub deps` for `wallet`, `transaction`, `address` — no new
   dependency edges.
6. Verify barrel symbol sets: diff exported identifiers in `wallet.dart`,
   `transaction.dart`, `address.dart` before and after (symbols unchanged,
   only paths changed).
7. Author security-reviewer artifact: `docs/BW-0005/security/phase-3-security.md`.

---

## Interfaces And Contracts

No interfaces change in this phase. All contracts remain in `domain/` which is
untouched. Assembly public symbols are unchanged. The only change is that
internal `src/application/` import paths gain an `hd/` or `node/` segment.

---

## Security Review Gate

This is a Critical-lane phase. A security-reviewer artifact must be authored at
`docs/BW-0005/security/phase-3-security.md` before the phase is marked complete.

The security review must verify each of the following:

1. **Cross-trust import check passed.** All six grep commands in the boundary
   section return zero rows.
2. **HD signing flow intact.** `prepare_hd_send_use_case.dart` →
   `send_hd_transaction_use_case.dart` → `lib/core/adapters/hd_transaction_signer.dart`
   → `packages/keys/lib/src/application/sign_transaction_use_case.dart`. No new
   intermediate site introduced outside `hd/` subfolders.
3. **No HD-private metadata exposed to Node code.** `Address.derivationPath`
   is populated only by `hd_address_generation_strategy.dart` (now in `address/
   application/hd/`). Node strategy never reads or writes `derivationPath`.
   Verify by inspecting `node_address_generation_strategy.dart` post-move.
4. **No new logging of private material.** Confirm no `developer.log` or error
   surface in moved files emits seed, mnemonic, derivation-path, xpub, or
   private-key data.
5. **DI wire integrity.** Diff `wallet_assembly.dart`, `transaction_assembly.dart`,
   `address_assembly.dart` against pre-Phase-3 state. Confirm:
   - `createHdWallet`/`restoreHdWallet` wired to HD-only types.
   - `createNodeWallet` wired to Node-only types.
   - `prepareHdSend`/`sendHdTransaction` wired to `HdAddressDataSource` and
     `TransactionSigner` (HD context).
   - `prepareNodeSend`/`sendNodeTransaction` wired to `NodeTransactionDataSource`.
   - `HdAddressGenerationStrategy` receives `SeedRepository` + `KeyDerivationService`;
     `NodeAddressGenerationStrategy` receives `AddressRemoteDataSource`.
6. **App-side adapter boundary.** Confirm `hd_address_data_source_impl.dart`
   imports only `package:address/address.dart` and `package:transaction/transaction.dart`
   (barrel-level) and no `src/.*/node/` path.
7. **Reference-vector signing tests green.** `flutter test packages/keys/test/`
   exits 0 with identical test output.
8. **`keys` package untouched.** Confirm zero diffs in `packages/keys/`.

---

## Error Handling And Edge Cases

- **Barrel path typo:** If a barrel `export` path is wrong after the move, `dart
  analyze` will report `uri_does_not_exist`. The check command catches this
  before tests run.
- **Test import not updated:** Test files import via public barrels; relocation
  of test files into `hd/`/`node/` sub-directories requires no import changes
  in test code. Relative fixture imports (`fakes/`, `mocks/`) may need updating
  if the test moves to a deeper directory — the implementer must verify each
  relocated test file's relative imports and update them (or convert to
  `package:` imports).
- **Shared fixture path break:** `fakes/` and `mocks/` remain at the
  `usecase/` level. Relocated tests in `usecase/hd/` and `usecase/node/`
  reference them one level up (e.g. `../fakes/fake_bip39_service.dart`). This
  is a relative import — acceptable in test files per project rules; verify
  these resolve.
- **`dart pub deps` cycle:** The file moves do not alter `pubspec.yaml`
  dependencies. No new cycle risk. Run `dart pub deps` as a sanity check.

---

## Checks

```bash
# Per-batch analysis (run after each batch)
flutter analyze --fatal-infos --fatal-warnings

# Per-batch test (run after each batch)
flutter test

# Cross-trust boundary (run after Batch C and Batch D)
grep -rn "src/application/node/" packages/wallet/lib/src/application/hd/ || echo "PASS"
grep -rn "src/application/hd/"   packages/wallet/lib/src/application/node/ || echo "PASS"
grep -rn "src/application/node/" packages/transaction/lib/src/application/hd/ || echo "PASS"
grep -rn "src/application/hd/"   packages/transaction/lib/src/application/node/ || echo "PASS"
grep -rn "src/application/node/" packages/address/lib/src/application/hd/ || echo "PASS"
grep -rn "src/application/hd/"   packages/address/lib/src/application/node/ || echo "PASS"

# Reference-vector signing tests (run in Batch D)
flutter test packages/keys/test/

# Dependency graph (run in Batch D)
dart pub deps --directory packages/wallet
dart pub deps --directory packages/transaction
dart pub deps --directory packages/address

# Folder layout verification
ls packages/wallet/lib/src/application/
ls packages/transaction/lib/src/application/
ls packages/address/lib/src/application/

# Security artifact presence (gate check)
test -f docs/BW-0005/security/phase-3-security.md && echo "PRESENT" || echo "MISSING"
```

---

## Risks

| Risk | Mitigation |
|------|------------|
| Relative fixture imports break when tests move into `hd/`/`node/` subdirectory | Implementer checks every relative import in each relocated test file; updates to `../fakes/` paths or converts to absolute package imports |
| Barrel path typo causes a symbol to disappear | `dart analyze` after every barrel edit; run before running tests |
| Assembly import update missed (file not in the classification matrix) | Assembly files have a bounded import set; implementer diffs pre/post assembly file and verifies every import path that points to `src/application/` |
| `transaction_assembly.dart` directly imports `hd_send_preparation.dart` or `node_send_preparation.dart` | Implementer reads actual current imports in assembly file before editing; updates any direct import of those data classes |
| DI wire swap during import-path edit | Security reviewer diffs all three assembly files; reference-vector signing tests provide runtime regression detection |
| Cross-package HD→Node import introduced accidentally | Full cross-trust grep in Batch D catches it |
