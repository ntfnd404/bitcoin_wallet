# Plan: BW-0001 Phase 2 — Domain Models & Interfaces

Status: `PLAN_APPROVED`
Ticket: BW-0001

---

## Overview

Create all domain entities and interfaces in `packages/domain/lib/src/`.
Update `AppConstants` with derivation paths.
Update `AppDependencies` + `AppDependenciesBuilder` to use typed fields.

**Package rules:** `packages/domain` stays zero-dependency. No Flutter imports.

---

## Implementation order

1. `2.6` — `BitcoinNetwork` enum (needed by 2.4)
2. `2.1` — entities (enums first, then classes)
3. `2.2` — repository interfaces
4. `2.3` — service interfaces
5. `2.4` — `AppConstants` using `BitcoinNetwork`
6. Update `packages/domain/lib/domain.dart` barrel — uncomment exports
7. Update `lib/core/di/app_dependencies.dart` — add typed fields
8. Update `lib/core/di/app_dependencies_builder.dart` — add stubs
9. `flutter analyze` — must be zero warnings

---

## Files to create

### `packages/domain/lib/src/entity/bitcoin_network.dart`

```dart
/// Bitcoin network configuration.
///
/// Switching the active network requires changing one constant in [AppConstants].
enum BitcoinNetwork {
  mainnet(
    p2pkhPrefix: 0x00,
    p2shPrefix: 0x05,
    bech32Hrp: 'bc',
    coinType: 0,
    rpcPort: 8332,
  ),
  testnet(
    p2pkhPrefix: 0x6F,
    p2shPrefix: 0xC4,
    bech32Hrp: 'tb',
    coinType: 1,
    rpcPort: 18332,
  ),
  regtest(
    p2pkhPrefix: 0x6F,
    p2shPrefix: 0xC4,
    bech32Hrp: 'bcrt',
    coinType: 1,
    rpcPort: 18443,
  );

  const BitcoinNetwork({
    required this.p2pkhPrefix,
    required this.p2shPrefix,
    required this.bech32Hrp,
    required this.coinType,
    required this.rpcPort,
  });

  /// Version byte for P2PKH (Legacy) addresses.
  final int p2pkhPrefix;

  /// Version byte for P2SH (Wrapped SegWit) addresses.
  final int p2shPrefix;

  /// Human-readable part for Bech32/Bech32m addresses.
  final String bech32Hrp;

  /// BIP44 coin_type: 0 = mainnet, 1 = testnet/regtest.
  final int coinType;

  /// Default Bitcoin Core RPC port for this network.
  final int rpcPort;
}
```

### `packages/domain/lib/src/entity/wallet_type.dart`

```dart
enum WalletType { node, hd }
```

### `packages/domain/lib/src/entity/address_type.dart`

```dart
enum AddressType { legacy, wrappedSegwit, nativeSegwit, taproot }
```

### `packages/domain/lib/src/entity/wallet.dart`

```dart
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
  }) =>
      Wallet(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
      );
}
```

### `packages/domain/lib/src/entity/address.dart`

```dart
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
  final String? derivationPath;

  Address copyWith({
    String? value,
    AddressType? type,
    String? walletId,
    int? index,
    String? derivationPath,
  }) =>
      Address(
        value: value ?? this.value,
        type: type ?? this.type,
        walletId: walletId ?? this.walletId,
        index: index ?? this.index,
        derivationPath: derivationPath ?? this.derivationPath,
      );
}
```

### `packages/domain/lib/src/entity/mnemonic.dart`

```dart
/// Immutable wrapper around a BIP39 word list.
///
/// Does not override [toString] — prevents accidental logging of seed words.
final class Mnemonic {
  const Mnemonic({required this.words});

  final List<String> words;
}
```

### `packages/domain/lib/src/repository/wallet_repository.dart`

```dart
import '../entity/address.dart';
import '../entity/address_type.dart';
import '../entity/mnemonic.dart';
import '../entity/wallet.dart';

abstract interface class WalletRepository {
  /// Returns all wallets persisted on this device.
  Future<List<Wallet>> getWallets();

  /// Creates a new Node Wallet via Bitcoin Core RPC `createwallet`.
  ///
  /// Throws [UnsupportedError] if called on an HD-only implementation.
  Future<Wallet> createNodeWallet(String name);

  /// Creates a new HD Wallet, generates a BIP39 mnemonic, stores the seed,
  /// and returns both the wallet metadata and the mnemonic.
  ///
  /// [wordCount] must be 12 or 24.
  /// Throws [UnsupportedError] if called on a Node-only implementation.
  Future<(Wallet, Mnemonic)> createHDWallet(String name, {int wordCount = 12});

  /// Restores an HD Wallet from an existing [mnemonic] after BIP39 validation.
  ///
  /// Throws [ArgumentError] if [mnemonic] fails BIP39 checksum validation.
  /// Throws [UnsupportedError] if called on a Node-only implementation.
  Future<Wallet> restoreHDWallet(String name, Mnemonic mnemonic);

  /// Generates the next address of [type] for [wallet].
  Future<Address> generateAddress(Wallet wallet, AddressType type);

  /// Returns all addresses previously generated for [wallet].
  Future<List<Address>> getAddresses(Wallet wallet);
}
```

### `packages/domain/lib/src/repository/seed_repository.dart`

```dart
import '../entity/mnemonic.dart';

abstract interface class SeedRepository {
  /// Persists [mnemonic] for [walletId] in secure storage.
  Future<void> storeSeed(String walletId, Mnemonic mnemonic);

  /// Returns the [Mnemonic] for [walletId], or `null` if none is stored.
  Future<Mnemonic?> getSeed(String walletId);

  /// Deletes the stored seed for [walletId]. No-op if absent.
  Future<void> deleteSeed(String walletId);
}
```

### `packages/domain/lib/src/service/bip39_service.dart`

```dart
import '../entity/mnemonic.dart';

abstract interface class Bip39Service {
  /// Generates a BIP39 mnemonic with [wordCount] words (12 or 24).
  ///
  /// Throws [ArgumentError] if [wordCount] is not 12 or 24.
  Mnemonic generateMnemonic({int wordCount = 12});

  /// Returns `true` if [mnemonic] passes BIP39 checksum validation.
  bool validateMnemonic(Mnemonic mnemonic);
}
```

### `packages/domain/lib/src/service/key_derivation_service.dart`

```dart
import '../entity/address.dart';
import '../entity/address_type.dart';
import '../entity/mnemonic.dart';

abstract interface class KeyDerivationService {
  /// Derives a Bitcoin address from [mnemonic] at [type] and [index].
  ///
  /// Derivation paths (regtest, coin_type=1):
  /// - legacy          → m/44'/1'/0'/0/[index]
  /// - wrappedSegwit   → m/49'/1'/0'/0/[index]
  /// - nativeSegwit    → m/84'/1'/0'/0/[index]
  /// - taproot         → m/86'/1'/0'/0/[index]
  Address deriveAddress(Mnemonic mnemonic, AddressType type, int index);
}
```

---

## Files to update

### `packages/domain/lib/domain.dart`

Uncomment exports as files are created:
```dart
export 'src/entity/address.dart';
export 'src/entity/address_type.dart';
export 'src/entity/mnemonic.dart';
export 'src/entity/wallet.dart';
export 'src/entity/wallet_type.dart';
export 'src/repository/seed_repository.dart';
export 'src/repository/wallet_repository.dart';
export 'src/service/bip39_service.dart';
export 'src/service/key_derivation_service.dart';
// export 'src/entity/utxo.dart';  ← Phase 4 scope, leave commented
```

### `lib/core/constants/app_constants.dart`

Replace with network-aware version:
```dart
import 'package:domain/domain.dart';

abstract final class AppConstants {
  /// Active Bitcoin network. Change this one constant to switch networks.
  static const BitcoinNetwork network = BitcoinNetwork.regtest;

  static String get rpcUrl => 'http://127.0.0.1:${network.rpcPort}';
  static const String rpcUser     = 'bitcoin';
  static const String rpcPassword = 'bitcoin';

  /// BIP44/49/84/86 account-level paths. Append '/<index>' at derivation time.
  static String get derivationPathLegacy =>
      "m/44'/${network.coinType}'/0'/0";
  static String get derivationPathWrappedSegwit =>
      "m/49'/${network.coinType}'/0'/0";
  static String get derivationPathNativeSegwit =>
      "m/84'/${network.coinType}'/0'/0";
  static String get derivationPathTaproot =>
      "m/86'/${network.coinType}'/0'/0";
}
```

### `lib/core/di/app_scope.dart`

`AppScope` (InheritedWidget) — отделён от `lib/app.dart`.
`AppScope` — инфраструктура, не фича. Живёт в `lib/core/di/`.

### `lib/core/di/app_dependencies.dart`

```dart
import 'package:domain/domain.dart';

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

### `lib/core/di/app_dependencies_builder.dart`

Add private stub classes (throw `UnimplementedError`), return them from `build()`.
Stubs are named `_StubWalletRepository`, `_StubSeedRepository`, etc.

---

## Verification

```sh
flutter analyze          # zero warnings
flutter run -d macos     # app launches, Hello World visible
```

Manually verify: `AppScope.of(context)` is accessible (no StateError at launch).
