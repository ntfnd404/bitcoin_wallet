# Tasklist: BW-0001 — Wallet Creation, Address Generation, Seed Phrase

Status: `TASKLIST_READY`
Context: Idea `docs/idea-BW-0001.md` · Vision `docs/vision-BW-0001.md`

---

## Progress

| Phase | Tasks | Done |
|-------|-------|------|
| 1. Foundation | 3 | 3 |
| 2. Domain | 6 | 6 |
| 3. Data: RPC + Node Wallet | 3 | 3 |
| 4. Data: HD Wallet + Key Derivation | 4 | 4 |
| 5. BLoC | 3 | 3 |
| 6. UI: Screens | 6 | 6 |
| 7. Navigation & Integration | 2 | 2 |

---

## Phase 1: Foundation

- [x] **1.1 Add dependencies to pubspec.yaml**
  - Add: `crypto`, `flutter_bloc: 9.1.1`, `flutter_secure_storage: 10.0.0`,
    `json_annotation`, `pointycastle`, `uuid: 4.5.3`
  - Dev: `json_serializable`
  - Acceptance: `flutter pub get` succeeds; all packages visible on all platforms

- [x] **1.2 Create folder structure**
  - `lib/core/constants/`, `packages/` workspace scaffold
  - Acceptance: structure matches `docs/vision-BW-0001.md`

- [x] **1.3 BitcoinRpcClient**
  - File: `packages/rpc_client/lib/src/bitcoin_rpc_client.dart`
  - HTTP POST to `http://bitcoin:bitcoin@127.0.0.1:18443`
  - Method `call(method, params)` → `Future<Map<String, Object?>>`
  - Acceptance: `getblockchaininfo` returns `chain: regtest`

---

## Phase 2: Domain Models & Interfaces

- [x] **2.1 Domain entities**
  - `WalletType` (enum), `AddressType` (enum)
  - `Wallet` (immutable class), `Address` (immutable class), `Mnemonic` (immutable class — no `toString`)
  - Files: `packages/domain/lib/src/entity/*.dart`
  - Acceptance: `flutter analyze` clean; each model has `const` constructor and `copyWith`

- [x] **2.2 Repository interfaces**
  - `WalletQueryRepository` (read-only composite interface), `NodeWalletRepository`, `HdWalletRepository`, `SeedRepository`
  - Files: `packages/domain/lib/src/repository/*.dart`
  - Acceptance: `abstract interface class` with doc comments on all methods

- [x] **2.3 Domain service interfaces**
  - `Bip39Service`, `KeyDerivationService`
  - Files: `packages/domain/lib/src/service/*.dart`
  - Acceptance: interfaces define contract without implementation

- [x] **2.4 AppConstants**
  - `lib/core/constants/app_constants.dart`
  - `network` (active `BitcoinNetwork`), `rpcUrl`, `rpcUser`, `rpcPassword`, derivation paths via `network.coinType`
  - Acceptance: switching network = one line change; no magic numbers

- [x] **2.5 DI scaffold**
  - `lib/core/di/app_dependencies.dart` — immutable container (fields = domain interfaces)
  - `lib/core/di/app_dependencies_builder.dart` — composition root (stub, filled in Phases 3–4)
  - `lib/app.dart` — `AppScope` (InheritedWidget) + `App` widget (replaces `MainApp`)
  - `lib/main.dart` — `runZonedGuarded` + `AppDependenciesBuilder().build()` + `AppScope`
  - Acceptance: app compiles and launches; `AppScope.of(context)` is accessible in widget tree

- [x] **2.6 BitcoinNetwork**
  - `packages/domain/lib/src/entity/bitcoin_network.dart`
  - Enhanced enum: `mainnet`, `testnet`, `regtest` with fields `p2pkhPrefix`, `p2shPrefix`, `bech32Hrp`, `coinType`, `rpcPort`
  - Acceptance: switching to mainnet = one constant in `AppConstants`; no magic numbers in derivation

---

## Phase 3: Data — RPC & Node Wallet

- [x] **3.1 SecureStorage adapter**
  - `packages/storage/lib/src/secure_storage.dart` — already scaffolded
  - Wrapper around `flutter_secure_storage`
  - Acceptance: write/read/delete work; no plaintext in logs

- [x] **3.2 NodeWalletRepositoryImpl**
  - `packages/data/lib/src/repository/node_wallet_repository_impl.dart`
  - `createNodeWallet` → RPC `createwallet`
  - `generateAddress` → RPC `getnewaddress` with type (`legacy`, `p2sh-segwit`, `bech32`, `bech32m`)
  - Acceptance: Legacy starts `m`, bech32 starts `bcrt1q`, bech32m starts `bcrt1p`
  - HD methods throw `UnsupportedError`

- [x] **3.3 Address verification via Bitcoin Core**
  - Unit test or manual check: addresses from `NodeWalletRepositoryImpl`
    match expected regtest format per type
  - Acceptance: `getaddressinfo` returns correct `scriptPubKey.type`

---

## Phase 4: Data — HD Wallet & Key Derivation

- [x] **4.1 Bip39ServiceImpl**
  - `packages/data/lib/src/service/bip39_service_impl.dart`
  - Uses `crypto` + `pointycastle` (manual BIP39 implementation)
  - `generateMnemonic(wordCount: 12|24)` → `Mnemonic`
  - `validateMnemonic(mnemonic)` → `bool`
  - Acceptance: generated mnemonic passes validation; invalid does not

- [x] **4.2 KeyDerivationServiceImpl**
  - `packages/data/lib/src/service/key_derivation_service_impl.dart`
  - Uses `crypto` + `pointycastle` for BIP32 derivation + paths from `AppConstants`
  - `deriveAddress(mnemonic, AddressType, index)` → `Address`
  - Paths: `m/44'/1'/0'/0/n`, `m/49'/1'/0'/0/n`, `m/84'/1'/0'/0/n`, `m/86'/1'/0'/0/n`
  - Acceptance: regtest prefixes correct; derivation deterministic

- [x] **4.3 SeedRepositoryImpl**
  - `packages/data/lib/src/repository/seed_repository_impl.dart`
  - Stores seed under key `seed_<walletId>`
  - Acceptance: seed survives app restart; missing seed returns null

- [x] **4.4 HdWalletRepositoryImpl + data-layer gateway**
  - `packages/data/lib/src/repository/hd_wallet_repository_impl.dart` — pure CRUD: `saveWallet`, `getWallets`, `saveAddress`, `getAddresses`, `nextAddressIndex`
  - `packages/data/lib/src/gateway/bitcoin_core_gateway_impl.dart` — data-internal RPC gateway (`createWallet`, `generateAddress`)
  - `packages/data/lib/src/repository/node_wallet_repository_impl.dart` — delegates to gateway + WalletLocalStore
  - `packages/data/lib/src/repository/composite_wallet_query_repository.dart` — merges node + HD repos for `GetWalletsUseCase`
  - Business logic (BIP39 + derivation + UUID) lives in use cases under `lib/feature/wallet/domain/usecase/`
  - Acceptance: restored wallet generates identical addresses as original

---

## Phase 5: BLoC

- [x] **5.1 WalletBloc** (`lib/feature/wallet/bloc/wallet/`)
  - Events: `WalletListRequested`, `NodeWalletCreateRequested(name)`,
    `HdWalletCreateRequested(name, wordCount)`, `WalletRestoreRequested(name, mnemonic)`,
    `SeedConfirmed(walletId)`, `SeedViewRequested(walletId)`
  - State: `WalletState { wallets, status, pendingWallet, pendingMnemonic }`
  - `WalletStatus`: `initial, loading, loaded, creating, awaitingSeedConfirmation, error`
  - Constructor receives use cases, not repositories
  - Acceptance: after `HdWalletCreateRequested` → status `awaitingSeedConfirmation`

- [x] **5.2 AddressBloc** (`lib/feature/wallet/bloc/address/`)
  - Events: `AddressListRequested(wallet)`, `AddressGenerateRequested(wallet, type)`
  - State: `AddressState { addresses, status, lastGenerated }`
  - `AddressStatus`: `initial, loading, loaded, generating, error`
  - Constructor receives `GetAddressesUseCase` + `GenerateAddressUseCase`
  - Acceptance: `lastGenerated` has correct `derivationPath`

- [x] **5.3 WalletScope (DI)**
  - `lib/feature/wallet/di/wallet_scope.dart`
  - `StatefulWidget` wrapping `_InheritedWalletScope` + `WalletScopeBlocFactory`
  - Factory creates all use cases from injected repos/services; factory creates BLoCs
  - Acceptance: accessible via `WalletScope.of(context)`

---

## Phase 6: UI Screens

- [x] **6.1 WalletListScreen** (`view/screen/list/`) — list + FAB; empty state; navigate to CreateWalletScreen
- [x] **6.2 CreateWalletScreen** (`view/screen/setup/`) — type selector + name input; Node→Detail, HD→Seed
- [x] **6.3 SeedPhraseScreen** (`view/screen/setup/`) — 12/24-word grid; warning; mandatory confirmation
- [x] **6.4 RestoreWalletScreen** (`view/screen/setup/`) — seed input; real-time BIP39 validation
- [x] **6.5 WalletDetailScreen** (`view/screen/detail/`) — addresses by type; generate button; show seed (HD only)
- [x] **6.6 AddressScreen** (`view/screen/detail/`) — address text + copy; QR code; derivation path or "Managed by Bitcoin Core"

---

## Phase 7: Navigation & Integration

- [x] **7.1 Navigator setup**
  - `lib/core/routing/app_router.dart`
  - Route constants and helper methods for `Navigator.push` / `Navigator.pop` / `Navigator.pushNamed`
  - Screens: WalletListScreen, CreateWalletScreen, SeedPhraseScreen, RestoreWalletScreen,
    WalletDetailScreen, AddressScreen
  - Acceptance: navigation works on all platforms

- [x] **7.2 Wire navigation and WalletScope**
  - Add `AppRouter` and named routes to `MaterialApp` in `lib/app.dart`
  - Wrap `MaterialApp` with `WalletScope` (feature DI) inside `App`
  - Fill `AppDependenciesBuilder` with all remaining implementations
  - Acceptance: app launches and shows `WalletListScreen`; all BLoC deps resolved

---

## Definition of Done

- [ ] All tasks above marked `[x]`
- [ ] HD Wallet: seed → addresses match on restore
- [ ] Node Wallet: addresses generated via RPC with correct regtest prefix
- [ ] Seed phrase stored in flutter_secure_storage
- [ ] `flutter analyze` — no errors or warnings
- [ ] App launches on macOS
