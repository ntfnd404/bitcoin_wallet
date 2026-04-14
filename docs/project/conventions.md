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
│   │   ├── address/                                ← independent bounded context
│   │   │   ├── domain/
│   │   │   │   └── usecase/
│   │   │   │       ├── generate_address_use_case.dart
│   │   │   │       ├── get_addresses_use_case.dart
│   │   │   │       └── strategy/
│   │   │   ├── bloc/
│   │   │   │   ├── address_bloc.dart
│   │   │   │   ├── address_event.dart
│   │   │   │   └── address_state.dart
│   │   │   ├── di/address_scope.dart
│   │   │   └── view/
│   │   │       ├── screen/address_screen.dart
│   │   │       └── widget/address_type_section.dart
│   │   │
│   │   └── wallet/
│   │       ├── domain/
│   │       │   └── usecase/             # Application-layer use cases
│   │       ├── bloc/wallet/
│   │       │   ├── wallet_bloc.dart
│   │       │   ├── wallet_event.dart
│   │       │   └── wallet_state.dart
│   │       ├── di/wallet_scope.dart
│   │       └── view/
│   │           ├── screen/
│   │           │   ├── list/            # WalletListScreen
│   │           │   ├── setup/           # CreateWalletScreen, SeedPhraseScreen, RestoreWalletScreen
│   │           │   └── detail/          # WalletDetailScreen
│   │           └── widget/
│   └── main.dart
└── packages/
    ├── domain/     # entities, repository interfaces, service interfaces (shared across features)
    ├── data/       # repository + service impls, local store, gateway, crypto
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

- Feature = **BLoC + DI + View + Application use cases**.
- A feature **may** contain `domain/usecase/` — these are Application-layer use cases
  that orchestrate infrastructure for this specific Bounded Context.
- A feature **must not** contain `data/` — repository/service implementations live in packages.
- Shared domain primitives (entities, repository interfaces, service interfaces) live in
  `packages/domain` and are consumed by both use cases and implementations.
- Each new Bounded Context gets its own `feature/<name>/` with its own `domain/usecase/`, BLoC, and view.
  Shared infra is added to packages.
- **Feature independence:** Features are independent Bounded Contexts. They do NOT import code from
  other features' domain/bloc layers. Cross-feature dependencies only allowed in:
  - Router (composition point)
  - UI (view importing another feature's view/widget is acceptable)
  - DI (scopes wired in app.dart)
- **Address feature:** Independent from Wallet. Owned by Wallet (walletId exists), but:
  - Can be queried independently (future: TransactionHistory will query addresses)
  - Has own AddressScope, BLoCs, views
  - Wallet feature does NOT import address/{domain,bloc}; uses address/{view,widget}

---

## Design Principles

SOLID, KISS, YAGNI, GRASP (High Cohesion, Low Coupling).
Patterns: Repository, Adapter, Factory, Observer, Strategy.
See [guidelines.md](./guidelines.md) for detailed examples.

---

## State Management

BLoC only — no Cubits. Events = past-tense user actions (`WalletListRequested`).
Hand-written immutable state classes — no `freezed` or code generation.

```dart
final class WalletState {
  const WalletState({
    this.wallets = const [],
    this.status = WalletStatus.initial,
    this.pendingWallet,
    this.pendingMnemonic,
    this.errorMessage,
  });

  final List<Wallet> wallets;
  final WalletStatus status;
  final Wallet? pendingWallet;
  final Mnemonic? pendingMnemonic;
  final String? errorMessage;

  WalletState copyWith({...});
}

enum WalletStatus { initial, loading, loaded, creating, awaitingSeedConfirmation, error }
```

BLoC constructors receive **use cases**, not repositories.

---

## Dependency Injection

- Constructor-based DI only. No service locator (no GetIt).
- **App-level**: `AppDependenciesBuilder` → `AppDependencies` (infra). `AppScope` (InheritedWidget) exposes it to tree.
- **Feature-level**: `WalletScope` is a `StatefulWidget` composition root:
  - Reads `AppDependencies` via `AppScope.of(context)` in `initState` 
  - Creates all feature use cases from dependencies
  - Session-level BLoC (`WalletBloc`) is created via static factory `WalletBlocFactory.create(...)` inside `BlocProvider(create: ...)` in `build()`
  - Session BLoC available to all descendants via `context.read<WalletBloc>()`
  - Screen-level BLoCs created on-demand via `WalletScope.newXxxBloc(context)` (static helper)
  - Screen-level BLoCs wrapped in `BlocProvider(create: ...)` inside route builders in `AppRouter`
- **Factory pattern**: Static factories (`abstract final class WalletBlocFactory`, `AddressBlocFactory`) with static `create(...)` methods — no instantiation, encapsulates assembly logic

---

## Repositories and Gateways

- `abstract interface class` for interfaces; `Impl` suffix for implementations.
- Doc comments on all interface methods.
- **Repository** = storage contract (CRUD). No business logic.
  - `WalletQueryRepository` — read-only composite interface (ISP).
  - `NodeWalletRepository implements WalletQueryRepository` — commands go via RPC gateway; queries served from local cache.
  - `HdWalletRepository implements WalletQueryRepository` — pure local CRUD.
  - `SeedRepository` — secure storage of mnemonics.
- **Gateway** = data-internal adapter for an external system. Not exported to domain.
  - `BitcoinCoreGateway` / `BitcoinCoreGatewayImpl` — wraps Bitcoin Core JSON-RPC. Lives in `packages/data/src/gateway/`.
- **CompositeWalletQueryRepository** — merges node + HD repositories for `GetWalletsUseCase`.
- **Use Cases** — Application layer, live in `lib/feature/<name>/domain/usecase/`. Orchestrate repositories and services; produce and return domain entities.

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

These are hard rules. Never violate them.

- **Never** use mainnet/testnet keys or real funds
- **Never** use `!` (null assertion) operator — null-check with a local variable instead
- **Never** use `dynamic` — use `Object` or `Object?`; JSON maps = `Map<String, Object?>`
- **Never** use `print` — use `dart:developer` log
- **Never** use Cubit — BLoC only, always
- **Never** use GetIt or any service locator — constructor DI + InheritedWidget only
- **Never** expose private keys outside the data/domain layer
- **Never** use relative imports — always `package:` imports
- **Never** use `BlocProvider.value` — always `BlocProvider(create: ...)`
- **Never** pass BLoC as constructor parameter to Widget — use `context.read<T>()` instead
- **Never** do `BlocProvider(create: (_) => widget.bloc)` — this hands lifecycle to provider while BLoC was created externally; let provider own the BLoC
- **Never** commit with analyzer warnings or infos — `flutter analyze --fatal-infos --fatal-warnings` must pass
- **Never** use `^` in dependency versions — exact versions only (e.g. `crypto: 3.0.7`)
- **Never** create private `_buildXxx` methods in widgets — extract as separate widget classes
- **Never** put repository/service implementations inside a feature directory — use `packages/data`
- **Never** put shared entities or interfaces inside a feature directory — use `packages/domain`
- **Never** log or expose mnemonic/seed/private key material in UI, logs, or error messages
