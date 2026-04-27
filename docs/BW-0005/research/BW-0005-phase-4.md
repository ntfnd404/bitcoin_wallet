# Research: BW-0005 Phase 4 — Package READMEs + Rewrite `architecture.md`

Status: `RESEARCH_DONE`
Ticket: BW-0005
Phase: 4
Lane: Professional
Workflow Version: 3
Owner: Researcher

---

## Codebase Facts

### Workspace inventory (must be exactly nine READMEs)

`ls /Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/` returns:

`address`, `bitcoin_node`, `keys`, `rpc_client`, `shared_kernel`, `storage`, `transaction`, `ui_kit`, `wallet` — exactly nine entries.

Root `pubspec.yaml` lines 9–18 list the same nine names under
`workspace:`. There is no `domain` package.

`find /Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages -maxdepth 2 -name README.md`
returns zero rows. Phase 4 must produce nine.

### Per-package raw material

Each section below lists what the implementer needs to draft the README:
public barrel symbols, declared `pubspec.yaml` dependencies, the
`lib/src/` directory tree, and the consumer modules (which packages
depend on it — derived from the dependency graph below).

---

#### 1. `address`

- Path: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/`
- Barrel `address.dart` exports: `AddressGenerationStrategy`, `GenerateAddressUseCase`, `HdAddressGenerationStrategy`, `NodeAddressGenerationStrategy`, `AddressLocalDataSource`, `AddressRemoteDataSource`, `Address`, `AddressRepository`
- Assembly `address_assembly.dart`: `AddressAssembly` (public), exposes `addressRepository`, `generateAddress`
- `pubspec.yaml` deps: `keys`, `shared_kernel`, `wallet`
- `lib/src/` tree (post-Phase-3, expected): `domain/{entity,repository,data_sources}/`, `application/{hd,node,*shared interface and orchestrator at root}`, `data/{*shared at root}`
- Consumers (depend on this package): `bitcoin_node`, app

#### 2. `bitcoin_node`

- Path: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/bitcoin_node/`
- Barrel `bitcoin_node.dart` exports 8 `*Impl` symbols: `AddressRemoteDataSourceImpl`, `BlockGenerationDataSourceImpl`, `BroadcastDataSourceImpl`, `NodeTransactionDataSourceImpl`, `TransactionRemoteDataSourceImpl`, `UtxoRemoteDataSourceImpl`, `UtxoScanDataSourceImpl`, `WalletRemoteDataSourceImpl`
- No assembly file
- `pubspec.yaml` deps: `address`, `rpc_client`, `shared_kernel`, `transaction`, `wallet`
- `lib/src/` tree (post-Phase-1, expected): `wallet/`, `address/`, `transaction/`, `utxo/`, `block/`
- Consumers: app only (`lib/core/di/app_dependencies_builder.dart` is the sole importer of the barrel)

#### 3. `keys`

- Path: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/keys/`
- Barrel `keys.dart` exports: `GetXpubUseCase`, `SignTransactionUseCase`, `AccountXpub`, `DerivedAddress`, `Mnemonic`, `SigningInput`, `SigningOutput`, `SeedRepository`, `Bip39Service`, `KeyDerivationService`, `TransactionSigningService`
- Assembly `keys_assembly.dart`: `KeysAssembly` exposing `bip39Service`, `keyDerivationService`, `seedRepository`, `getXpub`, `signTransaction`
- `pubspec.yaml` deps: `crypto: 3.0.7`, `pointycastle: 4.0.0`, `shared_kernel`
- `lib/src/` tree: `domain/{entity,repository,service}/`, `application/{get_xpub_use_case, sign_transaction_use_case, signing_input_param}.dart`, `data/{bip39_service_impl, bip39_wordlist, key_derivation_service_impl, seed_repository_impl, transaction_signing_service_impl, crypto/}.dart`
- Consumers: `wallet`, `address`, app (via `keys_assembly.dart`)

#### 4. `rpc_client`

- Path: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/rpc_client/`
- Barrel `rpc_client.dart` exports: `BitcoinRpcClient`, `RpcException`
- No assembly file
- `pubspec.yaml` deps: `http: 1.6.0`
- `lib/src/` tree: `bitcoin_rpc_client.dart`, `exceptions/`
- Consumers: `bitcoin_node`, app

#### 5. `shared_kernel`

- Path: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/shared_kernel/`
- Barrel `shared_kernel.dart` exports: `AddressType`, `BitcoinNetwork`, `Satoshi`, `SecureStorage`
- No assembly file
- `pubspec.yaml` deps: none (sole leaf)
- `lib/src/` tree: `address_type.dart`, `bitcoin_network.dart`, `satoshi.dart`, `secure_storage.dart`
- Consumers: every business and infra package except `rpc_client` and `ui_kit` — namely `keys`, `wallet`, `address`, `transaction`, `bitcoin_node`, `storage`, app

#### 6. `storage`

- Path: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/storage/`
- Barrel `storage.dart` exports: `FlutterSecureStorage` (re-export), `SecureStorage` (re-export from local), `SecureStorageImpl`
- No assembly file
- `pubspec.yaml` deps: `flutter` (sdk), `flutter_secure_storage: 10.0.0`, `meta: ^1.17.0`, `shared_kernel`
- `lib/src/` tree: `secure_storage.dart`, `secure_storage_impl.dart`
- Consumers: app only (composition root)

#### 7. `transaction`

- Path: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/`
- Barrel `transaction.dart` exports (current): all 11 application use cases + 7 data-source contracts + 9 entities + 1 exception + 2 repositories + 8 services + 4 value objects (the value-object set will drop `HdAddressEntry` after Phase 2)
- Assembly `transaction_assembly.dart`: `TransactionAssembly` exposing `getTransactions`, `getTransactionDetail`, `getUtxos`, `scanUtxos`, `broadcastTransaction`, `prepareNodeSend`, `prepareHdSend`, `sendNodeTransaction`, `sendHdTransaction`, `blockGeneration`
- `pubspec.yaml` deps (current): `shared_kernel` only. After Phase 2: also `address`
- `lib/src/` tree (post-Phase-3): `domain/{data_sources,entity,exception,repository,service,value_object}/`, `application/{hd,node,*shared at root}`, `data/{*shared at root}`
- Consumers: `bitcoin_node`, app

#### 8. `ui_kit`

- Path: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/ui_kit/`
- Barrel `ui_kit.dart`: all exports commented out today (placeholder)
- No assembly file
- `pubspec.yaml` deps: `flutter` (sdk)
- `lib/src/` tree: `theme/`, `tokens/`, `typography/` (all empty / TBD)
- Consumers: none today (the app does not yet import the barrel)

#### 9. `wallet`

- Path: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/wallet/`
- Barrel `wallet.dart` exports: `CreateHdWalletUseCase`, `CreateNodeWalletUseCase`, `RestoreHdWalletUseCase`, `WalletLocalDataSource`, `WalletRemoteDataSource`, `Wallet` (sealed) + parts `HdWallet`, `NodeWallet`, `HdWalletRepository`, `NodeWalletRepository`, `WalletRepository`
- Assembly `wallet_assembly.dart`: `WalletAssembly` exposing `walletRepository`, `createNodeWallet`, `createHdWallet`, `restoreHdWallet`
- `pubspec.yaml` deps: `keys`, `shared_kernel`, `uuid: 4.5.3`
- `lib/src/` tree (post-Phase-3): `domain/{entity,repository,data_sources}/`, `application/{hd,node}/`, `data/{*shared at root}`
- Consumers: `address`, `bitcoin_node`, app

---

### Real dependency graph (derived from `packages/*/pubspec.yaml`)

This is the graph the rewritten `architecture.md` must show:

```
shared_kernel (no deps)
  ↑ keys
  ↑ storage
  ↑ wallet (also → keys)
  ↑ address (also → keys, wallet)
  ↑ transaction (also → address after Phase 2)
  ↑ bitcoin_node (also → wallet, address, transaction, rpc_client)

rpc_client (no workspace deps; only `http`)
  ↑ bitcoin_node

ui_kit (no workspace deps)
  (no consumer today)

storage
  ↑ app

App (lib/) depends on every workspace package.
```

### Stale points in current `docs/project/architecture.md`

Comparing the current document
(`/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/project/architecture.md`)
against the real workspace:

| Location | Stale claim | Reality |
|---|---|---|
| Lines 22–62 (Dependency Graph diagram) | Shows only `wallet`, `address`, `keys`, `bitcoin_node`, `shared_kernel`, `rpc_client` | Workspace has 9 packages including `transaction`, `storage`, `ui_kit` |
| Line 53 (graph edges) | `wallet → keys → shared_kernel`, `address → keys, wallet` | Correct |
| Line 59 (graph edges) | `bitcoin_node → wallet, address, rpc_client` | Missing `→ transaction` (verified in `bitcoin_node/pubspec.yaml`) |
| Line 89–95 (`packages/`) | Lists `shared_kernel`, `ui_kit`, `storage`, `rpc_client`, `bitcoin_node` (with old single-line description) | Missing `transaction`. `bitcoin_node` description is pre-Phase-1 (mentions only `WalletRemoteDataSourceImpl`, `AddressRemoteDataSourceImpl`) |
| Lines 96–124 (`keys/` tree) | Lists files in old layout (`bip39_service_impl.dart` directly under `data/`) | Mostly correct; `application/` use cases (`get_xpub_use_case`, `sign_transaction_use_case`, `signing_input_param`) are missing |
| Lines 126–171 (`wallet/` and `address/` trees) | `wallet/domain/entity/wallet.dart` + `wallet_type.dart` listed; `wallet/data/wallet_serializer.dart` listed; `address/data/address_serializer.dart` listed | Reality: `wallet_type.dart` deleted; `hd_wallet.dart` and `node_wallet.dart` exist as parts; `wallet_serializer.dart` replaced by `wallet_mapper.dart`; `address_serializer.dart` replaced by `address_mapper.dart`; new `hd_wallet_repository.dart` and `node_wallet_repository.dart` exist |
| Line 175 (Ownership Table) | Missing `transaction` row | Add row for `transaction` |
| Lines 254–263 (ISP) | Says `BitcoinCoreRemoteDataSource` was split into `WalletRemoteDataSource` and `AddressRemoteDataSource` only | Reality: also `TransactionRemoteDataSource`, `UtxoRemoteDataSource`, `UtxoScanDataSource`, `BroadcastDataSource`, `NodeTransactionDataSource`, `BlockGenerationDataSource`, `HdAddressDataSource` (the latter removed in Phase 2) |
| Lines 312–326 (Avoiding Cycles) | Lists graph; misses `transaction` | Update to include `transaction → shared_kernel, address` |
| Lines 330–356 (DI / Bootstrap Graph) | Missing `TransactionAssembly` and the adapter wiring | Add the actual flow shown in `lib/core/di/app_dependencies_builder.dart` |
| Whole document | Pre-Phase-1 flat `bitcoin_node`, no HD/Node subfolders | After Phases 1 + 3, document the post-refactor tree |
| Whole document | Mentions `HdAddressEntry`-shaped flow in passing? | Verified: no direct mention of `HdAddressEntry` in `architecture.md`, but `architecture.md` still lacks the `transaction → address` edge that Phase 2 introduces |
| `conventions.md` lines 73–83 | Same outdated dependency graph | Must update in lockstep with `architecture.md` (PRD §Constraints) |

### Confirmed `conventions.md` rule to add (Phase 4 deliverable 4)

Add a process rule near the existing prohibitions: any change to a
package's layer structure (subfolder add / remove / rename) must touch
that package's `README.md` in the same PR. PRD specifies this is a
process rule, not a CI rule.

---

## External Facts

- All project `.md` files are English-only (CLAUDE.md memory
  `feedback_language`). Phase 4 outputs must comply.
- `/aidd-run-checks` runs format → analyze → test. None of those
  inspect markdown content; markdown lint is allowed to flag style
  issues. No CI rule enforces the README-touch process rule.
- Phase 4 must run **after** Phases 1–3 ship (PRD Negative scenario).
  If any earlier phase regresses, the corresponding README sections must
  be re-verified.

---

## Risks

| Risk | Impact | Recommendation |
|------|--------|----------------|
| README captures pre-refactor state because Phase 4 starts before Phases 1–3 finish | Documentation drift on day one | PRD §Constraints already requires post-refactor authoring; planner must gate Phase 4 on Phase 3 completion |
| README invents a public symbol or barrel that does not exist (e.g. claims `ui_kit` exposes design tokens — it currently exposes nothing) | Misleading onboarding | Each documented public symbol must be cross-checked against the actual barrel file |
| Dependency graph in rewritten `architecture.md` includes an aspirational edge or omits a real one | Planner agent generates wrong plans | Graph must be derived from the per-package `pubspec.yaml` `dependencies:` blocks; the table in this research file is the source of truth |
| Mixed-language content slips into a README | Forbidden by CLAUDE.md `feedback_language` | Reviewer checklist verifies each file is English-only |
| README count drifts from nine | Forbidden by Phase 4 success metric | `ls packages/*/README.md \| wc -l` must equal 9 |
| `conventions.md` and `architecture.md` diverge again because they re-state overlapping facts (dependency graph appears in both) | Two sources of truth | PRD calls `architecture.md` the single source of truth; `conventions.md` should reference it, not duplicate it |
| `ui_kit` README becomes aspirational vs descriptive (the package has no real exports today) | Misleading content | README must describe today's state honestly: "placeholder design system; tokens, theme, typography intended; no exports yet" — and explicitly mark the empty barrel |

---

## Design Pressure

- The README template (five sections per PRD: Purpose, Public API,
  Dependencies, When-to-add-here, Layer layout) maps cleanly onto the
  raw material assembled above. No package requires a different
  template.
- `architecture.md` rewrite is mostly mechanical: add `transaction`,
  refresh `bitcoin_node` post-Phase-1, add `hd/`/`node/` subfolders
  post-Phase-3 to `wallet/`, `transaction/`, `address/`, regenerate the
  dependency graph from `pubspec.yaml`. The stale-points table above
  enumerates every paragraph that needs editing.
- Adding the README-touch process rule to `conventions.md` is a small
  Markdown insert near the existing Prohibited list. No CI rule, no new
  tooling.
- No source code is modified in Phase 4. `flutter analyze`, `flutter
  test` are stable across the phase. The phase's only risk is content
  accuracy.

---

## References

- Phase 4 PRD: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/BW-0005/prd/BW-0005-phase-4.prd.md`
- Source-of-truth files for graph and tree facts:
  - Root workspace: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/pubspec.yaml`
  - Per-package pubspecs: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/*/pubspec.yaml`
  - Per-package barrels: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/*/lib/*.dart`
  - DI composition root: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/lib/core/di/app_dependencies_builder.dart`
- Documents to rewrite: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/project/architecture.md` and (smaller edits) `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/project/conventions.md`
- Recommended verification commands the implementer should run:
  - `ls packages/*/README.md | wc -l` → 9
  - `grep -n "transaction" docs/project/architecture.md` → shows the new section
  - `grep -n "README" docs/project/conventions.md` → shows the new process rule
  - `for d in packages/*/; do echo "=== $d"; cat $d/pubspec.yaml | grep -A1 "path:"; done` → cross-check the dependency graph in `architecture.md`
  - Manual diff: `architecture.md` `bitcoin_node` subfolder list vs `ls packages/bitcoin_node/lib/src/`
  - Manual diff: `architecture.md` HD/Node subfolder list vs `ls packages/{wallet,transaction,address}/lib/src/{application,data}/`
