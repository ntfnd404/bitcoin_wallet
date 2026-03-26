# Project Conventions

The project constitution — architecture and code rules for bitcoin-wallet.
All agents and Claude Code follow this document first.

---

## Project Overview

**Bitcoin Wallet** — Flutter portfolio app demonstrating Bitcoin engineering fundamentals.
Backed by a local Bitcoin Core `regtest` node in Docker.
Target platforms: iOS, Android, macOS, Windows, Linux. Web — optional.

---

## Platforms

| Platform | Status |
|----------|--------|
| iOS | Primary |
| Android | Primary |
| macOS | Primary |
| Windows | Primary |
| Linux | Primary |
| Web | Optional |

---

## Wallet Types

The app supports **two fundamentally different wallet types**:

### Node Wallet (custodial)
- Bitcoin Core manages and holds the keys
- Flutter is a UI layer communicating with the node via JSON-RPC
- Demonstrates: RPC skills, understanding of custodial architecture

### HD Wallet (non-custodial)
- BIP39 mnemonic is generated and stored in the app
- Key derivation happens locally following BIP32/44/49/84/86
- Seed phrase stored in `flutter_secure_storage`
- Demonstrates: cryptography, HD key derivation, self-custody

---

## Supported Address Types

All four types, for both wallet kinds:

| Type | Script | Derivation path (regtest, coin=1) |
|------|--------|-----------------------------------|
| Legacy | P2PKH | `m/44'/1'/0'` |
| Wrapped SegWit | P2SH-P2WPKH | `m/49'/1'/0'` |
| Native SegWit | P2WPKH (Bech32) | `m/84'/1'/0'` |
| Taproot | P2TR (Bech32m) | `m/86'/1'/0'` |

Regtest prefixes: Legacy=`m`, P2SH=`2`, Bech32=`bcrt1q`, Bech32m=`bcrt1p`.

---

## Seed Phrase

- BIP39 standard (12 or 24 words)
- Displayed to the user on wallet creation (user must confirm backup)
- Stored encrypted in `flutter_secure_storage`
- Full wallet restore from seed phrase is supported

---

## RPC Connection

```
URL:  http://127.0.0.1:18443
Auth: bitcoin:bitcoin (Basic Auth)
```

- Regtest only. No mainnet, no testnet.
- `txindex=1` enabled on the node.
- No server-side proxy between Flutter and Bitcoin Core.

---

## Architecture

### Layers (Clean Architecture)

```
Presentation → Domain → Data
```

- **Presentation**: Flutter UI, BLoC (`lib/feature/*/view/`, `lib/view/`)
- **Domain**: business logic, entities, repository interfaces (`lib/domain/`)
- **Data**: repository implementations, RPC client, storage (`lib/data/`)

### Module structure

Feature-first organization:

```
lib/
├── core/               # Shared: theme, extensions, utils, constants
├── data/               # Data layer
│   ├── api/            # Bitcoin Core RPC client
│   ├── repository/     # Repository implementations
│   └── storage/        # flutter_secure_storage adapter
├── domain/             # Domain layer
│   ├── model/          # Entities (Wallet, Address, Mnemonic, Utxo, Tx)
│   ├── repository/     # Repository interfaces (abstract interface class)
│   └── service/        # Domain services (BIP39, key derivation)
├── feature/            # Feature modules
│   └── <feature>/
│       ├── bloc/       # BLoC: events, states
│       ├── di/         # Scoped DI (Scope widget + BlocFactory)
│       ├── domain/     # Feature-specific business logic
│       └── view/       # Screens + widgets/
├── routing/            # go_router
└── view/               # Shared UI components
```

---

## State Management

- **BLoC only** — no Cubits
- Events named as completed actions: `WalletCreated`, `AddressGenerated`, `SeedConfirmed`
- State: single freezed class with an enum status (not multiple factory constructors)
- All mutable state lives in the State class, never in private BLoC fields
- Exception: `StreamSubscription` is allowed as a private field

```dart
// Correct
@freezed
abstract class WalletState with _$WalletState {
  const factory WalletState({
    @Default([]) List<Wallet> wallets,
    @Default(WalletStatus.initial) WalletStatus status,
  }) = _WalletState;
}

enum WalletStatus { initial, loading, loaded, error }
```

---

## Dependency Injection

- Manual constructor-based DI via factory classes
- `InheritedWidget` scopes at the feature level
- No service locator (no GetIt etc.)
- Navigation wraps Scope, not BlocProvider

---

## Repositories

- `abstract interface class` for the interface
- `Impl` suffix for the implementation
- Doc comments on all interface methods
- `tryFrom*` for nullable factory constructors

```dart
abstract interface class WalletRepository {
  /// Creates a new HD wallet and returns the generated mnemonic.
  Future<(Wallet, Mnemonic)> createHDWallet(String name);
}

class WalletRepositoryImpl implements WalletRepository { ... }
```

---

## Code Style

- Dart 3+ with null safety
- **Never `!` operator** — always null-check with a local variable
- **Never `print`** — use `dart:developer` log or a proper logger
- Trailing commas in multi-line constructs
- Curly braces in all `if`/`for`/`while`
- Single quotes
- `_` prefix for private members
- One class/model = one file
- Functions: aim for <20 lines, single responsibility
- No magic numbers — use named constants

---

## Testing

- All Bitcoin-specific code (BIP39, key derivation, coin selection, script) must have unit tests
- RPC integration — integration tests against a live regtest node (do not mock Bitcoin Core)
- Tests are a separate task, not part of feature implementation

---

## Dependencies

- Exact versions without caret (`coinlib: 2.2.0`, not `^2.2.0`)
- Sorted alphabetically in pubspec.yaml
- Before adding a new package: verify platform support and regtest compatibility

---

## Prohibited

- Mainnet/testnet keys or real funds
- Hardcoded credentials outside of configuration constants
- `!` operator
- `print`
- Cubit
- GetIt / service locator
- Private keys handled outside the data/domain layer
