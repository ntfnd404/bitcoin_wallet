# Phase 2: Domain Models & Interfaces

Status: `PLAN_APPROVED`
Ticket: BW-0001

---

## Goal

Define all domain entities, repository interfaces, service interfaces, and
`AppConstants` derivation paths in the `packages/domain` package.

---

## Context

Phase 1 delivered `BitcoinRpcClient`, the workspace structure, and the DI scaffold
(`AppScope`, `AppDependencies`, `AppDependenciesBuilder`). Task 2.5 (DI scaffold) is
already complete.

Phase 2 establishes the **stable core** that all other phases depend on:
- `data` package (Phases 3–4) implements these interfaces
- `feature/wallet` BLoC (Phase 5) depends on these interfaces via `AppDependencies`
- Nothing in the app can call domain logic before Phase 2 is done

---

## Tasks

- [ ] **2.1** Domain entities — `WalletType`, `AddressType`, `Wallet`, `Address`, `Mnemonic`
- [ ] **2.2** Repository interfaces — `WalletRepository`, `SeedRepository`
- [ ] **2.3** Service interfaces — `Bip39Service`, `KeyDerivationService`
- [ ] **2.4** `AppConstants` — network config + derivation paths via `network.coinType`
- [x] **2.5** DI scaffold — `AppDependencies`, `AppDependenciesBuilder`, `AppScope` (split to `lib/core/di/`), `main.dart` *(done)*
- [ ] **2.6** `BitcoinNetwork` enum — `mainnet`, `testnet`, `regtest` с network params

After 2.1–2.3: update `AppDependencies` with typed fields and add stub
`UnimplementedError` implementations in `AppDependenciesBuilder`.

---

## Acceptance Criteria

- `packages/domain` has zero dependencies (pubspec unchanged)
- `flutter analyze` — zero warnings
- All entities have `const` constructors and `copyWith`
- `Mnemonic` has no `toString()` override
- All interface methods have doc comments
- App launches on macOS: `AppScope.of(context)` returns `AppDependencies` with all fields

---

## Technical Details

### Enums

```dart
// wallet_type.dart
enum WalletType { node, hd }

// address_type.dart
enum AddressType { legacy, wrappedSegwit, nativeSegwit, taproot }
```

### Entities

```dart
// wallet.dart
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

  Wallet copyWith({String? id, String? name, WalletType? type, DateTime? createdAt}) =>
      Wallet(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
      );
}

// address.dart
final class Address {
  const Address({
    required this.value,
    required this.type,
    required this.walletId,
    required this.index,
    this.derivationPath,
  });

  final String value;
  final AddressType type;
  final String walletId;
  final int index;
  final String? derivationPath; // null for Node Wallet

  Address copyWith({...}) => ...;
}

// mnemonic.dart — no toString()
final class Mnemonic {
  const Mnemonic({required this.words});
  final List<String> words;
}
```

### Interfaces

```dart
abstract interface class WalletRepository {
  Future<List<Wallet>> getWallets();
  Future<Wallet> createNodeWallet(String name);
  Future<(Wallet, Mnemonic)> createHDWallet(String name, {int wordCount = 12});
  Future<Wallet> restoreHDWallet(String name, Mnemonic mnemonic);
  Future<Address> generateAddress(Wallet wallet, AddressType type);
  Future<List<Address>> getAddresses(Wallet wallet);
}

abstract interface class SeedRepository {
  Future<void> storeSeed(String walletId, Mnemonic mnemonic);
  Future<Mnemonic?> getSeed(String walletId);
  Future<void> deleteSeed(String walletId);
}

abstract interface class Bip39Service {
  Mnemonic generateMnemonic({int wordCount = 12});
  bool validateMnemonic(Mnemonic mnemonic);
}

abstract interface class KeyDerivationService {
  Address deriveAddress(Mnemonic mnemonic, AddressType type, int index);
}
```

### AppConstants additions

```dart
static const String derivationPathLegacy        = "m/44'/1'/0'/0";
static const String derivationPathWrappedSegwit = "m/49'/1'/0'/0";
static const String derivationPathNativeSegwit  = "m/84'/1'/0'/0";
static const String derivationPathTaproot       = "m/86'/1'/0'/0";
```

### AppDependencies (after 2.1–2.3)

```dart
final class AppDependencies {
  const AppDependencies({
    required this.walletRepository,
    required this.seedRepository,
    required this.bip39Service,
    required this.keyDerivationService,
  });

  final WalletRepository walletRepository;
  final SeedRepository seedRepository;
  final Bip39Service bip39Service;
  final KeyDerivationService keyDerivationService;
}
```

`AppDependenciesBuilder.build()` returns stubs that throw `UnimplementedError`.
Real implementations are wired in Phases 3–4.
