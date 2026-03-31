# Project Conventions

Architecture and code rules for bitcoin-wallet. Read first, always follow.

---

## Project Overview

**Bitcoin Wallet** — Flutter portfolio app demonstrating Bitcoin engineering fundamentals.
Backed by a local Bitcoin Core `regtest` node in Docker.
Platforms: iOS, Android, macOS, Windows, Linux (primary); Web optional.

---

## Wallet Types

### Node Wallet (custodial)
- Bitcoin Core manages keys; Flutter is a UI over JSON-RPC.

### HD Wallet (non-custodial)
- BIP39 mnemonic generated in-app; keys derived locally via BIP32/44/49/84/86.
- Seed stored in `flutter_secure_storage`.

---

## Supported Address Types

| Type | Script | Derivation path (regtest, coin=1) |
|------|--------|-----------------------------------|
| Legacy | P2PKH | `m/44'/1'/0'` |
| Wrapped SegWit | P2SH-P2WPKH | `m/49'/1'/0'` |
| Native SegWit | P2WPKH (Bech32) | `m/84'/1'/0'` |
| Taproot | P2TR (Bech32m) | `m/86'/1'/0'` |

Regtest prefixes: Legacy=`m`, P2SH=`2`, Bech32=`bcrt1q`, Bech32m=`bcrt1p`.

---

## RPC Connection

```
URL:  http://127.0.0.1:18443
Auth: bitcoin:bitcoin (Basic Auth)
```

Regtest only. `txindex=1`. No proxy.

---

## Architecture

### Layers (Clean Architecture + Hexagonal)

```
Presentation → Domain ← Data
```

- **Presentation** — Flutter UI + BLoC. `lib/`. Depends on `domain` interfaces only.
- **Domain** — entities + repository/service interfaces. Pure Dart. `packages/domain`.
- **Data** — implementations. `packages/data`. Uses `domain`, `rpc_client`, `storage`.
- **Infra** — `rpc_client`, `storage`: each wraps one external system, no domain knowledge.
- **UI** — `ui_kit`: design system, Flutter-only, no domain knowledge.

### Project structure

```
bitcoin_wallet/
├── lib/
│   ├── core/
│   │   ├── constants/app_constants.dart
│   │   ├── di/                          # AppDependencies, AppDependenciesBuilder, AppScope
│   │   └── routing/app_router.dart
│   ├── common/                          # widgets/, extensions/, utils/
│   ├── feature/
│   │   └── wallet/
│   │       ├── bloc/                    # WalletBloc, WalletEvent, WalletState
│   │       ├── di/wallet_scope.dart
│   │       └── view/screen/ + widget/
│   └── main.dart
└── packages/
    ├── domain/     # entities, repository interfaces, service interfaces
    ├── data/       # repository + service impls, local store, crypto
    ├── rpc_client/ # BitcoinRpcClient, RpcException
    ├── storage/    # SecureStorage interface + SecureStorageImpl
    └── ui_kit/     # tokens, typography, theme
```

### Package dependency graph

```
data      → domain, rpc_client, storage
ui_kit    → Flutter SDK
rpc_client → http
storage   → flutter_secure_storage
domain    → (nothing)
```

### Package type rules

| Type | Packages | Rule |
|------|----------|------|
| **core** | `domain` | Entities + interfaces. Pure Dart. Zero deps. |
| **core** | `data` | Implements domain. Orchestrates infra adapters. |
| **infra** | `rpc_client`, `storage` | Wraps one external system. No domain knowledge. |
| **ui** | `ui_kit` | Design system only. No domain knowledge. |

### Feature rules

- Feature = **BLoC + DI + View only** — no `domain/` or `data/` inside a feature.
- Domain and data shared exclusively via packages.

---

## Design Principles

SOLID, KISS, YAGNI, GRASP (High Cohesion, Low Coupling).
Patterns: Repository, Adapter, Factory, Observer, Strategy.
See [guidelines.md](./guidelines.md) for detailed examples.

---

## State Management

BLoC only — no Cubits. Events = past-tense user actions (`WalletListRequested`).

```dart
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

- Constructor-based DI. `InheritedWidget` at feature scope.
- No service locator (no GetIt).

---

## Repositories

- `abstract interface class` for interfaces; `Impl` suffix for implementations.
- Doc comments on all interface methods.

---

## Code Style

See [code-style-guide.md](./code-style-guide.md).

---

## Testing

- All Bitcoin-specific code (BIP39, derivation, coin selection, script) must have unit tests.
- RPC integration — tests against a live regtest node. Do not mock Bitcoin Core.

---

## Dependencies

- Exact versions: `crypto: 3.0.7`, not `^3.0.7`. Alphabetical in pubspec.yaml.
- No high-level Bitcoin wallet library — implement BIP39/BIP32/address encoding manually
  using `crypto` + `pointycastle`. Goal: demonstrate knowledge of Bitcoin standards.

---

## Prohibited

- Mainnet/testnet keys or real funds
- `!` operator — null-check with a local variable instead
- `dynamic` — use `Object` or `Object?`
- `print` — use `dart:developer` log
- Cubit, GetIt / service locator
- Private keys outside the data/domain layer
