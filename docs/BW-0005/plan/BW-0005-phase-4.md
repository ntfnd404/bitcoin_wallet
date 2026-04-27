# Plan: BW-0005 Phase 4 — Package READMEs + Rewrite `architecture.md`

Status: `PLAN_APPROVED`
Ticket: BW-0005
Phase: 4
Lane: Professional
Workflow Version: 3
Owner: Planner / Architect

---

## Phase Scope

Produce nine `README.md` files (one per workspace package), rewrite
`docs/project/architecture.md` to reflect the post-Phases-1-3 state, and
add a process rule to `docs/project/conventions.md` requiring a README
touch whenever a package layer structure changes.

No source code is modified. Runtime behaviour is invariant.

Security review is **not required** — this is a Professional-lane
documentation phase with no changes to crypto, signing, key handling,
seed storage, or API contracts.

---

## File Changes

| File | Change | Why |
|------|--------|-----|
| `packages/address/README.md` | Create | Nine-package README requirement |
| `packages/bitcoin_node/README.md` | Create | Nine-package README requirement |
| `packages/keys/README.md` | Create | Nine-package README requirement |
| `packages/rpc_client/README.md` | Create | Nine-package README requirement |
| `packages/shared_kernel/README.md` | Create | Nine-package README requirement |
| `packages/storage/README.md` | Create | Nine-package README requirement |
| `packages/transaction/README.md` | Create | Nine-package README requirement |
| `packages/ui_kit/README.md` | Create | Nine-package README requirement |
| `packages/wallet/README.md` | Create | Nine-package README requirement |
| `docs/project/architecture.md` | Rewrite | Stale pre-Phase-1/3 state; missing `transaction` |
| `docs/project/conventions.md` | Small insert | Add README-touch process rule |

---

## README Specification Per Package

Every README must contain exactly these five sections in this order:

1. **Purpose** — one paragraph stating what the package owns and why it exists as a separate package.
2. **Public API** — barrel file name(s), assembly class name (if any), and a prose summary of what is exported. No exhaustive symbol dump. No invented symbols — each must exist in the barrel.
3. **Dependencies** — workspace `path:` deps declared in `pubspec.yaml` and why each one is needed. Leaf packages (no workspace deps) state that explicitly.
4. **When to add code here** — a decision heuristic of no more than four bullet points so contributors and the planner agent can route new code correctly.
5. **Layer layout** — a brief folder tree showing `domain/`, `application/`, `data/` (where applicable) and any trust-model subfolders (`hd/`, `node/`) introduced in Phase 3.

### Package-specific constraints

**`address`**
- Barrel: `address.dart`. Assembly: `address_assembly.dart` (`AddressAssembly`).
- Exports: `AddressGenerationStrategy`, `GenerateAddressUseCase`, `HdAddressGenerationStrategy` (in `application/hd/`), `NodeAddressGenerationStrategy` (in `application/node/`), `AddressLocalDataSource`, `AddressRemoteDataSource`, `Address`, `AddressRepository`.
- Deps: `keys`, `shared_kernel`, `wallet`.
- Layer layout must show post-Phase-3 `application/hd/` and `application/node/` subfolders.

**`bitcoin_node`**
- Barrel: `bitcoin_node.dart`. No assembly.
- Exports: `AddressRemoteDataSourceImpl` (`src/address/`), `BlockGenerationDataSourceImpl` (`src/block/`), `BroadcastDataSourceImpl` (`src/transaction/`), `NodeTransactionDataSourceImpl` (`src/transaction/`), `TransactionRemoteDataSourceImpl` (`src/transaction/`), `UtxoRemoteDataSourceImpl` (`src/utxo/`), `UtxoScanDataSourceImpl` (`src/utxo/`), `WalletRemoteDataSourceImpl` (`src/wallet/`).
- Deps: `address`, `rpc_client`, `shared_kernel`, `transaction`, `wallet`.
- Layer layout must show post-Phase-1 consumer-aligned subfolders: `wallet/`, `address/`, `transaction/`, `utxo/`, `block/`.
- Consumer note: wired exclusively in `lib/core/di/app_dependencies_builder.dart`; no other package imports this barrel.

**`keys`**
- Barrel: `keys.dart`. Assembly: `keys_assembly.dart` (`KeysAssembly`).
- Exports: `GetXpubUseCase`, `SignTransactionUseCase`, `AccountXpub`, `DerivedAddress`, `Mnemonic`, `SigningInput`, `SigningOutput`, `SeedRepository`, `Bip39Service`, `KeyDerivationService`, `TransactionSigningService`.
- Deps: `shared_kernel` only (plus third-party `crypto`, `pointycastle` — mention these).
- `application/` subfolders (`get_xpub_use_case`, `sign_transaction_use_case`) must appear in layer tree.
- When-to-add-here: only BIP-standard crypto primitives, key derivation, signing. Never put HD wallet orchestration here.

**`rpc_client`**
- Barrel: `rpc_client.dart`. No assembly.
- Exports: `BitcoinRpcClient`, `RpcException`.
- Deps: none (workspace). Third-party: `http`.
- When-to-add-here: only low-level JSON-RPC transport concerns.

**`shared_kernel`**
- Barrel: `shared_kernel.dart`. No assembly.
- Exports: `AddressType`, `BitcoinNetwork`, `Satoshi`, `SecureStorage`.
- Deps: none — sole leaf in the workspace.
- When-to-add-here: only shared primitives that every other package needs AND that carry zero business logic. Explicit rule: never put entities, repositories, use cases, or module-specific types here.

**`storage`**
- Barrel: `storage.dart`. No assembly.
- Exports: `FlutterSecureStorage` (re-export), `SecureStorage` (re-export from `shared_kernel`), `SecureStorageImpl`.
- Deps: `shared_kernel`, Flutter SDK, `flutter_secure_storage`.
- Consumer: app composition root only.
- When-to-add-here: only concrete Flutter secure-storage implementation. Never business logic.

**`transaction`**
- Barrel: `transaction.dart`. Assembly: `transaction_assembly.dart` (`TransactionAssembly`).
- Exports (post-Phase-2): all use cases and data-source contracts and entities EXCEPT `HdAddressEntry` (removed in Phase 2). Explicitly note the `HdAddressEntry` removal.
- Deps: `shared_kernel`, `address` (added in Phase 2 — note this explicitly).
- Layer layout must show post-Phase-3 `application/hd/` and `application/node/` subfolders.

**`ui_kit`**
- Barrel: `ui_kit.dart`. No assembly.
- Current state: all exports are commented out (placeholder). README must describe today's honest state, not aspirational.
- Deps: Flutter SDK only. No workspace deps.
- When-to-add-here: shared design-system widgets, tokens, and theme only. No domain knowledge.

**`wallet`**
- Barrel: `wallet.dart`. Assembly: `wallet_assembly.dart` (`WalletAssembly`).
- Exports: `CreateHdWalletUseCase`, `CreateNodeWalletUseCase`, `RestoreHdWalletUseCase`, `WalletLocalDataSource`, `WalletRemoteDataSource`, `Wallet` (sealed) + parts `HdWallet`/`NodeWallet`, `HdWalletRepository`, `NodeWalletRepository`, `WalletRepository`.
- Deps: `keys`, `shared_kernel`, plus third-party `uuid`.
- Layer layout must show post-Phase-3 `application/hd/` and `application/node/` subfolders.

---

## `docs/project/architecture.md` Rewrite Scope

The implementer must update the following sections. Each change is
derived from real `pubspec.yaml` entries and barrel files — no
aspirational edges.

### 1. Dependency Graph (lines 22–62)

Replace entirely with a graph that includes all nine packages:

```
shared_kernel (no workspace deps)
  ↑ keys          (also → crypto, pointycastle)
  ↑ storage       (also → flutter_secure_storage, Flutter SDK)
  ↑ wallet        (also → keys, uuid)
  ↑ address       (also → keys, wallet)
  ↑ transaction   (also → address)
  ↑ bitcoin_node  (also → wallet, address, transaction, rpc_client)

rpc_client (no workspace deps; → http)
  ↑ bitcoin_node

ui_kit (no workspace deps; → Flutter SDK)
  (no workspace consumer)

App (lib/) depends on all nine workspace packages.
```

### 2. Project Structure — `packages/` section (lines 89–171)

- Add `transaction/` entry with post-Phase-2 and post-Phase-3 tree (deps: `shared_kernel`, `address`; `application/hd/`, `application/node/`).
- Update `bitcoin_node/` description: change from "WalletRemoteDataSourceImpl, AddressRemoteDataSourceImpl" (two entries) to all eight `*Impl` exports with their consumer-aligned subfolders (`wallet/`, `address/`, `transaction/`, `utxo/`, `block/`).
- Update `keys/` tree: add `application/` use-case files (`get_xpub_use_case.dart`, `sign_transaction_use_case.dart`, `signing_input_param.dart`).
- Update `wallet/` tree: replace `wallet_type.dart` with `hd_wallet.dart` + `node_wallet.dart`; replace `wallet_serializer.dart` with `wallet_mapper.dart`; add `hd_wallet_repository.dart` and `node_wallet_repository.dart`; add `application/hd/` and `application/node/` subfolders.
- Update `address/` tree: replace `address_serializer.dart` with `address_mapper.dart`; add `application/hd/` and `application/node/` subfolders.

### 3. Ownership Table (line 175)

- Add `transaction` row: owns `PrepareHdSendUseCase`, `PrepareNodeSendUseCase`, and all transaction/UTXO domain types; exposes use cases, data-source contracts, entities.
- Update `bitcoin_node` row: list all eight `*Impl` exports (not just two).
- Update `wallet` row: remove `WalletType` (deleted); add `HdWallet`, `NodeWallet`, `HdWalletRepository`, `NodeWalletRepository`.

### 4. ISP section (lines 254–263)

Replace the two-interface table with the full post-Phase-2 set:

| Interface | Module |
|-----------|--------|
| `WalletRemoteDataSource` | wallet |
| `AddressRemoteDataSource` | address |
| `TransactionRemoteDataSource` | transaction |
| `UtxoRemoteDataSource` | transaction |
| `UtxoScanDataSource` | transaction |
| `BroadcastDataSource` | transaction |
| `NodeTransactionDataSource` | transaction |
| `BlockGenerationDataSource` | transaction |
| `HdAddressDataSource` | transaction (removed in Phase 2) |

Note `HdAddressDataSource` removal: Phase 2 replaced `HdAddressEntry` with `Address`; `HdAddressDataSource` now returns `List<Address>`.

### 5. Avoiding Cycles section (lines 312–326)

Add `transaction` to the DAG listing:

```
keys           → shared_kernel
wallet         → shared_kernel, keys
address        → shared_kernel, keys, wallet
transaction    → shared_kernel, address
bitcoin_node   → wallet, address, transaction, rpc_client, shared_kernel
```

### 6. DI / Bootstrap Graph (lines 330–356)

Add `TransactionAssembly` and its adapters after `AddressAssembly`:

```
→ TransactionRemoteDataSourceImpl  (bitcoin_node)
→ UtxoRemoteDataSourceImpl         (bitcoin_node)
→ UtxoScanDataSourceImpl           (bitcoin_node)
→ BroadcastDataSourceImpl          (bitcoin_node)
→ NodeTransactionDataSourceImpl    (bitcoin_node)
→ BlockGenerationDataSourceImpl    (bitcoin_node)
→ HdAddressDataSourceImpl          (lib/core/adapters/)
→ TransactionAssembly              (transaction module)
```

Update `AppDependencies` container line to include `transaction`.

### 7. Trust-boundary note (new subsection)

Add a subsection after "Module Internal Structure" describing the HD/Node subfolder split introduced in Phase 3:

- `application/hd/` and `application/node/` exist in `wallet`, `address`, and `transaction`.
- `hd/` files must not import from `node/` within the same package and vice versa.
- Reference ADR-002 for the rationale (subfolder, not separate-package, split).

---

## `docs/project/conventions.md` Change

Insert one new bullet in the **Prohibited** section (or add a new short
section "Process Rules" immediately before Prohibited if a separate
heading is cleaner):

> **README touch rule**: any change to a package's layer structure
> (subfolder add, remove, or rename under `domain/`, `application/`, or
> `data/`) must touch that package's `README.md` in the same PR. This is
> a process rule; no CI check enforces it — reviewer discipline is the
> barrier.

Also update the package dependency graph block (lines 74–83) so it
matches the rewritten `architecture.md`. Since `architecture.md` is the
single source of truth (PRD §Constraints), `conventions.md` should
reference rather than duplicate the full graph — update the block to the
real nine-package edges or add a note pointing to `architecture.md`.

---

## Sequencing

The phase has three coherent batches. Each batch is independently
reviewable. No batch modifies source code.

### Batch A — Nine package READMEs

Author all nine `README.md` files in one pass. Verify each documented
symbol against its barrel before writing. Order of authoring:

1. `shared_kernel` (leaf, simplest)
2. `rpc_client` (leaf, no workspace deps)
3. `keys` (one workspace dep)
4. `storage` (one workspace dep, Flutter)
5. `wallet` (depends on `keys`, `shared_kernel`)
6. `address` (depends on `keys`, `shared_kernel`, `wallet`)
7. `transaction` (depends on `shared_kernel`, `address`)
8. `bitcoin_node` (depends on all business packages)
9. `ui_kit` (placeholder; honest state)

Verification after batch: `ls packages/*/README.md | wc -l` must return 9.

### Batch B — Rewrite `docs/project/architecture.md`

Apply all seven change areas listed above. Derive every graph edge from
`packages/*/pubspec.yaml`. Derive every tree entry from the real `lib/src/`
directory. Cross-check post-Phase-3 subfolders against actual directories
in `packages/{wallet,transaction,address}/lib/src/{application,data}/`.

Verification:
- `grep -n "transaction" docs/project/architecture.md` shows the new package section.
- Manual diff: `bitcoin_node` subfolder names match `ls packages/bitcoin_node/lib/src/`.
- Manual diff: dependency graph edges match each `packages/*/pubspec.yaml`.
- Manual diff: HD/Node subfolder names match actual directories.

### Batch C — Update `docs/project/conventions.md`

Insert the README-touch process rule. Update the stale dependency graph
block to match `architecture.md` (or replace with a reference).

Verification: `grep -n "README" docs/project/conventions.md` shows the new rule.

### Final check

Run `/aidd-run-checks` (format → analyze → test). No source changed;
all checks are expected green. Markdown lint warnings are acceptable but
must not block the phase.

---

## Interfaces And Contracts

Not applicable — this phase introduces no new Dart interfaces or
contracts. All documented interfaces already exist.

---

## Error Handling And Edge Cases

- **Invented symbol**: if a barrel does not export a symbol the README
  would describe, omit the symbol and add a TODO note. Never invent.
- **`ui_kit` placeholder state**: README must describe today's honest
  state. Do not describe aspirational tokens or theme until they exist.
- **Pre-refactor README risk**: Phases 1–3 are already complete (all
  marked Done in the tasklist). The implementer must still spot-check
  two or three key post-Phase-3 source directories before finalising any
  README section that references HD/Node subfolders.
- **`conventions.md` and `architecture.md` divergence**: after the
  update, `conventions.md` must not re-state the full dependency graph
  inline if it differs from `architecture.md`. Prefer a reference or a
  brief summary that stays consistent.

---

## Checks

- `ls packages/*/README.md | wc -l` returns 9
- `grep -n "transaction" docs/project/architecture.md` — non-empty
- `grep -n "README" docs/project/conventions.md` — non-empty
- Manual diff: `architecture.md` `bitcoin_node` subfolders vs `ls packages/bitcoin_node/lib/src/`
- Manual diff: `architecture.md` dependency graph vs each `packages/*/pubspec.yaml`
- Manual diff: `architecture.md` HD/Node subfolders vs `ls packages/{wallet,transaction,address}/lib/src/{application,data}/`
- `flutter analyze --fatal-infos --fatal-warnings` exits 0 (no source changed; must remain green)
- `flutter test` exits 0 (no source changed; must remain green)

---

## Risks

- **Content drift on day one**: mitigated by the README-touch process
  rule added to `conventions.md`.
- **`ui_kit` aspirational content**: README must be descriptive, not
  prescriptive. Mark the empty barrel explicitly.
- **`conventions.md` internal graph duplication**: update or replace the
  stale dependency block so it does not contradict `architecture.md`.
- **Missing post-Phase-3 directory verification**: implementer must
  confirm HD/Node subdirectory names match the real tree before writing
  README layer-layout sections for `wallet`, `address`, `transaction`.
