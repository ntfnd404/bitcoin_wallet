# Vision: Wallet Creation, Address Generation, Seed Phrase (BW-0001)

Status: `RESEARCH_DONE`
Date: 2026-03-26

---

## Overview

This document is the authoritative technical design for BW-0001.
It covers architecture, dependency decisions, Bitcoin specifics, and data flows.

Two wallet types coexist in a single app:
- **Node Wallet** — custodial; Bitcoin Core manages keys; Flutter calls RPC.
- **HD Wallet** — non-custodial; BIP39 mnemonic in app; keys in `flutter_secure_storage`.

---

## Current Codebase State

```
lib/
└── main.dart   # Hello World — no architecture, starting from scratch
```

Flutter SDK: Dart ^3.11.3. All layers created from scratch.

---

## Architecture

Clean Architecture: **Data → Domain → Presentation**
State management: **BLoC** (flutter_bloc + freezed)
Navigation: **go_router**
DI: manual constructor-based via Scope widgets (InheritedWidget)

### File structure to create

```
lib/
├── core/constants/app_constants.dart
├── data/
│   ├── api/bitcoin_rpc_client.dart
│   ├── repository/
│   │   ├── node_wallet_repository_impl.dart
│   │   ├── hd_wallet_repository_impl.dart
│   │   └── seed_repository_impl.dart
│   ├── service/
│   │   ├── bip39_service_impl.dart
│   │   └── key_derivation_service_impl.dart
│   └── storage/secure_storage.dart
├── domain/
│   ├── model/
│   │   ├── wallet.dart
│   │   ├── wallet_type.dart
│   │   ├── address.dart
│   │   ├── address_type.dart
│   │   └── mnemonic.dart
│   ├── repository/
│   │   ├── wallet_repository.dart
│   │   └── seed_repository.dart
│   └── service/
│       ├── bip39_service.dart
│       └── key_derivation_service.dart
└── feature/wallet/
    ├── bloc/
    ├── di/
    └── view/
```

---

## Dependencies

### BIP39 / HD Key Derivation

| Package | Version | Platforms | Notes |
|---------|---------|-----------|-------|
| `bip39` | 1.0.6 | all | BIP39 only, pure Dart |
| `bitcoin_flutter` | 0.0.6 | all | BIP32 only, outdated |
| `hdwallet` | 1.5.0 | all | BIP44/49/84, no Taproot |
| **`coinlib`** | **2.2.0** | **all (incl. Web, Linux)** | **Full: BIP32, all addr types, Taproot, active** |

**Decision: `coinlib`** — only active library with BIP32 + P2PKH + P2SH-P2WPKH + P2WPKH + P2TR + configurable network params (regtest) + all platforms.

See `docs/adr/ADR-001-coinlib.md` for full decision record.

### Required packages

```yaml
dependencies:
  coinlib: 2.2.0
  flutter_bloc: 8.1.6
  flutter_secure_storage: 9.2.4
  freezed_annotation: 2.4.4
  go_router: 14.8.1
  json_annotation: 4.9.0
  qr_flutter: 4.1.0
  shared_preferences: 2.3.4
  uuid: 4.5.1

dev_dependencies:
  build_runner: 2.4.13
  freezed: 2.5.7
  json_serializable: 6.9.4
```

⚠️ `flutter_secure_storage` uses unencrypted `localStorage` on Web — show warning in UI.

---

## Domain Layer

### Models

```dart
// lib/domain/model/wallet_type.dart
enum WalletType { node, hd }

// lib/domain/model/address_type.dart
enum AddressType { legacy, wrappedSegwit, nativeSegwit, taproot }

// lib/domain/model/wallet.dart
@freezed
abstract class Wallet with _$Wallet {
  const factory Wallet({
    required String id,
    required String name,
    required WalletType type,
    required DateTime createdAt,
  }) = _Wallet;
}

// lib/domain/model/address.dart
@freezed
abstract class Address with _$Address {
  const factory Address({
    required String value,
    required AddressType type,
    required String? derivationPath, // null for Node Wallet
    required int index,
  }) = _Address;
}

// lib/domain/model/mnemonic.dart
@freezed
abstract class Mnemonic with _$Mnemonic {
  const factory Mnemonic({required List<String> words}) = _Mnemonic;
  // No toString() — prevents accidental logging of sensitive data
}
```

### Repository interfaces

```dart
// lib/domain/repository/wallet_repository.dart
abstract interface class WalletRepository {
  Future<List<Wallet>> getWallets();
  Future<Wallet> createNodeWallet(String name);
  Future<(Wallet, Mnemonic)> createHDWallet(String name, {int wordCount = 12});
  Future<Wallet> restoreHDWallet(String name, Mnemonic mnemonic);
  Future<Address> generateAddress(Wallet wallet, AddressType type);
  Future<List<Address>> getAddresses(Wallet wallet);
}

// lib/domain/repository/seed_repository.dart
abstract interface class SeedRepository {
  Future<void> storeSeed(String walletId, Mnemonic mnemonic);
  Future<Mnemonic?> getSeed(String walletId);
  Future<void> deleteSeed(String walletId);
}
```

### Service interfaces

```dart
// lib/domain/service/bip39_service.dart
abstract interface class Bip39Service {
  Mnemonic generateMnemonic({int wordCount = 12});
  bool validateMnemonic(Mnemonic mnemonic);
}

// lib/domain/service/key_derivation_service.dart
abstract interface class KeyDerivationService {
  Address deriveAddress(Mnemonic mnemonic, AddressType type, int index);
}
```

---

## Data Layer

### RPC Client

```dart
// lib/data/api/bitcoin_rpc_client.dart
class BitcoinRpcClient {
  // POST http://bitcoin:bitcoin@127.0.0.1:18443
  Future<Map<String, dynamic>> call(String method, [List<dynamic> params = const []]);
}
```

### Repository implementations

```dart
// NodeWalletRepositoryImpl
// createNodeWallet → RPC createwallet
// generateAddress  → RPC getnewaddress with address type
// HD methods throw UnsupportedError

// HdWalletRepositoryImpl
// createHDWallet   → Bip39Service.generate → store seed → return (wallet, mnemonic)
// restoreHDWallet  → Bip39Service.validate → store seed
// generateAddress  → KeyDerivationService.derive at next index

// SeedRepositoryImpl
// flutter_secure_storage, key: "seed_${walletId}"
```

---

## Presentation Layer

### BLoC

```dart
// WalletBloc events:
//   WalletListRequested
//   NodeWalletCreateRequested(name)
//   HdWalletCreateRequested(name, wordCount)
//   WalletRestoreRequested(name, mnemonic)
//   SeedConfirmed(walletId)
//   SeedViewRequested(walletId)
// State: WalletState { wallets, status, pendingWallet, pendingMnemonic }
// WalletStatus: initial, loading, loaded, creating, awaitingSeedConfirmation, error

// AddressBloc events:
//   AddressListRequested(walletId)
//   AddressGenerateRequested(wallet, type)
// State: AddressState { addresses, status, lastGenerated }
// AddressStatus: initial, loading, loaded, generating, error
```

### Screens

| Screen | File | Description |
|--------|------|-------------|
| WalletListScreen | `wallet_list_screen.dart` | List + FAB |
| CreateWalletScreen | `create_wallet_screen.dart` | Type selector + name input |
| SeedPhraseScreen | `seed_phrase_screen.dart` | Seed display + confirmation |
| RestoreWalletScreen | `restore_wallet_screen.dart` | Seed phrase input |
| WalletDetailScreen | `wallet_detail_screen.dart` | Addresses + actions |
| AddressScreen | `address_screen.dart` | Address + QR + derivation path |

### Navigation

```
/                         → WalletListScreen
/wallet/create            → CreateWalletScreen
/wallet/seed              → SeedPhraseScreen
/wallet/restore           → RestoreWalletScreen
/wallet/:id               → WalletDetailScreen
/wallet/:id/address/:type → AddressScreen
```

---

## Bitcoin Specifics

### Regtest network parameters

| Parameter | Value |
|-----------|-------|
| coin_type (BIP44) | `1` |
| P2PKH version byte | `0x6F` → prefix `m` or `n` |
| P2SH version byte | `0xC4` → prefix `2` |
| Bech32 HRP | `bcrt` → prefix `bcrt1q` |
| Bech32m HRP | `bcrt` → prefix `bcrt1p` |

### Derivation paths

| Type | Path |
|------|------|
| Legacy P2PKH | `m/44'/1'/0'/0/n` |
| Wrapped SegWit P2SH-P2WPKH | `m/49'/1'/0'/0/n` |
| Native SegWit P2WPKH | `m/84'/1'/0'/0/n` |
| Taproot P2TR | `m/86'/1'/0'/0/n` |

### Bitcoin Core RPC for Node Wallet

```json
{ "method": "createwallet",  "params": { "wallet_name": "name", "descriptors": true } }
{ "method": "getnewaddress", "params": ["label", "legacy"] }
{ "method": "getnewaddress", "params": ["label", "p2sh-segwit"] }
{ "method": "getnewaddress", "params": ["label", "bech32"] }
{ "method": "getnewaddress", "params": ["label", "bech32m"] }
```

---

## Data Flows

### HD Wallet creation

```
CreateWalletScreen
  → WalletBloc.add(HdWalletCreateRequested(name))
  → HdWalletRepositoryImpl.createHDWallet(name)
    → Bip39ServiceImpl.generateMnemonic()
    → SeedRepositoryImpl.storeSeed(walletId, mnemonic)
    → store wallet metadata in SharedPreferences
  ← (Wallet, Mnemonic)
  → emit(state.copyWith(status: awaitingSeedConfirmation, pendingMnemonic: mnemonic))
SeedPhraseScreen shows mnemonic, user confirms → navigate to WalletDetailScreen
```

### Address generation (HD Wallet)

```
WalletDetailScreen, user selects address type
  → AddressBloc.add(AddressGenerateRequested(wallet, type))
  → HdWalletRepositoryImpl.generateAddress(wallet, type)
    → KeyDerivationServiceImpl.deriveAddress(mnemonic, type, nextIndex)
      → coinlib: derive key at m/84'/1'/0'/0/n
      → coinlib: encode as P2WPKH bech32 with HRP='bcrt'
    ← Address(value: 'bcrt1q...', derivationPath: "m/84'/1'/0'/0/0")
  → emit(state.copyWith(lastGenerated: address))
AddressScreen shows address + QR
```

### Node Wallet address generation

```
WalletDetailScreen
  → AddressBloc.add(AddressGenerateRequested(wallet, type))
  → NodeWalletRepositoryImpl.generateAddress(wallet, type)
    → BitcoinRpcClient.call('getnewaddress', [label, 'bech32'])
  ← Address(value: 'bcrt1q...', derivationPath: null)
```

---

## Non-Functional Requirements

- `Mnemonic` has no `toString()` — prevents accidental logging
- Seed phrase does not propagate beyond `SeedPhraseScreen` in the UI layer
- Private keys exist only in domain/data layer
- On Web: warning that `flutter_secure_storage` uses unencrypted localStorage

---

## Open Questions

- [ ] Verify `coinlib` regtest address correctness (phase 3 task 3.3)
- [ ] Default mnemonic length: 12 for demo, option for 24
