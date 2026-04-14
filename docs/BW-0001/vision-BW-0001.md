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

Clean Architecture + Hexagonal: **Data → Domain ← Presentation**
State management: **BLoC** (flutter_bloc)
Navigation: **Flutter built-in Navigator**
DI: manual constructor-based via Scope widgets (InheritedWidget)
Workspace: Dart pub workspace monorepo — domain and data live in separate packages.

### File structure to create

```
bitcoin_wallet/                             # workspace root
│
├── lib/
│   ├── core/
│   │   ├── constants/app_constants.dart   # rpcUrl, rpcUser, derivation paths
│   │   └── routing/app_router.dart        # route constants + Navigator helpers
│   ├── common/
│   │   ├── widgets/                       # shared app-level components
│   │   ├── extensions/                    # BuildContext, String extensions
│   │   └── utils/                         # pure helpers
│   └── feature/wallet/
│       ├── bloc/
│       │   ├── wallet_bloc.dart
│       │   ├── wallet_event.dart
│       │   └── wallet_state.dart
│       ├── di/
│       │   └── wallet_scope.dart
│       └── view/
│           ├── screen/
│           │   ├── wallet_list_screen.dart
│           │   ├── wallet_detail_screen.dart
│           │   ├── create_wallet_screen.dart
│           │   ├── seed_phrase_screen.dart
│           │   ├── restore_wallet_screen.dart
│           │   └── address_screen.dart
│           └── widget/
│               └── wallet_card.dart
│
└── packages/
    ├── domain/lib/src/
    │   ├── entity/
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
    ├── data/lib/src/
    │   ├── repository/
    │   │   ├── node_wallet_repository_impl.dart
    │   │   ├── hd_wallet_repository_impl.dart
    │   │   └── seed_repository_impl.dart
    │   └── service/
    │       ├── bip39_service_impl.dart
    │       └── key_derivation_service_impl.dart
    ├── rpc/lib/src/
    │   └── bitcoin_rpc_client.dart
    ├── storage/lib/src/
    │   └── secure_storage.dart
    └── ui_kit/lib/src/
        ├── tokens/
        ├── typography/
        └── theme/
```

---

## Dependencies

### BIP39 / HD Key Derivation

**Decision: implement BIP39/BIP32/address encoding manually** — the goal of the project is to demonstrate knowledge of Bitcoin standards, not to use ready-made Bitcoin abstractions.

Only low-level crypto primitives are used:

| Package | Version | Role |
|---------|---------|------|
| `crypto` | 3.0.7 | SHA-256, HMAC-SHA512, RIPEMD-160 |
| `pointycastle` | 4.0.0 | secp256k1 EC operations (BIP32 derivation, signing) |

Implemented manually:
- BIP39: wordlist lookup, entropy → mnemonic → seed (PBKDF2-HMAC-SHA512)
- BIP32: HMAC-SHA512 child key derivation, hardened/normal paths
- Address encoding: P2PKH, P2SH-P2WPKH, P2WPKH (bech32), P2TR (bech32m)
- Base58Check, Bech32/Bech32m encoding

ADR-001 (coinlib) — superseded by this decision.

### Required packages

```yaml
dependencies:
  crypto: 3.0.7
  flutter_bloc: 9.1.1
  flutter_secure_storage: 10.0.0
  json_annotation: 4.11.0
  pointycastle: 4.0.0
  uuid: 4.5.3

dev_dependencies:
  json_serializable: 6.13.1
```

⚠️ `flutter_secure_storage` uses unencrypted `localStorage` on Web — show warning in UI.

---

## Domain Layer

### Models

```dart
// packages/domain/lib/src/entity/wallet_type.dart
enum WalletType { node, hd }

// packages/domain/lib/src/entity/address_type.dart
enum AddressType { legacy, wrappedSegwit, nativeSegwit, taproot }

// packages/domain/lib/src/entity/wallet.dart
final class Wallet {
  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String name;
  final WalletType type;
  final DateTime createdAt;

  Wallet copyWith({
    String? id,
    String? name,
    WalletType? type,
    DateTime? createdAt,
  }) => Wallet(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
  );
}

// packages/domain/lib/src/entity/address.dart
final class Address {
  const Address({
    required this.value,
    required this.type,
    required this.derivationPath, // null for Node Wallet
    required this.index,
  });

  final String value;
  final AddressType type;
  final String? derivationPath;
  final int index;

  Address copyWith({
    String? value,
    AddressType? type,
    String? derivationPath,
    int? index,
  }) => Address(
    value: value ?? this.value,
    type: type ?? this.type,
    derivationPath: derivationPath ?? this.derivationPath,
    index: index ?? this.index,
  );
}

// packages/domain/lib/src/entity/mnemonic.dart
final class Mnemonic {
  const Mnemonic({required this.words});

  final List<String> words;

  // No toString() — prevents accidental logging of sensitive data
}
```

### Repository interfaces

```dart
// packages/domain/lib/src/repository/wallet_repository.dart
abstract interface class WalletRepository {
  Future<List<Wallet>> getWallets();
  Future<Wallet> createNodeWallet(String name);
  Future<(Wallet, Mnemonic)> createHDWallet(String name, {int wordCount = 12});
  Future<Wallet> restoreHDWallet(String name, Mnemonic mnemonic);
  Future<Address> generateAddress(Wallet wallet, AddressType type);
  Future<List<Address>> getAddresses(Wallet wallet);
}

// packages/domain/lib/src/repository/seed_repository.dart
abstract interface class SeedRepository {
  Future<void> storeSeed(String walletId, Mnemonic mnemonic);
  Future<Mnemonic?> getSeed(String walletId);
  Future<void> deleteSeed(String walletId);
}
```

### Service interfaces

```dart
// packages/domain/lib/src/service/bip39_service.dart
abstract interface class Bip39Service {
  Mnemonic generateMnemonic({int wordCount = 12});
  bool validateMnemonic(Mnemonic mnemonic);
}

// packages/domain/lib/src/service/key_derivation_service.dart
abstract interface class KeyDerivationService {
  Address deriveAddress(Mnemonic mnemonic, AddressType type, int index);
}
```

---

## Data Layer

### RPC Client

```dart
// packages/rpc_client/lib/src/bitcoin_rpc_client.dart
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

Navigation uses Flutter's built-in Navigator with `Navigator.push` / `Navigator.pop` / `Navigator.pushNamed`.

```
WalletListScreen  →  Navigator.push → CreateWalletScreen
CreateWalletScreen (Node)  →  Navigator.pushReplacement → WalletDetailScreen
CreateWalletScreen (HD)    →  Navigator.push → SeedPhraseScreen
SeedPhraseScreen           →  Navigator.pushReplacement → WalletDetailScreen
WalletDetailScreen         →  Navigator.push → AddressScreen
                           →  Navigator.push → RestoreWalletScreen
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
    → store wallet metadata in flutter_secure_storage
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
      → derive key at m/84'/1'/0'/0/n using crypto + pointycastle
      → encode as P2WPKH bech32 with HRP='bcrt'
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

- [ ] Verify regtest address correctness for manual derivation (phase 3 task 3.3)
- [ ] Default mnemonic length: 12 for demo, option for 24
