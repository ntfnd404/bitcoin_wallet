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

### Layers (Clean Architecture + Hexagonal)

```
Presentation → Domain ← Data
```

- **Presentation** — Flutter UI + BLoC. Lives in `lib/`. Depends on `domain` interfaces only.
- **Domain** — entities + repository/service interfaces. Pure Dart, no Flutter. `packages/domain`.
- **Data** — repository and service implementations. `packages/data`. Uses `domain`, `rpc_client`, `storage`.
- **Infra adapters** — `rpc_client`, `storage`: each wraps one external system, no domain knowledge.
- **Design system** — `ui_kit`: Flutter-only, no domain knowledge.

### Full project structure

```
bitcoin_wallet/                             # Flutter app — workspace root
│
├── lib/
│   │
│   ├── core/                               # Infrastructure — no UI widgets
│   │   ├── constants/                      # AppConstants: rpcUrl, rpcUser, derivation paths
│   │   │   └── app_constants.dart
│   │   └── routing/                        # AppRouter, route name constants
│   │       └── app_router.dart
│   │
│   ├── common/                             # Shared Flutter code (not design-system)
│   │   ├── widgets/                        # App-level shared components
│   │   ├── extensions/                     # BuildContext, String, Iterable extensions
│   │   └── utils/                          # Pure helpers, no Flutter dependency
│   │
│   ├── feature/                            # Feature-first modules
│   │   └── wallet/                         # ← one folder per feature
│   │       ├── bloc/
│   │       │   ├── wallet_bloc.dart
│   │       │   ├── wallet_event.dart
│   │       │   └── wallet_state.dart       # + feature-specific mappers here
│   │       ├── di/
│   │       │   └── wallet_scope.dart       # InheritedWidget + BlocFactory
│   │       └── view/
│   │           ├── screen/
│   │           │   ├── wallet_list_screen.dart
│   │           │   ├── wallet_detail_screen.dart
│   │           │   ├── create_wallet_screen.dart
│   │           │   ├── seed_phrase_screen.dart
│   │           │   ├── restore_wallet_screen.dart
│   │           │   └── address_screen.dart
│   │           └── widget/
│   │               └── wallet_card.dart
│   │
│   └── main.dart
│
├── packages/
│   │
│   │   ╔═ CORE ════════════════════════════════════════════════════════╗
│   │
│   ├── domain/                             # Pure Dart — zero dependencies
│   │   └── lib/src/
│   │       ├── entity/                     # Wallet, Address, Mnemonic, AddressType, WalletType
│   │       ├── repository/                 # abstract interface WalletRepository, SeedRepository
│   │       └── service/                    # abstract interface Bip39Service, KeyDerivationService
│   │
│   ├── data/                               # Implements domain interfaces
│   │   └── lib/src/                        # Depends on: domain, rpc_client, storage
│   │       ├── repository/                 # NodeWalletRepositoryImpl, HdWalletRepositoryImpl, SeedRepositoryImpl
│   │       └── service/                    # Bip39ServiceImpl, KeyDerivationServiceImpl
│   │
│   │   ╔═ INFRA ════════════════════════════════════════════════════════╗
│   │
│   ├── rpc_client/                                # Bitcoin Core JSON-RPC HTTP client
│   │   └── lib/src/                        # Pure Dart — no domain knowledge
│   │       └── bitcoin_rpc_client.dart     # BitcoinRpcClient, RpcException
│   │
│   ├── storage/                            # flutter_secure_storage adapter
│   │   └── lib/src/                        # Thin wrapper — write / read / delete
│   │       └── secure_storage.dart
│   │
│   │   ╔═ UI ═══════════════════════════════════════════════════════════╗
│   │
│   └── ui_kit/                             # Design system — Flutter only, no domain
│       └── lib/src/
│           ├── tokens/                     # Colors, spacing, sizes (design tokens)
│           ├── typography/                 # Text styles
│           └── theme/                      # AppTheme, ThemeData
│
└── pubspec.yaml                            # workspace: lists all packages
```

### Package dependency graph

```
lib/ (Flutter app)
  ├── common/          ──→  ui_kit
  ├── feature/wallet/  ──→  data, domain, ui_kit
  │
  └── [packages]
        data      ──→  domain, rpc_client, storage
        ui_kit    ──→  Flutter SDK
        rpc_client ──→  http
        storage   ──→  flutter_secure_storage
        domain    ──→  (nothing — stable core)
```

### Package type rules

| Type | Packages | Rule | Dependencies |
|------|----------|------|--------------|
| **core** | `domain` | Entities + interfaces. Pure Dart. Zero deps. Never knows about Flutter or infra. | — |
| **core** | `data` | Implements domain interfaces. Orchestrates infra adapters. | `domain`, `rpc_client`, `storage` |
| **infra** | `rpc_client`, `storage` | Each wraps exactly one external system. No domain knowledge. | external lib only |
| **ui** | `ui_kit` | Design system: tokens, typography, theme. No domain knowledge. | Flutter SDK only |
| **integration** | *(future)* | External protocol or SDK with its own logic/UI (WalletConnect, MFA, TPM…). | `domain` + `ui_kit` if needed |

### Rule for adding a new package

Ask: what category is it?

- Wraps an external system (TPM, MFA, WalletConnect protocol, window_manager) → **infra** package
- Adds UI components or design primitives → **ui** package or extend `ui_kit`
- Brings a full SDK with logic + screens (WalletConnect UI, analytics) → **integration** package
- Is pure shared business logic → extend `domain`

### Feature rules

- A feature contains **BLoC + DI + View only** — no `domain/` or `data/` subdirs inside a feature.
- Feature-specific mappers live in `bloc/` alongside the BLoC they serve.
- Domain and data are shared exclusively via packages.

---

## Design Principles

We follow **SOLID**, **KISS**, **YAGNI**, and key **GRASP** principles (High Cohesion, Low Coupling, Information Expert, Protected Variations).
Design patterns in use: Repository, Adapter, Factory, Observer, Strategy.
See [docs/project/guidelines.md](./guidelines.md) for detailed guidance and examples.

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
- **Never `dynamic`** — use `Object` (non-nullable) or `Object?` (nullable); JSON maps are `Map<String, Object?>`
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

- Exact versions without caret (`crypto: 3.0.7`, `pointycastle: 4.0.0`, not `^3.0.7`)
- Sorted alphabetically in pubspec.yaml
- Before adding a new package: verify platform support and regtest compatibility
- BIP39/BIP32/address encoding is implemented manually using low-level crypto primitives (`crypto`, `pointycastle`). No high-level Bitcoin wallet library is used — the goal is to demonstrate knowledge of Bitcoin standards.

---

## Prohibited

- Mainnet/testnet keys or real funds
- Hardcoded credentials outside of configuration constants
- `!` operator
- `dynamic` — use `Object` or `Object?` instead
- `print`
- Cubit
- GetIt / service locator
- Private keys handled outside the data/domain layer
