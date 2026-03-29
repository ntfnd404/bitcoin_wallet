# Tasklist: FEAT-001 — Wallet Creation, Address Generation, Seed Phrase

Status: `TASKLIST_READY`
Context: Idea `docs/idea-FEAT001.md` · Vision `docs/vision-FEAT001.md`

---

## Progress

| Phase | Tasks | Done |
|-------|-------|------|
| 1. Foundation | 3 | 0 |
| 2. Domain | 4 | 0 |
| 3. Data: RPC + Node Wallet | 3 | 0 |
| 4. Data: HD Wallet + Key Derivation | 4 | 0 |
| 5. BLoC | 3 | 0 |
| 6. UI: Screens | 6 | 0 |
| 7. Navigation & DI | 2 | 0 |

---

## Phase 1: Foundation

- [ ] **1.1 Add dependencies to pubspec.yaml**
  - Add: `coinlib`, `flutter_bloc`, `flutter_secure_storage`, `freezed_annotation`,
    `go_router`, `json_annotation`, `qr_flutter`, `shared_preferences`, `uuid`
  - Dev: `build_runner`, `freezed`, `json_serializable`
  - Acceptance: `flutter pub get` succeeds; all packages visible on all platforms

- [ ] **1.2 Create folder structure**
  - `lib/core/constants/`, `lib/data/api/`, `lib/data/repository/`, `lib/data/storage/`,
    `lib/data/service/`, `lib/domain/model/`, `lib/domain/repository/`, `lib/domain/service/`,
    `lib/feature/wallet/`, `lib/routing/`
  - Acceptance: structure matches `docs/vision-FEAT001.md`

- [ ] **1.3 BitcoinRpcClient**
  - File: `lib/data/api/bitcoin_rpc_client.dart`
  - HTTP POST to `http://bitcoin:bitcoin@127.0.0.1:18443`
  - Method `call(method, params)` → `Future<Map<String, dynamic>>`
  - Acceptance: `getblockchaininfo` returns `chain: regtest`

---

## Phase 2: Domain Models & Interfaces

- [ ] **2.1 Domain models**
  - `WalletType` (enum), `AddressType` (enum)
  - `Wallet` (freezed), `Address` (freezed), `Mnemonic` (freezed — no `toString`)
  - Files: `lib/domain/model/*.dart`
  - Acceptance: `flutter analyze` clean; `build_runner` generates `.freezed.dart`

- [ ] **2.2 Repository interfaces**
  - `WalletRepository`, `SeedRepository`
  - Files: `lib/domain/repository/*.dart`
  - Acceptance: `abstract interface class` with doc comments on all methods

- [ ] **2.3 Domain service interfaces**
  - `Bip39Service`, `KeyDerivationService`
  - Files: `lib/domain/service/*.dart`
  - Acceptance: interfaces define contract without implementation

- [ ] **2.4 AppConstants**
  - `lib/core/constants/app_constants.dart`
  - `rpcUrl`, `rpcUser`, `rpcPassword`, derivation paths per `AddressType`
  - Acceptance: no magic strings in code; all values are named constants

---

## Phase 3: Data — RPC & Node Wallet

- [ ] **3.1 SecureStorage adapter**
  - `lib/data/storage/secure_storage.dart`
  - Wrapper around `flutter_secure_storage`
  - Acceptance: write/read/delete work; no plaintext in logs

- [ ] **3.2 NodeWalletRepositoryImpl**
  - `lib/data/repository/node_wallet_repository_impl.dart`
  - `createNodeWallet` → RPC `createwallet`
  - `generateAddress` → RPC `getnewaddress` with type (`legacy`, `p2sh-segwit`, `bech32`, `bech32m`)
  - Acceptance: Legacy starts `m`, bech32 starts `bcrt1q`, bech32m starts `bcrt1p`
  - HD methods throw `UnsupportedError`

- [ ] **3.3 Address verification via Bitcoin Core**
  - Unit test or manual check: addresses from `NodeWalletRepositoryImpl`
    match expected regtest format per type
  - Acceptance: `getaddressinfo` returns correct `scriptPubKey.type`

---

## Phase 4: Data — HD Wallet & Key Derivation

- [ ] **4.1 Bip39ServiceImpl**
  - `lib/data/service/bip39_service_impl.dart`
  - Uses `coinlib`
  - `generateMnemonic(wordCount: 12|24)` → `Mnemonic`
  - `validateMnemonic(mnemonic)` → `bool`
  - Acceptance: generated mnemonic passes validation; invalid does not

- [ ] **4.2 KeyDerivationServiceImpl**
  - `lib/data/service/key_derivation_service_impl.dart`
  - Uses `coinlib` BIP32 + paths from `AppConstants`
  - `deriveAddress(mnemonic, AddressType, index)` → `Address`
  - Paths: `m/44'/1'/0'/0/n`, `m/49'/1'/0'/0/n`, `m/84'/1'/0'/0/n`, `m/86'/1'/0'/0/n`
  - Acceptance: regtest prefixes correct; derivation deterministic

- [ ] **4.3 SeedRepositoryImpl**
  - `lib/data/repository/seed_repository_impl.dart`
  - Stores seed under key `seed_<walletId>`
  - Acceptance: seed survives app restart; missing seed returns null

- [ ] **4.4 HdWalletRepositoryImpl**
  - `lib/data/repository/hd_wallet_repository_impl.dart`
  - `createHDWallet(name)` → generate mnemonic → store seed → `(Wallet, Mnemonic)`
  - `restoreHDWallet(name, mnemonic)` → validate → store seed
  - `generateAddress(wallet, type)` → derive at next index
  - Acceptance: restored wallet generates identical addresses as original

---

## Phase 5: BLoC

- [ ] **5.1 WalletBloc**
  - Events: `WalletListRequested`, `NodeWalletCreateRequested(name)`,
    `HdWalletCreateRequested(name, wordCount)`, `WalletRestoreRequested(name, mnemonic)`,
    `SeedConfirmed(walletId)`, `SeedViewRequested(walletId)`
  - State: `WalletState { wallets, status, pendingWallet, pendingMnemonic }`
  - `WalletStatus`: `initial, loading, loaded, creating, awaitingSeedConfirmation, error`
  - Acceptance: after `HdWalletCreateRequested` → status `awaitingSeedConfirmation`

- [ ] **5.2 AddressBloc**
  - Events: `AddressListRequested(walletId)`, `AddressGenerateRequested(wallet, type)`
  - State: `AddressState { addresses, status, lastGenerated }`
  - `AddressStatus`: `initial, loading, loaded, generating, error`
  - Acceptance: `lastGenerated` has correct `derivationPath`

- [ ] **5.3 WalletScope (DI)**
  - `lib/feature/wallet/di/wallet_scope.dart`
  - `InheritedWidget` + `WalletScopeBlocFactory`
  - Provides `WalletBloc` and `AddressBloc`
  - Acceptance: accessible via `context.walletScopeBlocFactory`

---

## Phase 6: UI Screens

- [ ] **6.1 WalletListScreen** — list + FAB; empty state; navigate to CreateWalletScreen
- [ ] **6.2 CreateWalletScreen** — type selector + name input; Node→Detail, HD→Seed
- [ ] **6.3 SeedPhraseScreen** — 12/24-word grid; warning; mandatory confirmation
- [ ] **6.4 RestoreWalletScreen** — seed input; real-time BIP39 validation
- [ ] **6.5 WalletDetailScreen** — addresses by type; generate button; show seed (HD only)
- [ ] **6.6 AddressScreen** — address text + copy; QR code; derivation path or "Managed by Bitcoin Core"

---

## Phase 7: Navigation & Integration

- [ ] **7.1 go_router setup**
  - `lib/routing/app_router.dart`
  - Routes: `/`, `/wallet/create`, `/wallet/seed`, `/wallet/restore`,
    `/wallet/:id`, `/wallet/:id/address/:type`
  - Acceptance: navigation works on all platforms

- [ ] **7.2 Update main.dart**
  - `MaterialApp.router` with go_router
  - Initialize DI (WalletScope at root)
  - Acceptance: app launches and shows WalletListScreen

---

## Definition of Done

- [ ] All tasks above marked `[x]`
- [ ] HD Wallet: seed → addresses match on restore
- [ ] Node Wallet: addresses generated via RPC with correct regtest prefix
- [ ] Seed phrase stored in flutter_secure_storage
- [ ] `flutter analyze` — no errors or warnings
- [ ] App launches on macOS
